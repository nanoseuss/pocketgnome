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

@interface CombatProfile : NSObject <NSCoding, NSCopying> {
    NSString *_name;
    NSMutableArray *_combatEntries;
    
    BOOL combatEnabled, onlyRespond, attackNeutralNPCs, attackHostileNPCs, attackPlayers, attackPets;
    BOOL attackAnyLevel, ignoreElite, ignoreLevelOne;
    
    float attackRange;
    int attackLevelMin, attackLevelMax;
}

+ (id)combatProfile;
+ (id)combatProfileWithName: (NSString*)name;

- (BOOL)unitFitsProfile: (Unit*)unit ignoreDistance: (BOOL)ignoreDistance;

- (unsigned)entryCount;
- (IgnoreEntry*)entryAtIndex: (unsigned)index;

- (void)addEntry: (IgnoreEntry*)entry;
- (void)removeEntry: (IgnoreEntry*)entry;
- (void)removeEntryAtIndex: (unsigned)index;

@property (readwrite, retain) NSArray *entries;
@property (readwrite, copy) NSString *name;
@property (readwrite, assign) BOOL combatEnabled;
@property (readwrite, assign) BOOL onlyRespond;
@property (readwrite, assign) BOOL attackNeutralNPCs;
@property (readwrite, assign) BOOL attackHostileNPCs;
@property (readwrite, assign) BOOL attackPlayers;
@property (readwrite, assign) BOOL attackPets;
@property (readwrite, assign) BOOL attackAnyLevel;
@property (readwrite, assign) BOOL ignoreElite;
@property (readwrite, assign) BOOL ignoreLevelOne;

@property (readwrite, assign) float attackRange;
@property (readwrite, assign) int attackLevelMin;
@property (readwrite, assign) int attackLevelMax;

@end
