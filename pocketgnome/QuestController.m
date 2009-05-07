//
//  QuestController.m
//  Pocket Gnome
//
//  Created by Josh on 4/22/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "BotController.h"
#import "QuestController.h"
#import "Controller.h"
#import "MemoryAccess.h"
#import "PlayerDataController.h"
#import "Player.h"
#import "Quest.h"
#import "QuestItem.h"
#import "WaypointController.h"
#import "RouteSet.h"

// 3.1.1 valid
#define QUEST_START_STATIC			((IS_X86) ? 0x14125F0 : 0x0)

@implementation QuestController

static QuestController *questController = nil;

+ (QuestController *)questController {
	if (questController == nil)
		questController = [[[self class] alloc] init];
	return questController;
}

- (id) init {
    self = [super init];
	
	if(questController) {
		[self release];
		self = questController;
	} else if(self != nil) {
        
		questController = self;
		_playerQuests = [[NSMutableArray array] retain];
		_routes = [[NSMutableArray array] retain];
		
		isQuesting = false;
		
		
		
		[NSBundle loadNibNamed: @"Quest" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
	self.minSectionSize = [self.view frame].size;
	self.maxSectionSize = NSZeroSize;
}
		
- (NSArray*)playerQuests {
    return [[_playerQuests retain] autorelease];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize routes = _routes;

- (NSString*)sectionTitle {
    return @"Quest";
}

typedef struct QuestInfo {
    UInt32  questID;
    UInt32  bytes;
    UInt32  bytes1;
    UInt32  bytes2;
} QuestInfo;

- (void)loadingView{
	
	if ( ![playerDataController playerIsValid] ){
		[questStartStopButton setEnabled: NO];
		//return;
	}
	else{
		[questStartStopButton setEnabled: YES];
	}
	
	
	
	[self loadPlayerQuests];
	
	// Populate our _routes Array for the drop down! We're adding the type RouteSet
	NSMutableArray *routes = [NSMutableArray array];
	RouteSet *tmp = nil;
	int i;
	for ( i = 0; i < [[routeController routes] count]; i++ ){
		tmp = [[routeController routes] objectAtIndex:i];
		[routes addObject:tmp];
	}
	
	self.routes = routes;

	[questTable reloadData];
}

- (void)loadPlayerQuests{
	
	
	// Get access to memory
	MemoryAccess *wowMemory = [controller wowMemoryAccess];
	
	int i, j;
	BOOL questExists = false;
	UInt32 playerAddress = [playerDataController baselineAddress];
	
	// Add the player's current quests to the array pls
	for ( i = 0; i < 25; i++ ){
		QuestInfo quest;
		if([wowMemory loadDataForObject: self atAddress: (playerAddress + PlayerField_QuestStart) + i*sizeof(quest) Buffer:(Byte*)&quest BufLength: sizeof(quest)]) {
			if ( quest.questID > 0 ){
				// Don't add the object if it already exists!  (i'm sure there is an easier way to search than this... but i don't think comparing objects will work as the old objects will have data from wowhead)
				
				for ( j = 0; j < [_playerQuests count]; j++ ){
					if ( quest.questID == [[[_playerQuests objectAtIndex:j] ID] intValue]) {
						questExists = true;
						break;
					}
				}
				
				if ( !questExists ){
					[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:quest.questID]:[NSNumber numberWithInt:i+1]]];
				}
				
				questExists = false;
			}
			else{
				break;
			}
		}
	}
	
	PGLog(@"Loaded %d quests", [_playerQuests count] );
	
	// Get the data for each quest from WoWHead
	int k;
	for(k = 0; k < [_playerQuests count]; k++ ){
		[[_playerQuests objectAtIndex:k] reloadQuestData];
	}
	
	/*
	// No real point in using the below unless you want to find the Title IDs (faction)...  The below bytes simply go from 1 up to the max quest number... (bytes... bytes1 and bytes2 are always 0)
	if(wowMemory) {
		// Shouldn't be more than 50 (25 quests + 25 potential headings)
        for(i = 0; i< 50; i++)
		{
            UInt32 questStart = QUEST_START_STATIC;
			
			QuestInfo quest;
			if([wowMemory loadDataForObject: self atAddress: (questStart) + i*sizeof(quest) Buffer:(Byte*)&quest BufLength: sizeof(quest)]) {
				//PGLog(@"ID: %d, 1:%d, 2:%d, 3:%d", quest.questID, quest.bytes, quest.bytes1, quest.bytes2);
				
				if ( quest.questID == 0 ) continue;
				
				// Check to see if this object exists (if it does then it's not a heading)
				NSEnumerator *enumerator = [_playerQuests objectEnumerator];
				Quest *obj;

				while ((obj = [enumerator nextObject]) != nil)
				{
					// Found a valid quest ID... lets save the extra data
					if ( [[obj ID] intValue] == quest.questID )
					{
						PGLog(@"Found quest %d (%d, %d, %D)", quest.questID, quest.bytes, quest.bytes1, quest.bytes2);
						
						obj._bytes1 = [NSNumber numberWithInt:quest.bytes];
						obj._bytes2 = [NSNumber numberWithInt:quest.bytes1];
						obj._bytes3 = [NSNumber numberWithInt:quest.bytes2];
						
						break;
					} 
				}
			}
		}
	}*/
	
	/*
	 // For when i don't have the ability to start wow...
	[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:19]:[NSNumber numberWithInt:0]]];
	[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:91]:[NSNumber numberWithInt:1]]];
	[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:122]:[NSNumber numberWithInt:2]]];
	[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:125]:[NSNumber numberWithInt:3]]];
	[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:126]:[NSNumber numberWithInt:4]]];
	[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:127]:[NSNumber numberWithInt:5]]];
	[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:128]:[NSNumber numberWithInt:6]]];
	[_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:145]:[NSNumber numberWithInt:7]]];
	 
	 
	 // Get the data for each quest from WoWHead
	 int k;
	 for(k = 0; k < [_playerQuests count]; k++ ){
		 [[_playerQuests objectAtIndex:k] reloadQuestData];
	 }*/
}

- (void) dumpQuests{
	if ( !_playerQuests || ![_playerQuests count] ){
		return;
	}
	
	int k, i;
	Quest *tmp;
	NSLog(@"Total quests: %i", [_playerQuests count] );
	for(k = 0; k < [_playerQuests count]; k++ ){
		tmp = [_playerQuests objectAtIndex:k];
		
		PGLog(@"Quest: %@ %@ %d %d %d", [tmp ID], [tmp name], [tmp._bytes1 intValue], [tmp._bytes2 intValue], [tmp._bytes3 intValue]);
		
		if ( [tmp requiredItemTotal] ){
			for(i = 0; i < [tmp requiredItemTotal]; i++){
				PGLog(@"  Required Item: %@ Quantity: %@", [tmp requiredItemIDIndex:i], [tmp requiredItemQuantityIndex:i]);	// crash here b/c of item
			}
		}
	}
}

- (NSMutableArray*)routes {
   return [[_routes retain] autorelease];
}

- (IBAction)startQuesting: (id)sender{
	if (!isQuesting){
		isQuesting = YES;
		[questStartStopButton setTitle: @"Stop Questing"];
	}
	else{
		isQuesting = NO;
		[questStartStopButton setTitle: @"Start Questing"];
	}
	
	
	// Lets actually fire the bot up!  Things we need to do:
	//		change [controller theRoute]
	//		monitor quest items (inventory, mob kills)
	
	if ( isQuesting ){
		// Find the first enabled quest!
		int i;
		RouteSet *route = nil;
		Quest *quest = nil;
		for(i=0;i<[_playerQuests count];i++){
			quest = [_playerQuests objectAtIndex:i];
			
			if ( [quest enabled] ){
				route = [quest route];
			}
		}
		
		if ( route != nil ){
			// Note: there still has to be a valid route selected on the "Bot" tab - will write custom function later....
			[botController startBotWithRoute: sender: route];
		}
	}
}

#pragma mark -
#pragma mark NSTableView Delesource

- (IBAction)tableRowDoubleClicked: (id)sender {
    
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_playerQuests count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1) return nil;
	
    if( [[aTableColumn identifier] isEqualToString: @"Quest Name"] ) {
        return [[_playerQuests objectAtIndex:rowIndex] name];
    }
	else if( [[aTableColumn identifier] isEqualToString: @"Order"] ) {
        return [NSString stringWithFormat: @"%d", rowIndex+1];
    }
	else if( [[aTableColumn identifier] isEqualToString: @"Route"] ) {
		return [NSNumber numberWithInt:[_routes indexOfObjectIdenticalTo:[[_playerQuests objectAtIndex:rowIndex] route]]];
	}
	else if( [[aTableColumn identifier] isEqualToString: @"Enabled"] ) {
		return [[_playerQuests objectAtIndex:rowIndex] enabled];
	}
	else if( [[aTableColumn identifier] isEqualToString: @"RouteTurnIn"] ) {
		return [NSNumber numberWithInt:[_routes indexOfObjectIdenticalTo:[[_playerQuests objectAtIndex:rowIndex] routeToTurnIn]]];
	}
	else{
		PGLog(@"Need value for %@", [aTableColumn identifier]);
	}
    
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	
	
	//Quest *quest = nil;
	// Value of the selected item is anObject - we want to update our MutableArray here! w00t!
	if( [[aTableColumn identifier] isEqualToString: @"Enabled"] ) {
		Quest *quest = [_playerQuests objectAtIndex:rowIndex];
		[quest setEnabled:anObject];
	}
	else if( [[aTableColumn identifier] isEqualToString: @"Route"] ) {
		[[_playerQuests objectAtIndex:rowIndex] setRoute:[self getRouteSetFromIndex:anObject]];
	}
	else if( [[aTableColumn identifier] isEqualToString: @"RouteTurnIn"] ) {
		[[_playerQuests objectAtIndex:rowIndex] setRouteToTurnIn:[self getRouteSetFromIndex:anObject]];
	}
}

- (RouteSet*)getRouteSetFromIndex: (id)anObject{
	return [_routes objectAtIndex:[anObject intValue]];
}

/*
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    //[self validateBindings];
	NSTableView *tv = [aNotification object];
	
	//PGLog(@"Name: %@", [aNotification name]);
	//NSTableViewSelectionDidChangeNotification
	
	//PGLog(@"Row selected: %d", [tv selectedRow]);
}*/

@end

// Using QUEST_START_STATIC
/* This quest list is a bit confusing... her is an example:
 0x0		7905			<-- quest id
 0x4		12				<-- unknown
 0x8		0				<-- unknown
 0xC		0				<-- unknown
 0x10	38				<-- Zone ID
 0x14	0
 0x18	1
 0x1C	0
 0x20	256				<-- quest id
 0x24	9
 0x28	0
 0x2C	0
 0x30	44				<-- Zone ID
 0x34	0
 0x38	1
 0x3C	0
 0x40	125				<-- quest id
 0x44	3
 0x48	0
 0x4C	0
 0x50	145				<-- quest id
 0x54	7
 0x58	0
 0x5C	0
 */