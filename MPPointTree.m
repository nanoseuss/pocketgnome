//
//  MPPointTree.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPPointTree.h"
#import "MPAVLTree.h"
#import "MPAVLRangedTree.h"
#import "MPPoint.h"
#import "MPLocation.h"

@implementation MPPointTree
@synthesize xSlices, zTolerance, count;




- (id) init {
	
	if ((self = [super init])) {
		
		self.xSlices = [MPAVLTree tree];
		zTolerance = 2.8;
		count = 0;
	}
	return self;
}


- (void) dealloc
{
    [xSlices autorelease];
	
    [super dealloc];
}


#pragma mark -


- (void) addPoint:(MPPoint *)aPoint {

	MPLocation *pointLocation = [aPoint location];
	MPAVLTree *xSlice = [xSlices objectForValue:[pointLocation xPosition]];
	NSRange zRange;
	
	if (xSlice != nil) {
		
		MPAVLRangedTree *zSlice = [xSlice objectForValue:[pointLocation yPosition]];
		if (zSlice != nil) {
			
			MPPoint *currPoint = [zSlice objectForValue: [pointLocation zPosition]];
			if (currPoint == nil) {
				
				zRange = [self zRangeFromValue:[pointLocation zPosition]];
				[zSlice addObject: aPoint forRange: zRange];
				count++;
			}
			else {
					// this shouldn't happen... but if it does ...
					// what do we do here?
			}
			
		}
		else {
			
			zRange = [self zRangeFromValue:[pointLocation zPosition]];
			zSlice = [MPAVLRangedTree tree];
			[zSlice addObject: aPoint forRange: zRange];
			[xSlice addObject:zSlice withValue:[pointLocation yPosition]];
			count++;
		}

		
	} else {
		
		zRange = [self zRangeFromValue:[pointLocation zPosition]];
		MPAVLRangedTree *zSlice = [MPAVLRangedTree tree];
		[zSlice addObject: aPoint forRange: zRange];
		
		xSlice = [MPAVLTree tree];
		[xSlice addObject:zSlice withValue:[pointLocation yPosition]];
		[xSlices addObject:xSlice withValue:[pointLocation xPosition]];
		count++;
	}
	
}




- (MPPoint *) pointAtX:(float)xPos Y:(float)yPos Z:(float)zPos {
	
	MPAVLTree *xSlice = [xSlices objectForValue:xPos];
	if (xSlice != nil) {
		MPAVLTree *zSlice = [xSlice objectForValue:yPos];
		if (zSlice != nil) {
			return [zSlice objectForValue:zPos];
		}
	}
	return nil;
}




- (void) removePointAtX:(float)xPos Y:(float)yPos Z:(float)zPos {
	
	MPAVLTree *xSlice = [xSlices objectForValue:xPos];
	if (xSlice != nil) {
		MPAVLTree *zSlice = [xSlice objectForValue:yPos];
		if (zSlice != nil) {
			[zSlice removeObjectWithValue:zPos];
			count--;
			//MPpoint point = [zSlice objectForValue:zPos];
			//if (point != nil) {
			//	[zSlice removeObjectWithValue:zPos];
			//}
		}
	}
}


- (NSRange) zRangeFromValue: (float) zVal {
	
	float lowerZ, upperZ, nextVal;
	nextVal = (zVal >=0)? 1.0f: -1.0f;
	if ( zVal >= 0 ) {
		
		lowerZ = ( (int) (zVal / zTolerance) * zTolerance);
		
	} else {
		upperZ = ( (int) (zVal / zTolerance) * zTolerance);
		lowerZ = upperZ + (nextVal * zTolerance);
	}
	
	return NSMakeRange(lowerZ, zTolerance);
	
}

			 
#pragma mark -
#pragma mark Convienience Methods
			 
+ (id) tree {
	 return [[[MPPointTree alloc] init] autorelease];
 }


+ (id) treeWithZTolerance: (float) tolerance {
	MPPointTree *newTree = [MPPointTree tree];
	[newTree setZTolerance:tolerance];
	return newTree;
}

@end
