//
//  MPOperationMultiply.m
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationMultiply.h"
#import "MPValue.h"


@implementation MPOperationMultiply



- (NSInteger) value {
	
	return ((NSInteger) [left value]) * ((NSInteger) [right value]);
}



+ (MPOperationMultiply *) operation {
	
	MPOperationMultiply *newValue =  [[[MPOperationMultiply alloc] init] autorelease];
	return newValue;
}


@end