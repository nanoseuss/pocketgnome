//
//  MPLine.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPLine.h"
#import "MPLocation.h"
#import "Position.h"

@implementation MPLine
@synthesize A, B, C, xMin, xMax, yMin, yMax;

-(id) init {

	return [self initWithA:0 B:0 C:0];
}
	
-(id) initWithA:(float)valA B:(float)valB C:(float)valC {
	
	if ((self = [super init])) {
		A = valA;
		B = valB;
		C = valC;
		xMin = 0;
		xMax = 0;
		yMin = 0;
		yMax = 0;
	}
	return self;
}



- (void) dealloc
{
	
    [super dealloc];
}


#pragma mark  -


- (MPLocation *) locationOfIntersectionWithLine: (MPLine *)line {

	double det = A *[line B] - [line A]*B;
	if (det == 0) {
		return nil;
	} else {
		
		float x = ([line B]*C - B*[line C])/det;
		float y = (A*[line C] - [line A]*C)/det;
		
		MPLocation *intersectionLocation = [MPLocation locationAtX:x Y:y Z:1.0];
		
		if ([self locationWithinBounds: intersectionLocation] &&
			[line locationWithinBounds: intersectionLocation] ) {
			return intersectionLocation;
		}
		
	}
	
	return nil;
	
}


- (BOOL) locationWithinBounds: (MPLocation *) location {
	
	float x = [location xPosition];
	float y = [location yPosition];
	
	if ( (xMin <= x) && (x <= xMax) &&
		(yMin <= y) && (y <= yMax) ) {
		
		return YES;
	}
	
	return NO;
}

#pragma mark -

+ (MPLine *) lineStartingAt: (MPLocation *)startLocation endingAt:(MPLocation *) endingLocation {
	
	float A = [endingLocation yPosition] - [startLocation yPosition];
	float B = [startLocation xPosition] - [endingLocation xPosition];
	float C = A*[startLocation xPosition] + B*[startLocation yPosition];
	
	MPLine *newLine = [[[MPLine alloc] initWithA:A B:B C:C] autorelease];
	float x1 = [startLocation xPosition];
	float x2 = [endingLocation xPosition];
	float y1 = [startLocation yPosition];
	float y2 = [endingLocation yPosition];
	
	[newLine setXMin:(x1<x2)?x1:x2 ];
	[newLine setXMax:(x1<x2)?x2:x1 ];
	[newLine setYMin:(y1<y2)?y1:y2 ];
	[newLine setYMax:(y1<y2)?y2:y1 ];
	
	return newLine;
}

@end
