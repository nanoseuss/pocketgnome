//
//  FishController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/23/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "FishController.h"
#import "Controller.h"
#import "NodeController.h"
#import "PlayerDataController.h"
#import "ChatController.h"
#import "BotController.h"
#import "InventoryController.h"
#import "MemoryViewController.h"
#import "LootController.h"
#import "SpellController.h"
#import "MovementController.h"

#import "Offsets.h"
#import "Errors.h"

#import "Node.h"
#import "Position.h"
#import "MemoryAccess.h"
#import "Player.h"
#import "Item.h"
#import "Spell.h"

#import "PTHeader.h"

#import <ShortcutRecorder/ShortcutRecorder.h>

#define USE_ITEM_MASK       0x80000000

#define ITEM_REINFORCED_CRATE	44475


#define OFFSET_MOVED			0xB4		// When this is 1 the bobber has moved!  Offset from the base address
#define OFFSET_STATUS			0xB6		// This is 132 when the bobber is normal, shortly after it moves it's 148, then finally finishes at 133 (is it animation state?)
	#define STATUS_NORMAL		132
#define OFFSET_VISIBILITY		0xC0		// Set this to 0 to hide the bobber!

// TO DO:
//	Log out on full inventory
//  Add a check for hostile players near you
//  Add a check for friendly players near you (and whisper check?)
//  Check for GMs?
//	Add a check for the following items: "Reinforced Crate", "Borean Leather Scraps", then /use them :-)
//  Select a route to run back in case you are killed (add a delay until res option as well?)
//  /use Bloated Mud Snapper
//  Recast if didn't land near the school?
//  new bobber detection method?  fire event when it's found?  Can check for invalid by firing off [node validToLoot]
//  turn on keyboard turning if we're facing a node?
//  make sure user has bobbers in inventory
//  closing wow will crash PG - fix this

@interface FishController (Internal)
- (void)updateFishCount;
- (void)startFishing;
- (void)stopFishing;
- (void)fishBegin;
- (BOOL)applyLure;
- (Node*)faceNearestSchool;
- (void)fishingController;
@end


@implementation FishController

- (id)init{
    self = [super init];
    if (self != nil) {
		
		_isFishing = NO;
		_playerGUID = 0;
		_totalFishLooted = 0;
		_ignoreIsFishing = NO;
		_bobber = nil;
		_useContainer = 0;
		//_blockActions = NO;
		
		// UI options
		_optApplyLure = NO;
		_optKillWow = NO;
		_optShowGrowl = NO;
		_optUseContainers = NO;
		_optFaceSchool = NO;
		_optRecast = NO;
		_optHideOtherBobbers = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(fishLooted:) 
                                                     name: ItemLootedNotification 
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self 
												 selector: @selector(playerHasDied:) 
													 name: PlayerHasDiedNotification 
												   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsInvalid:) 
                                                     name: PlayerIsInvalidNotification 
                                                   object: nil];
		
        [NSBundle loadNibNamed: @"Fishing" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
	
    [fishingRecorder setCanCaptureGlobalHotKeys: YES];
    
    KeyCombo combo1 = { NSShiftKeyMask, kSRKeysF13 };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"FishingCode"])
        combo1.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"FishingCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"FishingFlags"])
        combo1.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"FishingFlags"] intValue];
	
    [fishingRecorder setDelegate: nil];
	
    [fishingRecorder setKeyCombo: combo1];
    
    [fishingRecorder setDelegate: self];
}


@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Fishing";
}

// Called when player clicks start/stop fishing!
- (IBAction)startStopFishing: (id)sender {	

	if ( ![playerController playerIsValid] ){
		[status setStringValue: [NSString stringWithFormat:@"Player not valid!"]];
		return;
	}
	
	// This never changes, so lets store it so we aren't reading it during our main thread
	_playerGUID = [[playerController player] GUID];
	
	Spell *fishingSpell = [spellController playerSpellForName: @"Fishing"];
	if ( fishingSpell ){
		_fishingSpellID = [[fishingSpell ID] intValue];
	}
	else{
		[status setStringValue: [NSString stringWithFormat:@"You need to learn fishing!"]];
		return;
	}
	
	// Load up our GUI checkboxes!
	_optApplyLure			= [applyLureCheckbox state];
	_optKillWow				= [killWoWCheckbox state];
	_optShowGrowl			= [showGrowlNotifications state];
	_optUseContainers		= [useContainers state];
	_optFaceSchool			= [faceSchool state];
	_optRecast				= [recastIfMiss state];
	_optHideOtherBobbers	= [hideOtherBobbers state];
	
	// Reset our fishing variables!
	_applyLureAttempts = 0;
	_ignoreIsFishing = NO;
	
	if ( _isFishing ){
		[self stopFishing];
	}
	else{
		[self startFishing];
	}
}

