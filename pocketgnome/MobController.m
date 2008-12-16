//
//  MobController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/17/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//
#import <ScreenSaver/ScreenSaver.h>

#import "MobController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "MemoryViewController.h"
#import "CombatController.h"
#import "MovementController.h"
#import "AuraController.h"
#import "BotController.h"
#import "SpellController.h"

#import "MemoryAccess.h"

#import "Mob.h"
#import "Waypoint.h"
#import "Position.h"
#import "Offsets.h"

#import "ImageAndTextCell.h"


@interface MobController (Internal)
- (BOOL)trackingMob: (Mob*)mob;
@end

@implementation MobController

+ (void)InitializeDataBrowserCallbacks {
}

static MobController* sharedController = nil;

+ (MobController *)sharedController {
	if (sharedController == nil)
		sharedController = [[[self class] alloc] init];
	return sharedController;
}

- (id) init {
    self = [super init];
	if(sharedController) {
		[self release];
		self = sharedController;
	} else if (self != nil) {
        sharedController = self;
        _updateTimer = nil;
        [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObject: @"0.25" forKey: @"MobControllerUpdateFrequency"]];
        _mobList = [[NSMutableArray array] retain];
        _mobDataList = [[NSMutableArray array] retain];
        cachedPlayerLevel = 0;
        
        // wow memory access validity
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryAccessValid:) 
                                                     name: MemoryAccessValidNotification 
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryAccessInvalid:) 
                                                     name: MemoryAccessInvalidNotification 
                                                   object: nil];
        
        [NSBundle loadNibNamed: @"Mobs" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
    
    self.updateFrequency = [[NSUserDefaults standardUserDefaults] floatForKey: @"MobControllerUpdateFrequency"];
    
    [mobTable setDoubleAction: @selector(mobTableDoubleClick:)];
    [(NSTableView*)mobTable setTarget: self];

    ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable: NO];
    [[mobTable tableColumnWithIdentifier: @"Name"] setDataCell: imageAndTextCell];

    //_updateTimer = [NSTimer scheduledTimerWithTimeInterval: self.updateFrequency target: self selector: @selector(reloadMobData:) userInfo: nil repeats: YES];
    //[_updateTimer retain];
}

#pragma mark Notifications

- (void)memoryAccessValid: (NSNotification*)notification {
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(!memory) return;
    //PGLog(@"Reloading memory access for %d mobs.", [_mobList count]);
    for(Mob *mob in _mobList) {
        [mob setMemoryAccess: memory];
    }
}

- (void)memoryAccessInvalid: (NSNotification*)notification {
    [self resetAllMobs];
}


#pragma mark Accessors

@synthesize view;
@synthesize updateFrequency = _updateFrequency;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Mobs";
}

- (void)setUpdateFrequency: (float)frequency {
    if(frequency < 0.1) frequency = 0.1;
    
    [self willChangeValueForKey: @"updateFrequency"];
    _updateFrequency = [[NSString stringWithFormat: @"%.2f", frequency] floatValue];
    [self didChangeValueForKey: @"updateFrequency"];
    
    [[NSUserDefaults standardUserDefaults] setFloat: _updateFrequency forKey: @"MobControllerUpdateFrequency"];

    [_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval: _updateFrequency target: self selector: @selector(reloadMobData:) userInfo: nil repeats: YES];
}

- (NSImage*)toolbarIcon {
    NSImage *original = [NSImage imageNamed: @"INV_Misc_Head_Dragon_Bronze"];
    NSImage *newImage = [original copy];
    
    NSDictionary *attributes = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Helvetica-Bold" size: 18], NSFontAttributeName,
                                 [NSColor whiteColor], NSForegroundColorAttributeName, nil] autorelease];
    
    NSString *count = [NSString stringWithFormat: @"%d", [_mobList count]];
    NSSize numSize = [count sizeWithAttributes:attributes];
    NSSize iconSize = [original size];
    
    if ([_mobList count]) {
        
        [newImage lockFocus];
        float max = ((numSize.width > numSize.height) ? numSize.width : numSize.height) + 8.0f;
        
        NSRect circleRect = NSMakeRect(iconSize.width - max, 0, max, max); // iconSize.width - max, iconSize.height - max
        NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:circleRect];
        [[NSColor colorWithCalibratedRed:0.8f green:0.0f blue:0.0f alpha:1.0f] set];
        [bp fill];
        [count drawAtPoint: NSMakePoint(NSMidX(circleRect) - numSize.width / 2.0f, NSMidY(circleRect) - numSize.height / 2.0f + 2.0f) 
                withAttributes: attributes];
        
        [newImage unlockFocus];
    }

    return [newImage autorelease];
}

