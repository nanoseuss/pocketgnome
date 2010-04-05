//
//  MPOperationEQ.m
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationEQ.h"
#import "MPValue.h"

@implementation MPOperationEQ



- (BOOL) value {
	
	if (([left isString]) || ([right isString])) {
		return ([ (NSString *)[left value] isEqualToString:[right value]]);
	}
	
	return ((NSInteger) [left value]) == ((NSInteger) [right value]);
}



+ (MPOperationEQ *) operation {
	
	MPOperationEQ *newOperation =  [[[MPOperationEQ alloc] init] autorelease];
	return newOperation;
}


@end