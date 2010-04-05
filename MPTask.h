//
//  Task.h
//  TaskParser
//
//  Created by Coding Monkey on 8/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPParser;	
@class MPValue;		
@class MPValueFloat;
@class MPLocation;	
@class MPActivity;	
@class PatherController;
@class Mob;
@class Position;


// This enum defines our Task Status state for our task display 
typedef enum TaskStatus { 
    TaskStatusFinished = 1, 
    TaskStatusNoWant	= 2, 
    TaskStatusWant	= 3
} MPTaskStatus; 


/*!
 * @class      MPTask
 * @abstract   Represents a Task that has activities to be done.
 * @discussion 
 * In MacPather a Task represents work that your toon needs to perform.  
 * 
 * You can define many different tasks that you want to accomplish. When there are numerous 
 * Tasks that want to do work, MacPather will pick the Task that is defined with the highest 
 * priority (ie the lowest $Prio definition).
 *
 * A Task can contain many Activities that need to be performed in order to accomplish 
 * the Task.  So for example a Buy{} task might contain a WalkToVendor{} activity as well as a 
 * BuyItemFromVendor{} activity.
 *
 * It is the Activities returned from MPTasks that determines the actual actions your
 * toon is performing.
 *		
 */
@interface MPTask : NSObject {
	
	NSString *name;
	MPTask* parent;
	
	NSMutableArray* subTasks;	// the temp copy of childTasks when reading the parsing File.
	NSArray* childTasks;   // optimization: the working copy of childTasks
	
	NSMutableDictionary* definedVariables; // the variable definitions from the task files.
	
	BOOL active;  // is this task currently active
	
	MPTask *bestTask;
	
	
	NSInteger priority;
	
	MPTaskStatus currentStatus;
	
	PatherController *patherController;
	
//	MPActivity* noActivity;

}
	

@property(readonly, retain) NSString* name;
@property (retain) MPTask* parent;
@property(retain) NSMutableArray *subTasks;
@property(retain) NSArray *childTasks;
@property (retain) NSMutableDictionary* definedVariables;
@property (retain) MPTask* bestTask;
@property (readwrite) MPTaskStatus currentStatus;
@property (readwrite, retain) PatherController *patherController;


- (id) initWithPather: (PatherController *)controller;

#pragma mark -
#pragma mark Task File Parsing 

/*!
 * @function parseTaskDataWithParser
 * @abstract Reads in the Task definition for this task.
 * @discussion
 *	Reads in the Task Definition for this Task.
 */
- (void) parseTaskDataWithParser:(MPParser*) parser;


/*!
 * @function parseTaskDataWithParser
 * @abstract Reads in the variable definition for this task.
 * @discussion
 *	Reads in the variable Definition for this Task.
 */
- (void)pullTaskVariableInfo: (MPParser*) parser;


/*!
 * @function parseTaskDataWithParser
 * @abstract Reads in the Task definition for this task.
 * @discussion
 *	Reads in the Task Definition for this Task.
 */
- (void)parseTaskDataWithParser: (MPParser*) parser;


/*!
 * @function addSubTask
 * @abstract Store the given task as a child task.
 * @discussion
 *	The sub Task list is a temporary list of childTasks that gets created during initialization.  This list will be copied as an NSArray into childTasks.
 */
- (void)addSubTask: (MPTask*) aTask;




#pragma mark -
#pragma mark TreeView Data Source & Display 

/*!
 * @function numberOfChildren
 * @abstract Return the number of children this task has.
 * @discussion
 *	
 */
- (NSInteger) numberOfChildren;

/*!
 * @function childAtIndex
 * @abstract Return the child task at the given index.
 * @discussion
 *	
 */
- (MPTask *) childAtIndex:(NSInteger)index;


/*!
 * @function showStatusName
 * @abstract Display name on the Task Tree
 * @discussion
 *	
 */
- (NSString *) showStatusName;


