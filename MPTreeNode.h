//
//  MPTreeNode.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MPTreeNode : NSObject {

	MPTreeNode *left, *right, *parent;
	NSInteger balance, depth, leftDepth, rightDepth;
	float value;
	id content;
}
@property (readwrite, retain) MPTreeNode *left, *right, *parent;
@property (readwrite) NSInteger balance, depth;
@property (readwrite) float value;
@property (retain) id content;



- (void) addNode: (MPTreeNode *)node forValue: (float) nodeValue;
- (MPTreeNode *)  nodeForValue: (float) searchValue;

- (void) refreshDepthAndBalance;
- (void) refreshToRoot;

- (BOOL) isEqual: (float) givenValue;
- (BOOL) isGreaterThan: (float) givenValue;
- (BOOL) isLessThan: (float) givenValue;

- (MPTreeNode *) largestNode;
- (MPTreeNode *) smallestNode;

- (void) debug: (NSString *)spacerString;

+ (id) nodeWithObject: (id) object forValue: (float) objectValue;


@end
