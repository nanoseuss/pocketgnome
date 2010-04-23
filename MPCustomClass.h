//
//  MPCustomClass.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Mob;
@class PatherController;

//// These are the states passed from your Custom Class back to the MPActivityAttack 
//// activity.  The activity will then respond to these return states

typedef enum CombatState { 
    CombatStateInCombat			= 1,	// target still alive
	CombatStateSuccess			= 2,	// you killed your target
	CombatStateSuccessWithAdd	= 3,	// killed target but have another mob
	CombatStateBugged			= 4,	// target seems bugged (EVADING, etc...)
	CombatStateBuggedWithAdd	= 5,	// Bugged but you picked up another mob
	CombatStateDied				= 6,	// you died ... dang!
	CombatStateMistake			= 7		// Given an invalid mob (dead) to attack
} MPCombatState; 



//// These are for use inside your custom class to help determine initial actions and 
//// regular actions.
typedef enum CCCombatState { 
    CCCombatPreCombat	= 1,	// performing initial prep
	CCCombatCombat	= 2		// get em!
} MPCCCombatState; 



@protocol PatherClass

/*!
 * @function name
 * @abstract Return a Name for your Custom Class.
 * @discussion 
 * Use this to display the name of your custom class in drop lists. 
 */
- (NSString *) name;



/*!
 * @function preCombatWithMob:atDistance
 * @abstract perform your pre combat actions.
 * @discussion 
 * This routine is called upon an approach to your next victim (see MPTaskPull).  It should not
 * actively loop waiting for your toon to approach, but rather it is called ~ 1/sec as the 
 * approach takes place.  
 *
 * This routine is provided with the mob that is being approached as well as the current distance
 * to that mob.  You can perform different actions as you approach to certain distances.
 *
 * NOTE: the MPTaskPull Task will automatically pass control to the MPActivityAttack activity once
 * you reach the AttackDistance setting in PocketGnome.  When that happens, this routine will no longer
 * be called. So your preCombat actions should be for those actions that need to happen before combat AND
 * before you reach AttackDistance from your target.  After that, your killTarget: routine will need to 
 * handle any preCombat actions that need to happen at or withing AttackDistance.
 */
- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob;


/*!
 * @function killTarget
 * @abstract perform your attack actions.
 * @discussion 
 * This routine is expected to be called, choose an action, perform it, then return.  This routine 
 * should be called ~100ms, so it acts like a loop.  Your CC just needs to maintain it's state and 
 * reference that the next call.
 *
 * NOTE: Do not actively loop in this routine like in previous Pather Classes!
 */
- (MPCombatState) killTarget: (Mob *) aTarget;

/*!
 * @function rest
 * @abstract Perform any rest actions.
 * @discussion 
 * It is up to your class to figure out what to do when resting.
 *
 * Called by the Rest{} task.
 *
 * Returns YES if resting is done, NO otherwise.
 */
- (BOOL) rest;

/*!
 * @function runningAction
 * @abstract Perform any checks and actions while patrolling.
 * @discussion 
 * This method is called by the MPActivityWalk activity as it is walking. It should be
 * called ~10/sec.  So don't attempt to do very much on each call.
 */
- (void) runningAction;


/*!
 * @function setup
 * @abstract Setup your bot for action. 
 * @discussion 
 * This method will be called once Pather is ready to run.  At this point, your character
 * should be loaded in memory, and you should then do your initial spell setup.
 */
- (void) setup;

+ (id) classWithController: (PatherController *) controller;
@end



@interface MPCustomClass : NSObject <PatherClass> {
	Mob *currentMob;
	PatherController *patherController;
}
@property (readwrite, retain) Mob *currentMob;
@property (retain) PatherController *patherController;

-(id) init;
-(id) initWithController: (PatherController *) controller;


- (NSArray *) mobsAttackingMe;

@end
