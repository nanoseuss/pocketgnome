//
//  MPOperationAdd.m
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPOperationAdd.h"
#import "MPValue.h"

@implementation MPOperationAdd


- (NSInteger) value {
	
	return ((NSInteger) [left value]) + ((NSInteger) [right value]);
}



+ (MPOperationAdd *) operation {
	
	MPOperationAdd *newValue =  [[[MPOperationAdd alloc] init] autorelease];
	return newValue;
}


@end
