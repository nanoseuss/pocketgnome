//
//  MPSquare.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPSquare.h"
#import "MPPoint.h"
#import "MPLocation.h"
#import "Position.h"
#import "MPLine.h"

@implementation MPSquare
@synthesize points, 
			topBorderConnections, 
			leftBorderConnections, 
			bottomBorderConnections, 
			rightBorderConnections,
			myDrawRect,
			isTraversible, 
			onPath,
			costAdjustment,
			zPos, 
			width, height;




-(id) init {
	
	if ((self = [super init])) {
		self.points = nil;
		self.topBorderConnections = [NSMutableArray array];
		self.leftBorderConnections = [NSMutableArray array];
		self.bottomBorderConnections = [NSMutableArray array];
		self.rightBorderConnections = [NSMutableArray array];
		self.myDrawRect = nil;
		
		costAdjustment = 1.0f;
		isTraversible = NO;
		onPath = NO;
		
		zPos = 0;
		width = 0;
		height = 0;
		
	}
	return self;
}



- (void) dealloc
{
    [points autorelease];
    [topBorderConnections autorelease];
	[leftBorderConnections autorelease];
	[rightBorderConnections autorelease];
	[bottomBorderConnections autorelease];
	[myDrawRect autorelease];
	
    [super dealloc];
}

#pragma mark -


- (NSArray *) points {
	return points;
}

- (BOOL) containsLocation: (MPLocation *)aLocation {
	
	float x0, x3, y0, y1;
	
	x0 = [[(MPPoint *)[points objectAtIndex:0] location] xPosition];
	x3 = [[(MPPoint *)[points objectAtIndex:3] location] xPosition];
	y0 = [[(MPPoint *)[points objectAtIndex:0] location] yPosition];
	y1 = [[(MPPoint *)[points objectAtIndex:1] location] yPosition];
	
	float locX, locY;
	locX = [aLocation xPosition];
	locY = [aLocation yPosition];
	
	if ((locX >= x0) && (locX <= x3) && (locY >= y1) && (locY <= y0)) {
		return YES;
	}

	return NO;
}


- (MPSquare *) adjacentSquareContainingLocation: (MPLocation*)aLocation {
	
	// check top connections:
	for( MPSquare* square in topBorderConnections) {
		if ([square containsLocation:aLocation]) {
			return square;	
		}
	}
	
	// check Left connections:
	for( MPSquare* square in leftBorderConnections) {
		if ([square containsLocation:aLocation]) {
			return square;	
		}
	}
	
	// check bottom connections:
	for( MPSquare* square in bottomBorderConnections) {
		if ([square containsLocation:aLocation]) {
			return square;	
		}
	}
	
	// check right connections:
	for( MPSquare* square in rightBorderConnections) {
		if ([square containsLocation:aLocation]) {
			return square;	
		}
	}
	
	// not found
	return nil;
}


- (MPPoint *) pointAtPosition: (int) position {

	MPPoint *point = nil;
	
	if ( position < [points count]) {
		point = [points objectAtIndex:position];
	}
	return point;
}


- (void) addTopBorderConnection: (MPSquare *) square {

	NSArray *copyConnections = [topBorderConnections copy];
	if (![copyConnections containsObject:square]) {
		[topBorderConnections addObject:square];
	}
}

- (void) addLeftBorderConnection: (MPSquare *) square {

	NSArray *copyConnections = [leftBorderConnections copy];
	if (![copyConnections containsObject:square]) {
		[leftBorderConnections addObject:square];
	}
}

- (void) addRightBorderConnection: (MPSquare *) square {

	NSArray *copyConnections = [rightBorderConnections copy];
	if (![copyConnections containsObject:square]) {
		[rightBorderConnections addObject:square];
	}
}

- (void) addBottomBorderConnection: (MPSquare *) square {

	NSArray *copyConnections = [bottomBorderConnections copy];
	if (![copyConnections containsObject:square]) {
		[bottomBorderConnections addObject:square];
	}
}


