//
//  MPRangedTreeNode.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPRangedTreeNode.h"


@implementation MPRangedTreeNode
@synthesize range, minValue, maxValue;


- (id) init {
	
	if ((self = [super init])) {
		
		minValue = 0;
		maxValue = 0;
		
	}
	return self;
}


#pragma mark -


- (BOOL) isEqual: (float) givenValue {	
	// Note: ranges are from min to (but not including) max 
	return ((self.minValue <= givenValue) && (givenValue < (self.maxValue)));
}


- (BOOL) isGreaterThan: (float) givenValue {
	return (self.minValue > givenValue);
}


- (BOOL) isLessThan: (float) givenValue {
	return (self.maxValue <= givenValue);
}


#pragma mark -
#pragma mark Convienience Methods

+ (id) nodeWithObject: (id) object forRange:(NSRange)range {
	return [MPRangedTreeNode nodeWithObject:object withMinVal:range.location MaxVal:range.location + range.length ];	
}


+ (id) nodeWithObject: (id) object withMinVal: (float)minVal MaxVal: (float) maxVal {
	MPRangedTreeNode *newNode = [[[MPRangedTreeNode alloc] init] autorelease];
	[newNode setContent:object];
	[newNode setMinValue:minVal];
	[newNode setMaxValue:maxVal];
	
	return newNode;	
}

@end
