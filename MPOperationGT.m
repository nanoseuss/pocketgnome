//
//  MPOperationGT.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationGT.h"
#import "MPValue.h"

@implementation MPOperationGT



- (BOOL) value {
	
	return ((NSInteger) [left value]) > ((NSInteger) [right value]);
}



+ (MPOperationGT *) operation {
	
	MPOperationGT *newOperation =  [[[MPOperationGT alloc] init] autorelease];
	return newOperation;
}

@end