- (MPLocation *) locationOfIntersectionWithSquare: (MPSquare *) aSquare {
	
	MPLocation *location = nil;
	
	if ([topBorderConnections containsObject:aSquare]) {
		
		location = [self topEdgeMidPointWithSquare: (MPSquare *)aSquare];
			
	} else if ([leftBorderConnections containsObject:aSquare]) {
		
		location = [self leftEdgeMidPointWithSquare: (MPSquare *)aSquare];
			
	} else if ([bottomBorderConnections containsObject:aSquare]) {

		location = [self bottomEdgeMidPointWithSquare: (MPSquare *)aSquare];
		
	} else if ([rightBorderConnections containsObject:aSquare]) {
			
		location = [self rightEdgeMidPointWithSquare: (MPSquare *)aSquare];
		
	}
	
	return location;
}


- (MPLocation *) topEdgeMidPointWithSquare: (MPSquare *)aSquare {

	MPLocation *point0 = [(MPPoint *)[points objectAtIndex:0] location];
	
	NSArray *sqPoints = [aSquare points];
	float myP0X, myP3X, sqP1X, sqP2X;
	
	// get X positions of my top edge : Point0, Point3
	myP0X = [[(MPPoint *)[points objectAtIndex:0] location] xPosition];
	myP3X = [[(MPPoint *)[points objectAtIndex:3] location] xPosition];
	
	// get X positions of aSquare's bottom edge: Point1 & Point2
	sqP1X = [[(MPPoint *)[sqPoints objectAtIndex:1] location] xPosition];
	sqP2X = [[(MPPoint *)[sqPoints objectAtIndex:2] location] xPosition];
	
	
	// decide on which X positions make up the edge
	float x0,x3, xMid;
	x0 = (myP0X > sqP1X)? myP0X: sqP1X;  // max(myP0X, sqP1X);
	x3 = (myP3X < sqP2X)? myP3X: sqP2X;  // min(myP3X, sqP2X);
	
	
	// get mid point of the edge
	xMid = x0 + ((x3 - x0)/2);
	
	return [MPLocation locationAtX:xMid Y:[point0 yPosition] Z:[point0 zPosition]];
}



- (MPLocation *) bottomEdgeMidPointWithSquare: (MPSquare *)aSquare {
	
	MPLocation *point0 = [(MPPoint *)[points objectAtIndex:0] location];
	
	NSArray *sqPoints = [aSquare points];
	float sqP0X, sqP3X, myP1X, myP2X;
	
	// get X positions of aSquare's top edge : Point0, Point3
	sqP0X = [[(MPPoint *)[sqPoints objectAtIndex:0] location] xPosition];
	sqP3X = [[(MPPoint *)[sqPoints objectAtIndex:3] location] xPosition];
	
	// get X positions of my bottom edge: Point1 & Point2
	myP1X = [[(MPPoint *)[points objectAtIndex:1] location] xPosition];
	myP2X = [[(MPPoint *)[points objectAtIndex:2] location] xPosition];
	
	
	// decide on which X positions make up the edge
	float x0,x3, xMid;
	x0 = (sqP0X > myP1X)? sqP0X: myP1X;  // max(sqP0X, myP1X);
	x3 = (sqP3X < myP2X)? sqP3X: myP2X;  // min(sqP3X, myP2X);
	
	
	// get mid point of the edge
	xMid = x0 + ((x3 - x0)/2);
	
	return [MPLocation locationAtX:xMid Y:[point0 yPosition] Z:[point0 zPosition]];
	
}



