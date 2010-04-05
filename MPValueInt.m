//
//  MPIntValue.m
//  TaskParser
//
//  Created by Coding Monkey on 9/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPValueInt.h"


@implementation MPValueInt

@synthesize integerValue;

- (id) init {
	if ((self = [super init])) {
		integerValue = 0;
	}
	return self;
}



- (NSInteger) value {

	return integerValue;
}



+ (MPValueInt *) intFromString: (NSString *) data {
	
	MPValueInt *newValue =  [[[MPValueInt alloc] init] autorelease];
	[newValue setIntegerValue: [data integerValue]];
	return newValue;
}


+ (MPValueInt *) intFromData: (NSInteger) data {
	
	MPValueInt *newValue =  [[[MPValueInt alloc] init] autorelease];
	[newValue setIntegerValue: data];
	return newValue;
}
@end
