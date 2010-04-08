//
//  MPActivityWalk.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityWalk.h"
#import "MPActivity.h"
#import "MPTask.h"
#import "PatherController.h"
#import "Route.h"
#import "MovementController.h"
#import "Waypoint.h"
#import "Position.h"
#import "PlayerDataController.h"
#import "MPNavigationController.h"
#import "RouteSet.h"


@interface MPActivityWalk (Internal)

- (BOOL) isRouteDone;
@end


@implementation MPActivityWalk
@synthesize route, routeSet, useMount, timerMoveDelay, movementController;


- (id) init {
	return [self initWithRoute:nil andTask:nil usingMount:NO];
}

- (id) initWithRoute: (Route*)aRoute andTask:(MPTask*)aTask usingMount:(BOOL)mount {
	
	if ((self = [super initWithName:@"Walk" andTask:aTask])) {
		self.route = [aRoute copy];
		self.routeSet = [RouteSet routeSetWithName:@"My Route"];
		[routeSet setRoute:route forKey:PrimaryRoute];
		
		currentIndex = 0;
		previousIndex = 0;
		indexLastWaypoint = [[route waypoints] count] -1;
		
		self.useMount = mount;
		self.timerMoveDelay = [MPTimer timer:2000]; // 2 sec delay before attempting to "resume"
		[timerMoveDelay forceReady];
		self.movementController = [[task patherController] movementController];
		state = WalkStateNotStarted;
	}
	return self;
}


- (void) dealloc
{
    [route release];
	[movementController release];
	
    [super dealloc];
}


#pragma mark -

// here we need to make sure we are moving on our route.
- (void) start {
	
	PGLog(@"[start]");
	
	// make sure we don't send these commands too frequently
	if ([timerMoveDelay ready]) {
	PGLog(@"[start] -- Timer Ready");		
		
		
		// if our current position tracking is not at initial point
		if (previousIndex != 0) {
			
			// (then we have been running before, but have been interrupted)
			
			// if current route != our route
			Route *currentRoute = [[movementController currentRouteSet] routeForKey:PrimaryRoute];
			if (currentRoute != route) {
				
				// (whoever interrupted us messed with our route)
				
				// setup our route again
				[movementController resetMovementState]; // clear their stuff out
				[movementController setPatrolRouteSet:routeSet];
				
			} // end if
			
			// resume movement
			[movementController resumeMovement];
			
			return;
			
		} // end if
	
		
	PGLog(@"[start] -- setting up movementController");
		// if we get to here, then we need to setup the mC with our route (1st time)
		// setup our route with movementController
		[movementController setPatrolRouteSet:routeSet];
			
		// kick start it!
		Waypoint *firstWaypoint = [[route waypoints] objectAtIndex:0];
		[movementController setDestinationWaypoint:firstWaypoint];
		[movementController moveToPosition:[firstWaypoint position]]; // 1st waypoint position
		PGLog(@"      ----> movingToPosition  %@", [firstWaypoint position]);
		
		// make sure we don't send these commands too quickly
		[timerMoveDelay start];
	}
	
/*	
	
	Route *currentRoute = [[movementController currentRouteSet] routeForKey:PrimaryRoute];
	if (([movementController isPatrolling]) && (currentRoute == route)) {
		PGLog(@"[walk][start]resumeMovement");
		[movementController resumeMovement];
	} else {
		
		// find closest waypoint in our route
//		[movementController setPatrolRoute:route];
		Waypoint *closestWaypoint = [self closestWaypoint];
		
		// if closest waypoint == last waypoint in our list then 
		NSArray *routeWaypoints = [route waypoints];
		if ( [routeWaypoints objectAtIndex:[routeWaypoints count]-1] == closestWaypoint) {
		
			PGLog(@"[walk][start] closest Waypoint == last waypoint ... moving to 1st");
			
			//  move to 1st waypoint.  (should move and stop when there, then we beginPatrol from there)
			[movementController moveToPosition:[routeWaypoints objectAtIndex:0]];
		
		} else {
			// just run route normally until end
			PGLog(@"[walk][start]beginPatrolAndStopAtLastPoint");
			
			[movementController setPatrolRouteSet:routeSet];
			
		}
	}
 */

}