- (MPLocation *) leftEdgeMidPointWithSquare: (MPSquare *)aSquare {
	
	MPLocation *point1 = [(MPPoint *)[points objectAtIndex:1] location];
	
	NSArray *sqPoints = [aSquare points];
	
	float myP0Y, myP1Y, sqP3Y, sqP2Y;
	
	// get the y positions on my left edge
	myP0Y = [[(MPPoint *)[points objectAtIndex:0] location] yPosition];
	myP1Y = [[(MPPoint *)[points objectAtIndex:1] location] yPosition];
	
	// get the y positions of aSquare's  Right edge
	sqP3Y = [[(MPPoint *)[sqPoints objectAtIndex:3] location] yPosition];
	sqP2Y = [[(MPPoint *)[sqPoints objectAtIndex:2] location] yPosition];
	
	
	float y0,y1, yMid;
	y0 = (myP0Y < sqP3Y)? myP0Y: sqP3Y;  // upper Y is min of myP0Y & sqP3Y
	y1 = (myP1Y > sqP2Y)? myP1Y: sqP2Y;  // lower Y is max of myP1Y & sqP2Y
	
	yMid = y1 + ((y0 - y1)/2); // mid point 
	
	return [MPLocation locationAtX:[point1 xPosition] Y:yMid Z:[point1 zPosition]];
}




- (MPLocation *) rightEdgeMidPointWithSquare: (MPSquare *)aSquare {
	
	MPLocation *point1 = [(MPPoint *)[points objectAtIndex:1] location];
	
	NSArray *sqPoints = [aSquare points];
	
	float myP3Y, myP2Y, sqP0Y, sqP1Y;
	
	// get the y positions on my left edge
	myP3Y = [[(MPPoint *)[points objectAtIndex:3] location] yPosition];
	myP2Y = [[(MPPoint *)[points objectAtIndex:2] location] yPosition];
	
	// get the y positions of aSquare's  Right edge
	sqP0Y = [[(MPPoint *)[sqPoints objectAtIndex:0] location] yPosition];
	sqP1Y = [[(MPPoint *)[sqPoints objectAtIndex:1] location] yPosition];
	
	
	float y0,y1, yMid;
	y0 = (myP3Y < sqP0Y)? myP3Y: sqP0Y;  // upper Y is min of myP3Y & sqP0Y
	y1 = (myP2Y > sqP1Y)? myP2Y: sqP1Y;  // lower Y is max of myP2Y & sqP1Y
	
	yMid = y1 + ((y0 - y1)/2); // mid point 
	
	return [MPLocation locationAtX:[point1 xPosition] Y:yMid Z:[point1 zPosition]];
}


- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation {
	MPLine *thisLine = [MPLine lineStartingAt:startLocation endingAt:endLocation];
	return [self hasClearPathFrom:startLocation to:endLocation usingLine:thisLine ];
}


- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation usingLine:(MPLine *) aLine {
	
	if ([self containsLocation:endLocation]) {
		return YES;
	}
	

	float selectedDist = INFINITY;
	float currentDist = 0;
	int selectedIndex = -1;
	MPLocation *selectedLocation = nil;
	
	int index, nextIndx;
	for (index = 0; index <= 3; index ++ ) {
		
		nextIndx = index +1;
		if (nextIndx > 3) nextIndx = 0;
		
		MPLocation *loc0 = [(MPPoint *)[points objectAtIndex:index] location];
		MPLocation *loc1 = [(MPPoint *)[points objectAtIndex:nextIndx] location];
		
		MPLine *currLine = [MPLine lineStartingAt:loc0 endingAt:loc1];
		MPLocation *currentLocation = [aLine locationOfIntersectionWithLine:currLine];
		
		if (currentLocation != nil) {
		
			currentDist = [currentLocation distanceToPosition:endLocation];
			if (currentDist < selectedDist) {
				selectedDist = currentDist;
				selectedIndex = index;
				selectedLocation = currentLocation;
			}
			
		}
	}
	
	if ( selectedIndex != -1 ) {
		
		NSArray *exitBorderSquares = nil;
		
		switch (selectedIndex) {
			case 0:
				// left Side
				exitBorderSquares = leftBorderConnections;
				break;
			case 1:
				// bottom
				exitBorderSquares = bottomBorderConnections;
				break;
			case 2:
				// right side
				exitBorderSquares = rightBorderConnections;
				break;
			case 3:
				// top 
				exitBorderSquares = topBorderConnections;
				break;
			default:
				break;
		}
		
		for( MPSquare *square in exitBorderSquares) {
			
			if ([square isTraversible]) {
				if ([square containsLocation:selectedLocation]) {
				
					return [square hasClearPathFrom:startLocation to:endLocation usingLine:aLine];
				}
			}
		}
		
	}
	
	
	
	return NO;
	
}

