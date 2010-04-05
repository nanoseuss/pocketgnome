//
//  MPWhenTask.h
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTaskConditional.h"


typedef enum WhenTaskState { 
    WhenTaskStateWaiting	= 1, 
    WhenTaskStateRunning	= 2, 
    WhenTaskStateStopped	= 3
} MPWhenTaskState; 


/*!
 * @class      MPWhenTask
 * @abstract   Execute single child when condition is true, and keep executing even if condition
 *             becomes false in the process
 * @discussion 
 * (following is from PPather wiki documentation)
 * When will start executing it's single child when it's condition becomes true. If 
 * this condition later becomes false again, When will continue to run it's child regardless. 
 * This is in contrast to the If task which will stop it's child if it's condition becomes false 
 * after it was previously true.
 *
 * The following example will show a scenario where When is very useful. As soon as the 
 * condition is true (equipment durability is less than 30%), the nested Seq will execute. It 
 * will first do a Walk to the vendor, then execute a Vendor task which will repair your equipment.
 * At this point, the When task's condition will become false (durability is no longer less than 
 * 30%, but 100%). Using an If task would stop the Seq immediately after repairing, but as we are 
 * using When, the Seq is allowed to keep running eventhough the condition is now false, so the
 * second Walk can execute normally.
 * <code>
 *	 When
 *	 {
 *		 $cond = $MyDurability <= 0.3;
 *		 Seq
 *		 {
 *			 Walk
 *			 {
 *				 $Locations = [[X,Y,Z], [X,Y,Z]];
 *			 }
 *			 Vendor
 *			 {
 *				 $NPC = "Repair Guy";
 *			 }
 *			 Walk
 *			 {
 *				 $Locations = [[X,Y,Z], [X,Y,Z]];
 *			 }
 *		 }
 *	 }
 * </code>
 *		
 */
@interface MPTaskWhen : MPTaskConditional {
	MPWhenTaskState taskState;
}



#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;
@end
