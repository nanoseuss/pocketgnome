//
//  MPTaskController.m
//  TaskParser
//
//  Created by Coding Monkey on 9/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskController.h"
#import "MPTask.h"
#import "MPActivity.h"
#import "MPPerformanceController.h"
#import "MPTimer.h"
#import "PatherController.h"


@implementation MPTaskController

@synthesize currentRunningState, wantedRunningState;
@synthesize inCombat;
@synthesize currentActivity, newActivity;
@synthesize timerWorkTime;



static MPTask *rootTask = nil;




- (id) init {
	if ((self = [super init])) {
		self.currentRunningState = RunningStateStopped;
		self.wantedRunningState = RunningStateStopped;
		self.inCombat = NO;
		self.currentActivity = nil;
		self.timerWorkTime = [MPTimer timer:1000];
	}
	return self;
}


- (void) dealloc
{
	PGLog(@"[TaskController dealloc]");
    [currentActivity release];
    [newActivity release];
	[timerWorkTime release];
    [super dealloc];
}


#pragma mark -

// now why would we try to loadTaskFile without our patherController???
- (void) loadTaskFile:(NSString*)fileName {
	[self loadTaskFile:fileName withPather:nil];
}


- (void) loadTaskFile:(NSString*)fileName withPather:(PatherController*)controller {
	PGLog(@"loadTaskFile");
	if(rootTask != nil) {
		[rootTask autorelease];  //?? or should this be stored for some reason??
		rootTask = nil;
	}
	if(currentActivity != nil) {
		[currentActivity stop];
		[currentActivity autorelease];
		self.currentActivity = nil;
	 } 
	rootTask = [MPTask rootTaskFromFile:fileName withPather:controller];
}


- (BOOL) rootTaskLoaded {
	return (rootTask != nil);
}

#pragma mark -
#pragma mark Task Operation


// find the current Task that should be doing work
- (void) evaluateTasks {
	[timerWorkTime start];
	
	// tell tasks to clearBestTask  (resets Par tasks to re-eval their children)
	[rootTask clearBestTask];
	
	PGLog( @"taskController->evaluateTasks");
	
	if (wantedRunningState != RunningStateRunning) {
	
		PGLog (@"  [evaluateTasks] wantedRunningState != RunningStateRunning ... so don't do anything.");
		// so if we don't want to run ... then just return
		return;
	}
	
	// if currentState == Running
	if (currentRunningState == RunningStateRunning) {

		newActivity = nil;

		// find new activity
		if ((rootTask != nil) && ([rootTask wantToDoSomething])) {
			self.newActivity = [rootTask activity];
		}

		// if changed Activities then
		if (newActivity != currentActivity) {
		
			if (newActivity != nil) {
			PGLog( @"  --> new Activity found (%@) -> (%@)", [[newActivity task] name],[newActivity name]);
			} else {
				PGLog(@"  --> nil activity returned " );
			}
			
			if (currentActivity != nil) {
			
				// stop Current Activity
				[currentActivity stop];
			
				// delay Current Activity's task (so we give the new one a chance to run for a while)
				
				
				// mark currentActivity's Parent Task Line as Inactive
				[[currentActivity task] markInactive];

			}

			// update current activity == new Activity
			self.currentActivity = self.newActivity;

			if (currentActivity != nil) {

				// mark current activity's ParentTaskLine as Active
				[[currentActivity task] markActive];

				
				// currentActivity.start()
				[currentActivity start];
			}
		} // end if

		
		
	} // end if
	[performanceController storeWorkTime:[timerWorkTime elapsedTime]];
}



// Have the current activity do it's work
- (void) processCurrentActivity {

	MPTask *currTask;
	
	[timerWorkTime start];
	
	PGLog( @"taskController->processCurrentActivity [%@] -> [%@]",[[currentActivity task] name], [currentActivity name]);
	
	// if wantedState != Running and currentActivity exists
	if (wantedRunningState != RunningStateRunning) {
		
		if (currentActivity != nil) {
		
			PGLog (@"   - wantedState != runningState --> shut down currentActivity");
			// currentActivity.stop()
			[currentActivity stop];
			
			// mark taskOwner Line as inactive 
			[[currentActivity task] markInactive];
			
			// currentActivity = nil
			[self setCurrentActivity:nil];
		
		}
		
		// since we don't want to be running, just return.
		return; 
		
	} // end if
	
	// if currentState == running
	if ((currentRunningState == RunningStateRunning)) {
	
		// if currentActivity is nil 
		if (currentActivity == nil) {
		
			// if wantedState == Running
				// start noActivity timer
			// end if
			
			// call evaluateTasks
			[self evaluateTasks];
			
			return;
			
		} // end if
		
		// stop noActivity timer
		BOOL done = NO;
		if (currentActivity != nil) {
			// Do our Activity now
			done = [currentActivity work];
		}
		
		// if (done) {
		if (done) {
		
			// log Finished Activity
			PGLog(@"   --> Activity says it is done (%@) -> (%@)", [[currentActivity task] name], [currentActivity name] );
			
			// get TaskOwner of currentActivity
			currTask = [currentActivity task];
			
			// [taskOwner activityDone:currentActivity];
			[currTask activityDone:currentActivity];
			
			// mark taskOwner Line as inactive
			[currTask markInactive];
			
			// currentActivity = nil;
			[self setCurrentActivity:nil];
			
		} // end if
		
	} else {
	

		// for either paused or Stopped states ... stop activity.
		// if currentActivity exists
		if (currentActivity != nil ) {
			
			PGLog (@"   - running state: stopped.  So shutting down currentActivity");
			
			// currentActivity.stop()
			[currentActivity stop];
			
			// mark task inactive
			[[currentActivity task] markInactive];
			
			// currentActivity = nil
			[self setCurrentActivity:nil];
			
			return; // need this??
			
		} // end if
		
	} // end if
	
	[performanceController storeWorkTime:[timerWorkTime elapsedTime]];
}




#pragma mark -

+ (MPTask*) rootTask {
	return rootTask;
}
 

@end
