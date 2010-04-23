//
//  MPActivityLoot.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"
@class MPTimer;
//@class MovementController;
@class Mob;
@class MPMover;


typedef enum LootActivity { 
    LootActivityNotStarted	= 1,	// haven't performed initial loot action
	LootActivityLooting	= 2,	// In process of looting
	LootActivityWaitingForSkinningStart = 3,  // waiting for skinning to start
	LootActivitySkinning   = 4,	// Skinning Mob
	LootActivityFinished	= 5		// All done.
} MPLootActivity; 

@interface MPActivityLoot : MPActivity {

	BOOL shouldSkin;
	NSInteger attemptCount;
	Mob *lootMob;
	MPLootActivity state;
	MPTimer *timeOut, *timeToSkin;
	MPMover *mover;
//	MovementController *movementController;
}
@property (retain) MPTimer *timeOut, *timeToSkin;
@property (retain) Mob *lootMob;
@property (retain) MPMover *mover;
//@property (retain) MovementController *movementController;


#pragma mark -

+ (id)  lootMob:(Mob *)aMob andSkin:(BOOL)doSkin forTask:(MPTask *)aTask;
@end
