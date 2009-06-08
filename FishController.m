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

#import "Offsets.h"

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

// Fishing bobber flags
#define ANIM_FLAG_MOVED			0x1
#define ANIM_FLAG_GONE			0x10000
#define ANIM_FLAG_UNKNOWN		0xF0001

//When reading animation as 32-bit integer:
#define ANIMATION_CAST			8650752
#define ANIMATION_MOVED			8650753
#define ANIMATION_GONE			8716288

// TO DO:
//	Log out on full inventory
//  Add a check for hostile players near you
//  Add a check for friendly players near you (and whisper check?)
//  Check for GMs?
//	Add a check for the following items: "Reinforced Crate", "Borean Leather Scraps", then /use them :-)
//  Select a route to run back in case you are killed (add a delay until res option as well?)

@implementation FishController

- (id)init{
    self = [super init];
    if (self != nil) {
		
		_isFishing = NO;
		_useCrate = NO;
		_playerGUID = 0;
		_bobberGUID = 0;
		_totalFishLooted = 0;
		_startTime = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(fishLooted:) 
                                                     name: ItemLootedNotification 
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

	Player *player = [playerController player];
	if ( !player ) {
		return;
	}
	
	if ( _playerGUID == 0 ){
		_playerGUID = [player GUID];
	}
	
	Spell *fishingSpell = [spellController playerSpellForName: @"Fishing"];
	if ( fishingSpell ){
		_fishingSpellID = [[fishingSpell ID] intValue];
	}
	else{
		PGLog(@"[Fishing] You need to learn fishing first!");
	}
	
	// TO DO: Reset GUI!
	_totalFishLooted = 0;
	
	// Reset lure attempts
	_applyLureAttempts = 0;
	
	if ( _isFishing ){
		[startStopButton setTitle: @"Start Fishing"];
		_isFishing = NO;
	}
	else{
		[startStopButton setTitle: @"Stop Fishing"];
		_isFishing = YES;
		
		// Save what time we started!
		_startTime = [NSDate date];
		
		// Start our "kill wow" timer if we need to
		if ( [killWoWCheckbox state] ){

			// Kill it in a wee bit
			[self performSelector: @selector(closeWoW) withObject: nil afterDelay:[closeWoWTimer floatValue]*60*60 ];
		}
	}

	// Lets start fishing!
	[self fishBegin];
}

-(void)closeWoW{
	// Only kill wow if we're still fishing!
	if ( _isFishing ){
		PGLog(@"[Fishing] Timer expired, closing WoW!");
		[controller killWOW];
	}
}

-(BOOL)isFishing{
	if ( [playerController spellCasting] == _fishingSpellID ){
		return YES;
	}
		
	return NO;
}

- (void)fishBegin{
	if ( !_isFishing){
		return;
	}
	
	// Well we don't want to fish if something killed us do we!
	if ( [playerController isDead] ){
		[self startStopFishing:nil];
		return;
	}
	
	// Lets apply some lure if we need to!
	if ( [self applyLure] ){
		
		// Well we now need to wait for the lure to be applied, so lets come back to fishing in 3 seconds :-)
		[self performSelector: @selector(fishBegin) withObject: nil afterDelay: 3.0];
		
		return;
	}
	
	// We don't want to start fishing if we already are!
	if ( ![self isFishing] ){
		
		
		// Do we need to use a crate?
		if ( _useCrate && [useReinforcedCrates state] ){
			
			// Use our crate!
			[botController performAction:(USE_ITEM_MASK + ITEM_REINFORCED_CRATE)];
			
			// Wait a bit before we cast the next one!
			usleep([controller refreshDelay]*2);
			
			// Reset our BOOL!
			_useCrate = NO;
		}
		
		// If casting fails for some reason lets try again in a second!
		if ( ![botController performAction: _fishingSpellID] ){
			[self performSelector: @selector(fishBegin) withObject: nil afterDelay: 1.0];
			
			return;
		}
		
		// Find our player's fishing bobber! - we need to wait a couple seconds after cast, so the object list can re-populate
		[self performSelector: @selector(findBobber) withObject: nil afterDelay: 2.0];
	}
	else{
		
		// If we get here, my logic is more than likely fail (it happens from time to time)
		[self performSelector: @selector(fishBegin) withObject: nil afterDelay: [playerController castTimeRemaining] + 1.0f];
	}
}

- (BOOL)applyLure{
	if ( ![applyLureCheckbox state] ){
		return NO;
	}

	Item *item = [itemController itemForGUID: [[playerController player] itemGUIDinSlot: SLOT_MAIN_HAND]];
	if ( ![item hasTempEnchantment] && _applyLureAttempts < 3 ){
		
		int lureItemID = [[luresPopUpButton selectedItem] tag];
		
		//TO DO: Make sure the user has some in their inventory!
		
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
		}
		else{
			_applyLureAttempts++;
		}
		
		return YES;
	}
	
	return NO;
}


