//
//  CombatProfileActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IgnoreEntry.h"
#import "SaveDataObject.h"

@class Unit;
@class Player;

@interface CombatProfile : SaveDataObject {
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
	
	// New additions
	BOOL partyDoNotInitiate;
	BOOL partyIgnoreOtherFriendlies;
	BOOL partyEmotes;
	int partyEmotesIdleTime;
	int partyEmotesInterval;
	BOOL followEnabled;
	BOOL followStopFollowingOOR;
	float followStopFollowingRange;
	BOOL acceptResurrection;
	BOOL checkForCampers;
	float checkForCampersRange;
	BOOL avoidMobsWhenResurrecting;	
	float moveToCorpseRange;
	
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

// New additions
@property (readwrite, assign) BOOL checkForCampers;
@property (readwrite, assign) BOOL partyDoNotInitiate;
@property (readwrite, assign) BOOL partyIgnoreOtherFriendlies;
@property (readwrite, assign) BOOL partyEmotes;
@property (readwrite, assign) int partyEmotesIdleTime;
@property (readwrite, assign) int partyEmotesInterval;
@property (readwrite, assign) BOOL followEnabled;
@property (readwrite, assign) BOOL followStopFollowingOOR;
@property (readwrite, assign) float followStopFollowingRange;
@property (readwrite, assign) BOOL acceptResurrection;
@property (readwrite, assign) float checkForCampersRange;
@property (readwrite, assign) BOOL avoidMobsWhenResurrecting;
@property (readwrite, assign) float moveToCorpseRange;

@end
