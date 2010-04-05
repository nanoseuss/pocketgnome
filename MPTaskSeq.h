//
//  MPSeqTask.h
//  TaskParser
//
//  Created by admin on 9/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"



/*!
 * @class      MPSeqTask
 * @abstract   The Sequence (Seq) task runs a set of sub tasks in sequence.
 * @discussion 
 * The Seq task manages one or more sub tasks that can each run in sequence.  It starts with it's first
 * child task and operates it until that task reports back that it is finished or doesn't wantToDoSomething.
 * It then switches to the next task in the list and operates that one.  Once all the child tasks have 
 * completed, then the Seq task will be finished.
 *
 * Sequence Tasks are helpful when you must perform a set of tasks in order:
 * <code>
 *	Seq
 *	{
 *		 Walk { $Locations = [[X, Y, Z], [X, Y, Z]]; }
 *		 Harvest { $Types = ["Herb"]; }
 *	}
 * </code>
 *		
 */
@interface MPTaskSeq : MPTask {
	NSInteger currentIndex;
}


/*!
 * @function bestTask
 * @abstract Return the current child task that is doing work.
 * @discussion
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
 * @abstract Return the location of the current task's desired action.
 * @discussion
 *	For a Seq task, we return the location of the current child task that is running now. 
 */
- (MPLocation *) location;




/*!
 * @function restart
 * @abstract Reset this task's child tasks. (and start with the 1st child again)
 * @discussion
 *	A Seq task needs to make sure all it's children are restarted, and then begin to work with the first
 *  child again.
 */
- (void) restart;





/*!
 * @function wantToDoSomething
 * @abstract Find the next task that wants to do something.  If none, then return false.
 * @discussion
 *	Returns YES when there is work to be done.  Else returns NO.
 */
- (BOOL) wantToDoSomething;



/*!
 * @function activity
 * @abstract Returns the current activity needing to be done for this task's current child task.
 * @discussion
 */
- (MPActivity*) activity;



/*!
 * @function activityDone
 * @abstract Tells the current child task that the supplied activity has reported "done".
 * @discussion
 *	Returns YES or NO for some reason.
 */
- (BOOL) activityDone: (MPActivity*)activity;



#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
