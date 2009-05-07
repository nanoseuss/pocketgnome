//
//  QuestController.h
//  Pocket Gnome
//
//  Created by Josh on 4/22/09.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class PlayerDataController;
@class WaypointController;
@class RouteSet;

@interface QuestController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet PlayerDataController   *playerDataController;
	IBOutlet WaypointController		*routeController;
	IBOutlet BotController			*botController;
	
	IBOutlet NSTableView		*questTable;
	IBOutlet NSView				*view;
	
	IBOutlet NSButton *questStartStopButton;
	
	NSMutableArray				*_playerQuests;
	NSMutableArray				*_routes;
    
    NSSize minSectionSize, maxSectionSize;
	
	BOOL isQuesting;
}

// Controller interface
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readwrite, retain) NSMutableArray *routes;

- (IBAction)startQuesting: (id)sender;

- (void)loadPlayerQuests;

- (void)loadingView;

- (void)dumpQuests;

- (NSArray*)playerQuests;

- (RouteSet*)getRouteSetFromIndex: (id)anObject;

@end