- (void)startFishing{
	_isFishing = YES;
	
	[startStopButton setTitle: @"Stop Fishing"];
	
	// Reset our loot!
	_totalFishLooted = 0;
	[lootController resetLoot];
	//[statisticsTableView reloadData];
	//[self updateFishCount];
	
	// Start our "kill wow" timer if we need to
	if ( _optKillWow ){
		[self performSelector: @selector(closeWoW) withObject: nil afterDelay:[closeWoWTimer floatValue]*60*60 ];
	}
	
	// Fire off a thread to handle all fishing!
	[NSThread detachNewThreadSelector: @selector(fishingController) toTarget: self withObject: nil];
	//[self fishingController];
}

- (void)stopFishing{
	[startStopButton setTitle: @"Start Fishing"];
	
	_isFishing = NO;
}

- (void)closeWoW{
	if ( _isFishing ){
		[self stopFishing];
		
		[controller killWOW];
	}
}

- (BOOL)isFishing{
	return ( ([playerController spellCasting] == _fishingSpellID) ? YES : NO);
}

- (void)fishBegin{
	if ( !_isFishing){
		return;
	}
	
	// Well we don't want to fish if something killed us do we!
	if ( [playerController isDead] ){
		[self stopFishing];
		return;
	}
	
	// Lets apply some lure if we need to!
	if ( [self applyLure] ){
		return;
	}
	
	// Do we want to face the nearest school?
	if ( _optFaceSchool ){
		_nearbySchool = [self faceNearestSchool];
	}
	
	// We don't want to start fishing if we already are!
	if ( ![self isFishing] || _ignoreIsFishing ){
		
		// Reset this!  We only want this to be YES when we have to re-cast b/c we're not close to a school!
		_ignoreIsFishing = NO;
		
		// Do we need to use a crate?
		if ( _useContainer > 0 && _optUseContainers ){
			
			// Use our crate!
			[botController performAction:(USE_ITEM_MASK + _useContainer)];
			
			// Wait a bit so we can loot it!
			usleep([controller refreshDelay]*2);
			
			// Reset our container item ID!
			_useContainer = 0;
			
			[status setStringValue: [NSString stringWithFormat:@"Empyting a container"]];
		}
		
		// If casting fails for some reason lets try again in a second!
		int castSuccess = [botController performAction: _fishingSpellID];
		[status setStringValue: [NSString stringWithFormat:@"Fishing"]];
		if ( castSuccess != ErrNone ){
			
			// Check for "full inventory" and kill wow if we get here :/
			if ( castSuccess == ErrInventoryFull ){
				[status setStringValue: [NSString stringWithFormat:@"Closing WoW, Inventory is Full"]];
				
				[self closeWoW];
			}
		}
	}
}

- (BOOL)applyLure{
	if ( !_optApplyLure ){
		return NO;
	}
	
	Item *item = [itemController itemForGUID: [[playerController player] itemGUIDinSlot: SLOT_MAIN_HAND]];
	if ( ![item hasTempEnchantment] && _applyLureAttempts < 3 ){
		
		int lureItemID = [[luresPopUpButton selectedItem] tag];

		// Lets actually use the item we want to apply!
		[botController performAction:(USE_ITEM_MASK + lureItemID)];
		
		// Wait a bit before we cast the next one!
		usleep([controller refreshDelay]*2);
		
		// Now use our fishing pole so it's applied!
		[botController performAction:(USE_ITEM_MASK + [item entryID])];
		
		// we may need this?
		usleep([controller refreshDelay]);
		
		// Are we casting the lure on our fishing pole?
		if ( [playerController spellCasting] > 0 ){
			_applyLureAttempts = 0;
			[status setStringValue: [NSString stringWithFormat:@"Applying Lure"]];
			
			//_blockActions = YES;
			
			//[self performSelector: @selector(resetBlock) withObject: nil afterDelay:3.5 ];
			
			// This will "pause" our main thread until this is complete!
			usleep(3500000);
		}
		else{
			_applyLureAttempts++;
		}
		
		return YES;
	}
	
	return NO;
}

//- (void)resetBlock{
	//_blockActions = NO;	
//}

- (Node*)faceNearestSchool{
	NSArray *fishingSchools = [nodeController allFishingSchools];
	Position *playerPosition = [playerController position];
	
	float closestDistance = INFINITY;
	float distance = INFINITY;
	Node *closestNode = nil;
	for ( Node *school in fishingSchools ){
		distance = [playerPosition distanceToPosition: [school position]];
		
		if ( distance <= 25.0f && distance < closestDistance ){
			closestNode = school;
			closestDistance = distance;
		}
	}
	
	// Then we have a fishing pool w/in range!
	if ( closestNode != nil ){
		[movementController turnTowardObject: closestNode];
		return closestNode;
	}
	
	return nil;
}


