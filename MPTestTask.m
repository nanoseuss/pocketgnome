//
//  MPTestTask.m
//  TaskParser
//
//  Created by admin on 9/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTestTask.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "MPActivityWait.h"
#import "TestActivity.h"


@implementation MPTestTask

@synthesize timerUpTime, timerDownTime;
@synthesize myActivity;
@synthesize locations;

- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		state = TestTaskStateBegin;
		name = @"TestTask";
		myActivity = nil;
		self.locations = nil;
	}
	return self;
}

- (void) setup {
	upTime = (NSInteger) [[self integerFromVariable:@"uptime" orReturnDefault:1000] value];
	downTime = (NSInteger) [[self integerFromVariable:@"dtime" orReturnDefault:1000] value];
	timerUpTime = [MPTimer timer:upTime];
	timerDownTime = [MPTimer timer:downTime];
	
	self.locations = [self locationsFromVariable:@"locations"];
	
	name = [self stringFromVariable:@"name" orReturnDefault:@"defaultName"];
}


- (void) dealloc
{
    [timerUpTime release];
    [timerDownTime release];
	[myActivity release];
	
    [super dealloc];
}

#pragma mark -





- (MPLocation *) location {
	return nil;
}


- (void) restart { }


- (BOOL) wantToDoSomething {
	
	BOOL doI = YES;
	
	switch (state) {
			
		case TestTaskStateBegin:
			[timerUpTime start];
			state = TestTaskStateUp;
			doI = YES;
			break;
			
		case TestTaskStateUp:
			if ([timerUpTime ready] ) {
				state = TestTaskStateDown;
				[timerDownTime start];
				doI = NO;
			} 
			break;
			
		case TestTaskStateDown:
			if ([timerDownTime ready] ) {
				state = TestTaskStateUp;
				[timerUpTime start];
				doI = YES;
			} else {
				doI = NO;
			}
			break;
	}
	if (doI) {
		currentStatus = TaskStatusWant;
	} else {
		currentStatus = TaskStatusNoWant;
	}
	return doI;
}


- (BOOL) isFinished {
	return NO;
}


- (MPActivity *) activity {

	// create (or recreate) our activity based on the needs at the moment
	if (myActivity == nil)	{
//		[self setMyActivity:[MPActivityWait waitIndefinatelyForTask:self]];
		[self setMyActivity:[TestActivity waitIndefinatelyForTask:self]];
	}
	
	// return the activity to work on
	return myActivity;
}



- (BOOL) activityDone: (MPActivity*)activity {

	// that activity is done so release it 
	if (activity == myActivity) {
		[myActivity autorelease];
		[self setMyActivity:nil];
	}
	
	return YES; // ??
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTestTask alloc] initWithPather:controller] autorelease];
}

@end
