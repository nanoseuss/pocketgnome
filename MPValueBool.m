//
//  MPBoolValue.m
//  TaskParser
//
//  Created by admin on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPValueBool.h"


@implementation MPValueBool

@synthesize boolValue;

- (id) init {
	if ((self = [super init])) {
		boolValue = NO;
	}
	return self;
}


- (BOOL) value {
	
	return boolValue;
}


+ (MPValueBool *) initWithData: (BOOL) data {

	MPValueBool *newValue = [[[MPValueBool alloc] init] autorelease];
	[newValue setBoolValue:data];
	return newValue;
}

@end
