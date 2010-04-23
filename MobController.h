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
#import "Mob.h"
#import "ObjectController.h"

@class CombatProfile;

@class BotController;

@class ObjectsController;

@interface MobController : ObjectController {
    IBOutlet BotController *botController;
    IBOutlet id memoryViewController;
    IBOutlet id combatController;
    IBOutlet id movementController;
    IBOutlet id auraController;
    IBOutlet id spellController;
	
	IBOutlet ObjectsController	*objectsController;

    IBOutlet id trackFriendlyMenuItem;
    IBOutlet id trackNeutralMenuItem;
    IBOutlet id trackHostileMenuItem;
    
    IBOutlet NSPopUpButton *additionalList;
    
    int cachedPlayerLevel;
    Mob *memoryViewMob;
}

+ (MobController *)sharedController;

@property (readonly) NSImage *toolbarIcon;

- (unsigned)mobCount;
- (NSArray*)allMobs;
- (void)doCombatScan;

- (void)clearTargets;
- (Mob*)playerTarget;
- (Mob*)mobWithEntryID: (int)entryID;
- (NSArray*)mobsWithEntryID: (int)entryID;
- (Mob*)mobWithGUID: (GUID)guid;

- (NSArray*)mobsWithinDistance: (float)mobDistance 
						MobIDs: (NSArray*)mobIDs 
					  position:(Position*)position 
					 aliveOnly:(BOOL)aliveOnly;

- (NSArray*)mobsWithinDistance: (float)distance
                    levelRange: (NSRange)range
                  includeElite: (BOOL)elite
               includeFriendly: (BOOL)friendly
                includeNeutral: (BOOL)neutral
                includeHostile: (BOOL)hostile;
- (Mob*)closestMobForInteraction:(UInt32)entryID;

- (NSArray*)uniqueMobsAlphabetized;
- (Mob*)closestMobWithName:(NSString*)mobName;

- (IBAction)updateTracking: (id)sender;

@end
