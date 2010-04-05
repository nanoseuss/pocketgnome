//
//  MPActivityApproach.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityApproach.h"
#import "MPTask.h"
#import	"Unit.h"
#import "MovementController.h"
#import "PlayerDataController.h"
#import "PatherController.h"
#import "Position.h"
#import "MPTimer.h"



@implementation MPActivityApproach
@synthesize unit, useMount, lastPosition, moveTimer, movementController, playerDataController;

- (id) initWithUnit: (Unit*)aUnit andDistance:(float)howClose andTask:(MPTask*)aTask  {
	
	if ((self = [super initWithName:@"Approach" andTask:aTask])) {
		self.unit = aUnit;
		distance = howClose;
		self.lastPosition = nil;
		
		self.moveTimer = [MPTimer timer:850];
		
		self.movementController = [[task patherController] movementController];
		self.playerDataController = [[task patherController] playerData];
	}
	return self;
}


- (void) dealloc
{
    [unit release];
	[movementController release];
	[playerDataController release];
	[moveTimer release];
	[lastPosition release];
	
    [super dealloc];
}


#pragma mark -




- (void) start {

	// face Unit
	[playerDataController faceToward:[unit position]];
	
	// ensure movementController isn't running a route
	[movementController resetMovementState];
	[movementController setCurrentRouteSet:nil];
	
	// tell mC our desired distance
	[movementController setCloseEnough:distance];
	
	// start moving towards given unit
	[movementController moveToObject:unit];
	
	
	[moveTimer start];
	
	self.lastPosition = [unit position];
}



// Make sure we are making progress towards the target.  Stop when in range.
- (BOOL) work {
	
	
	// ok, current mC will walk us to 5.0yds of our unit.

	// if distance to unit < distance 
	Position *playerPosition = [playerDataController position];
	float currentDistance = [playerPosition distanceToPosition: [unit position]];
	if ( currentDistance < distance ) {
	
		PGLog(@"[work] currentDistance[%0.2f] < distance[%0.2f] --> stopping!",currentDistance, distance);
		
		// stop movement
		[movementController stopMovement];
		
		// we are within our desired distance so we are done
		return YES;
	} // end if



	// if we aren't moving for some reason 
	if (![movementController isMoving]) { 
	
		PGLog(@"[work] don't seem to be moving! --> resume");
		// resumeMovement
		//[movementController resumeMovement];
		[self start];
	}
	
	
	// if movement controller has different unit selected:
//	if ([movementController unit] != unit) {
//		PGLog(@"[work] movement controller has wrong unit!  try again.");
//		[self start];
//	}
	
	
/*	if (lastPosition != nil) {
		
		if ([lastPosition distanceToPosition:[unit position]] > 0.1f) {
			// adjust for movement ... 
			[movementController moveToObject:unit andNotify:NO];
		}
	}
*/
	
	// start moving towards given unit
/*
	if ([moveTimer ready]) {
		[movementController moveToMelee:unit];
		[moveTimer reset];
	}
*/
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
//	[movementController pauseMovement];
	[movementController setCloseEnough:5.0f];
	[movementController stopMovement];
	[movementController resetMovementState];
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (unit != nil) {
		
		Position *playerPosition = [playerDataController position];
		float currentDistance = [playerPosition distanceToPosition: [unit position]];
	
		[text appendFormat:@"  approaching [%@]  [%0.2f / %0.2f]", [unit name], currentDistance, distance];
		
	} else {
		[text appendString:@"  no unit to approach"];
	}
	
	return text;
}

#pragma mark -

+ (id) approachUnit:(Unit*)aUnit withinDistance:(float) howClose forTask:(MPTask *)aTask {

	return [[[MPActivityApproach alloc] initWithUnit:aUnit andDistance:howClose andTask:aTask] autorelease];

}
@end
