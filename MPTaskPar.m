//
//  MPParTask.m
//  TaskParser
//
//  Created by Coding Monkey on 8/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskPar.h"
#import "MPTask.h"


@implementation MPTaskPar


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		
		name = @"Par";

	}
	return self;
}


#pragma mark -

- (MPTask *) bestTask {
	
	// many of my methods use [bestTask] to reference the task I 
	// decided was the most important one at the time.  So let's not
	// regenerate it each time (can be quite intensive possibly), but
	// simply remember which one we decided.
	
	// [TaskController evaluateTasks] will call our [resetBestTask] method
	// and clear it out so we re-evaluate it every 100 ms (or so)
	if (bestTask == nil) {
		
		// myLocation
//		MPLocation *myLocation;
		
		// bestDistance = MAX_INT
		NSInteger bestDistance = 1000000; // or HUGE_VALF for float 
		
		// bestPriority = MAX_INT
		NSInteger bestPriority = 1000000; 
		
		NSInteger currentDistance;
		NSInteger currentPriority;
//		MPLocation *currentLocation;
		
		// foreach task in childTasks
		for ( MPTask *task in childTasks) {
		
			// if !(task.finished()) && (task.wantToDoSomething()) then
			if ((![task isFinished]) && ([task wantToDoSomething])) {
			
				// currDistance = 0
				currentDistance = 0;
				
				// currPrio = task.priority
				currentPriority = [task priority];
				
				// To Do:  choose the closest task to do first.
				// currLoc = task.location()
				// if currLoc != nil
					// currDistance = myLocation.distanceTo(currLoc)
				// end if
				
				// if currPrio < bestPriority then
				if (currentPriority < bestPriority ) {
				
					// bestTask = task
					bestTask = task;
					
					// bestPriority = currPrio
					bestPriority = currentPriority;
					
					// bestDistance = currDistance
					bestDistance = currentDistance;
					
				} else if (currentPriority == bestPriority)  { // else if (currPrio == bestPriority) then
					// if currDistance < bestDistance then
					if (currentDistance < bestDistance ) {
					
						// bestTask = task
						bestTask = task;
						
						// bestDistance = currDistance
						bestDistance = currentDistance;
						
					} // end if
				} // end if
			} // end if
			
		}// next 
		
	}
	return bestTask;  
}



- (BOOL) isFinished {

	BOOL amI = YES;
	
	// IF any of my child tasks are not finished, then neither am I
	for ( MPTask *task in childTasks) {
		if (![task isFinished]){
			amI = NO;
			break;
		}
	}
	[self updateFinishedStatus:amI];
	return amI;
}



// return the desired location of my best task
- (MPLocation *) location {
	return [[self bestTask] location];
}



// restart all my kiddos!
- (void) restart {
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
	return [[[MPTaskPar alloc] initWithPather:controller] autorelease];
}

@end
