//
//  MPActivityFollow.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPActivityFollow.h"

#import "Mob.h"
#import "MPCustomClass.h"
#import "MPMover.h"
#import "PlayerDataController.h"
#import "Position.h"
#import "Unit.h"






@interface MPActivityFollow (Internal)

- (float) myDistanceToUnit:(Unit *)unit;
- (float) myDistanceToPosition:(Position *)position;
- (void) removeClosePositions;

@end






@implementation MPActivityFollow

@synthesize followUnit, lastPosition, mover, targetRoute;



- (id) initWithUnit: (Unit*)aUnit approachTo: (float) howClose maxDistance:(float) howFar andTask:(MPTask*)aTask {
	
	if ((self = [super initWithName:@"Follow" andTask:aTask])) {
		
		self.followUnit = aUnit	;
		approachTo = howClose;
		maxDistance = howFar;
		
		lastHeading = 0;
		self.lastPosition = nil;
		
		self.mover = [MPMover sharedMPMover];
		self.targetRoute = [NSMutableArray array];
		
		state = FollowStateInRange;
	}
	return self;
}


- (void) dealloc
{
    [followUnit release];
	[lastPosition release];
	[mover release];
	[targetRoute release];
	
    [super dealloc];
}




#pragma mark -

- (void) start {

	state = FollowStateInRange;
	if ((followUnit != nil)&& ([followUnit isValid])) {
		lastHeading = [followUnit directionFacing];
		self.lastPosition = [followUnit position];
		[targetRoute addObject:[followUnit position]];
	}
	
}


- (BOOL) work{
	
	MPLocation *nextStep = nil;
	
	// if !unit.isValid
	if (![followUnit isValid]) {
		state = FollowStateLastKnownPosition;
	}
		
	
	
	switch (state) {
			
			
		default:
		case FollowStateInRange:
			
			if ([targetRoute count] == 0) {
				[targetRoute addObject:[followUnit position]];
			}
			
			// if (shouldmove) 
			if ([self myDistanceToUnit:followUnit] > maxDistance) {
				
				nextStep = (MPLocation *) [targetRoute objectAtIndex:0];
				// move to
				[mover moveTowards:nextStep  within:1.0f facing:nextStep];
				
				// state == approaching
				state = FollowStateApproaching;
				
			} else {
				
				[mover faceLocation: (MPLocation *)[followUnit position]];
			}// end if
			break;
		
			
			
		case FollowStateApproaching:
			
			// if !shouldMove to Unit
			if ([self myDistanceToUnit:followUnit] <= approachTo) {
				// stop move
				[mover stopAllMovement];
				
				// state == InRange
				state = FollowStateInRange;
				
				return NO;
			} // end if
			
			
			[self removeClosePositions];
			
			
			if ([targetRoute count] == 0) {
				[targetRoute addObject:[followUnit position]];
			}
			
			
			// do move
			nextStep = (MPLocation *)[targetRoute objectAtIndex:0];
			[mover moveTowards:nextStep within:1.0f facing:nextStep];
			break;
			
			
			
		case FollowStateLastKnownPosition:
			
			
			if ([followUnit isValid]) {
				
				state = FollowStateInRange;
				return [self work];
			}
			
			
			[self removeClosePositions];
			
			nextStep = nil;
			if ([targetRoute count] > 0) {
				nextStep = (MPLocation *) [targetRoute objectAtIndex:0];
			} else {
				nextStep = (MPLocation *) lastPosition;
			}

			// just move to their last known position
			[mover moveTowards:nextStep within:1.0f facing:nextStep];
			break;

	}
	
	
	if ([followUnit isValid]) {
		
		// if lastHeading != unit.heading
		if (lastHeading != [followUnit directionFacing]) {
			
			// if (distance from last added spot > XX)
			Position *lastRoutePosition = [targetRoute lastObject];
			float distanceFromLastPosition = [lastRoutePosition distanceToPosition:[followUnit position]];
			if (distanceFromLastPosition > 2.25f) {
				
				
				// targetRoute[] = [unit position]
				[targetRoute addObject:[followUnit position]];
				
				// lastHeading = unit.heading
				lastHeading = [followUnit directionFacing];
				
			}// end if
		}// end if
		
		
		if ([self myDistanceToUnit:followUnit] <= 2.25f) {
			
			// we are close enough to clear our route and start over
			[targetRoute removeAllObjects];
		}
		
		// just keep track of the last known position of the followUnit
		self.lastPosition = [followUnit position];
	}
	
	return NO;
}

- (void) stop{
	
	[mover stopAllMovement];
}


- (NSString *) description {
	NSMutableString *text = [NSMutableString stringWithFormat: @" activity[%@] \n   targetRoute[%d]", name, [targetRoute count]];
	if ([targetRoute count] > 0) {
		[text appendFormat:@"\n  <%@>", [targetRoute objectAtIndex:0]];
	}
	return text; 
}

#pragma mark -
#pragma mark Helper Methods


- (float) myDistanceToUnit:(Unit *)unit {
	return [self myDistanceToPosition: [unit position]];
}



- (float) myDistanceToPosition:(Position *)position {
	
	Position *playerPosition = [[PlayerDataController sharedController] position];
	return [playerPosition distanceToPosition: position];
}



- (void) removeClosePositions {
	
	// while (!shouldMOve to nextSpot) && (count targetRoute > 0)
	while (([targetRoute count] > 0) && ([self myDistanceToPosition:[targetRoute objectAtIndex:0]] <= 1.0f)) {
		[targetRoute removeObjectAtIndex:0];
	}

	
}


#pragma mark -

+ (id) follow:(Unit *) unit howClose:(float)howClose howFar:(float) howFar forTask:(MPTask *) task {
	
	return [[[MPActivityFollow alloc] initWithUnit:unit approachTo:howClose maxDistance:howFar andTask:task] autorelease];
}

@end
