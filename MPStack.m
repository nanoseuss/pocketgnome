//
//  MPStack.m
//  TaskParser
//
//  Created by Coding Monkey on 8/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPStack.h"


@implementation NSMutableArray (MPStack)

- (void)push:(id)inObject
{
	if(inObject) [self addObject:inObject];
}

- (id)pop
{
	id theResult = nil;
	if([self count])
	{
		theResult = [[[self lastObject] retain] autorelease];
		[self removeLastObject];
	}
	return theResult;
}

@end