#pragma mark -

- (void)selectMob: (Mob*)mob {
    // set mob as target
    if(mob && [mob isValid]) {
        [playerData setPrimaryTarget: [mob GUID]];
        [mob select];
    } else {
        // deselect all
        [playerData setPrimaryTarget: 0];
        for(Mob *mob in _mobList) {
            [mob deselect];
        }
    }
}

/*
// old-style manual totem detection
- (BOOL)mobIsOurTotem: (Mob*)mob {
    UInt64 createdByGUID  = [mob createdBy];
    UInt32 createdBySpell = [mob createdBySpell];
    
    if( ([mob unitBytes2] == 0x2801) && (createdBySpell != 0) && (createdByGUID != 0) && ([mob petNumber] == 0) && ([mob petNameTimestamp] == 0)) {
        Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: createdBySpell]];
        if( [spellController isPlayerSpell: spell] && ([playerData GUID] == createdByGUID)) {
            return YES;
        }
    }
    return NO;
}*/

- (Mob*)playerTarget {
    GUID playerTarget = [playerData targetID];
    
    for(Mob *mob in _mobList) {
        if( playerTarget == [mob GUID]) {
            return mob;
        }
    }
    return nil;
}

- (Mob*)mobWithEntryID: (int)entryID {
    for(Mob *mob in _mobList) {
        if( entryID == [mob entryID]) {
            return [[mob retain] autorelease];
        }
    }
    return nil;
}

- (Mob*)mobWithGUID: (GUID)guid {
    for(Mob *mob in _mobList) {
        if( guid == [mob GUID]) {
            return [[mob retain] autorelease];
        }
    }
    return nil;
}

- (unsigned)mobCount {
    return [_mobList count];
}

- (NSArray*)allMobs {
    return [[_mobList retain] autorelease];
}


- (void)addAddresses: (NSArray*)addresses {
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    NSMutableArray *dataList = _mobList;
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(![memory isValid]) return;
    
    [self willChangeValueForKey: @"mobCount"];

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
        if( ![addressDict objectForKey: address] ) {
            [dataList addObject: [Mob mobWithAddress: address inMemory: memory]];
        } else {
            [[addressDict objectForKey: address] setRefreshDate: now];
        }
    }
    
    [self didChangeValueForKey: @"mobCount"];
    [self updateTracking: nil];
}

/*- (BOOL)addMob: (Mob*)mob {
    if(mob && ![self trackingMob: mob]) {
        [self willChangeValueForKey: @"mobCount"];
        [_mobList addObject: mob];
        [self didChangeValueForKey: @"mobCount"];
        
        return YES;
    }
    return NO;
}*/

- (IBAction)resetMobList: (id)sender {
    [self resetAllMobs];
    [mobTable reloadData];
}

- (IBAction)targetMob: (id)sender {
    int selectedRow = [mobTable selectedRow];
    if(selectedRow == -1) return;
    
    if(selectedRow >= [_mobDataList count]) return;
    Mob *mob = [[_mobDataList objectAtIndex: selectedRow] objectForKey: @"Mob"];
    [self selectMob: mob];
}

- (IBAction)faceMob: (id)sender {
    int selectedRow = [mobTable selectedRow];
    if(selectedRow == -1) return;
    
    if(selectedRow >= [_mobDataList count]) return;
    Mob *mob = [[_mobDataList objectAtIndex: selectedRow] objectForKey: @"Mob"];
    
    [movementController turnToward: [mob position]];
            
    //if(angleBetween > 0)
    //    [playerDataController setPlayerDirection: angleOffset];
    //else
    //    [playerDataController setPlayerDirection: 2.0*3.1415926 - angleOffset];
    
}

