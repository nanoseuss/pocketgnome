//
//  PlayersController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/25/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "PlayersController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "MemoryViewController.h"
#import "MovementController.h"

#import "ImageAndTextCell.h"

#import "Player.h"
#import "Unit.h"
#import "Offsets.h"

@interface PlayersController (Internal)
- (BOOL)trackingPlayer: (Player*)trackingPlayer;
- (NSString*)unitClassToString: (UnitClass)unitClass;
@end

@implementation PlayersController

static PlayersController *sharedPlayers = nil;

+ (PlayersController *)sharedPlayers {
	if (sharedPlayers == nil)
		sharedPlayers = [[[self class] alloc] init];
	return sharedPlayers;
}

- (id) init
{
    self = [super init];
	if(sharedPlayers) {
		[self release];
		self = sharedPlayers;
    } else {
        sharedPlayers = self;
        _updateTimer = nil;
        [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObject: @"0.5" forKey: @"PlayersControllerUpdateFrequency"]];
        _playerList = [[NSMutableArray array] retain];
        _playerDataList = [[NSMutableArray array] retain];
		_playerNameList = [[NSMutableDictionary dictionary] retain];

        // wow memory access validity
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryAccessValid:) 
                                                     name: MemoryAccessValidNotification 
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryAccessInvalid:) 
                                                     name: MemoryAccessInvalidNotification 
                                                   object: nil];
        
        [NSBundle loadNibNamed: @"Players" owner: self];
    }

    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
    
    self.updateFrequency = [[NSUserDefaults standardUserDefaults] floatForKey: @"PlayersControllerUpdateFrequency"];
    
    [playerTable setDoubleAction: @selector(playerTableDoubleClick:)];
    [(NSTableView*)playerTable setTarget: self];
    
    ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable: NO];
    [[playerTable tableColumnWithIdentifier: @"Class"] setDataCell: imageAndTextCell];
    [[playerTable tableColumnWithIdentifier: @"Race"] setDataCell: imageAndTextCell];
    [[playerTable tableColumnWithIdentifier: @"Gender"] setDataCell: imageAndTextCell];

}

#pragma mark Notifications

- (void)memoryAccessValid: (NSNotification*)notification {
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(!memory) return;
    for(Player *player in _playerList) {
        [player setMemoryAccess: memory];
    }
}

- (void)memoryAccessInvalid: (NSNotification*)notification {
    [self resetPlayerList: nil];
}

#pragma mark Accessors

@synthesize view;
@synthesize updateFrequency;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Other Players";
}

- (void)setUpdateFrequency: (float)frequency {
    if(frequency < 0.1) frequency = 0.1;
    
    [self willChangeValueForKey: @"updateFrequency"];
    updateFrequency = [[NSString stringWithFormat: @"%.2f", frequency] floatValue];
    [self didChangeValueForKey: @"updateFrequency"];
    
    [[NSUserDefaults standardUserDefaults] setFloat: updateFrequency forKey: @"PlayersControllerUpdateFrequency"];

    [_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval: self.updateFrequency target: self selector: @selector(reloadPlayerData:) userInfo: nil repeats: YES];
}

#pragma mark -
#pragma mark Data Set Management

- (NSArray*)allPlayers {
    return [[_playerList retain] autorelease];
}

- (Player*)playerTarget {
    GUID playerTarget = [playerData targetID];
    
    for(Player *player in _playerList) {
        if( playerTarget == [player GUID]) {
            return [[player retain] autorelease];
        }
    }
    return nil;
}

- (Player*)playerWithGUID: (GUID)guid {
    for(Player *player in _playerList) {
        if( guid == [player GUID]) {
            return [[player retain] autorelease];
        }
    }
    return nil;
}

- (void)addAddresses: (NSArray*)addresses {
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    NSMutableArray *dataList = _playerList;
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(![memory isValid]) return;
    
    [self willChangeValueForKey: @"playerCount"];

    // enumerate current object addresses
    // determine which objects need to be removed
    for(WoWObject *obj in dataList) {
        if([obj isValid]) {
            [addressDict setObject: obj forKey: [NSNumber numberWithUnsignedLongLong: [obj baseAddress]]];
        } else {
            [objectsToRemove addObject: obj];
        }
    }
    
    // remove any if necessary
    if([objectsToRemove count]) {
        [dataList removeObjectsInArray: objectsToRemove];
    }
    
    // add new objects if they don't currently exist
    NSDate *now = [NSDate date];
    for(NSNumber *address in addresses) {
        // skip current player
        if([playerData baselineAddress] == [address unsignedIntValue])
            continue;
            
        if( ![addressDict objectForKey: address] ) {
            [dataList addObject: [Player playerWithAddress: address inMemory: memory]];
        } else {
            [[addressDict objectForKey: address] setRefreshDate: now];
        }
    }
    
    [self didChangeValueForKey: @"playerCount"];
    [self updateTracking: nil];
}

