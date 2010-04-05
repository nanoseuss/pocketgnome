//
//  MPPointTree.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPAVLTree;
@class MPPoint;

@interface MPPointTree : NSObject {
	MPAVLTree *xSlices;
	float zTolerance;
	int count;
}
@property (retain) MPAVLTree *xSlices;
@property (readwrite) float zTolerance;
@property (readonly) int count;

- (void) addPoint: (MPPoint *)aPoint;
- (MPPoint *) pointAtX: (float) xPos Y: (float) yPos Z:(float)zPos;
- (void) removePointAtX:(float)xPos Y:(float)yPos Z:(float)zPos;


- (NSRange) zRangeFromValue: (float) zVal;



#pragma mark -
#pragma mark Convienience Methods

+ (id) tree;
+ (id) treeWithZTolerance: (float) tolerance;

@end