- (IBAction)additionalStart: (id)sender {
    int tag = [additionalList selectedTag];
    if(tag <= 0) return;
    
    Mob *mobToMove = nil;
    
    if(tag == 1) {
        
        int selectedRow = [mobTable selectedRow];
        if(selectedRow == -1 || selectedRow >= [_mobDataList count]) {
            NSBeep();
            return;
        }
        
        mobToMove = [[_mobDataList objectAtIndex: selectedRow] objectForKey: @"Mob"];
    } else {
        // create a list of all out grumpy peons and their distance from us
        NSMutableArray *mobList = [NSMutableArray array];
        Position *playerPosition = [(PlayerDataController*)playerData position];
        for(Mob *mob in _mobList) {
            if([mob entryID] == tag) { 
                
                float distance = [playerPosition distanceToPosition: [mob position]];
                [mobList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                     mob,                                                  @"Mob",
                                     [NSNumber numberWithFloat: distance],                 @"Distance", nil]];
            }
        }
        PGLog(@"Found %d mobs of type %d.", [mobList count], tag);
        
        // sort the list by distance
        [mobList sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"Distance" ascending: YES] autorelease]]];
        
        // pick our closest mob and move to it
        if([mobList count]) {
            if(tag == 23311) { // 23311 = Disobedient Dragonmaw Peon
                for(NSDictionary *dict in mobList) {
                    Mob *closestPeon = [dict objectForKey: @"Mob"];
                    
                    // check to see that this Peon has an appropriate GrumpyBuff.
                    if( [auraController unit: closestPeon hasDebuff: 40735] || [auraController unit: closestPeon hasDebuff: 40732] || [auraController unit: closestPeon hasDebuff: 40714]) {                    
                        mobToMove = closestPeon;
                        break;
                    }
                }
            } else {
                if([mobList count])
                    mobToMove = [[mobList objectAtIndex: 0] objectForKey: @"Mob"];
            }
        }
    }
    
    if(mobToMove) {
        [self selectMob: mobToMove];
        //Position *mobPosition = [mobToMove position];
        //if(tag == 23311)    // adjust the height for peons
        //    [mobPosition setZPosition: [mobPosition zPosition] + 20.0f];
        
        PGLog(@"Moving to mob: %@", mobToMove);
        
        [movementController moveToObject: mobToMove andNotify: NO];
        //[movementController moveToWaypoint: [Waypoint waypointWithPosition: mobPosition]];
    }
}

- (IBAction)additionalStop: (id)sender {
    
    [movementController setPatrolRoute: nil];
}

#pragma mark -

- (NSArray*)mobsWithinDistance: (float)mobDistance
                    levelRange: (NSRange)range
                  includeElite: (BOOL)includeElite
               includeFriendly: (BOOL)friendly
                includeNeutral: (BOOL)neutral
                includeHostile: (BOOL)hostile {
    
    NSMutableArray *withinRangeMobs = [NSMutableArray array];
    
    BOOL ignoreLevelOne = ([playerData level] > 10) ? YES : NO;
    Position *playerPosition = [(PlayerDataController*)playerData position];
    
    for(Mob *mob in _mobList) {
        
        if(!includeElite && [mob isElite])
            continue;   // ignore elite if specified
        
        float distance = [playerPosition distanceToPosition: [mob position]];
                
        if((distance != INFINITY) && (distance <= mobDistance)) {
            int lowLevel = range.location;
            if(lowLevel < 1) lowLevel = 1;
            if(lowLevel == 1 && ignoreLevelOne) lowLevel = 2;
            int highLevel = lowLevel + range.length;
            int mobLevel = [mob level];
            
            int faction = [mob factionTemplate];
            BOOL isFriendly = [playerData isFriendlyWithFaction: faction];
            BOOL isHostile = [playerData isHostileWithFaction: faction];
            
            // only include:
            if(   [mob isValid]                                             // 1) valid mobs
               && ![mob isDead]                                             // 2) mobs that aren't dead
               && ((friendly && isFriendly)                                 // 3) friendly as specified
                   || (neutral && !isFriendly && !isHostile)                //    neutral as specified
                   || (hostile && isHostile))                               //    hostile as specified
               && ((mobLevel >= lowLevel) && (mobLevel <= highLevel))       // 4) mobs within the level range
               && ![mob isPet]                                              // 5) mobs that are not player pets
               && [mob isSelectable]                                        // 6) mobs that are selectable
               && [mob isAttackable]                                        // 7) mobs that are attackable
               && ![mob isTappedByOther] )                                  // 8) mobs that are not tapped by someone else
                [withinRangeMobs addObject: mob];
        }
    }
    
    return withinRangeMobs;
}

