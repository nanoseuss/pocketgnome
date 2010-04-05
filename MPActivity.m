//
//  MPActivity.m
//  TaskParser
//
//  Created by admin on 9/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivity.h"
#import "MPTask.h"
#import "MPTaskController.h"

@implementation MPActivity

@synthesize name;
@synthesize task;
@synthesize taskController;

- (id) init {
	return [self initWithName:@"MPActivity" andTask:nil];
}

- (id) initWithName:(NSString*)aName andTask:(MPTask*)aTask {

	if ((self = [super init])) {
		self.name = aName;
		self.task = aTask;
		self.taskController = [[aTask patherController] taskController];
	}
	return self;
}


- (void) dealloc
{
    [name autorelease];
    [task autorelease];
	[taskController autorelease];
    [super dealloc];
}

#pragma mark -

- (MPLocation *) location{
	return nil;
}


- (void) start {}


- (BOOL) work{
	return YES;
}


- (void) stop{}

- (NSString *) description {
	return [NSString stringWithFormat:@" activity[%@] \n   unimplemented [describe] ", name];
}

@end
