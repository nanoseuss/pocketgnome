//
//  MPActivityAttack.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"
@class Mob;
@class MPCustomClass;
@class MPTaskController;
@class MPTimer;

typedef enum AttackState { 
    AttackStateNotStarted	= 1,	// performing initial prep
	AttackStateAttacking	= 2,	// get em!
	AttackStateFinished		= 3		// Finished and waiting 1 sec for Loot to become visible.
} MPAttackState; 


/*!
 * @class      MPActivityAttack
 * @abstract   This activity initiates combat with an in game unit.
 * @discussion 
 * Found someone who needs a little punishing?  This is the task for you.
 *
 */
@interface MPActivityAttack : MPActivity {
	Mob *mob;
	MPCustomClass *customClass;
	MPTimer *waitForLoot;
	MPAttackState state;
}
@property (readwrite,retain) Mob *mob;
@property (retain) MPCustomClass *customClass;
@property (retain) MPTimer *waitForLoot;


#pragma mark -

+ (id) attackMob: (Mob*)aMob forTask:(MPTask*)aTask;

@end
