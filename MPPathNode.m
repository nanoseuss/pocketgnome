//
//  MPPathNode.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPPathNode.h"
#import "MPPoint.h"
#import "MPLocation.h"
#import "Position.h"
#import "MPSquare.h"

@implementation MPPathNode
@synthesize parent,costG, costH, square, referencePoint;

-(id) init {
	
	if ((self = [super init])) {
		self.parent = nil;
		costG = 0;
		costH = 0;
		self.square = nil;
		self.referencePoint = nil;
	}
	return self;
}



- (void) dealloc
{
    [parent autorelease];
	[square autorelease];
	[referencePoint autorelease];
    
    [super dealloc];
}

#pragma mark -


- (void) setReferencePointTowardsLocation: (MPLocation *) aLocation {
	
	NSArray *pointList = [square points];
	float selectedDistance = INFINITY;
	float distance;
	MPPoint *selectedPoint = nil;
	
	for( MPPoint *point in pointList) {
		
		MPLocation *location = [point location];
		distance = [location distanceToPosition:aLocation];
		if (distance < selectedDistance ) {
			selectedDistance = distance;
			selectedPoint = point;
		}
		
	}
	
	self.referencePoint = selectedPoint;
}



- (int) cost 
{
	return  ((int)(costG + costH) * [square costAdjustment]);
}


#pragma mark -

+(id)node
{
	return [[[MPPathNode alloc] init] autorelease];
}


+(id)nodeWithSquare: (MPSquare *)aSquare
{
	MPPathNode *newNode = [MPPathNode node];
	[newNode setSquare:aSquare];
	return newNode;
}

@end
