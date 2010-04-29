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

#import "MovementController.h"
#import "MPCustomClass.h"
#import "MPMover.h"
#import "MPNavigationController.h"
#import "PlayerDataController.h"
#import "Position.h"
#import "Route.h"
#import "Waypoint.h"



@interface MPActivityWalk (Internal)

- (BOOL) isRouteDone;
@end



@implementation MPActivityWalk
@synthesize customClass, listLocations, movementController, mover;



- (id) init {
	return [self initWithRoute:nil andTask:nil usingMount:NO];
}



- (id) initWithRoute: (Route*)aRoute andTask:(MPTask*)aTask usingMount:(BOOL)mount {
	
	if ((self = [super initWithName:@"Walk" andTask:aTask])) {
		
		
		// convert Route to array of points
		NSArray *listWaypoints = [aRoute waypoints];
		NSMutableArray *locations = [NSMutableArray array];
		for( Waypoint *wp in listWaypoints){
			[locations addObject: (MPLocation *)[wp position]];
		}
		
		// store arrayLocations
		self.listLocations = [locations copy];
		
		// currentIndx = 0;
		currentIndex = 0;
		
		useMount = mount;
		self.mover = [MPMover sharedMPMover];
		self.movementController = [[task patherController] movementController];
		self.customClass = [[task patherController] customClass];
		
	}
	return self;
}



- (void) dealloc
{
	[customClass release];
	[listLocations release];
	[mover release];
	[movementController release];
	
    [super dealloc];
}



#pragma mark -



// get ready to start
- (void) start {

	// now that we have our own mover: make sure MC isn't running
	[movementController resetMovementState]; 

	
	///
	/// OK, let's try to find the closest point in our list of locations
	///
	Position *myPosition = [[PlayerDataController sharedController] position];
	
	float currentDistance, minDistance;
	int index = 0;
	int minIndex = 0;
	
	minDistance = INFINITY;
	
	for( Position *pos in listLocations) {
		currentDistance = [myPosition distanceToPosition:pos];
		if (currentDistance <= minDistance) {
			minIndex = index;
			minDistance = currentDistance;
		}
		index ++;
	}
	
	currentIndex = minIndex;
	
	///
	/// Now attempt to see if we are approaching currentIndex or have just
	/// passed it:
	///
	
	// find the previous location (index)
	int prevIndx = currentIndex;
	if (prevIndx == 0) {
		prevIndx = [listLocations count] -1;
	}
	
	float distToCurrent = INFINITY;
	float distToMe = INFINITY;
	
	// get the previous and current Positions
	Position *prevPosition = [listLocations objectAtIndex:prevIndx];
	Position *currPosition = [listLocations objectAtIndex:currentIndex];
	
	// figure the distance from Previous -> Current  && Previous -> Me
	distToCurrent = [prevPosition distanceToPosition:currPosition];
	distToMe = [prevPosition distanceToPosition:myPosition];
	
	// if distance to Current is < distance to Me : then we have already run past the current pos.
	// (or so I'm assuming ...)
	if (distToCurrent < distToMe) {
		
		// so let's assume the next position is the one we should be running to.
		currentIndex ++;
		
		// adjust for end of list
		if (currentIndex >= [listLocations count]) {
			currentIndex = 0;
		}
	}
	
	
}



- (BOOL) work {

	// update currentIndex to the next Loction if necessary
	while ((currentIndex < [listLocations count]) && ([task myDistanceToPosition:[listLocations objectAtIndex:currentIndex]] <= 1.0f)) {
		currentIndex++;
	}
	
	
	// do move
	if (currentIndex < [listLocations count]) {
		
		// move to next location 
		MPLocation *nextStep = (MPLocation *)[listLocations	objectAtIndex:currentIndex];
		[mover moveTowards:nextStep within:1.0f facing:nextStep];
		
		
		[customClass runningAction]; // <--- spam running action here
		
		return NO;
		
	} else {
		
		// we are done
		[mover stopAllMovement];
		currentIndex = 0; // reset to 1st Location
		return YES;
	}

}



- (void) stop{
	
	[mover stopAllMovement];
	
}



- (NSString *) description {
	
	NSMutableString *text = [NSMutableString stringWithFormat:@" ActivityWalk \n  %i of %i points in route \n  ", currentIndex+1,[listLocations count] ];
	return text;
}



#pragma mark -
#pragma mark Helper methods


/*
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
 
 */


#pragma mark -


+ (id) walkRoute:(Route*)aRoute forTask:(MPTask*) aTask useMount:(BOOL)mount {
	
	MPActivityWalk *newActivity = [[MPActivityWalk alloc] initWithRoute:aRoute andTask: aTask usingMount:mount];
	return [newActivity autorelease];
}


+ (id) walkToLocation:(MPLocation*)aLocation forTask:(MPTask*) aTask useMount:(BOOL)mount {
	
	
	MPLocation *currentLocation = (MPLocation *)[[[aTask patherController] playerData] position];
	Route *newRoute = [[[aTask patherController] navigationController] routeFromLocation:currentLocation toLocation:aLocation];
	// Route *newRoute = [navagationController routeToLocation: aLocation];
	
	return [MPActivityWalk walkRoute:newRoute forTask:aTask useMount:mount];
}


/*
+ (id) walkToUnit:(XXXX *)aUnit forTask:(MPTask*) aTask useMount:(BOOL)mount {
	return [MPActivityWalk walkToLocation:[aUnit position] forTask:aTask useMount:mount];
}
*/

@end