/*!
 * @function showStatusText
 * @abstract Display a brief status text on the Task Tree
 * @discussion
 *	
 */
- (NSString *) showStatusText;


/*!
 * @function updateWantStatus
 * @abstract Update the status display value to indicate our current wantToDoSomething status.
 * @discussion
 *	The Treeview data display will display the text of the tasks in various color based on it's current 
 *  status.
 *
 *  If the current Task is the Active task (or a parent there of) the text is GREEN
 *  If the current Task wantsToDoSomething then the text is RED
 *  If the current Task !wantsToDoSomething then the text is BLUE
 *  If the current Task isFinished then the Text is BLACK
 *	
 */
- (void) updateWantSatus:(BOOL)wantTo;
- (void) updateFinishedStatus:(BOOL)amI;

#pragma mark -
#pragma mark Common Task Data initialization 





/*!
 * @function boolFromVariable:orReturnDefault
 * @abstract Attempt to return a BOOL from the given defined variable.
 * @discussion
 *	This method will interpret the following values as YES: 'Y', 'YES', 'T', 'TRUE', '1'. Anything else is NO.
 */
- (BOOL) boolFromVariable: (NSString *) variableName orReturnDefault:(BOOL) defaultValue;


/*!
 * @function conditionFromVariable:orReturnDefault
 * @abstract Attempt to return an MPValue object from the given defined variable.
 * @discussion
 *	This method will return a default MPBoolValue with defaultValue if no variableName is found.
 */
- (MPValue *) conditionFromVariable: (NSString *) variableName orReturnDefault:(BOOL) defaultValue;


/*!
 * @function integerFromVariable:orReturnDefault
 * @abstract Attempt to return an MPValue object from the given defined variable.
 * @discussion
 *	This method will return a default MPIntValue with defaultValue if no variableName is found.
 */
- (MPValue *) integerFromVariable: (NSString *) variableName orReturnDefault:(NSInteger) defaultValue;


/*!
 * @function floatFromVariable:orReturnDefault
 * @abstract Attempt to return an MPValue object from the given defined variable.
 * @discussion
 *	This method will return a default MPFloatValue with defaultValue if no variableName is found.
 */
- (MPValue *) floatFromVariable: (NSString *) variableName orReturnDefault:(float) defaultValue;


/*!
 * @function stringFromVariable:orReturnDefault
 * @abstract Attempt to return an NSString object from the given defined variable.
 * @discussion
 *	This method will return a default NSString with defaultValue if no variableName is found.
 */
- (NSString *) stringFromVariable: (NSString *) variableName orReturnDefault:(NSString *) defaultValue;



/*!
 * @function locationsFromVariable
 * @abstract Attempt to return an array of MPLocation objects from the given defined variable
 * @discussion
 *	If variableName isn't found, nil will be returned.
 */
- (NSArray *) locationsFromVariable: (NSString *) variableName;



/*!
 * @function arrayStringsFromVariable
 * @abstract Attempt to return an array of NSString objects from the given defined variable
 * @discussion
 *	If variableName isn't found, an empty NSArray is returned.
 */
- (NSArray *) arrayStringsFromVariable: (NSString *) variableName;



/*!
 * @function arrayNumbersFromVariable
 * @abstract Attempt to return an array of NSNumber objects from the given defined variable
 * @discussion
 *	If variableName isn't found, an empty NSArray is returned.
 */
- (NSArray *) arrayNumbersFromVariable: (NSString *) variableName withExpectedType:(NSString*)type;

/*!
 * @function setup
 * @abstract Read in the given variables for this object.
 * @discussion
 *	This method will attempt to process the given parameters into their proper MPValue objects.  This method should be called
 *  after a Task has been fully read in from the task file.
 */
- (void) setup;

#pragma mark -
#pragma mark Common Task Operation Methods


/*!
 * @function priority
 * @abstract Returns the priority value of this task.
 * @discussion
 *	Returns a numeric priority value for this task.  The lower the value, the higher the prioirty of the 
 *  task.
 */