#pragma mark -
#pragma mark NavMeshView Display Routines


- (NSRect) nsrect {

	float x1, x2, y1, y0;
	
	x1 = [[(MPPoint *)[points objectAtIndex:1] location] xPosition];
	x2 = [[(MPPoint *)[points objectAtIndex:2] location] xPosition];
	y1 = [[(MPPoint *)[points objectAtIndex:1] location] yPosition];
	y0 = [[(MPPoint *)[points objectAtIndex:0] location] yPosition];
	
	return NSMakeRect( x1, y1, x2 - x1, y0 - y1);
}

- (void) display {
	
	
	if (myDrawRect == nil) {
		PGLog(@"Calculating Draw Rect ... ");
		
		NSRect newRect = [self nsrect];
		self.myDrawRect = [NSBezierPath bezierPathWithRect: newRect];
	}
	
	[myDrawRect setLineWidth: 0.02f];  // or just use 0.02
	[[NSColor grayColor] set];
	[myDrawRect stroke];
	
	if (onPath) {
		[[NSColor redColor] set];
	} else if ( !isTraversible) {
		[[NSColor blackColor] set];
	} else if (costAdjustment > 0.0) {
		[[NSColor yellowColor] set];
	} else if (costAdjustment < 0.0) {
		[[NSColor grayColor] set];
	} else {
		[[NSColor whiteColor] set];
	}
	[myDrawRect fill];
	
	
}




- (void) connectToAdjacentSquaresByPointReferences {
	
	// if [point0 squareWhereImPoint1] != nil then
	MPSquare *square;
	square = [(MPPoint *)[points objectAtIndex:0] squareWherePointIsInPosition:1];
	if (square != nil) {
		// assign this square to top border
		[topBorderConnections addObject:square];
		[square addBottomBorderConnection:self];
	}
	
	// if [point0 squareWhereImPoint3] != nil then
	square = [(MPPoint *)[points objectAtIndex:0] squareWherePointIsInPosition:3];
	if (square != nil) {
		// assign this square to left border
		[leftBorderConnections addObject:square];
		[square addRightBorderConnection:self];
	}
	
	// if [point1 squareWhereImPoint0] != nil then
	square = [(MPPoint *)[points objectAtIndex:1] squareWherePointIsInPosition:0];
	if (square != nil) {
		// assign this square to bottom border
		[bottomBorderConnections addObject:square];
		[square addTopBorderConnection:self];
	}
	
	// if [point3 squareWhereImPoint0] != nil then
	square = [(MPPoint *)[points objectAtIndex:3] squareWherePointIsInPosition:0];
	if (square != nil) {
		// assign this square to right border
		[rightBorderConnections addObject:square];
		[square addLeftBorderConnection:self];
	}

}



- (void) compileAdjacentSquaresThatIntersectRect: (NSRect) viewRect  intoList: (NSMutableArray *)listSquares {


		// check top connections:
	for( MPSquare* square in topBorderConnections) {
		if (NSIntersectsRect(viewRect, [square nsrect])) {
			[listSquares addObject:square];
			[square compileAdjacentSquaresThatIntersectRect:viewRect  intoList:listSquares];	
		}
	}
	
	// check Left connections:
	for( MPSquare* square in leftBorderConnections) {
		if (NSIntersectsRect(viewRect, [square nsrect])) {
			[listSquares addObject:square];
			[square compileAdjacentSquaresThatIntersectRect:viewRect  intoList:listSquares];	
		}
	}
	
	// check bottom connections:
	for( MPSquare* square in bottomBorderConnections) {
		if (NSIntersectsRect(viewRect, [square nsrect])) {
			[listSquares addObject:square];
			[square compileAdjacentSquaresThatIntersectRect:viewRect  intoList:listSquares];	
		}
	}
	
	// check right connections:
	for( MPSquare* square in rightBorderConnections) {
		if (NSIntersectsRect(viewRect, [square nsrect])) {
			[listSquares addObject:square];
			[square compileAdjacentSquaresThatIntersectRect:viewRect  intoList:listSquares];	
		}
	}

}




