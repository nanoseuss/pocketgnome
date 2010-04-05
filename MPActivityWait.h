//
//  MPActivityWait.h
//  TaskParser
//
//  Created by codingMonkey on 9/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"
@class MPTimer;


/*!
 * @class      MPActivityWait
 * @abstract   This activity simply does nothing.  It actually waits.
 * @discussion 
 * There are times in a task when you simply want to wait.  Sometimes that waiting is indefinate.  
 * Sometimes that waiting is for a specific period of time.  
 *
 * This activity is our waiting activity.  It can be called in several ways:
 *
 * - [MPActivityWait waitIndefinately] : returns a wait activity that just keeps on waiting.  No done 
 *   will be reported.  It is useful as a busy task waiting for other higher priority tasks to become 
 *   active.
 *
 * - [MPActivityWait waitForTime:XXXX] : returns a wait activity that will be active for the given XXXX ms.
 *   After that amount of time has expired, the activity will report done, and will close down.
 *
 */
@interface MPActivityWait : MPActivity {
	BOOL startedWait, startedIdle;
	MPTimer *timerWaitTime;		 // how long to wait.
	MPTimer *timerIdleActivity;  // do some random action every so often
}
@property (readonly, retain) MPTimer *timerWaitTime, *timerIdleActivity;


- (id) init;
- (id) initWithTask:(MPTask*)aTask;




#pragma mark -

/*!
 * @function waitIndefinately
 * @abstract Just keep waiting.
 * @discussion
 *	Returns a wait activity that just keeps on waiting.  No done will be reported.  It is useful as a 
 *  filler task waiting for other higher priority tasks to become active.
 */
+ (id) waitIndefinatelyForTask: (MPTask*) aTask;


/*!
 * @function waitForTime
 * @abstract Wait for a given amount of time (in ms).
 * @discussion
 *	Returns a wait activity that will be active for the given timeInMS. After that amount of time has 
 *  expired, the activity will report done, and will close down.
 */
+ (id) waitForTime: (NSInteger) timeInMS forTask:(MPTask *)aTask;

@end
