//
//  MPRouteTask.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"
@class Route;
@class MPActivityWalk;
@class MPTaskController;

/*!
 * @class      MPRouteTask
 * @abstract   Run through the given locations.
 * @discussion 
 * The Route task is for when you want to predefine a path you want to take.  It works like previous
 * waypoint system routes.
 *
 * NOTE: this task does NOT PATH between the points.  It simply points and runs.
 * <code>
 *	 Route
 *	 {
 *		 $Prio = 5;
 *		 $Locations =	[
 *							[x1, y1, z1],
 *							[x2, y2, z2],
 *							[x3, y3, z3],
 *							...
 *							[xN, yN, zN]
 *						];
 *		$Repeat = YES;  // default is single pass
 *		$Order  = Reverse;  // default is order : 
 *	 }
 * </code>
 *		
 */
@interface MPTaskRoute : MPTask {
	NSArray *locations;
	BOOL repeat;
	BOOL inOrder;
	BOOL done;
	Route *route;
	MPActivityWalk *walkActivity;
	MPTaskController *taskController; // for combat checking
}
@property (retain) MPActivityWalk *walkActivity;
@property (retain) MPTaskController *taskController;
@property (retain) NSArray *locations;
@property (retain) Route *route;




#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;

@end
