//
//  MPActivityRest.m
//  Pocket Gnome
//
//  Created by admin on 10/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityRest.h"
#import "MPActivity.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "MPCustomClass.h"

@implementation MPActivityRest
@synthesize lowHealth, lowMana, timeOutSeconds, restingTimeOut;

- (id) init {
	return [self initWithTask:nil];
}

- (id) initWithTask:(MPTask*)aTask {
	
	if ((self = [super initWithName:@"Rest Activity" andTask:aTask])) {
		self.lowHealth = 0;
		self.lowMana = 0;
		self.timeOutSeconds = 0;
		restHealth = NO;
		restMana = NO;
		restingTimeOut = nil;
	}
	return self;
}



- (void) dealloc
{
    [restingTimeOut release];

    [super dealloc];
}


#pragma mark -



- (void) start {
	PlayerDataController *player = [[task patherController] playerData];
	
	if ([player percentHealth] <= lowHealth) {
		restHealth = YES;
	}
	
	if ([player percentMana] <= lowMana) {
		restMana = YES;
	}

	if (timeOutSeconds > 0) {
		restingTimeOut = [MPTimer timer:(timeOutSeconds * 1000)];
		[restingTimeOut start];
	}
}


- (BOOL) work {
	
	PlayerDataController *player = [[task patherController] playerData];
	
	if ([player percentHealth] >= 98 ) {
		restHealth = NO;
	}
	
	if ([player percentMana] >= 98 ) {
		restMana = NO;
	}
	
	if (!(restHealth || restMana)) {
		PGLog(@"Rest Activity ---> both Health and Mana are >= 98%.  Good To Go!");
		return YES;
	}
	
	if (timeOutSeconds >0 ) {
		if ([restingTimeOut ready] ) {
			
			PGLog (@"Rest Activity ---> rested timeOutSeconds [%d] ... so exiting", timeOutSeconds );
			return YES;  // timed out ---> done!
		}
	}
	
	
	// otherwise, let our CC determine if we are done or not. 
	return [[[task patherController] customClass] rest];
}


- (void) stop{
	restHealth = NO;
	restMana = NO;
}




#pragma mark -


+ (id) restForLowHealth: (NSInteger) minHealth orLowMana: (NSInteger) minMana forAtMost: (NSInteger) seconds  forTask:(MPTask *)aTask {
	
	MPActivityRest *newActivity = [[[MPActivityRest alloc] initWithTask:aTask] autorelease];
	[newActivity setLowHealth:minHealth];
	[newActivity setLowMana:minMana];
	[newActivity setTimeOutSeconds: seconds];
	
	return newActivity;
}

@end