- (void)addPlayerNames: (NSDictionary*)names{
	
	//[addressDict setObject: obj forKey: [NSNumber numberWithUnsignedLongLong: [obj baseAddress]]];
	
	// Loop through our existing dictionary, we ONLY want to add new values!
	NSArray *keys = [names allKeys];
	
	for ( NSNumber *key in keys ){
		// It's new! Add it!
		if ( ![_playerNameList objectForKey: key] ){
			NSString *name = [names objectForKey:key];
			
			//PGLog(@"Add name: %@ for GUID: 0x%qx", name, [key longLongValue]);
			[_playerNameList  setObject: name forKey: key];
		}
	}
}

/*- (BOOL)addPlayer: (Player*)player {
    if(![player isValid]) return NO;
    
    // make sure this player is not us
    if([playerData baselineAddress] == [player baseAddress])
        return NO;
    
    if(![self trackingPlayer: player]) {
        [self willChangeValueForKey: @"playerCount"];
        [_playerList addObject: player];
        [self didChangeValueForKey: @"playerCount"];
        return YES;
    }
    return NO;
}*/

- (unsigned)playerCount {
    return [_playerList count];
}


- (BOOL)trackingPlayer: (Player*)trackingPlayer {
    for(Player *player in _playerList) {
        if( [player isEqualToObject: trackingPlayer] ) {
            return YES;
        }
    }
    return NO;
}


- (void)resetAllPlayers {
    [self willChangeValueForKey: @"playerCount"];
    [_playerList removeAllObjects];
    [self didChangeValueForKey: @"playerCount"];
}

- (void)reloadPlayerData: (NSTimer*)timer {
    if(![[playerTable window] isVisible]) return;
    if(![playerData playerIsValid:self]) return;
    
    [_playerDataList removeAllObjects];
    
    // only resort and display the table if the window is visible
    if( [[playerTable window] isVisible]) {
        cachedPlayerLevel = [playerData level];
        for(Player *player in _playerList) {

            if( ![player isValid] )
                continue;
            
            float distance = [[playerData position] distanceToPosition: [player position]];
            
            BOOL isHostile = [playerData isHostileWithFaction: [player factionTemplate]];
            BOOL isNeutral = (!isHostile && ![playerData isFriendlyWithFaction: [player factionTemplate]]);
            
            //int unitClass = [player unitClass];
            //int unitRace = [player race];
            //int unitGender = [player gender];
            
            unsigned level = [player level];
            if(level > 100) level = 0;
            
            [_playerDataList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                         player,                                                                @"Player",
                                         [NSString stringWithFormat: @"0x%X", [player lowGUID]],                @"ID",
                                         ([player isGM] ? @"GM" : [Unit stringForClass: [player unitClass]]),   @"Class",
                                         [Unit stringForRace: [player race]],                                   @"Race",
                                         [Unit stringForGender: [player gender]],                               @"Gender",
                                         [NSString stringWithFormat: @"%d%%", [player percentHealth]],          @"Health",
                                         [NSNumber numberWithUnsignedInt: level],                               @"Level",
                                         [NSNumber numberWithFloat: distance],                                  @"Distance", 
                                         (isNeutral ? @"4" : (isHostile ? @"2" : @"5")),                        @"Status",
                                         [player iconForRace: [player race] gender: [player gender]],           @"RaceIcon",
                                         [NSImage imageNamed: [Unit stringForGender: [player gender]]],         @"GenderIcon",
                                         [player iconForClass: [player unitClass]],                             @"ClassIcon",
                                         nil]];
        }
        
        [_playerDataList sortUsingDescriptors: [playerTable sortDescriptors]];
        [playerTable reloadData];
    }
}

#pragma mark -

- (NSArray*)friendlyPlayers{
	
	NSMutableArray *friendlyUnits = [NSMutableArray array];
	
	for(Unit *unit in _playerList) {
		int faction = [unit factionTemplate];
		BOOL isFriendly = [playerData isFriendlyWithFaction: faction];
	
		if ( isFriendly){
			[friendlyUnits addObject: unit];
		}	
	}
	
	return friendlyUnits;
}

