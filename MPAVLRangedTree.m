//
//  MPAVLRangedTree.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPAVLRangedTree.h"
#import "MPAVLTree.h"
#import "MPRangedTreeNode.h"

@implementation MPAVLRangedTree



- (void) addObject: (id) object forRange: (NSRange) range {
	
	[self addObject:object withMinValue:range.location maxValue:(range.location + range.length)];
	
}

- (void) addObject:(id) object withMinValue:(float)aMinValue maxValue:(float)aMaxValue {
	
	MPRangedTreeNode *objectNode = [MPRangedTreeNode nodeWithObject:object withMinVal:aMinValue MaxVal:aMaxValue];
	
	if (root == nil) {
		self.root = objectNode;
	} else {
		// assume "value" is midpoint of range.
		float value = aMinValue + ((aMaxValue - aMinValue) /2);
		[root addNode:objectNode forValue:value];
		[self balanceTreeStartingAtNode:objectNode];
	}
	
}







#pragma mark -
#pragma mark Convienience Methods

+ (id) tree {
	return [[[MPAVLRangedTree alloc] init] autorelease];
}

@end
