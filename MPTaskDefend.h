//
//  MPTaskDefend.h
//  Pocket Gnome
//
//  Created by admin on 10/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"
@class MPValue;
@class MPActivityApproach;
@class MPActivityAttack;
@class MPTaskController;
@class MobController;
@class PlayerDataController;
@class MPCustomClass;
@class Mob;
#import "MPTaskPull.h"



/*!
 * @class      MPTaskDefend
 * @abstract   Defend yourself.
 * @discussion 
 * (from http://wiki.ppather.net)
 * Fights back against monsters that attack you, without this task in a script the toon will not fight 
 * back to any monsters that attack.
 * <code>
 *	 Defend
 *	 {
 *		$Prio = 3;
 *	 }
 * </code>
 *		
 */

@interface MPTaskDefend : MPTask {

	float attackDistance;
	
	MPActivityApproach *approachActivity;
	MPActivityAttack *attackActivity;
	
	MobController *mobController;
	PlayerDataController *playerData;
	MPCustomClass *customClass;
	
	MPTaskController *taskController;
	
	Mob* selectedMob;
	
	MPPullState state;  // we'll follow the same states as MPTaskPull 
}
@property (retain) MPActivityApproach *approachActivity;
@property (retain) MPActivityAttack *attackActivity;
@property (retain) MobController *mobController;
@property (retain) PlayerDataController *playerData;
@property (retain) MPCustomClass *customClass;
@property (retain) MPTaskController *taskController;
@property (retain) Mob *selectedMob;

#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