// We just want to run this in it's own thread, basically it will just find our bobbers for us :-)
// TO DO: THERE IS A CRASH IN HERE SOMEWHERE! No clue where... stack:
/*
 Thread 7 Crashed:
 0   libobjc.A.dylib               	0x90ceaef4 _objc_error + 116
 1   libobjc.A.dylib               	0x90ceaf2a __objc_error + 52
 2   libobjc.A.dylib               	0x90ce921c _freedHandler + 58
 3   com.savorydeviate.PocketGnome 	0x000642a2 -[FishController fishingController] + 888 (FishController.m:415)
 4   com.apple.Foundation          	0x93865964 -[NSThread main] + 45
 5   com.apple.Foundation          	0x93865914 __NSThread__main__ + 1499
 6   libSystem.B.dylib             	0x9910dfe1 _pthread_start + 345
 7   libSystem.B.dylib             	0x9910de66 thread_start + 34
 
 Thread 7 Crashed:
 0   libobjc.A.dylib               	0x90ce1924 objc_msgSend + 36
 1   com.apple.Foundation          	0x93865964 -[NSThread main] + 45
 2   com.apple.Foundation          	0x93865914 __NSThread__main__ + 1499
 3   libSystem.B.dylib             	0x9910dfe1 _pthread_start + 345
 4   libSystem.B.dylib             	0x9910de66 thread_start + 34
 */
- (void)fishingController{
	
	if ( !_isFishing ){
		return;
	}
	
	// We don't want to do anything here :(  /cry  Check again shortly!
	//if ( _blockActions ){
	//	[self performSelector: @selector(fishingController) withObject: nil afterDelay:0.1];
		
	//	return;
	//}
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	UInt16 stat, bouncing;
	int lootWindowOpenCount = 0;
	BOOL clicked = NO;

	while ( _isFishing ){
		// Find our bobber!
		for ( Node *bobber in [nodeController allFishingBobbers] ){
			// If this isn't 132, then the bobber is gone or just got activated!  (I believe this is the animation state, but not 100% sure)
			if ( [[controller wowMemoryAccess] loadDataForObject: self atAddress: ([bobber baseAddress] + OFFSET_STATUS) Buffer: (Byte *)&stat BufLength: sizeof(stat)] ){
			
				// Our player's bobber!
				if ( [bobber owner] == _playerGUID ){

					// Is our bobber normal yet?
					if ( stat == STATUS_NORMAL ){
						
						// Then we found a new bobber!
						if ( _bobber != bobber ){
							_bobber = bobber;
							
							//[memoryViewController setBaseAddress:[NSNumber numberWithInt:[_bobber baseAddress]]];
							
							// Should we check to see if it landed nearby?
							if ( _nearbySchool && _optFaceSchool && _optRecast ){
								float distance = [[bobber position] distanceToPosition: [_nearbySchool position]];
								
								// Reset this, otherwise we might try to read it when we don't want to! ( = crash)
								_nearbySchool = nil;
								
								// Fish again! Didn't land in the school!
								if ( distance > 5.0f ){
									_ignoreIsFishing = YES;
									
									[self fishBegin];
								}
							}
						}
					}
				}
				// not ours - hide it?
				else if ( _optHideOtherBobbers && _bobber != bobber ){
					UInt8 value = 0;
					[[controller wowMemoryAccess] saveDataForAddress: ([bobber baseAddress] + OFFSET_VISIBILITY) Buffer: (Byte *)&value BufLength: sizeof(value)];
				}
			}
		}
		
		// Check to see if we should take action on our bobber!
		if ( _bobber ){
			// Grab some values!
			if ( [[controller wowMemoryAccess] loadDataForObject: self atAddress: ([_bobber baseAddress] + OFFSET_MOVED) Buffer: (Byte *)&bouncing BufLength: sizeof(bouncing)] ){
				[[controller wowMemoryAccess] loadDataForObject: self atAddress: ([_bobber baseAddress] + OFFSET_STATUS) Buffer: (Byte *)&stat BufLength: sizeof(stat)];
				
				// Time to click!
				if ( bouncing && !clicked ){
					[status setStringValue: [NSString stringWithFormat:@"Looting"]];
					clicked = YES;

					// "Click" our bobber!
					if ( ![botController interactWithMouseoverGUID: [_bobber GUID]] ){
						[status setStringValue: [NSString stringWithFormat:@"Did you forget to bind your Interact with Mouseover?"]];
					}
				}
			}
			
			// Our bobber is gone! O noes!  Set it to nil so on next pass we start fishing again!
			if ( stat != STATUS_NORMAL ){
				_bobber = nil;
				clicked = NO;
			}
			
			// Sometimes the loot window sticks, i hate it, lets add a fix!
			if ( [lootController isLootWindowOpen] ){
				lootWindowOpenCount++;
				
				// Loot window has been open too long lets accept it!
				if ( lootWindowOpenCount > 20 ){
					[lootController acceptLoot];
				}
			}
		}
		else{

			// Only start fishing again if we're not casting!  We could be fishing our applying Lure!
			if ( ![playerController spellCasting] ){
				[self fishBegin];
				lootWindowOpenCount = 0;
			}
		}
		
		// Sleep for 0.1 seconds
		usleep(100000);
	}
	//[self performSelector: @selector(fishingController) withObject: nil afterDelay:0.1];

	
	[pool drain];
}

