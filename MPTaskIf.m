//
//  MPIfTask.m
//  TaskParser
//
//  Created by admin on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskIf.h"


@implementation MPTaskIf


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		
		name = @"If";
	}
	return self;
}




#pragma	mark -




- (BOOL) isFinished {
	
	// if condition false then finished.
	BOOL amI =  (BOOL)[condition value];
	if (!amI) {
		[self updateFinishedStatus:YES];
		return YES;
	}
	
	// otherwise see if our child is finished
	amI = [child isFinished];
	[self updateFinishedStatus:amI];
	return amI;
}



// I wantToDoSomething only if my bestTask wants to do something
- (BOOL) wantToDoSomething {
	BOOL doI = (BOOL)[condition value];
	if (doI) {
		doI = [child wantToDoSomething];
	}
	[self updateWantSatus:doI];
	return doI;
}





#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskIf alloc] initWithPather:controller] autorelease];
}


@end
