//
//  MPSeqTask.m
//  TaskParser
//
//  Created by admin on 9/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskSeq.h"
#import "MPTask.h"


@implementation MPTaskSeq


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		
		name = @"Seq";
		currentIndex = 0;
		
	}
	return self;
}


#pragma mark -
#pragma mark Treeview Status Display


- (NSString *) showStatusText {
	NSMutableString* value = [NSMutableString stringWithString:@""];
	
	[value appendFormat:@"(%@)  %d/%d", [super showStatusText], currentIndex, [childTasks count]];
	return [value retain];
}


#pragma mark -

- (MPTask *) bestTask {
	
	if (bestTask == nil) {
		
		// if currentChildIndex < count of childTasks
		while (currentIndex < [childTasks count]) {
		
			MPTask *checkMe = [childTasks objectAtIndex:currentIndex];
			if( ([checkMe isFinished]) || (![checkMe wantToDoSomething])) {
				currentIndex++;
			} else {
				break;
			}
		}
		
		if (currentIndex < [childTasks count]) {
			bestTask = [childTasks objectAtIndex:currentIndex];
		}
	}
	
	return bestTask;
}




- (BOOL) isFinished {
	
	MPTask *currChild = [self bestTask];
	BOOL amI =  (currChild == nil);
	[self updateFinishedStatus:amI];
	return amI;
}



// return the desired location of my best task
- (MPLocation *) location {
	return [[self bestTask] location];
}



// restart all my kiddos!
- (void) restart {
	currentIndex = 0;
	for ( MPTask *task in childTasks) {
		[task restart];
	}
}


// I wantToDoSomething only if my bestTask wants to do something
- (BOOL) wantToDoSomething {
	BOOL doI = ([self bestTask] != nil);
	[self updateWantSatus:doI];
	return doI;
}



- (MPActivity*) activity {
	
	MPTask *currentTask = [self bestTask];
	if (currentTask == nil) {
		
		return nil;
	}
	return [currentTask activity];
}



- (BOOL) activityDone: (MPActivity*)activity {
	return [[self bestTask] activityDone:activity];
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskSeq alloc] initWithPather:controller] autorelease];
}


@end
