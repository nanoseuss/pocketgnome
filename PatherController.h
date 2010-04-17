//
//  PatherController.h
//  TaskParser
//
//  Created by Coding Monkey on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTaskController.h"
#import "MPTimer.h"
@class MPPerformanceController;
@class BotController;
@class CombatController;
@class MacroController;
@class MovementController;
@class MobController;
@class MPNavigationController;
@class MPNavMeshView;
@class PlayerDataController;
@class MPCustomClass;
@class LootController;
@class WoWObject;
@class WaypointController;
@class BlacklistController;
@class MPLocation;
@class Controller;
@class MPMover;


@interface PatherController : NSObject {
	
	//// Other Controllers
	IBOutlet MPTaskController* taskController;
	IBOutlet MPPerformanceController *performanceController;
	
	IBOutlet BotController *botController;
	IBOutlet CombatController *combatController; 
	IBOutlet MacroController *macroController;
	IBOutlet MovementController *movementController;
	IBOutlet MobController *mobController;
	IBOutlet PlayerDataController *playerData;
	IBOutlet LootController *lootController;
	IBOutlet WaypointController *waypointController;
	IBOutlet BlacklistController *blacklistController;
	IBOutlet id controller;
	
	
	//// Interface Objects
	IBOutlet NSTextField* pathView;
	IBOutlet NSOutlineView* taskOutlineView;
	IBOutlet NSButton* startBotButton;
	IBOutlet NSButton* pauseBotButton;
	IBOutlet NSLevelIndicator* averageLoadIndicator;
	IBOutlet NSTextField* taskDescription;
	IBOutlet NSTextField* activityDescription;
	
	
	// TaskGenerator Tab
	IBOutlet NSTextField* generatedTask;
	IBOutlet NSButton *includeDefendTask;
	IBOutlet NSButton *includeLootTask;
	IBOutlet NSButton *includeRestTask;
	IBOutlet NSButton *includePullTask;
	IBOutlet NSButton *includeRouteTask;
	IBOutlet NSButton *includeGhostRouteTask;
	
	
	//// NavMesh Interface Objects
	IBOutlet MPNavMeshView *navMeshView;
	IBOutlet NSButton *navMeshLiveUpdating;
	IBOutlet NSSlider *scaleSlider;
	IBOutlet MPNavigationController *navigationController;
	IBOutlet NSButton *enableGraphAdjustments;
	IBOutlet NSTextField *zToleranceText;
	IBOutlet NSMatrix *updateModeOptions;
	IBOutlet NSTextField *scaleValue;
	IBOutlet NSSlider *areaSlider;
	IBOutlet NSTextField *areaValue;
	IBOutlet NSTextField *labelNumSquares;
	IBOutlet NSTextField *labelNumPoints;
	IBOutlet NSTextField *labelCurrentPosition;
	
	IBOutlet NSTextField *textboxDestLocation;
	
	
	// the patherPanel
	IBOutlet NSView *view;  
	NSSize minSectionSize, maxSectionSize;
	
			
	//// internal operations
	NSTimer *timerCheckPatherStopConditions;
	NSTimer *timerEvaluateTasks;
	NSTimer *timerProcessCurrentActivity;
	NSTimer *timerUpdateUI;
	NSTimer *timerPerformanceCycle;
	NSTimer *timerMPMover;
	
	MPTimer *timerWorkTime;
	
	NSMutableArray *unitsLootBlacklisted;  // when looting mob failed, don't try again.
	
	// CustomClass 
	MPCustomClass *customClass;
	
	MPMover *combatMover;
	
	BOOL isThreadStartedNavMeshView, isThreadStartedNavMeshAdjustments;
	
	MPLocation *deleteMeRouteDest;
	
}
@property (readonly) MPTaskController *taskController;
@property (readonly) BotController *botController;
@property (readonly) MacroController *macroController;
@property (readonly) MovementController *movementController;
@property (readonly) MobController *mobController;
@property (readonly) PlayerDataController *playerData;
@property (readonly) CombatController *combatController;
@property (readonly) LootController *lootController;
@property (readonly) WaypointController *waypointController;
@property (readonly) BlacklistController *blacklistController;
@property (readonly) Controller *controller;
@property (readonly) MPNavigationController *navigationController;

@property (retain) NSTimer *timerCheckPatherStopConditions, *timerEvaluateTasks, *timerProcessCurrentActivity, *timerUpdateUI, *timerPerformanceCycle, *timerMPMover;
@property (retain) MPTimer *timerWorkTime;

@property (retain) NSMutableArray *unitsLootBlacklisted;

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;


@property (retain) MPCustomClass *customClass;
@property (retain) MPMover *combatMover;


@property (retain) MPLocation *deleteMeRouteDest;

#pragma mark -
#pragma mark Interface Actions

/*!
 * @function findFile
 * @abstract Responds to the Find File button.
 * @discussion
 *	This routine is responsible for letting the user select a file, and then reading in the Task info. 
 */
- (IBAction) findFile: sender;


