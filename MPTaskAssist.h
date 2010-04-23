//
//  MPTaskAssist.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/21/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTaskPull.h"





/*!
 * @class      MPTaskAssist
 * @abstract   Chooses Targets based upon Assisting your specified party members.
 * @discussion 
 * The Assist Task is a special form of a Pull task.  Instead of searching all the nearby
 * mobs for mobs that match a given Pull criteria, it simply scans a specified list of 
 * players/units for mobs that they are attacking.  If they are attacking a mob, then 
 * this task will initiate a pull of that mob.
 *
 * The task should be in the following format:
 * <code>
 *	 Assist
 *	 {
 *		$Prio = 3;
 *		$Names = ["Earnie","Burt"];  // names of players/units to assist
 *	 }
 * </code>
 *		
 */
@interface MPTaskAssist : MPTaskPull {

	NSArray *assistNames, *assistUnits;
	MPTimer *timerUpdateList;
}
@property (retain) NSArray *assistNames, *assistUnits;
@property (retain) MPTimer *timerUpdateList;


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
