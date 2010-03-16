//
//  JumpToWaypointActionController.h
//  Pocket Gnome
//
//  Created by Josh on 3/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActionController.h"

@interface JumpToWaypointActionController : ActionController {

	NSMutableArray *_waypoints;
	
	IBOutlet NSPopUpButton	*waypointsPopUpButton;
}

+ (id)jumpToWaypointActionControllerWithTotalWaypoints: (int)waypoints;

@property (readwrite, retain) NSArray *waypoints;

@end