- (void)updateFishCount{
	//double differenceInSeconds = [_startTime timeIntervalSinceNow];
	//double fishPerSecond = (float)_totalFishLooted/differenceInSeconds;
	
	[fishCaught setStringValue: [NSString stringWithFormat: @"Fish Caught: %d", _totalFishLooted]];
	
	[statisticsTableView reloadData];
}

- (IBAction)showBobberStructure: (id)sender{
	if ( _bobber == nil || !_isFishing ){
		return;
	}
	
	if ( [_bobber infoAddress] > 0 ){
		[memoryViewController setBaseAddress:[NSNumber numberWithInt:[_bobber baseAddress]]];
		//[memoryViewController showObjectMemory: _bobber];
		[controller showMemoryView];
	}
}

- (IBAction)tmp: (id)sender{
	
	//[itemController itemsInBags];
	
}

#pragma mark Notifications

// Called whenever ANY item is looted
- (void)fishLooted: (NSNotification*)notification {
	if ( !_isFishing )
		return;
	
	NSNumber *itemID = (NSNumber *)[notification object];
	
	// Lets use the crate we looted!
	if ( [itemID intValue] == ITEM_REINFORCED_CRATE ){
		_useContainer = ITEM_REINFORCED_CRATE;
	}
	
	_totalFishLooted++;
	
	[self updateFishCount];
}

- (void)playerHasDied: (NSNotification*)not { 
	[status setStringValue: [NSString stringWithFormat:@"Player has died, fishing stopped"]];
	[self stopFishing];
	
}

- (void)playerIsInvalid: (NSNotification*)not {
    if( _isFishing ) {
		[status setStringValue: [NSString stringWithFormat:@"Player is no longer valid, fishing stopped"]];
        [self stopFishing];
    }
}

#pragma mark ShortcutRecorder Delegate

- (void)toggleGlobalHotKey:(SRRecorderControl*)sender
{
	if (startStopBotGlobalHotkey != nil) {
		[[PTHotKeyCenter sharedCenter] unregisterHotKey: startStopBotGlobalHotkey];
		[startStopBotGlobalHotkey release];
		startStopBotGlobalHotkey = nil;
	}
    
    KeyCombo keyCombo = [sender keyCombo];
    
    if((keyCombo.code >= 0) && (keyCombo.flags >= 0)) {
        startStopBotGlobalHotkey = [[PTHotKey alloc] initWithIdentifier: @"StartStopBot"
                                                               keyCombo: [PTKeyCombo keyComboWithKeyCode: keyCombo.code
                                                                                               modifiers: [sender cocoaToCarbonFlags: keyCombo.flags]]];
        
        [startStopBotGlobalHotkey setTarget: startStopButton];
        [startStopBotGlobalHotkey setAction: @selector(performClick:)];
        
        [[PTHotKeyCenter sharedCenter] registerHotKey: startStopBotGlobalHotkey];
    }
}

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo {
    if(recorder == fishingRecorder) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"FishingCode"];
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"FishingFlags"];
		[self toggleGlobalHotKey: fishingRecorder];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark TableView Delegate & Datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return ([[lootController itemsLooted] count]);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if((rowIndex == -1) || (rowIndex >= [[lootController itemsLooted] count]))
        return nil;
	
    if(aTableView == statisticsTableView) {

		NSEnumerator *enumerator = [[lootController itemsLooted] keyEnumerator];
		id key;
		int i=0;
		
		// Yea this makes me think we probably shouldn't be using a dictionary object...
		while ((key = [enumerator nextObject])) {
			
			// We want this row!
			if ( i == rowIndex ){
				
				// Lets get an actual item, in case we don't have the name!  Thanks GO!
				Item *item = [itemController itemForID:[NSNumber numberWithInt:[key intValue]]];
				
				if ( [item name] == nil ){
					// This doesn't work since this is threaded, QQ
					[item loadName];
				}

				if([[aTableColumn identifier] isEqualToString: @"Item"])
					return [NSString stringWithFormat: @"%@", [itemController nameForID: [NSNumber numberWithInt:[key intValue]]]];
				if([[aTableColumn identifier] isEqualToString: @"Quantity"])
					return [NSString stringWithFormat: @"%@", [[lootController itemsLooted] objectForKey:key]];
			}
			i++;
		}
    }
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

@end