- (NSArray*)playersWithinDistance: (float)unitDistance
                       levelRange: (NSRange)range
                  includeFriendly: (BOOL)friendly
                   includeNeutral: (BOOL)neutral
                   includeHostile: (BOOL)hostile {
    
    
    NSMutableArray *unitsWithinRange = [NSMutableArray array];
    
    BOOL ignoreLevelOne = [playerData level] > 10 ? YES : NO;
	
    for(Unit *unit in _playerList) {
        
        float distance = [[(PlayerDataController*)playerData position] distanceToPosition: [unit position]];
        
        if(distance != INFINITY && distance <= unitDistance) {
            int lowLevel = range.location;
            if(lowLevel < 1) lowLevel = 1;
            if(lowLevel == 1 && ignoreLevelOne) lowLevel = 2;
            int highLevel = lowLevel + range.length;
            int unitLevel = [unit level];
            
            int faction = [unit factionTemplate];
            BOOL isFriendly = [playerData isFriendlyWithFaction: faction];
            BOOL isHostile = [playerData isHostileWithFaction: faction];
			
            // only include:
            if(   [unit isValid]                                                // 1) valid units
               && ![unit isDead]                                                // 2) units that aren't dead
               && ((friendly && isFriendly)                                     // 3) friendly as specified
                   || (neutral && !isFriendly && !isHostile)                    //    neutral as specified
                   || (hostile && isHostile))                                   //    hostile as specified
               && (unitLevel >= lowLevel) && unitLevel <= highLevel             // 4) units within the level range
               && [unit isSelectable]                                           // 5) units that are selectable
               && [unit isAttackable]                                           // 6) units that are attackable
               && [unit isPVP] )                                                // 7) units that are PVP
                [unitsWithinRange addObject: unit];
        }
    }
    
    return unitsWithinRange;
}

- (BOOL)playerWithinRangeOfUnit: (float)distance Unit:(Unit*)unit includeFriendly:(BOOL)friendly includeHostile:(BOOL)hostile {
	
	PGLog(@"checking distance %0.2f  %@ %d %d", distance, unit, friendly, hostile);
	Position *position = [unit position];
	
	// loop through all players
	for(Unit *player in [self allPlayers]) {
		
		BOOL isHostile = [playerData isHostileWithFaction: [player factionTemplate]];
		// range check
		float range = [position distanceToPosition: [player position]];
		
		if (
			range <= distance &&						// 1 - in range
			(!friendly || (friendly && !isHostile)) &&	// 2 - friendly
			(!hostile || (hostile && isHostile))		// 3 - hostile
			){
			PGLog(@"[Loot] Player %@ found %0.2f yards away! I scared! Friendly?(%d)  Hostile?(%d)", player, range, friendly, hostile);
			return YES;
		}
	}
	
	return NO;
}

- (IBAction)updateTracking: (id)sender {
    if(![playerData playerIsValid:self]) return;
    if((sender == nil) && ![trackHostile state] && ![trackFriendly state])
        return;
    
    for(Unit *unit in _playerList) {
        BOOL isHostile = [playerData isHostileWithFaction: [unit factionTemplate]];
        BOOL isFriendly = [playerData isFriendlyWithFaction: [unit factionTemplate]];
        BOOL shouldTrack = NO;
        
        if( [trackHostile state] && isHostile) {
            shouldTrack = YES;
        }
        if( [trackFriendly state] && isFriendly) {
            shouldTrack = YES;
        }
        
        if(shouldTrack) [unit trackUnit];
        else            [unit untrackUnit];
    }
}

#pragma mark IBActions

- (IBAction)facePlayer: (id)sender {

    int selectedRow = [playerTable selectedRow];
    if(selectedRow == -1) return;
    
    if(selectedRow >= [_playerDataList count]) return;
    Player *player = [[_playerDataList objectAtIndex: selectedRow] objectForKey: @"Player"];
    
    [movementController turnTowardObject: player];
}

- (IBAction)targetPlayer: (id)sender {

    int selectedRow = [playerTable selectedRow];
    if(selectedRow == -1) return;
    
    if(selectedRow >= [_playerDataList count]) return;
    Player *player = [[_playerDataList objectAtIndex: selectedRow] objectForKey: @"Player"];
    [playerData setPrimaryTarget: [player GUID]];
}

