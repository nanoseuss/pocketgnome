//
//  MPUntilTask.m
//  TaskParser
//
//  Created by codingMonkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskUntil.h"


@implementation MPTaskUntil
@synthesize child;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		
		name = @"Until";
		child = nil;
//		taskState = WhenTaskStateWaiting;
	}
	return self;
}




#pragma	mark -





- (BOOL) isFinished {
	
	BOOL amI = ((BOOL) [condition value]);
	if (!amI) {
		// until task wants to keep going, see if child does
		if ([child isFinished]) {
		
			// let's try to restart it then
			[child restart];
		}
	}
	
	// if child wouldn't restart
	if ( [child isFinished]) {
		amI = YES;
	}
	[self updateFinishedStatus:amI];
	return amI;
}





// I wantToDoSomething only if my bestTask wants to do something
- (BOOL) wantToDoSomething {
	
	BOOL doI = ((BOOL) [condition value]);
	
	if (doI) {
		// cond == YES, so we want to stop now.
		[self updateWantSatus:NO];
		return NO;
	}
	
	// condition still false so go by child status:
	doI = [child wantToDoSomething];
	[self updateWantSatus:doI];
	return doI;
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskUntil alloc] initWithPather:controller] autorelease];
}

@end