/*!
 * @function startBot
 * @abstract Responds to the Start/Stop button.
 * @discussion
 *	Performs the actions necessary to either start the bot, or to stop an operating bot. 
 */
- (IBAction) startPather: sender;


/*!
 * @function pauseBot
 * @abstract Responds to the Pause button.
 * @discussion
 *	Performs the actions necessary to pause the current operation of the bot. 
 */
- (IBAction) pausePather: sender;



/*!
 * @function generateList
 * @abstract Responds to the Generate Location List button.
 * @discussion
 *	Takes the currently selected Route and transforms it into a Location list for Pather task files. 
 */
- (IBAction) generateList: sender;



/*!
 * @function changeLiveUpdate
 * @abstract Responds to the checkbox for Live Update of the NavMesh
 * @discussion
 *	Will begin a thread to continually update the display of the NavMesh as the user runs around.
 */
- (IBAction) changeLiveUpdate: sender;





/*!
 * @function changeNavMeshScale
 * @abstract Responds to the slider to change the scale of the NavMesh display
 * @discussion
 *	
 */
- (IBAction) changeNavMeshScale: sender;

/*!
 * @function changeNavMeshScaleFromText
 * @abstract Responds to a change in the Scale textbox value
 * @discussion
 *	
 */
- (IBAction) changeNavMeshScaleFromText: sender;


/*!
 * @function changeZTolerance
 * @abstract Responds to a change in the Z Tolerance Text field
 * @discussion
 *	
 */
- (IBAction) changeZTolerance: sender;




/*!
 * @function changeAreaScale
 * @abstract Responds to the slider to change the Area to update
 * @discussion
 *	
 */
- (IBAction) changeAreaScale: sender;

/*!
 * @function changeAreaFromText
 * @abstract Responds to a change in the Area textbox value
 * @discussion
 *	
 */
- (IBAction) changeAreaFromText: sender;


/*!
 * @function updateUI
 * @abstract Refreshes the UserInterface.
 * @discussion
 *	Makes sure the stats in the UI are updated. 
 */
- (void) updateUI;


#pragma mark -
#pragma mark MacPather operation checking


/*!
 * @function checkPatherStopConditions
 * @abstract Responsible for making sure MacPather stops on conditions set by the User.
 * @discussion
 *	This routine checks for the conditions specified in the User Interface and signals a stop (or an action) when one of them 
 *  occurs.
 */
- (void) checkPatherStopConditions;


/*!
 * @function runningCheck
 * @abstract Checks conditions that are only active when a bot is running
 * @discussion
 *	This routine checks for the conditions specified in the User Interface and signals a stop (or an action) when one of them 
 *  occurs.
 */
- (void) runningCheck;


/*!
 * @function pausedCheck
 * @abstract Checks conditions that are only active when a bot is paused.
 * @discussion
 *	This routine checks for the conditions specified in the User Interface and signals a stop (or an action) when one of them 
 *  occurs.
 */
- (void) pausedCheck;


/*!
 * @function processStateChange
 * @abstract Make sure the system is in the proper state for the desired State change.
 * @discussion
 *	Different States require different Timers and Resources to be in place for the proper execution of that state.  This 
 *  method makes sure we are in the proper state.
 */
- (void) processStateChange;



#pragma mark -
#pragma mark BlackLists



/*!
 * @function lootBlacklistUnit
 * @abstract Blacklist a unit for looting.
 * @discussion
 *	When a loot error happens on a unit, mark that unit as blacklisted so the Loot task wont try it again.
 *  Units remain blacklsited for 300 seconds.
 */
- (void)lootBlacklistUnit: (WoWObject*)unit;


/*!
 * @function removeUnitFromLootBlacklist
 * @abstract Remove a unit from the lootBlackList.
 * @discussion
 *	This method is automatically scheduled to run X seconds after the unit is added via [lootBlacklistUnit].
 */
- (void)removeUnitFromLootBlacklist: (WoWObject*)unit;


/*!
 * @function isLootBlacklisted
 * @abstract Is the current unit being blacklisted for looting?
 * @discussion
 *	Returns YES if it is in our lootBlacklist.  NO otherwise.
 */
- (BOOL) isLootBlacklisted: (WoWObject *) unit;




#pragma mark -
#pragma mark Value Functions


/*!
 * @function getMyLevel
 * @abstract Returns the current level of the toon.
 * @discussion
 *	This method is called directly by the MPMyLevelValue object.  The PatherController object provides a single
 *  interface for our tasks/value objects to interface with PocketGnome's different controllers to gather data.
 */
- (NSInteger) getMyLevel;


/*!
 * @function getMyClass
 * @abstract Returns the current class name of the toon.
 * @discussion
 *	This method is called directly by the MPMyClassValue object.  The PatherController object provides a single
 *  interface for our tasks/value objects to interface with PocketGnome's different controllers to gather data.
 */
- (NSString *) getMyClass;

- (IBAction) testStuff: sender;
- (IBAction) testRoute: sender;
- (IBAction) testDestLocation: sender;


#pragma mark -
#pragma mark Singleton

+ (PatherController *)sharedPatherController;

@end