#pragma mark -

- (void)doCombatScan {
    // check to see if we're in combat
    NSMutableArray *inCombatMobs = [NSMutableArray array];
    for(Mob *mob in _mobList) {
        if(   [mob isValid] 
           && ![mob isDead] 
           && [mob isSelectable] 
           && [mob isInCombat] 
           && ![playerData isFriendlyWithFaction: [mob factionTemplate]]) {
            [inCombatMobs addObject: mob];
        }
    }
    [combatController setInCombatUnits: inCombatMobs];
}

- (BOOL)trackingMob: (Mob*)trackingMob {
    for(Mob *mob in _mobList) {
        if( [mob isEqualToObject: trackingMob] )
            return YES;
    }
    return NO;
}

- (void)resetAllMobs {
    [self willChangeValueForKey: @"mobCount"];
    [_mobList removeAllObjects];
    [self didChangeValueForKey: @"mobCount"];
}


- (void)reloadMobData: (NSTimer*)timer {
    if(![[mobTable window] isVisible] && ![botController isBotting]) return;
    if(![playerData playerIsValid]) return;
    
    [_mobDataList removeAllObjects];
    cachedPlayerLevel = [playerData level];
    
    // only resort and display the table if the window is visible
    if( [[mobTable window] isVisible]) {
        
        unsigned level, health;
        for(Mob *mob in _mobList) {
            
            if( ![mob isValid] )
                continue;
            
            // hide invisible mobs from the list
            if([mobHideNonSelectable state] && ![mob isSelectable])
                continue;
            
            health = [mob currentHealth];
            level = [mob level];
            
            NSString *name = [mob name];
            
            // check to see if it's a pet
            if([mob isPet]) {
                if( [mobHidePets state] ) continue;
                if( [mob isTotem]) {
                    name = [@"[Totem] " stringByAppendingString: name];
                } else {
                    name = [@"[Pet] " stringByAppendingString: name];
                }
            }
            
            // name = [[NSString stringWithFormat: @"[0x%X] ", [mob unitBytes2]] stringByAppendingString: name];
            
            BOOL isDead = [mob isDead];
            BOOL isCombat = [mob isInCombat];
            int faction = [mob factionTemplate];
            BOOL isHostile = [playerData isHostileWithFaction: faction];
            BOOL isNeutral = (!isHostile && ![playerData isFriendlyWithFaction: faction]);
            
            BOOL allianceFriendly = ([controller reactMaskForFaction: faction] & 0x2);
            BOOL hordeFriendly = ([controller reactMaskForFaction: faction] & 0x4);
            BOOL bothFriendly = hordeFriendly && allianceFriendly;
            allianceFriendly = allianceFriendly && !bothFriendly;
            hordeFriendly = hordeFriendly && !bothFriendly;
            BOOL critter = ([controller reactMaskForFaction: faction] == 0) && (level == 1);
            
            // skip critters if necessary
            if( [mobHideCritters state] && critter)
                continue;
            
            float distance = [[(PlayerDataController*)playerData position] distanceToPosition: [mob position]];
            
            NSImage *nameIcon = nil;
            if( !nameIcon && (level == PLAYER_LEVEL_CAP+3) && [mob isElite])
                nameIcon = [NSImage imageNamed: @"Skull"];
            
            if( !nameIcon && [mob isAuctioneer])    nameIcon = [NSImage imageNamed: @"BankerGossipIcon"];
            if( !nameIcon && [mob isStableMaster])  nameIcon = [NSImage imageNamed: @"Stable"];
            if( !nameIcon && [mob isBanker])        nameIcon = [NSImage imageNamed: @"BankerGossipIcon"];
            if( !nameIcon && [mob isInnkeeper])     nameIcon = [NSImage imageNamed: @"Innkeeper"];
            if( !nameIcon && [mob isFlightMaster])  nameIcon = [NSImage imageNamed: @"TaxiGossipIcon"];
            if( !nameIcon && [mob canRepair])       nameIcon = [NSImage imageNamed: @"Repair"];
            if( !nameIcon && [mob isVendor])        nameIcon = [NSImage imageNamed: @"VendorGossipIcon"];
            if( !nameIcon && [mob isTrainer])       nameIcon = [NSImage imageNamed: @"TrainerGossipIcon"];
            if( !nameIcon && [mob isQuestGiver])    nameIcon = [NSImage imageNamed: @"ActiveQuestIcon"];
            if( !nameIcon && [mob canGossip])       nameIcon = [NSImage imageNamed: @"GossipGossipIcon"];
            if( !nameIcon && allianceFriendly)      nameIcon = [NSImage imageNamed: @"AllianceCrest"];
            if( !nameIcon && hordeFriendly)         nameIcon = [NSImage imageNamed: @"HordeCrest"];
            if( !nameIcon && critter)               nameIcon = [NSImage imageNamed: @"Chicken"];
            if( !nameIcon)                          nameIcon = [NSImage imageNamed: @"NeutralCrest"];
            
            
            [_mobDataList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                      mob,                                                      @"Mob",
                                      name,                                                     @"Name",
                                      [NSNumber numberWithInt: [mob entryID]],                  @"ID",
                                      [NSNumber numberWithInt: health],                         @"Health",
                                      [NSNumber numberWithUnsignedInt: level],                  @"Level",
                                      [NSString stringWithFormat: @"0x%X", [mob baseAddress]],  @"Address",
                                      [NSNumber numberWithFloat: distance],                     @"Distance", 
                                      [mob isPet] ? @"Yes" : @"No",                             @"Pet",
                                      // isHostile ? @"Yes" : @"No",                           @"Hostile",
                                      // isCombat ? @"Yes" : @"No",                            @"Combat",
                                      (isDead ? @"3" : (isCombat ? @"1" : (isNeutral ? @"4" : (isHostile ? @"2" : @"5")))),  @"Status",
                                      nameIcon,                                                 @"NameIcon", 
                                      nil]];
            //[mobDict setObject: [NSNumber numberWithUnsignedInt: health] forKey: @"Health"];
            //[mobDict setObject: [NSNumber numberWithUnsignedInt: level] forKey: @"Level"];
            //[mobDict setObject: [NSNumber numberWithUnsignedInt: [mob baseAddress]] forKey: @"Address"];
            //[mobDict setObject: [NSNumber numberWithFloat: distance] forKey: @"Distance"];
        }
        
        [_mobDataList sortUsingDescriptors: [mobTable sortDescriptors]];
        [mobTable reloadData];
    }
    
    if( [combatController combatEnabled] ) {
        [self doCombatScan];
    }
}


