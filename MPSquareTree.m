//
//  MPSquareTree.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPSquareTree.h"
#import "MPAVLRangedTree.h"
#import "MPSquare.h"
#import "MPLocation.h"
#import "Position.h"


@interface MPSquareTree (Internal)

- (void) updateTreeAddingSquare:(MPSquare *)aSquare atX:(float) xPos Y:(float)yPos;
- (void) updateTreeRemovingSquare:(MPSquare *)aSquare atX:(float)xPos Y:(float)yPos;

@end



@implementation MPSquareTree
@synthesize xSlices, count, listSquares, baseSquareWidth, zTolerance, lock;


- (id) init {
	
	if ((self = [super init])) {
		
		self.xSlices = [MPAVLRangedTree tree];
		zTolerance = 2.8;
		baseSquareWidth = 1.5;
		count = 0;
		self.listSquares = [NSMutableArray array];
		self.lock = [[NSLock alloc] init];
		
	}
	return self;
}


- (void) dealloc
{
    [xSlices autorelease];
	[listSquares autorelease];
	
    [super dealloc];
}


#pragma mark -



- (void) addSquare:(MPSquare *)aSquare {
	
	NSRect squareRect = [aSquare nsrect];
	
	float baseX = squareRect.origin.x + (baseSquareWidth /2 );
	float baseY = squareRect.origin.y + (baseSquareWidth /2);
	
	int numXUnits = (int) (squareRect.size.width / baseSquareWidth);
	int numYUnits = (int) (squareRect.size.height / baseSquareWidth);
	
	int xIndx, yIndx;
	float xPos, yPos;
	
	for(xIndx = 0; xIndx < numXUnits; xIndx++) {
		xPos = baseX + (xIndx * baseSquareWidth);
		
		for(yIndx=0; yIndx < numYUnits; yIndx++) {
		
			yPos = baseY + (yIndx * baseSquareWidth);
			[self updateTreeAddingSquare:aSquare atX:xPos Y:yPos];
		}
		
	}
	count++;
	
	// making this thread safe ... ??
	[lock lock];
	[listSquares addObject:aSquare];
	[lock unlock];
}


- (MPSquare *) squareAtX: (float) xPos Y: (float) yPos Z:(float)zPos {
	
	MPAVLRangedTree *xSlice = [xSlices objectForValue:xPos];
	if (xSlice != nil) {
		
		NSMutableArray *squareList = [xSlice objectForValue:yPos];
		
		if (squareList != nil) {
			
			// there might be several squares overlapping in z-coordinates,
			// select the closest one (as long as it is withing the given zTolerance)
			// 
			float selectedZDist = INFINITY;
			MPSquare *selectedSquare = nil;
			
			for(MPSquare* square in squareList) {
			
				float zDist = zPos - [square zPos];
				if (zDist < 0) zDist *= -1;
				if (zDist < zTolerance) {
					if (zDist < selectedZDist) {
						selectedZDist = zDist;
						selectedSquare = square;
					}
				}
			}
			
			return selectedSquare;
		}
		
	}
	return nil;
	
}



// return a square using a MPLocation as a reference
- (MPSquare *) squareAtLocation: (MPLocation *) aLocation {
	return [self squareAtX: [aLocation xPosition] Y:[aLocation yPosition] Z:[aLocation zPosition]];
}



// remove the given square 
- (void) removeSquare: (MPSquare *)aSquare {
	
	//// First we remove any existing references to this square in our tree:
	
	NSRect squareRect = [aSquare nsrect];
	
	float baseX = squareRect.origin.x + (baseSquareWidth /2 );
	float baseY = squareRect.origin.y + (baseSquareWidth /2);
	
	int numXUnits = (int) (squareRect.size.width / baseSquareWidth);
	int numYUnits = (int) (squareRect.size.height / baseSquareWidth);
	
	int xIndx, yIndx;
	float xPos, yPos;
	
	for(xIndx = 0; xIndx < numXUnits; xIndx++) {
		xPos = baseX + (xIndx * baseSquareWidth);
		
		for(yIndx=0; yIndx < numYUnits; yIndx++) {
			
			yPos = baseY + (yIndx * baseSquareWidth);
			[self updateTreeRemovingSquare:aSquare atX:xPos Y:yPos];
		}
		
	}
	
	count--;
	
	[listSquares removeObject:aSquare];
}



