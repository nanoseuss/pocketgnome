//
//  MPMyClassValue.m
//  TaskParser
//
//  Created by codingMonkey on 9/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPMyClassValue.h"
#import "PatherController.h"

@implementation MPMyClassValue

- (id) initWithPather:(PatherController *)controller {
	if ((self = [super initWithPather:controller])) {
		isString = YES;
	}
	return self;
}



- (NSString *) value {
	
	return [patherController getMyClass]; // until we get this reading from PG
}



+ (MPMyClassValue *) initWithPather:(PatherController*)controller {
	
	return  [[[MPMyClassValue alloc] initWithPather:controller] autorelease];
}
@end
