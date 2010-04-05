//
//  MPPerformanceController.h
//  TaskParser
//
//  Created by admin on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
 * @class      MPPerformanceController
 * @abstract   The Performance Controller attempts to measure the amount of work being performed by our events.
 * @discussion 
 * The PerformanceController collects the amount of work (measured in ms) beind done by our various events
 * during a given time period.
 *
 * This data can be used by intensive routines to throttle their work so they can free up other events 
 * for processing.
 *		
 */
@interface MPPerformanceController : NSObject {
	NSMutableArray* currentMeasurements;	// the collection of measurements for the current time period
	NSMutableArray* historyMeasurements;	// the past [numHistoryMeasurements] of used time
	NSInteger numHistoryMeasurements;		// How many historical measurements to keep
	NSInteger maxTime;						// the max amount of MS our tasks should take
}
@property (readwrite,retain) NSMutableArray *currentMeasurements, *historyMeasurements;


/*!
 * @function storeWorkTime
 * @abstract Record the given timeUsed in the current cycle's calculations.
 * @discussion
 *	Used by an event to store how much work it performed during it's execution.  For example:
 *  <code>
 *	- (void) processEvents {
 *		 [timerWorkTime start];
 *		 ....
 *		 [performanceController storeWorkTime:[timerWorkTime elapsedTime]];
 *	}
 *  </code>
 */
- (void) storeWorkTime:(NSInteger) timeUsed;


/*!
 * @function reset
 * @abstract Compiles the current array of values into a historical value and starts over for another cycle.
 * @discussion
 *	This event should be called every time interval that is == to maxTime ms.
 */
- (void) reset;



/*!
 * @function averageLoad
 * @abstract Returns the average of the stored numHistoryMeasurements.
 * @discussion
 *	This event should be called every time interval that is == to maxTime ms.
 */
- (NSInteger) averageLoad;



/*!
 * @function lastLoad
 * @abstract Returns the last stored load value in the history array.
 * @discussion
 * Useful for figureing out the amount of time to use if there are no current load values.
 */
- (NSInteger) lastLoad;



/*!
 * @function currentLoad
 * @abstract Returns the SUM(currentArray).
 * @discussion
 *	Can be used to figure out how much time is left to use for the current cycle.
 */
- (NSInteger) currentLoad;



/*!
 * @function remainingLoad
 * @abstract Returns the amount of ms left in current cycle.
 * @discussion
 *	Can be by a task to figure out how much time it can use for an operation. For example:
 * <code>
 * - (void) work {
 *		timerWork = [MPTimer timer:[performanceController remainingLoad]];
 *      while (!taskDone && ![timerWork ready] ) {
 *			// do a unit of work here
 *		}
 *		[performanceController storeWorkTime:[timerWorkTime elapsedTime]];
 * }
 * </code>
 */
- (NSInteger) remainingLoad;


- (NSInteger) sum: (NSMutableArray *) myArray;

@end
