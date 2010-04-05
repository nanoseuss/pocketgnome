//
//  MPActivity.h
//  TaskParser
//
//  Created by codingMonkey on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPLocation.h"

@class MPTask;
@class MPTaskController;



/*!
 * @class      MPActivity
 * @abstract   Activities represent a basic unit of work that we want to accomplish.
 * @discussion 
 * In MacPather an Activity represents work that your toon needs to perform.  
 * 
 * One or more Activities are generally defined by a Task that needs to be done.
 *
 * Activities generally operate in the following manner:
 *	<pre>
 *		BOOL done = NO;
 *		MPActivity *newActivity = [currentTask activity];
 *		[newActivity start];
 *		while (!done = [newActivity work]) {
 *
 *		}
 *		MPTask *parentTask = [newActivity task];
 *		[parentTask activityDone: newActivity];
 *  </pre>
 *
 * Before an Activity is worked on, be sure to call it's [newActivity start] method.
 *
 * In order for an Activity to perform it's work, you must call [newActivity work].  This method is intended to 
 * be called repeatedly.  The method will return YES once the activity has completed, otherwise it continues to 
 * return NO.
 *
 * If an activity is being interrupted, then be sure to call it's [newActivity stop] method.
 *
 * Also, you can find out the desired location the activity wants to do work at using [newActivity location];
 *		
 */
@interface MPActivity : NSObject {
	NSString *name;
	MPTask *task;
	MPTaskController *taskController;
	
}

@property (readwrite, retain) NSString *name;
@property (readwrite, retain) MPTask *task;
@property (readwrite, retain) MPTaskController *taskController;


- (id) init;
- (id) initWithName:(NSString*)aName andTask:(MPTask*)aTask;


#pragma mark -


/*!
 * @function location
 * @abstract Return the location that this activity wants to do work at.
 * @discussion
 *	Returns an (MPLocation) representing where this activity wants to do work at.  (like a final destination)
 */
- (MPLocation *) location;


/*!
 * @function start
 * @abstract Prepare this Activity to begin doing work.
 * @discussion
 *	Performs any necessary initial setup of data and activities.
 */
- (void) start;


/*!
 * @function work
 * @abstract Perform the activity.
 * @discussion
 *	Carry out the activity.  This selector is intended to be called repeatedly.  The implementation should not
 *  loop internally.
 */
- (BOOL) work;


/*!
 * @function stop
 * @abstract Prepare this Activity to stop doing work before it was completed.
 * @discussion
 *	This should be called if an Activity is being interrupted.  This selector is for the Activity to cease it's current
 *  activity in a controlled manner.  (like stop running)
 */
- (void) stop;



@end