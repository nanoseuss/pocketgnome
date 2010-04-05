//
//  MPTaskWait.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskWait.h"
#import "MPTask.h"
#import "MPActivityWait.h"

@implementation MPTaskWait
@synthesize myActivity;

- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Wait";
		myActivity = nil;
	}
	return self;
}

- (void) setup {

}


- (void) dealloc
{
	[myActivity release];
	
    [super dealloc];
}

#pragma mark -




- (BOOL) isFinished {
	return NO;
}


- (MPLocation *) location {
	return nil;
}


- (void) restart { }


- (BOOL) wantToDoSomething {
	
	return YES;
}




- (MPActivity *) activity {
	
	// create (or recreate) our activity based on the needs at the moment
	if (myActivity == nil)	{
		[self setMyActivity:[MPActivityWait waitIndefinatelyForTask:self]];
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
	return [[[MPTaskWait alloc] initWithPather:controller] autorelease];
}

@end
