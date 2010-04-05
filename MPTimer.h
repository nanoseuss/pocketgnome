//
//  MPTimer.h
//  TaskParser
//
//  Created by admin on 9/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @class      MPTImer
 * @abstract   An object that tracks the time elapsed since it was started.
 * @discussion 
 * Useful in tracking cooldowns and making sure a minimum amount of time has 
 * elapsed before attempting an action.
 *		
 * The expected operaton of a timer is:
 * <pre>
 *	MPTimer *rejuvCooldown = [MPTimer timer:8000];
 *  [rejuvCooldown start];
 *  while( ![rejuvCooldown ready]) {
 *		sleep(100);
 *  }
 *  NSLog(@"Cooldown expired");
 *  [rejuvCooldown reset];  // starts it again!
 * </pre>
 */
@interface MPTimer : NSObject {
	NSDate *startTime;
	NSInteger duration, minDelay, maxDelay, difference;
	BOOL useRandom;
	BOOL forced;
	
}
@property (readwrite,retain) NSDate* startTime;
@property (readwrite) NSInteger duration;
@property (readwrite) NSInteger minDelay, maxDelay, difference;
@property (readwrite) BOOL useRandom;
@property (readwrite) BOOL forced;


/*!
 * @function start
 * @abstract Begins your timer.
 * @discussion
 *	Begins the operation of your timer by capturing the current time.
 */
- (void) start;



/*!
 * @function elapsedTime
 * @abstract Returns the amount of time (in ms) that has elapsed since [start] was called.
 * @discussion
 *	This method can be used to gather performance data for a routine, like so:
 * <code>
 *	- (void) example {
 *		[timer start];
 *		// do something important & worthy of timing
 *		elapsedTime = [timer elapsedTime];
 *  }
 * </code>
 */
- (NSTimeInterval) elapsedTime;


/*!
 * @function ready
 * @abstract Indicates if the given amount of time has elapsed.
 * @discussion
 *	Returns YES if > duration milliseconds have elapsed since [start] was called.
 *  NO otherwise.
 */
- (BOOL) ready;


/*!
 * @function reset
 * @abstract Restarts the timer.
 * @discussion
 */
- (void) reset;



/*!
 * @function forceReady
 * @abstract Timer will return Ready until next [timer start] command.
 * @discussion
 */
- (void) forceReady;


#pragma mark -


/*!
 * @function timer
 * @abstract Returns an initialized timer for the given duration (in ms)
 * @discussion
 */
+ (MPTimer *) timer: (NSInteger) delayInMS;


/*!
 * @function randomTimerFrom:To:
 * @abstract Returns with a randome delay duration (between minDelayInMS and maxDelayInMS).
 * @discussion
 */
+ (MPTimer *) randomTimerFrom: (NSInteger) minDelayInMS To:(NSInteger)maxDelayInMS;

@end
