/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import <Cocoa/Cocoa.h>
#import "SaveData.h"

@class Route;
@class RouteSet;
@class RouteCollection;
@class Waypoint;
@class Controller;
@class PlayerDataController;
@class BotController;

@class BetterTableView;
@class PTHotKey;
@class SRRecorderControl;

@class BetterSegmentedControl;
@class RouteVisualizationView;

@interface WaypointController : SaveData {

    IBOutlet Controller *controller;
    IBOutlet PlayerDataController *playerData;
    IBOutlet id mobController;
    IBOutlet BotController *botController;
    IBOutlet id movementController;
    IBOutlet id combatController;

    IBOutlet BetterTableView *waypointTable;
	IBOutlet NSOutlineView *routesTable;
    
    IBOutlet NSView *view;
    IBOutlet RouteVisualizationView *visualizeView;
    IBOutlet NSPanel *visualizePanel;
    IBOutlet NSMenu *actionMenu;
    IBOutlet NSMenu *testingMenu;

    // waypoint action editor
    IBOutlet NSPanel *wpActionPanel;
    IBOutlet NSTabView *wpActionTabs;
    IBOutlet NSTextField *wpActionDelayText;
    IBOutlet BetterSegmentedControl *wpActionTypeSegments;
    IBOutlet NSPopUpButton *wpActionIDPopUp;
    Waypoint *_editWaypoint;
	
    // waypoint recording
    IBOutlet NSButton *automatorStartStopButton;
    IBOutlet NSPanel *automatorPanel;
    IBOutlet NSTextField *automatorIntervalValue;
    IBOutlet NSProgressIndicator *automatorSpinner;
    IBOutlet RouteVisualizationView *automatorVizualizer;
    
    IBOutlet SRRecorderControl *shortcutRecorder;
	IBOutlet SRRecorderControl *automatorRecorder;
    
    IBOutlet id routeTypeSegment;
    RouteSet *_currentRouteSet;
	Route *_currentRoute;
    PTHotKey *addWaypointGlobalHotkey;
	PTHotKey *automatorGlobalHotkey;
    BOOL validSelection, validWaypointCount;
	BOOL isAutomatorRunning, disableGrowl;
    NSSize minSectionSize, maxSectionSize;
	
	IBOutlet NSPanel *descriptionPanel;
	NSString *_descriptionMultiRows;
	NSIndexSet *_selectedRows;
	
	NSString *_nameBeforeRename;
	
	IBOutlet NSButton		*scrollWithRoute;
	IBOutlet NSTextField	*waypointSectionTitle;
	
	// temp for route collections
	NSMutableArray *_routeCollectionList;
	RouteCollection *_currentRouteCollection;
	BOOL _validRouteSelection;
	BOOL _myHackVariableToLoadOldData;	// cry
	IBOutlet NSButton *startingRouteButton;
	IBOutlet NSTabView *waypointTabView;
	
	BOOL _validRouteSetSelected;
	BOOL _validRouteCollectionSelected;
	
	// for teh n00bs
	BOOL _firstTimeEverOnTheNewRouteCollections;
	IBOutlet NSPanel *helpPanel;
}

- (void)saveRoutes;

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

@property BOOL validSelection;
@property BOOL validWaypointCount;
@property BOOL isAutomatorRunning;
@property BOOL disableGrowl;
@property (readonly) Route *currentRoute;
@property (readwrite, retain) RouteSet *currentRouteSet;
@property (readonly, retain) RouteCollection *currentRouteCollection;
@property (readwrite, retain) NSString *descriptionMultiRows;

@property BOOL validRouteSelection;
@property BOOL validRouteSetSelected;
@property BOOL validRouteCollectionSelected;

- (NSArray*)routeCollections;
- (NSArray*)routes;
- (RouteCollection*)routeCollectionForUUID: (NSString*)UUID;

// route actions
- (IBAction)setRouteType: (id)sender;
- (IBAction)loadRoute: (id)sender;
- (IBAction)waypointMenuAction: (id)sender;
- (IBAction)closeDescription: (id)sender;

// importing/exporting
- (void)importRouteAtPath: (NSString*)path;

- (IBAction)visualize: (id)sender;
- (IBAction)closeVisualize: (id)sender;
- (IBAction)moveToWaypoint: (id)sender;
- (IBAction)testWaypointSequence: (id)sender;
- (IBAction)stopMovement: (id)sender;
- (IBAction)closestWaypoint: (id)sender;

// waypoint automation
- (IBAction)openAutomatorPanel: (id)sender;
- (IBAction)closeAutomatorPanel: (id)sender;
- (IBAction)startStopAutomator: (id)sender;
- (IBAction)resetAllWaypoints: (id)sender;

// waypoint actions
- (IBAction)addWaypoint: (id)sender;
- (IBAction)removeWaypoint: (id)sender;
- (IBAction)editWaypointAction: (id)sender;
- (void)waypointActionEditorClosed: (BOOL)change;

// new action/conditions
- (void)selectCurrentWaypoint:(int)index;

// new Route Collection stuff
- (IBAction)deleteRouteButton: (id)sender;
- (IBAction)deleteRouteMenu: (id)sender;
- (IBAction)addRouteSet: (id)sender;
- (IBAction)addRouteCollection: (id)sender;
- (IBAction)closeHelpPanel: (id)sender;
- (IBAction)startingRouteClicked: (id)sender;
- (IBAction)importRoute: (id)sender;
- (IBAction)exportRoute: (id)sender;
- (IBAction)renameRoute: (id)sender;
- (IBAction)duplicateRoute: (id)sender;

// TO DO: add import/export/show/duplicate

@end
