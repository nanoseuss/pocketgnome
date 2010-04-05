//
//  MPTaskGhostRoute.h
//  Pocket Gnome
//
//  Created by admin on 10/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"
@class MPLocation;
@class MPTimer;
@class Waypoint;
@class Route;
@class MPActivityWait;
@class MPActivityWalk;


typedef enum GhostRouteState { 
    GhostRouteWaitForRePop   = 1, 
    GhostRouteWaitForGraveYard = 2, 
    GhostRouteGhostWalkToClosestWaypoint = 3,
	GhostRouteMoveToRezPoint = 4,
	GhostRouteVerifyRez = 5
} MPGhostRouteState; 


/*!
 * @class      MPTaskGhostRoute
 * @abstract   Ghost walk back to your Corpse.
 * @discussion 
 * In the unfortunate event your toon dies, this task will take over and retrace the given route until it gets to the 
 * closest waypoint to your corpse.  Then it will attempt to walk to your corpse.  Once it is within range, it will Rez
 * and then attempt to continue on.
 *
 * Note: unlike PocketGnome, your GhostRoute task needs to be a single list of waypoints that will first navigate you from
 * the graveyard to your route, and then navigate your Route{} waypoints until it finds the corpse.
 * <code>
 *	 GhostRoute
 *	 {
 *		 $Prio = 1;
 *		 $Locations =	[
 *							// first plot the points back to your original route
 *							[x1, y1, z1],
 *							[x2, y2, z2],
 *							[x3, y3, z3],
 *							...
 *							[xN, yN, zN],
 *
 *							// now retrace your Route {} points to find your corpse:
 *							[x1, y1, z1],
 *							[x2, y2, z2],
 *							[x3, y3, z3],
 *							...
 *							[xN, yN, zN]
 *						];
 *	 }
 * </code>
 *		
 */
@interface MPTaskGhostRoute : MPTask {
	NSArray *locations;
	MPLocation *corpseLocation;
	Waypoint *closestWaypoint;
	Route *route;
	MPTimer *timerRetry;
	MPActivityWait *waitActivity;
	MPActivityWalk *walkToPositionActivity;
	MPActivityWalk *walkToWaypointActivity;
	
	MPGhostRouteState state;
}
@property (retain) MPActivityWait *waitActivity;
@property (retain) MPActivityWalk *walkToWaypointActivity, *walkToPositionActivity;
@property (retain) NSArray *locations;
@property (retain) Route *route;
@property (retain) Waypoint *closestWaypoint;
@property (retain) MPLocation *corpseLocation;
@property (readonly, retain) MPTimer *timerRetry;


#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;

@end