- (BOOL) work {
	
	
	
	// mC should be moving here, so we make sure it is happening.
	if (![movementController isPatrolling]) {  // if (![movementController isMoving]) {
		PGLog( @"[MPActivityWalk work]  -- mC didn't seem to be moving.  calling [start] again!");
		[self start];  // <-- he knows what to do to get us started
	}
	
	
	// if we are done, then report so
	if ([self isRouteDone]) {
		
		PGLog( @"       Route Done! ");
		return YES;
		
	} 
	
/*
PGLog( @"[MPActivityWalk work]");
	if ([movementController isMoving]) {
		state = WalkStateStarted;
	}
	
	switch (state) {
		case WalkStateNotStarted:
			PGLog( @"   state = NotStarted ");
			// if isPaused
			if (![movementController isMoving]) { 
				
				PGLog( @"       mC not moving -> resumeMovement ");
				// resumeMovement
				[movementController resumeMovement];
				[timerMoveDelay start];
			}
			break;
			
			
		case WalkStateStarted:
			PGLog( @"   state = Started ");
			// if isPaused
			if (![movementController isMoving]) { 
				
				PGLog( @"       mC not moving -> waitTimer ");
				
				// give some time for the movementcontroller to register moving 
				// after our initial [start] and attempting to "resume"
				if ([timerMoveDelay ready]) { 
					
					PGLog( @"       mC not moving -> timerReady -> resumeMovement ");
					// resumeMovement
					[movementController resumeMovement];
				}
			}
			
			
			// if isDone
			if ([self isRouteDone]) {
				
				PGLog( @"       Route Done! ");
				// ok, tell the taskController we are done:
				return YES;
			}
			
			break;
		default:
			break;
	}
*/	
			
	// otherwise, we exit (but we are not "done"). 
	return NO;
}


- (void) stop{
	[movementController stopMovement];
	
	// if isDone
		// reset current routeSet to nil
		// resetMovementState
	// end if
}




- (NSString *) description {
	
	Waypoint *currentDestination = [movementController destinationWaypoint];
	
	int currIndx = 0;
	if (currentDestination != nil) {
		currIndx = [[route waypoints] indexOfObject:currentDestination] + 1;
	}
	
	NSMutableString *text = [NSMutableString stringWithFormat:@" ActivityWalk \n  %i of %i points in route \n    p%i/c%i/l%i", currIndx,[[route waypoints] count], previousIndex, currIndx, indexLastWaypoint ];
	return text;
}

#pragma mark -
#pragma mark Helper methods

// attempts to see if the mC has finished and is starting over
- (BOOL) isRouteDone {

	// the mC seems to auto repeat a route when it reaches the end.
	// that makes since for PG, but for this activity, we only want to run
	// it 1x and then stop.  so here we attempt to see if we jump from the end
	// point to the beginning.  if so, we should be done then.
	
	// find index of current pointer
	Waypoint *movementControllerDestination = [movementController destinationWaypoint];
	Waypoint *currentWaypoint = nil;
	currentIndex=0;
	int index = 0;
	for( index =0; index < [[route waypoints] count]; index++) {
		currentWaypoint = [[route waypoints] objectAtIndex:index];
		if (currentWaypoint == movementControllerDestination) {
			currentIndex = index;
			break;
		}
	}
	
	// if previous pointer == last index
	if (previousIndex == indexLastWaypoint) {
		
		// if current pointer != previous pointer
		if (currentIndex != indexLastWaypoint) {
			
			// return YES
			return YES;
			
		} // end if
	} // end if
	
	// update previous == current
	previousIndex = currentIndex;
	
	return NO;

}

- (Waypoint*)closestWaypoint{
	Waypoint *startWaypoint = nil;
	Position *playerPosition = (Position *)[[[task patherController] playerData] position];
	float minDist = INFINITY, tempDist;
	for(Waypoint *waypoint in [route waypoints]) {
		tempDist = [playerPosition distanceToPosition: [waypoint position]];
		if( (tempDist < minDist) && (tempDist >= 0.0f)) {
			minDist = tempDist;
			startWaypoint = waypoint;
		}
	}
	
	return startWaypoint;
}


#pragma mark -


+ (id) walkRoute:(Route*)aRoute forTask:(MPTask*) aTask useMount:(BOOL)mount {
	
	MPActivityWalk *newActivity = [[MPActivityWalk alloc] initWithRoute:aRoute andTask: aTask usingMount:mount];
	return [newActivity autorelease];
}


+ (id) walkToLocation:(MPLocation*)aLocation forTask:(MPTask*) aTask useMount:(BOOL)mount {
	
	
	MPLocation *currentLocation = (MPLocation *)[[[aTask patherController] playerData] position];
	Route *newRoute = [[[aTask patherController] navigationController] routeFromLocation:currentLocation toLocation:aLocation];
	// Route *newRoute = [navagationController routeToLocation: aLocation];
	
	// until above is implemented ... fake it!
//	Route *newRoute = [Route route];
//	[newRoute addWaypoint:[Waypoint waypointWithPosition:[aTask myPosition] ] ];
//	[newRoute addWaypoint:[Waypoint waypointWithPosition:aLocation]];
	
	return [MPActivityWalk walkRoute:newRoute forTask:aTask useMount:mount];
}


/*
+ (id) walkToUnit:(XXXX *)aUnit forTask:(MPTask*) aTask useMount:(BOOL)mount {
	return [MPActivityWalk walkToLocation:[aUnit position] forTask:aTask useMount:mount];
}
*/

@end