- (NSInteger) priority;


/*!
 * @function location
 * @abstract Return the location this task want's to do work at.
 * @discussion
 *	The location is used to figure out which task should be active when two same priority tasks want 
 *  to do something at the same time.  The closest task wins out.
 *
 *  If a location isn't valid for this task (it can be done anywhere) then return nil.  
 */
- (MPLocation *) location;


/*!
 * @function restart
 * @abstract Reset this task to it's initial state.
 * @discussion
 *	There are certain times when a task should be reset to its beginning state so that a given
 *  sequence of events can be performed again.
 */
- (void) restart;


/*!
 * @function wantToDoSomething
 * @abstract Indicate if this task has work to be done.
 * @discussion
 *	Returns YES when there is work to be done.  Else returns NO.
 */
- (BOOL) wantToDoSomething;


/*!
 * @function finished
 * @abstract Indicates that this task is finished an no more work is to be done.
 * @discussion
 *	Returns YES when this task has completed all it's work.  NO otherwise.
 */
- (BOOL) isFinished;



/*!
 * @function activity
 * @abstract Returns the current activity needing to be done for this task.
 * @discussion
 *	A task may have many activities to carry out.  The task keeps track of which current activity
 *  to perform and returns that here.
 *
 *  If no activity is to be done, then it returns nil.
 */
- (MPActivity*) activity;


/*!
 * @function activityDone
 * @abstract Tells the task that the supplied activity has reported "done".
 * @discussion
 *	Returns YES or NO for some reason.
 */
- (BOOL) activityDone: (MPActivity*)activity;




/*!
 * @function clearBestTask
 * @abstract Clears out the bestTask evaluation so it will re-evaluate it again.
 * @discussion
 *	This is primarily useful for PAR tasks, as they cache their bestTask evaluation during
 *  an evaluation loop. However, other tasks can use this method to clear out previous decisions
 *  as well (see Pull Task).
 */
- (void) clearBestTask;




/*!
 * @function markInactive
 * @abstract Recursively marks this Task and all it's parents as inactive.
 * @discussion
 *	This is to allow the task list to display which tasks are currently active/inactive.
 */
- (void) markInactive;




/*!
 * @function markActive
 * @abstract Recursively marks this Task and all it's parents as active.
 * @discussion
 *	This is to allow the task list to display which tasks are currently active/inactive.
 */
- (void) markActive;


/*! 
 * @function description
 * @abstract return a description of this Task and it's current state
 * @discussion
 * Used in the UpdateUI routine.
 *
 */
- (NSString *) description;

#pragma mark -
#pragma mark Task Helpers


/*! 
 * @function myDistanceToMob
 * @abstract Returns the distance from your character to the given mob.
 * @discussion
 */
- (float) myDistanceToMob:(Mob *)mob;


/*! 
 * @function myDistanceToPosition
 * @abstract Returns the distance from your character to the given position.
 * @discussion
 */
- (float) myDistanceToPosition:(Position *)position;



/*! 
 * @function myPosition
 * @abstract Returns the player's current position.
 * @discussion
 */
- (Position *) myPosition;


#pragma mark -
#pragma mark Convienience Methods

/*!
 * @function rootTaskFromFile
 * @abstract Return the Root Task defined in the given file
 * @discussion
 *	Convienience method for returning the Top Level/Root Task defined in the given file.
 */
+ (MPTask*)rootTaskFromFile: (NSString*) fileName;
+ (MPTask*)rootTaskFromFile: (NSString *) fileName withPather:(PatherController*)controller;

/*!
 * @function taskFromKey
 * @abstract Return the Task object defined by the given Key
 * @discussion
 *	Returns an instance of the Task defined by the given Key.
 */
+ (MPTask*)taskFromKey: (NSString*) taskKey;
+ (MPTask*)taskFromKey: (NSString*) taskKey withPather:(PatherController*)controller;

@end
