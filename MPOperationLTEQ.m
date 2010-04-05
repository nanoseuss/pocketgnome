//
//  MPOperationLTEQ.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationLTEQ.h"
#import "MPValue.h"

@implementation MPOperationLTEQ



- (BOOL) value {
	
	return ((NSInteger) [left value]) <= ((NSInteger) [right value]);
}



+ (MPOperationLTEQ *) operation {
	
	MPOperationLTEQ *newOperation =  [[[MPOperationLTEQ alloc] init] autorelease];
	return newOperation;
}
@end