- (IBAction)updateTracking: (id)sender {
    if(![playerData playerIsValid]) return;
    if((sender == nil) && ![trackHostile state] && ![trackNeutral state] && ![trackFriendly state])
        return;
    
    for(Mob *mob in _mobList) {
        BOOL isHostile = [playerData isHostileWithFaction: [mob factionTemplate]];
        BOOL isFriendly = [playerData isFriendlyWithFaction: [mob factionTemplate]];
        BOOL isNeutral = (!isHostile && !isFriendly);
        BOOL shouldTrack = NO;
        
        if( [trackHostile state] && isHostile) {
            shouldTrack = YES;
        }
        if( [trackNeutral state] && isNeutral) {
            shouldTrack = YES;
        }
        if( [trackFriendly state] && isFriendly) {
            shouldTrack = YES;
        }
        
        if(shouldTrack) [mob trackUnit];
        else            [mob untrackUnit];
    }
}


#pragma mark -
#pragma mark TableView Delegate & Datasource

- (void)tableView:(NSTableView *)aTableView  sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    if(aTableView == mobTable) {
        [_mobDataList sortUsingDescriptors: [aTableView sortDescriptors]];
        [mobTable reloadData];
    }
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    if(aTableView == mobTable) {
        return [_mobDataList count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1) return nil;
    if(aTableView == mobTable) {
        if(rowIndex >= [_mobDataList count]) return nil;
        
        if([[aTableColumn identifier] isEqualToString: @"Distance"])
            return [NSString stringWithFormat: @"%.2f", [[[_mobDataList objectAtIndex: rowIndex] objectForKey: @"Distance"] floatValue]];
        
        if([[aTableColumn identifier] isEqualToString: @"Status"]) {
            NSString *status = [[_mobDataList objectAtIndex: rowIndex] objectForKey: @"Status"];
            if([status isEqualToString: @"1"])  status = @"Combat";
            if([status isEqualToString: @"2"])  status = @"Hostile";
            if([status isEqualToString: @"3"])  status = @"Dead";
            if([status isEqualToString: @"4"])  status = @"Neutral";
            if([status isEqualToString: @"5"])  status = @"Friendly";
            return [NSImage imageNamed: status];
        }
        
        return [[_mobDataList objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
    }
    
    return nil;
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex
{
    if( aRowIndex == -1) return;
        if(aTableView == mobTable) {
            if(aRowIndex >= [_mobDataList count]) return;
            
            if ([[aTableColumn identifier] isEqualToString: @"Name"]) {
                [(ImageAndTextCell*)aCell setImage: [[_mobDataList objectAtIndex: aRowIndex] objectForKey: @"NameIcon"]];
            }
            
            if( ![aCell respondsToSelector: @selector(setTextColor:)] )
                return;
            
            if(cachedPlayerLevel == 0 || [mobColorByLevel state] == NSOffState) {
                [aCell setTextColor: [NSColor blackColor]];
                return;
            }
            
            Mob *mob = [[_mobDataList objectAtIndex: aRowIndex] objectForKey: @"Mob"];
            int mobLevel = [mob level];
            
            if(mobLevel >= cachedPlayerLevel+5) {
                [aCell setTextColor: [NSColor redColor]];
                return;
            }
            
            if(mobLevel > cachedPlayerLevel+3) {
                [aCell setTextColor: [NSColor orangeColor]];
                return;
            }
            
            if(mobLevel > cachedPlayerLevel-2) {
                [aCell setTextColor: [NSColor colorWithCalibratedRed: 1.0 green: 200.0/255.0 blue: 30.0/255.0 alpha: 1.0]];
                return;
            }
            
            if(mobLevel > cachedPlayerLevel-8) {
                [aCell setTextColor: [NSColor colorWithCalibratedRed: 30.0/255.0 green: 115.0/255.0 blue: 30.0/255.0 alpha: 1.0] ]; // [NSColor greenColor]
                return;
            }
            
            [aCell setTextColor: [NSColor darkGrayColor]];
        }
    return;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
    
    if(aTableView == mobTable) {
        if( [[aTableColumn identifier] isEqualToString: @"Pet"] ) {
            return NO;
        }
        if( [[aTableColumn identifier] isEqualToString: @"Hostile"] ) {
            return NO;
        }
        if( [[aTableColumn identifier] isEqualToString: @"Combat"] ) {
            return NO;
        }
    }
    return YES;
}

- (void)mobTableDoubleClick: (id)sender {
    [memoryViewMob release];
    memoryViewMob = nil;
    if( [sender clickedRow] == -1 || [sender clickedRow] >= [_mobDataList count] ) return;
    
    [memoryViewController showObjectMemory: [[_mobDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Mob"]];
    [controller showMemoryView];
}

#pragma mark -

@end
