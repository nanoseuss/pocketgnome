//
//  WaypointActionEditor.h
//  Pocket Gnome
//
//  Created by Josh on 1/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Waypoint;

@class WaypointController;

@interface WaypointActionEditor : NSObject {

	IBOutlet WaypointController	*waypointController;
	
	IBOutlet NSPanel *editorPanel;
	IBOutlet NSPopUpButton	*addConditionDropDown;
	IBOutlet NSPopUpButton	*addActionDropDown;
	IBOutlet NSTableView	*conditionTableView;
	IBOutlet NSTableView	*actionTableView;
	IBOutlet NSTextField	*waypointDescription;
	
	NSMutableArray *_conditionList;
	NSMutableArray *_actionList;
	
	Waypoint *_waypoint;
}

+ (WaypointActionEditor *)sharedEditor;
- (void)showEditorOnWindow: (NSWindow*)window withWaypoint: (Waypoint*)wp withAction:(int)type;


- (IBAction)addCondition:(id)sender;
- (IBAction)addAction:(id)sender;

- (IBAction)closeEditor: (id)sender;
- (IBAction)saveWaypoint: (id)sender;

- (NSArray*)routes;
@end
