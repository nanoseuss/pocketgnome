//
//  MPConditionalTask.m
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskConditional.h"


@implementation MPTaskConditional

@synthesize condition, child;

- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		condition = nil;
		child = nil;
	}
	return self;
}

- (void) setup {
	self.condition = (MPValueBool *) [self conditionFromVariable:@"cond" orReturnDefault:NO];
	
	[super setup];
	if ([childTasks count] >= 1) {
		[self setChild:[childTasks objectAtIndex:0]];
	} else {
		PGLog(@" Error:  %@ task has no child task!", [self name]);
	}
}

- (void) dealloc
{
    [condition release];
	[child release];
    [super dealloc];
}

#pragma mark -
#pragma mark Common Conditional Task Methods

// Condition Tasks share these common methods:


// return the desired location of my child task
- (MPLocation *) location {
	return [child location];
}


// restart my child
- (void) restart {
	[child restart];
}


// return my childs current activity
- (MPActivity*) activity {
	return [child activity];
}


// tell child activityDone
- (BOOL) activityDone: (MPActivity*)activity {
	return [child activityDone:activity];
}



@end
