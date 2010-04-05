//
//  MPStringValue.m
//  TaskParser
//
//  Created by codingMonkey on 9/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPValueString.h"


@implementation MPValueString
@synthesize stringValue;

- (id) init {
	if ((self = [super init])) {
		stringValue = nil;
		isString = YES;
	}
	return self;
}

#pragma mark -


- (NSString *) value {

	return stringValue;
}



+ (MPValueString *) stringFromData: (NSString *) data {
	
	// remove any "
	data = [data stringByReplacingOccurrencesOfString:@"\"" withString:@""];
	
	MPValueString *newValue =  [[[MPValueString alloc] init] autorelease];
	[newValue setStringValue: data];
	return newValue;
}

@end
