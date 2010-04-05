//
//  MPTaskController.h
//  TaskParser
//
//  Created by Coding Monkey on 9/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "MPTask.h"
@class MPTask;
@class MPActivity;
@class MPPerformanceController;
@class MPTimer;
@class PatherController;

typedef enum RunningState { 
    RunningStateStopped = 1, 
    RunningStatePaused	= 2, 
    RunningStateRunning	= 3
} MPRunningState; 


/*!
 * @class MPTaskController
 * @abstract This is our main controller for our Tasks.
 * @discussion 
 *	The TaskController is controls the loading of our Tasks from the defined task file. It controls 
 *  the selection of the currently most important task to run, and the operation of those tasks.
 */
@interface MPTaskController : NSObject {


	IBOutlet MPPerformanceController *performanceController;
	
	MPRunningState currentRunningState, wantedRunningState;
	BOOL inCombat;	// flag denoting when we are currently in combat (other tasks should reference this and choose not to do anything if YES)
	MPActivity *currentActivity, *newActivity;

	MPTimer *timerWorkTime;
}

@property (readwrite) MPRunningState currentRunningState, wantedRunningState;
@property (readwrite) BOOL inCombat;
@property (readwrite, retain) MPActivity *currentActivity, *newActivity;
@property (retain) 	MPTimer *timerWorkTime;


- (void) loadTaskFile:(NSString*)fileName;
- (void) loadTaskFile:(NSString*)fileName withPather:(PatherController*)controller;
- (BOOL) rootTaskLoaded;


- (void) evaluateTasks;
- (void) processCurrentActivity;

#pragma mark -

+ (MPTask*) rootTask;

@end