// Lets find our bobber - then start monitoring it every 0.1 seconds
- (void)findBobber{
	if ( !_isFishing ){
		return;
	}
	
	NSArray *fishingBobbers = [nodeController allFishingBobbers];
	BOOL bobberFound = NO;
	
	for ( Node *bobber in fishingBobbers ){
		
		// We need to check to see if it is our players - and that it isn't a previous one!
		UInt32 animation = 0;
		[[controller wowMemoryAccess] loadDataForObject: self atAddress: ([bobber baseAddress] + 0xB4) Buffer: (Byte *)&animation BufLength: sizeof(animation)];
			
		// BAM our player's bobber is found yay!
		if ( [bobber owner] == _playerGUID && animation != ANIMATION_GONE ){
			bobberFound = YES;
			_bobber = bobber;
			_bobberGUID = [bobber GUID];
			
			// Start scanning to  check for when the bobber animation changes!
			[self performSelector: @selector(checkBobberAnimation:)
					   withObject: bobber
					   afterDelay: 0.1];
		}
	}
	
	// We should have found it :(  If we didn't lets keep searching!
	if ( !bobberFound ){
		
		// But wai!  Shouldn't we be fishing?
		if ( ![self isFishing] ){
			
			// Still searching when bobber is gone?  This makes me sad!  Fish again!
			[self fishBegin];
		}
		
		// Keep looking!
		else{
			[self performSelector: @selector(findBobber)
					   withObject: nil
					   afterDelay: 0.1];
		}
	}
}

// We want to check out bobber every 0.1 seconds to see if it has changed!
- (void)checkBobberAnimation:(id)sender{
	if ( !_isFishing ){
		return;
	}
	
	UInt32 animation = 0;
	if([[controller wowMemoryAccess] loadDataForObject: self atAddress: ([sender baseAddress] + 0xB4) Buffer: (Byte *)&animation BufLength: sizeof(animation)]) {

		// Click!
		if ( (animation & ANIM_FLAG_MOVED) == 0x1 ){
			[self clickBobber: sender];
			
			// This is where we should call to fish again! Let's add a delay in case of server lag, so we have time to auto-loot!
			[self performSelector: @selector(fishBegin)
					   withObject: nil
					   afterDelay: 3.0];
		
			return;
		}
		
		// Not fishing anymore?  Well lets stop searching and fish again!
		if ( ![self isFishing] ){
			[self performSelector: @selector(fishBegin)
					   withObject: nil
					   afterDelay: 1.0];
			
			return;
		}
		  
		[self performSelector: @selector(checkBobberAnimation:)
				   withObject: sender
				   afterDelay: 0.1];
	}
}

- (void)clickBobber:(Node*)bobber{
	UInt64 value = [bobber GUID];
	
	// Save our target to mouseover!
	if ( [[controller wowMemoryAccess] saveDataForAddress: (TARGET_TABLE_STATIC + TARGET_MOUSEOVER) Buffer: (Byte *)&value BufLength: sizeof(value)] ){
		
		// wow needs time to process the change
		usleep([controller refreshDelay]);
		
		// Use our hotkey!
		if ( ![botController interactWithMouseOver] ){
			PGLog(@"[Fishing] Unable to interact with MouseOver! Someone forgot to bind their key!");
		}
	}
	
	return;
}

- (void)updateFishCount{
	//double differenceInSeconds = [_startTime timeIntervalSinceNow];
	//double fishPerSecond = (float)_totalFishLooted/differenceInSeconds;
	
	[fishCaught setStringValue: [NSString stringWithFormat: @"Fish Caught: %d", _totalFishLooted]];
	
	[statisticsTableView reloadData];
}

// Called whenever ANY item is looted
- (void)fishLooted: (NSNotification*)notification {
	if ( !_isFishing )
		return;
	
	NSNumber *itemID = (NSNumber *)[notification object];

	// Lets use the crate we looted!
	if ( [itemID intValue] == ITEM_REINFORCED_CRATE ){
		_useCrate = YES;
	}
		
	_totalFishLooted++;
	
	[self updateFishCount];
}

- (IBAction)showBobberStructure: (id)sender{
	if ( _bobber == nil || !_isFishing ){
		return;
	}
	
	[memoryViewController showObjectMemory: _bobber];
    [controller showMemoryView];
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