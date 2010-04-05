//
//  MPOperation.m
//  TaskParser
//
//  Created by Coding Monkey on 9/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperation.h"


@implementation MPOperation


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


- (NSInteger) value{

	return 0;  // no one should be using this class!!! only sub classes.
}


@end