- (IBAction)resetPlayerList: (id)sender {
    [self resetAllPlayers];
    [playerTable reloadData];
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (void)tableView:(NSTableView *)aTableView  sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [_playerDataList sortUsingDescriptors: [aTableView sortDescriptors]];
    [playerTable reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_playerDataList count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1 || rowIndex >= [_playerDataList count]) return nil;
    
    if([[aTableColumn identifier] isEqualToString: @"Distance"])
        return [NSString stringWithFormat: @"%.2f", [[[_playerDataList objectAtIndex: rowIndex] objectForKey: @"Distance"] floatValue]];
    
    if([[aTableColumn identifier] isEqualToString: @"Status"]) {
        NSString *status = [[_playerDataList objectAtIndex: rowIndex] objectForKey: @"Status"];
        if([status isEqualToString: @"1"])  status = @"Combat";
        if([status isEqualToString: @"2"])  status = @"Hostile";
        if([status isEqualToString: @"3"])  status = @"Dead";
        if([status isEqualToString: @"4"])  status = @"Neutral";
        if([status isEqualToString: @"5"])  status = @"Friendly";
        return [NSImage imageNamed: status];
    }
    
    return [[_playerDataList objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex
{
    if( aRowIndex == -1 || aRowIndex >= [_playerDataList count]) return;
    
    if ([[aTableColumn identifier] isEqualToString: @"Race"]) {
        [(ImageAndTextCell*)aCell setImage: [[_playerDataList objectAtIndex: aRowIndex] objectForKey: @"RaceIcon"]];
    }
    if ([[aTableColumn identifier] isEqualToString: @"Class"]) {
        [(ImageAndTextCell*)aCell setImage: [[_playerDataList objectAtIndex: aRowIndex] objectForKey: @"ClassIcon"]];
    }
    if ([[aTableColumn identifier] isEqualToString: @"Gender"]) {
        [(ImageAndTextCell*)aCell setImage: [[_playerDataList objectAtIndex: aRowIndex] objectForKey: @"GenderIcon"]];
    }
    
    // do text color
    if( ![aCell respondsToSelector: @selector(setTextColor:)] )
        return;
    
    if(cachedPlayerLevel == 0 || [playerColorByLevel state] == NSOffState) {
        [aCell setTextColor: [NSColor blackColor]];
        return;
    }
    
    Player *player = [[_playerDataList objectAtIndex: aRowIndex] objectForKey: @"Player"];
    int level = [player level];
    
    if(level >= cachedPlayerLevel+5) {
        [aCell setTextColor: [NSColor redColor]];
        return;
    }
    
    if(level > cachedPlayerLevel+3) {
        [aCell setTextColor: [NSColor orangeColor]];
        return;
    }
    
    if(level > cachedPlayerLevel-2) {
        [aCell setTextColor: [NSColor colorWithCalibratedRed: 1.0 green: 200.0/255.0 blue: 30.0/255.0 alpha: 1.0]];
        return;
    }
    
    if(level > cachedPlayerLevel-8) {
        [aCell setTextColor: [NSColor colorWithCalibratedRed: 30.0/255.0 green: 115.0/255.0 blue: 30.0/255.0 alpha: 1.0] ]; // [NSColor greenColor]
        return;
    }
    
    [aCell setTextColor: [NSColor darkGrayColor]];
    return;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
    if( [[aTableColumn identifier] isEqualToString: @"RaceIcon"])
        return NO;
    if( [[aTableColumn identifier] isEqualToString: @"ClassIcon"])
        return NO;
    return YES;
}

- (void)playerTableDoubleClick: (id)sender {
    if( [sender clickedRow] == -1 || [sender clickedRow] >= [_playerDataList count] ) return;
    
    [memoryViewController showObjectMemory: [[_playerDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Player"]];
    [controller showMemoryView];
}

/*
 void NameFromGuid(LONGLONG guid, int numBytes, char *name)
 {                                                
 static const unsigned long nameStorePtr        = 0x011AE3D0 + 0x8;  // Player name database
 static const unsigned long nameMaskOffset      = 0x024;  // Offset for the mask used with GUID to select a linked list
 static const unsigned long nameBaseOffset      = 0x01c;  // Offset for the start of the name linked list
 static const unsigned long nameStringOffset    = 0x020;  // Offset to the C string in a name structure
 
 unsigned long mask, base, offset, current, shortGUID, testGUID;
 
 mask = ReadDword(nameStorePtr + nameMaskOffset);
 base = ReadDword(nameStorePtr + nameBaseOffset);
 
 shortGUID = guid & 0xffffffff;  // Only half the guid is used to check for a hit
 offset = 12 * (mask & shortGUID);  // select the appropriate linked list
 
 current = ReadDword(base + offset + 8);
 offset = ReadDword(base + offset);  // next-4 ?
 
 if (current == 0 || (current & 0x1)) {*name = 0; return;}
 
 testGUID = ReadDword(current);
 
 while (testGUID != shortGUID)
 {
 current = ReadDword(current + offset + 4);
 
 if (current == 0 || (current & 0x1)) {*name = 0; return;}
 testGUID = ReadDword(current);		
 }
 
 // Found the guid in the name list...
 ReadBytesIntoBuffer(current + nameStringOffset, numBytes, name);	
 }
*/ 

@end