- (void) removeSquareAtX:(float)xPos Y:(float)yPos Z:(float)zPos {
	
	MPSquare *squareToRemove = [self squareAtX:xPos Y:yPos Z:zPos];
	if (squareToRemove != nil) {
		[self removeSquare:squareToRemove];
	}
	
}


#pragma mark -

- (void) updateTreeAddingSquare:(MPSquare *)aSquare atX:(float)xPos Y:(float)yPos {
	
	
	MPAVLRangedTree *xSlice = [xSlices objectForValue:xPos];
	NSMutableArray *newYSlice;
	
	if (xSlice != nil) {
		
		NSMutableArray *ySlice = [xSlice objectForValue:yPos];
		
		if (ySlice != nil) {
			// now I have an array with references to Squares (differing by their Z axis)
			
			// do I need to check to see if current square is within zTolerance of any existing square in array?
			
			// if square not already in array -> add square to array
			if (![ySlice containsObject:aSquare]) {
				[ySlice addObject:aSquare];
			}
			
			
		} else {
			//// No Y position found:
			
			// create mutableArray (for squares)
			newYSlice = [NSMutableArray array];
			[newYSlice addObject:aSquare];
			
			// insert into xSlice 
			[xSlice addObject:newYSlice withMinValue:[self lowerBoundFromValue:yPos] maxValue:[self upperBoundFromValue:yPos] ];

		}

		
	} else {
		//// No X position found:
		
		// create mutableArray (for squares) & insert square
		newYSlice = [NSMutableArray array];
		[newYSlice addObject:aSquare];
		
		// create a RangedTree for Y Axis
		MPAVLRangedTree *newXslice = [MPAVLRangedTree tree];
		
		// insert array with proper Y Range
		[newXslice addObject:newYSlice withMinValue:[self lowerBoundFromValue:yPos] maxValue:[self upperBoundFromValue:yPos] ];
		
		// insert RangedTree-Y into xSlices for proper XRange
		[xSlices addObject:newXslice withMinValue:[self lowerBoundFromValue:xPos] maxValue:[self upperBoundFromValue:xPos] ];
		
	}

	
	
}



- (void) updateTreeRemovingSquare:(MPSquare *)aSquare atX:(float)xPos Y:(float)yPos {
	
	
	MPAVLRangedTree *xSlice = [xSlices objectForValue:xPos];	
	if (xSlice != nil) {
		
		NSMutableArray *ySlice = [xSlice objectForValue:yPos];
		
		if (ySlice != nil) {
			
			[ySlice removeObject:aSquare];
			
		} 
	} 
}



#pragma mark -
#pragma mark Utility Methods

- (float) lowerBoundFromValue:(float) value {
	
	float lower, upper;
	
	if (value >= 0) {
		lower = ( (int)(value / baseSquareWidth) * baseSquareWidth);
	} else {
		upper = ( (int)(value / baseSquareWidth) * baseSquareWidth);
		lower = upper - baseSquareWidth;
	}	
	
	return lower;
}


- (float) upperBoundFromValue:(float) value {
	
	float lower, upper;
	
	if (value >= 0) {
		lower = ( (int)(value / baseSquareWidth) * baseSquareWidth);
		upper = lower + baseSquareWidth;
	} else {
		upper = ( (int)(value / baseSquareWidth) * baseSquareWidth);
	}	
	
	return upper;
}



#pragma mark -
#pragma mark Convienience Methods

+ (id) tree {
	return [[[MPSquareTree alloc] init] autorelease];
}


+ (id) treeWithSquareWidth: (float) width ZTolerance: (float) tolerance {
	MPSquareTree *newTree = [MPSquareTree tree];
	[newTree setBaseSquareWidth:width];
	[newTree setZTolerance:tolerance];
	
	return newTree;
}

@end
