//
//  MPPoint.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPPoint.h"
#import "MPLocation.h"
#import "Position.h"
#import "MPSquare.h"


@implementation MPPoint
@synthesize location, squaresContainedIn;


-(id) init {

	return [self initWithLocation:nil];
}

- (id) initWithLocation: (MPLocation *) aLocation {
	
	if ((self = [super init])) {
		self.location = aLocation;
		self.squaresContainedIn = [NSMutableArray array];
	}
	return self;
}



- (void) dealloc
{
    [location autorelease];
    [squaresContainedIn autorelease];
	
    [super dealloc];
}

#pragma mark -


- (void) setX: (float) xPos {
	[location setXPosition:xPos];
}

- (void) setY: (float) yPos {
	[location setYPosition:yPos];
}

- (void) setZ: (float) zPos {
	[location setZPosition:zPos];
}


- (BOOL) isAt: (MPLocation *)aLocation withinZTolerance:(float) zTolerance {

	if (([location xPosition] == [aLocation xPosition]) &&
		([location yPosition] == [aLocation yPosition])) {
		
		if (abs( ([location zPosition] - [aLocation zPosition]) * 100 ) <= (zTolerance *100)) {
			return YES;
		}
	}
	return NO;
}


- (float) zDistanceTo: (MPLocation *)aLocation {
	float distance;
	
	if ([aLocation zPosition] >= [location zPosition]) {
		distance = [aLocation zPosition] - [location zPosition];
	} else {
		distance = [location zPosition] - [aLocation zPosition];
	}

	return distance;
}


- (void) containedInSquare: (MPSquare *) aSquare {

	NSArray *copyPoints = [squaresContainedIn copy]; // prevent Threading problem?
	if (![copyPoints containsObject:aSquare]) {
		[squaresContainedIn addObject:aSquare];
	}
}

- (void) removeContainingSquare: (MPSquare *) aSquare {
	if ([squaresContainedIn containsObject:aSquare]) {
		[squaresContainedIn removeObject:aSquare];
	}
}


- (MPSquare *) squareWherePointIsInPosition: (int) position {
	NSArray *copySquares = [squaresContainedIn copy]; //prevents threading problem
	for (MPSquare *square in copySquares) {
//PGLog( "squareWherePointIsInPosition [ %@ ]", square);
		if ( [[square points] objectAtIndex: position] == self) {
			return square;
		}
	}
	return nil;
}

#pragma mark -
#pragma mark Debug Labels

- (NSString *) describe {
	return [NSMutableString stringWithFormat: @"p(%0.2f, %0.2f, %0.2f) ", [location xPosition], [location yPosition], [location zPosition]];
}

#pragma mark -
#pragma mark Convienience Constructors

+ (MPPoint *) pointAtX: (float)locX Y:(float) locY Z:(float) locZ {
	
	MPLocation *thisLocation = [MPLocation locationAtX:locX Y:locY Z:locZ];
	return [[[MPPoint alloc] initWithLocation:thisLocation] autorelease];
}
@end
