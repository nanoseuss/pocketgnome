//
//  MPOperationNEQ.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationNEQ.h"


@implementation MPOperationNEQ


- (BOOL) value {
	
	return (![super value]);
}



+ (MPOperationNEQ *) operation {
	
	MPOperationNEQ *newOperation =  [[[MPOperationNEQ alloc] init] autorelease];
	return newOperation;
}
@end
