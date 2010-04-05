//
//  MPConditionOR.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPConditionOR.h"
#import "MPValueBool.h"

@implementation MPConditionOR


- (BOOL) value {
	
	return ((BOOL) [left value]) || ((BOOL) [right value]);
}



+ (MPConditionOR *) operation {
	
	MPConditionOR *newOperation =  [[[MPConditionOR alloc] init] autorelease];
	return newOperation;
}
@end
