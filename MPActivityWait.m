//
//  MPActivityWait.m
//  TaskParser
//
//  Created by codingMonkey on 9/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityWait.h"
#import "MPActivity.h"
#import "MPTimer.h"

@implementation MPActivityWait

@synthesize timerWaitTime, timerIdleActivity;

- (id) init {
	return [self initWithTask:nil];
}

- (id) initWithTask:(MPTask*)aTask {

	if ((self = [super initWithName:@"Wait Task" andTask:aTask])) {
		startedWait = NO;
		startedIdle = NO;
		timerWaitTime = nil;
		timerIdleActivity = [MPTimer randomTimerFrom:10000 To:40000];
	}
	return self;
}

- (void) setWaitTime: (NSInteger) timeInMS {

	if (timerWaitTime != nil) {
		[timerWaitTime autorelease];
		timerWaitTime = nil;
	}
	timerWaitTime = [MPTimer timer:timeInMS];
}


- (void) dealloc
{
    [timerWaitTime release];
    [timerIdleActivity release];
    [super dealloc];
}


#pragma mark -


- (void) start {}


- (BOOL) work {
	
	// make sure timer starts once we start getting a [work] request
	if ((timerWaitTime != nil) && (!startedWait)) {
		[timerWaitTime start];
		startedWait = YES;
	}
	
	if (!startedIdle) {
		[timerIdleActivity start];
		startedIdle = YES;
	}
	
	if ([timerIdleActivity ready]) {
	
		// do some random action here:
			// jump
			// rotate left
			// rotate right
			// '/sit'


		[timerIdleActivity reset];
	}
	
	
//	NSLog(@" zzzzz ... still waiting");
	
	// if started then we have a timer to watch
	if (startedWait) {
	
		// we are done when the timer is ready .. 
		return [timerWaitTime ready];
	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}


- (void) stop{}


#pragma mark -


+ (id) waitIndefinatelyForTask: (MPTask*) aTask {

	return [[MPActivityWait alloc] initWithTask: aTask];
}


+ (id) waitForTime: (NSInteger) timeInMS forTask:(MPTask *)aTask {

	MPActivityWait *newActivity = [MPActivityWait waitIndefinatelyForTask:aTask];
	[newActivity setWaitTime: timeInMS];
	
	return newActivity;
}

@end
