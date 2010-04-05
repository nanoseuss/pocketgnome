//
//  TestActivity.m
//  TaskParser
//
//  Created by admin on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TestActivity.h"
#import "MPActivity.h"
#import "MPTimer.h"
#import "MPTask.h"
#import "PatherController.h"


@implementation TestActivity

@synthesize timerWaitTime;

- (id) init {
	return [self initWithTask:nil];
}

- (id) initWithTask:(MPTask*)aTask {
	
	if ((self = [super initWithName:@"Test Task" andTask:aTask])) {
		self.timerWaitTime =  [MPTimer randomTimerFrom:20 To:80];
	}
	return self;
}


- (void) dealloc
{
    [timerWaitTime release];
    [super dealloc];
}


#pragma mark -


- (void) start {}


- (BOOL) work {
//	[timerWaitTime setDuration:<#(NSInteger)#>];
	
	NSInteger testVal = [[task patherController] getMyLevel];
	PGLog(@" the patherController's test value[%d]", testVal );
	
		
	// otherwise, we exit (but we are not "done"). 
	return NO;
}


- (void) stop{}


#pragma mark -


+ (id) waitIndefinatelyForTask: (MPTask*) aTask {
	
	return [[TestActivity alloc] initWithTask: aTask];
}
@end
