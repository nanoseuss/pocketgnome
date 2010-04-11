//
//  MPLocation.m
//  TaskParser
//
//  Created by codingMonkey on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPLocation.h"
#import "Position.h"
#import "Mob.h"

@implementation MPLocation


// return a location distance away from current position (in direction of heading)
- (MPLocation *) locationAtHeading: (float) heading andDistance:(float) distance {

	// hoping that heading is in radians
	// if in degrees then cos( (heading*pi)/180 )
	float newX = self.xPosition + (float) cos(heading)*distance;
	float newY = self.yPosition + (float) sin(heading)*distance;
	float newZ = self.zPosition; 
	
	return [[[MPLocation alloc] initWithX:newX Y:newY Z:newZ] autorelease];
}


#pragma mark -

+ (id) locationAtX: (float)xLoc Y: (float)yLoc Z:(float)zLoc {
	return [[[MPLocation alloc] initWithX:xLoc Y:yLoc Z:zLoc] autorelease];
}

+ (id) locationFromVariableData: (NSArray *)locationData{

	float xLoc = [(NSString *)[locationData objectAtIndex:0] floatValue];
	float yLoc = [(NSString *)[locationData objectAtIndex:1] floatValue];
	float zLoc = [(NSString *)[locationData objectAtIndex:2] floatValue];
	MPLocation *newLocation = [[[MPLocation alloc] initWithX:xLoc Y:yLoc Z:zLoc] autorelease];

	return [newLocation retain];
}

+ (id) locationFromPosition: (Position *) position {
	return [MPLocation locationAtX:[position xPosition] Y:[position yPosition] Z:[position zPosition]];
}

+ (id) locationInFrontOfTarget:(Mob *)mob atDistance:(float) distance {
	MPLocation *location = [MPLocation locationFromPosition:[mob position]];
	
	return [location locationAtHeading:[mob directionFacing] andDistance:distance];
}

+ (id) locationBehindTarget:(Mob *)mob atDistance:(float) distance {
	MPLocation *location = [MPLocation locationFromPosition:[mob position]];
	
	return [location locationAtHeading:([mob directionFacing] + M_PI) andDistance:distance];
}

@end
