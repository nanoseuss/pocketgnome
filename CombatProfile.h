//
//  IgnoreProfile.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/19/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IgnoreEntry.h"

@class Unit;
@class Player;

@interface CombatProfile : NSObject <NSCoding, NSCopying> {
    NSString *_name;
    NSMutableArray *_combatEntries;
    
    BOOL combatEnabled, onlyRespond, attackNeutralNPCs, attackHostileNPCs, attackPlayers, attackPets;
    BOOL attackAnyLevel, ignoreElite, ignoreLevelOne, ignoreFlying;
	
	// Healing
	BOOL healingEnabled, autoFollowTarget, mountEnabled;
	float healingRange;
	
	// Party
	UInt64 tankUnitGUID;
	UInt64 assistUnitGUID;
	UInt64 followUnitGUID;
	float followDistanceToMove, yardsBehindTargetStart, yardsBehindTargetStop;
	BOOL assistUnit, tankUnit, followUnit, partyEnabled;
	BOOL disableRelease;
    
    float attackRange, engageRange;
    int attackLevelMin, attackLevelMax;
	
	BOOL _changed;
	NSString *_UUID;
}

+ (id)combatProfile;
+ (id)combatProfileWithName: (NSString*)name;

- (BOOL)unitShouldBeIgnored: (Unit*)unit;

- (unsigned)entryCount;
- (IgnoreEntry*)entryAtIndex: (unsigned)index;

- (void)addEntry: (IgnoreEntry*)entry;
- (void)removeEntry: (IgnoreEntry*)entry;
- (void)removeEntryAtIndex: (unsigned)index;

@property (readwrite, retain) NSArray *entries;
@property (readwrite, copy) NSString *name;
@property (readwrite, assign) UInt64 tankUnitGUID;
@property (readwrite, assign) UInt64 assistUnitGUID;
@property (readwrite, assign) UInt64 followUnitGUID;
@property (readwrite, assign) BOOL combatEnabled;
@property (readwrite, assign) BOOL onlyRespond;
@property (readwrite, assign) BOOL attackNeutralNPCs;
@property (readwrite, assign) BOOL attackHostileNPCs;
@property (readwrite, assign) BOOL attackPlayers;
@property (readwrite, assign) BOOL attackPets;
@property (readwrite, assign) BOOL attackAnyLevel;
@property (readwrite, assign) BOOL ignoreElite;
@property (readwrite, assign) BOOL ignoreLevelOne;
@property (readwrite, assign) BOOL ignoreFlying;
@property (readwrite, assign) BOOL assistUnit;
@property (readwrite, assign) BOOL tankUnit;
@property (readwrite, assign) BOOL followUnit;
@property (readwrite, assign) BOOL partyEnabled;

@property (readwrite, assign) BOOL healingEnabled;
@property (readwrite, assign) BOOL autoFollowTarget;
@property (readwrite, assign) float followDistanceToMove;
@property (readwrite, assign) float yardsBehindTargetStart;
@property (readwrite, assign) float yardsBehindTargetStop;
@property (readwrite, assign) float healingRange;
@property (readwrite, assign) BOOL mountEnabled;
@property (readwrite, assign) BOOL disableRelease;

@property (readwrite, assign) float attackRange;
@property (readwrite, assign) float engageRange;
@property (readwrite, assign) int attackLevelMin;
@property (readwrite, assign) int attackLevelMax;

@property (readonly, retain) NSString *UUID;
@property (readwrite, assign) BOOL changed;

@end
