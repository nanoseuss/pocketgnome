//
//  MPOperationAND.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPConditionAND.h"
#import "MPValueBool.h"

@implementation MPConditionAND



- (BOOL) value {
	
	return ((BOOL) [left value]) && ((BOOL) [right value]);
}



+ (MPConditionAND *) operation {
	
	MPConditionAND *newOperation =  [[[MPConditionAND alloc] init] autorelease];
	return newOperation;
}
@end