- (NSMutableArray *) adjacentSquares {
	
	NSMutableArray *listSquares = [NSMutableArray array];
	
	//// Note:
	//// converting MPQ Data to Squares method:
	////	- read in area chunk
	////	- assume all area is traversible & create squares for that area (all traversible)
	////	- for each triangle that is intraversible:
	////		- start at point 1 of triangle & find square -> mark intraversible
	////		- follow line from point 1 -> point 2 and mark all squares crossed intraversible
	////		- follow line from point 2 -> point 3 and mark all squares crossed intraversilbe
	////		- follow line from point 3 -> point 1 and ...
	////		- then find any squares fully contained in triangle and mark intraversible
	////	- next
	
	
	
	
	// check top connections:
	//// TO DO: check to see if topBorderConnections is null, 
	////		if null -> call routine to read MPQ files and fill out area to the TOP
	////		(this way you only fill in the navmesh with squares as is needed)
	for( MPSquare* square in topBorderConnections) {
		[listSquares addObject:square];
	}
	
	// check Left connections:
	//// TO DO: check to see if leftBorderConnections is null, 
	////		if null -> call routine to read MPQ files and fill out area to the TOP
	for( MPSquare* square in leftBorderConnections) {
		[listSquares addObject:square];
	}
	
	// check bottom connections:
	//// TO DO: check to see if bottomBorderConnections is null, 
	////		if null -> call routine to read MPQ files and fill out area to the TOP
	for( MPSquare* square in bottomBorderConnections) {
		[listSquares addObject:square];
	}
	
	// check right connections:
	//// TO DO: check to see if rightBorderConnections is null, 
	////		if null -> call routine to read MPQ files and fill out area to the TOP
	for( MPSquare* square in rightBorderConnections) {
		[listSquares addObject:square];
	}
	
	return listSquares;
	
}


- (NSString *) describe {
	
	NSMutableString *description = [NSMutableString stringWithString:@"square ["];
	
	int indx=0;
	MPPoint *currentPoint;
	for( indx=0; indx < [points count]; indx++ ) {
		currentPoint = [points objectAtIndex:indx];
		[description appendString:[currentPoint describe]];
	}
	[description appendFormat:@" zPos:%0.2f ]", self.zPos];
	return description;
}

#pragma mark -
#pragma mark Convienience Constructors

+ (id) squareWithPoints:(NSArray *) points {
	
	MPSquare *newObject = [[MPSquare alloc] init];
	newObject.points = points;
	
	//// update points contained in
	for (MPPoint* point in points) {
		[point containedInSquare: newObject];
	}
	
	// calculate the squares zPos for zTolerance checking.
	// (for now just take zPos of point0, but should find zMin and zMax then zPos = zMin + ((zMax-zMin)/2);
	newObject.zPos = [[(MPPoint*)[points objectAtIndex:0] location] zPosition];

	
	//// find adjoining squares based on given points
	[newObject connectToAdjacentSquaresByPointReferences];
		
	
	//// store the square's width 
	float x0, x3;
	x0 = [[(MPPoint *)[points objectAtIndex:0] location] xPosition];
	x3 = [[(MPPoint *)[points objectAtIndex:3] location] xPosition];
	newObject.width = x3 - x0;
	
	//// store the square's height 
	float y0, y1;
	y0 = [[(MPPoint *)[points objectAtIndex:0] location] yPosition];
	y1 = [[(MPPoint *)[points objectAtIndex:1] location] yPosition];
	newObject.height = y0 - y1;
		
	PGLog( @"new Square at location %@", [newObject describe]);
	return newObject;
}

@end
