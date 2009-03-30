//
//  WaypointController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Route;
@class RouteSet;
@class Waypoint;
@class Controller;
@class PlayerDataController;

@class PTHotKey;
@class SRRecorderControl;

@class BetterSegmentedControl;
@class RouteVisualizationView;

@interface WaypointController : NSObject {

    IBOutlet Controller *controller;
    IBOutlet PlayerDataController *playerData;
    IBOutlet id mobController;
    IBOutlet id botController;
    IBOutlet id movementController;
    IBOutlet id combatController;

    IBOutlet id waypointTable;
    
    IBOutlet NSView *view;
    IBOutlet RouteVisualizationView *visualizeView;
    IBOutlet NSPanel *visualizePanel;
    IBOutlet NSMenu *actionMenu;
    IBOutlet NSMenu *testingMenu;
    IBOutlet NSPanel *renamePanel;
    
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
    PTHotKey *addWaypointGlobalHotkey;
	PTHotKey *automatorGlobalHotkey;
    NSMutableArray *_routes;
    BOOL validSelection, validWaypointCount;
    BOOL changeWasMade;
	BOOL isAutomatorRunning, disableGrowl;
    NSSize minSectionSize, maxSectionSize;
}

- (void)saveRoutes;

- (NSArray*)routes;
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



// route actions
- (IBAction)setRouteType: (id)sender;
- (IBAction)createRoute: (id)sender;
- (IBAction)loadRoute: (id)sender;
- (IBAction)removeRoute: (id)sender;
- (IBAction)renameRoute: (id)sender;
- (IBAction)closeRename: (id)sender;
- (IBAction)duplicateRoute: (id)sender;

// importing/exporting
- (void)importRouteAtPath: (NSString*)path;
- (IBAction)importRoute: (id)sender;
- (IBAction)exportRoute: (id)sender;

- (IBAction)visualize: (id)sender;
- (IBAction)closeVisualize: (id)sender;
- (IBAction)moveToWaypoint: (id)sender;
- (IBAction)testWaypointSequence: (id)sender;
- (IBAction)stopMovement: (id)sender;

// waypoint automation
- (IBAction)openAutomatorPanel: (id)sender;
- (IBAction)closeAutomatorPanel: (id)sender;
- (IBAction)startStopAutomator: (id)sender;
- (IBAction)resetAllWaypoints: (id)sender;

// waypoint actions
- (IBAction)addWaypoint: (id)sender;
- (IBAction)removeWaypoint: (id)sender;
- (IBAction)editWaypointAction: (id)sender;
- (IBAction)closeWaypointAction: (id)sender;
- (IBAction)changeWaypointAction: (id)sender;
- (IBAction)cancelWaypointAction: (id)sender;


@end
