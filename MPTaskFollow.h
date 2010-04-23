//  Replace: ActivityFollow, activityFollow, MPTaskFollow
//
//  MPTaskFollow.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class Mob;
@class MobController;
@class MPActivityFollow;
@class MPTaskController;
@class MPTimer;
@class PlayerDataController;
@class Unit;


/*
typedef enum PullState { 
    PullStateSearching   = 1, 
    PullStateApproaching = 2, 
    PullStateAttacking	 = 3,
	PullStateWrapup		 = 4
} MPPullState; 
*/

/*!
 * @class      MPTaskFollow
 * @abstract   Follow a given Player/Unit around.
 * @discussion 
 * (from http://wiki.ppather.net)
 * The Follow task is used when in groups/parties.  This task specifies a
 * unit to follow around.  The follow task will then find that unit and stay
 * within $ApproachTo & $MaxDistance of that unit.  
 *
 * When the unit gets $MaxDistance away from your character, it will then 
 * start moving towards the unit.
 *
 * Your character will continue to move towards the unit until it reaches 
 * $ApproachTo distance away.
 *
 * If no name is given to follow, your character will then search for the 
 * closest party member to follow.  
 *
 * When following, the MPActivityFollow activity will track the path of the 
 * unit being followed.  It will then attempt to trace that path as it 
 * approaches your unit.  Hopefully this will prevent getting caught on 
 * doorways and such.
 * 
 * In addition to party following, this task can be used in quests to follow units
 * as you escort them to their destination.
 * 
 * <code>
 *	 Follow
 *	 {
 *		$Prio  = 3;
 *		$Names = ["Player1","Unit2"];  // (Optional) Names of the players/units to follow
 *		$ApproachTo  = 10;  // Distance to approach your target
 *		$MaxDistance = 20; // When target gets this far away, begin to follow
 *	 }
 * </code>
 *		
 */
@interface MPTaskFollow : MPTask {
	
	float approachTo, maxDistance;
	
	MPActivityFollow *activityFollow;
	NSArray *listNames;
	Unit *unitToFollow;
	
//	MPPullState state;
}
@property (retain) NSArray *listNames;
@property (retain) MPActivityFollow *activityFollow;
@property (retain) Unit *unitToFollow;


#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
