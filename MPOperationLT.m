//
//  MPOperationLT.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationLT.h"
#import "MPValue.h"

@implementation MPOperationLT




- (BOOL) value {
	
	return ((NSInteger) [left value]) < ((NSInteger) [right value]);
}



+ (MPOperationLT *) operation {
	
	MPOperationLT *newOperation =  [[[MPOperationLT alloc] init] autorelease];
	return newOperation;
}

@end
