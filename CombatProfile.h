/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import <Cocoa/Cocoa.h>
#import "IgnoreEntry.h"
#import "SaveDataObject.h"

@class Unit;
@class Player;

@interface CombatProfile : SaveDataObject {
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

@end
