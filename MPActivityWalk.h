//
//  MPActivityWalk.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"
@class MovementController;
@class PatherController;
@class BotController;
@class Route;
@class MPTimer;
@class Waypoint;
@class RouteSet;


typedef enum WalkState { 
    WalkStateNotStarted		= 1,	// marks that we haven't begun walking, (so don't "resume" )
    WalkStateStarted		= 2		// we've already begun traveling the route, so ok to "resume"
} MPWalkState; 

/*!
 * @class      MPActivityWalk
 * @abstract   This activity moves you around the world.
 * @discussion 
 * Need to get from one location to another?  This is the activity to use.  
 *
 * This activity relys on PocketGnome's default MovementController (MC) to move.  The MC 
 * is based on a defined Route.  So this Activity will attemp to generate a route to give the 
 * MC, so it can do it's thing.
 *
 * This activity can be created several ways:
 *
 * - [MPActivityWalk walkRoute: forTask: useMount:] : A route is given, so this is easy.  Just pass this onto the MC.
 *
 * - [MPActivityWait walkToLocation: forTask: useMount:] : given a location we will have to generate a 
 *   route. (this is what Pathing is all about isn't it).  
 *
 * - [MPActivityWalk walkToUnit: forTask: useMount:] : given an in game unit, generate a route to get there.
 *
 */
@interface MPActivityWalk : MPActivity {
	Route *route;
	RouteSet *routeSet;
	BOOL useMount;
	MovementController *movementController;
	MPTimer *timerMoveDelay;
	int currentIndex, previousIndex, indexLastWaypoint;
	MPWalkState state;
}
@property (retain) Route *route;
@property (retain) RouteSet *routeSet;
@property (readwrite) BOOL useMount;
@property (readwrite, retain) MPTimer *timerMoveDelay;
@property (retain) MovementController *movementController;

- (id) initWithRoute: (Route*)aRoute andTask:(MPTask*)aTask usingMount:(BOOL)mount;


#pragma mark -
#pragma mark Helper methods

- (Waypoint*)closestWaypoint;

#pragma mark -

/*!
 * @function walkRoute:forTask:useMount:
 * @abstract Walk this defined Route.
 * @discussion
 *	Returns a walk activity to run the current route.
 */
+ (id) walkRoute: (Route *) aRoute forTask:(MPTask *)aTask useMount:(BOOL)mount;

/*!
 * @function walkToLocation:forTask:useMount:
 * @abstract Walk to this location.
 * @discussion
 *	Will generate a route that takes you to the desired location. (eventually)
 */
+ (id) walkToLocation:(MPLocation*)aLocation forTask:(MPTask*) aTask useMount:(BOOL)mount;

@end
