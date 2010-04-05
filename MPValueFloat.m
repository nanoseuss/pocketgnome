//
//  MPFloatValue.m
//  TaskParser
//
//  Created by Coding Monkey on 9/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPValueFloat.h"


@implementation MPValueFloat

@synthesize floatValue;

- (id) init {
	if ((self = [super init])) {
		floatValue = 0.0;
	}
	return self;
}


- (float) value {
	
	return floatValue;
}


+ (MPValueFloat *) initWithFloat: (float) data {
	
	MPValueFloat *newValue =  [[[MPValueFloat alloc] init] autorelease];
	[newValue setFloatValue:data ];
	return newValue;
}

+ (MPValueFloat *) initWithString: (NSString *) data {
	
	MPValueFloat *newValue =  [[[MPValueFloat alloc] init] autorelease];
	[newValue setFloatValue:[data doubleValue]];
	return newValue;
}


+ (MPValueFloat *) floatFromString: (NSString *) data {
	return [self initWithString:data];
}

@end
