//
//  MPOperationGTEQ.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationGTEQ.h"
#import "MPValue.h"


@implementation MPOperationGTEQ


- (BOOL) value {
	
	return ((NSInteger) [left value]) >= ((NSInteger) [right value]);
}



+ (MPOperationGTEQ *) operation {
	
	MPOperationGTEQ *newOperation =  [[[MPOperationGTEQ alloc] init] autorelease];
	return newOperation;
}

@end
