//
//  MPOperationSubtract.m
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationSubtract.h"
#import "MPValue.h"


@implementation MPOperationSubtract


- (NSInteger) value {
	
	return ((NSInteger) [left value]) - ((NSInteger) [right value]);
}



+ (MPOperationSubtract *) operation {
	
	MPOperationSubtract *newValue =  [[[MPOperationSubtract alloc] init] autorelease];
	return newValue;
}
@end
