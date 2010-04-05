//
//  MPParTask.h
//  TaskParser
//
//  Created by Coding Monkey on 8/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"





/*!
 * @class      MPParTask
 * @abstract   The Parallel (Par) task allows you to manage several sub tasks that run in parallel.
 * @discussion 
 * The Par task manages one or more sub tasks that can each run out of sequence.  When ever a task has work to do
 * it can run.  If more than one task wants to run at a time, the task with the highest priority runs first.
 *
 * When creating a Task file, your root task is almost always a Par task like this:
 * <code>
 *	 Par
 *	 {
 *		 $Minlevel = $MyLevel - 5; // Default min level to pull
 *		 $MaxLevel = $MyLevel + 1; // Default max level to pull
 *		 
 *		 Defend { $Prio = 0; } // If you are attacked, defend yourself
 *		 Rest { $Prio = 1;} // If you need to eat or drink, do it
 *		 Danger { $Prio = 3;  $DangerDistance = 20; }// If there is a hostile mob close, pull it
 *
 *		 Loot // If there are any dead mobs to loot, do it
 *		 {
 *			 $Prio = 4;
 *			 $Skin = false;
 *		 }
 *		 Harvest // See anything to pick up? Move to it and pick it up
 *		 {
 *			 $Prio = 5;
 *			 $Types = ["Herb","Ore"];
 *		 }
 *		 Pull // What I will kill?
 *		 {
 *			 $Prio = 7;
 *			 $Names = ["Mob1","Mob2"];
 *			 $Factions = [55,18,7]; // Should have at least one. Check the General->Target area of Pather for a targeted mobs Faction
 *			 $Distance = 20;
 *		 }
 *		 Hotspots // Where I'll move to
 *		 {
 *			 $Prio = 10;
 *			 $Order = "Random"; // can be Order, Reverse or Random
 *			 $Locations = ["x1,y1,z1,","x2,y2,z2"]; // Needs at least one location. Look in the General->Misc Info area of Pather for your task location.
 *		 }
 *	 }
 * </code>
 *		
 */
@interface MPTaskPar : MPTask {

}



/*!
 * @function bestTask
 * @abstract Returns the bestTask from among our child tasks.
 * @discussion
 *	Most of the Par task's methods should be performed by one of our child tasks. 
 *  This method will return the best child task to be performing it's actions next.  
 */
- (MPTask *) bestTask;





/*!
 * @function finished
 * @abstract Returns YES if all the child tasks are finished. NO otherwise.
 * @discussion
 */
- (BOOL) isFinished;


/*!
 * @function location
 * @abstract Return the location of the best tasks desired action.
 * @discussion
 *	For a Par task, we return the location of the child task that is the best task to run now. 
 */
- (MPLocation *) location;




/*!
 * @function restart
 * @abstract Reset this task's child tasks.
 * @discussion
 *	A Par task needs to make sure all it's children are restarted.
 */
- (void) restart;





/*!
 * @function wantToDoSomething
 * @abstract Indicate if this task's best task wants to do anything.
 * @discussion
 *	Returns YES when there is work to be done.  Else returns NO.
 */
- (BOOL) wantToDoSomething;



/*!
 * @function activity
 * @abstract Returns the current activity needing to be done for this task's best child task.
 * @discussion
 *	A task may have many activities to carry out.  The task keeps track of which current activity
 *  to perform and returns that here.
 *
 *  If no activity is to be done, then it returns nil.
 */
- (MPActivity*) activity;



/*!
 * @function activityDone
 * @abstract Tells the best child task that the supplied activity has reported "done".
 * @discussion
 *	Returns YES or NO for some reason.
 */
- (BOOL) activityDone: (MPActivity*)activity;


#pragma mark -

+ (id) initWithPather: (PatherController*)controller;

@end
