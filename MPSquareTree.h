//
//  MPSquareTree.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPAVLRangedTree;
@class MPSquare;
@class MPLocation;

@interface MPSquareTree : NSObject {
	MPAVLRangedTree *xSlices;
	float zTolerance, baseSquareWidth;
	int count;
	NSMutableArray *listSquares;
	NSLock *lock;
}
@property (retain) MPAVLRangedTree *xSlices;
@property (readonly) int count;
@property (retain) NSMutableArray *listSquares;
@property (readwrite) float baseSquareWidth, zTolerance;
@property (retain) NSLock *lock;

- (void) addSquare: (MPSquare *)aSquare;
- (MPSquare *) squareAtX: (float) xPos Y: (float) yPos Z:(float)zPos;
- (MPSquare *) squareAtLocation: (MPLocation *) aLocation;
- (void) removeSquare: (MPSquare *)aSquare;
- (void) removeSquareAtX:(float)xPos Y:(float)yPos Z:(float)zPos;



- (float) lowerBoundFromValue:(float) value;
- (float) upperBoundFromValue:(float) value;


#pragma mark -

+ (id) tree ;
+ (id) treeWithSquareWidth: (float) width ZTolerance: (float) tolerance;

@end
