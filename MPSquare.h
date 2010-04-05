//
//  MPSquare.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPLocation;
@class MPPoint;
@class MPLine;

@interface MPSquare : NSObject {

	
	NSArray *points;
	NSMutableArray *topBorderConnections, *leftBorderConnections, 
			*bottomBorderConnections, *rightBorderConnections;
	
	NSBezierPath *myDrawRect;
	
	//	double  costG, costH, cost;
	float costAdjustment;
	BOOL isTraversible,onPath;
	
	float zPos;
	
	float width, height;
	
}
@property (retain) NSArray *points;
@property (retain) NSArray *topBorderConnections, *leftBorderConnections, 
*bottomBorderConnections, *rightBorderConnections;
@property (retain) NSBezierPath *myDrawRect;
@property (readwrite) BOOL isTraversible, onPath;
@property (readwrite) float zPos;
@property (readwrite) float costAdjustment;
@property (readwrite) float width, height;


- (BOOL) containsLocation: (MPLocation *)aLocation;
- (MPSquare *) adjacentSquareContainingLocation: (MPLocation*)aLocation;
- (NSMutableArray *) adjacentSquares;
- (MPPoint *) pointAtPosition: (int) position;

- (NSArray *) points;

- (void) addTopBorderConnection: (MPSquare *) square;
- (void) addLeftBorderConnection: (MPSquare *) square;
- (void) addRightBorderConnection: (MPSquare *) square;
- (void) addBottomBorderConnection: (MPSquare *) square;


- (MPLocation *) topEdgeMidPointWithSquare: (MPSquare *)aSquare;
- (MPLocation *) bottomEdgeMidPointWithSquare: (MPSquare *)aSquare;
- (MPLocation *) leftEdgeMidPointWithSquare: (MPSquare *)aSquare;
- (MPLocation *) rightEdgeMidPointWithSquare: (MPSquare *)aSquare;
- (MPLocation *) locationOfIntersectionWithSquare: (MPSquare *) aSquare;
- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation;
- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation usingLine:(MPLine *) aLine;


/*!
 * @function nsrect
 * @abstract Returns an NSRect that represents the area of this Square.
 * @discussion
 */
- (NSRect) nsrect;
- (void)  display;
- (NSString *) describe;

- (void) connectToAdjacentSquaresByPointReferences;  // internal?

- (void) compileAdjacentSquaresThatIntersectRect: (NSRect) viewRect  intoList: (NSMutableArray *)listSquares;

#pragma mark -
#pragma mark Convienience Constructors

+ (id) squareWithPoints:(NSArray *) points;

@end
