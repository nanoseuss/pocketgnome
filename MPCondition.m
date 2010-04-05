//
//  MPCondition.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPCondition.h"


@implementation MPCondition
@synthesize left, right;


- (id) init {
	if ((self = [super init])) {
		left = nil;
		right = nil;
	}
	return self;
}

- (void) dealloc
{
    [left release];
    [right release];
    [super dealloc];
}

#pragma mark -

- (BOOL) value{
	
	return NO;  // no one should be using this class!!! only sub classes.
}

@end
