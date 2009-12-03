//
//  MobController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/17/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Mob.h"

@class CombatProfile;

@interface MobController : NSObject {
    IBOutlet id controller;
    IBOutlet id playerData;
    IBOutlet id botController;
    IBOutlet id memoryViewController;
    IBOutlet id combatController;
    IBOutlet id movementController;
    IBOutlet id auraController;
    IBOutlet id spellController;
    
    IBOutlet id view;
    
    IBOutlet id mobTable;
    IBOutlet id mobColorByLevel;
    //IBOutlet id mobHideNonSelectable;
    //IBOutlet id mobHidePets;
    //IBOutlet id mobHideCritters;
    
    IBOutlet id trackFriendlyMenuItem;
    IBOutlet id trackNeutralMenuItem;
    IBOutlet id trackHostileMenuItem;
    
    IBOutlet NSPopUpButton *additionalList;
    

    NSMutableArray *_mobList;
    NSMutableArray *_mobDataList;
    NSTimer *_updateTimer;
    float _updateFrequency;
    int cachedPlayerLevel;
    Mob *memoryViewMob;
    NSSize minSectionSize, maxSectionSize;
    NSString *filterString;
}

+ (MobController *)sharedController;

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readonly) NSImage *toolbarIcon;
@property float updateFrequency;

- (void)addAddresses: (NSArray*)addresses;
//- (BOOL)addMob: (Mob*)mob;
- (unsigned)mobCount;
- (NSArray*)allMobs;
- (void)resetAllMobs;
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

- (IBAction)filterMobs: (id)sender;
- (IBAction)updateTracking: (id)sender;
- (IBAction)resetMobList: (id)sender;
- (IBAction)targetMob: (id)sender;
- (IBAction)faceMob: (id)sender;
- (IBAction)additionalStart: (id)sender;
- (IBAction)additionalStop: (id)sender;

@end
