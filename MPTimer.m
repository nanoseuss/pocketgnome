//
//  MPTimer.m
//  TaskParser
//
//  Created by admin on 9/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTimer.h"


@implementation MPTimer

@synthesize startTime, duration, minDelay, maxDelay, difference, useRandom, forced;

- (id) init {
	if ((self = [super init])) {
		
		startTime = nil;
		duration = 0;
		
		// for random timer feature
		minDelay = 0;
		maxDelay = 0;
		difference = 0;
		useRandom = NO;
		forced = NO;
		
	}
	return self;
}


- (void) dealloc
{
    [startTime release];
    [super dealloc];
}

#pragma mark -


- (void) start {
	[self setStartTime:[NSDate date]];
	forced = NO; // reset our forced flag.
	
	if (useRandom) {
		duration = minDelay + (arc4random()%(difference));
	}
}

- (NSTimeInterval) elapsedTime {
	NSInteger amount = [startTime timeIntervalSinceNow] * -1000.0;
	return amount;
}

- (BOOL) ready {
	NSTimeInterval msPassed = [self elapsedTime];
	return ((duration <= msPassed) || (forced));
}


- (void) reset {
	[startTime autorelease];
	startTime = nil;
	[self start];
}


- (void) forceReady {
	forced = YES;
}


#pragma mark -

+ (MPTimer *) timer: (NSInteger) delayInMS {
	MPTimer *newTimer = [[[MPTimer alloc] init] autorelease];
	[newTimer setDuration:delayInMS];
	return [newTimer retain];
}

+ (MPTimer *) randomTimerFrom: (NSInteger) minDelayInMS To:(NSInteger)maxDelayInMS {

	MPTimer *newTimer = [MPTimer timer:1000];
	[newTimer setMinDelay: minDelayInMS];
	[newTimer setMaxDelay:maxDelayInMS];
	[newTimer setDifference:maxDelayInMS - minDelayInMS];  //Hmmm... no error checking?
	[newTimer setUseRandom:YES];

	return [newTimer retain];
}

@end
