//
//  EventController.h
//  Pocket Gnome
//
//  Created by Josh on 11/23/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define EventZoneChanged					@"EventZoneChanged"
#define EventBattlegroundStatusChange		@"EventBattlegroundStatusChange"

@class Controller;
@class PlayerDataController;

@interface EventController : NSObject {
	IBOutlet Controller *controller;
	IBOutlet PlayerDataController *playerController;
	
	NSTimer *_uberQuickTimer;
	NSTimer *_fiveSecondTimer;
	
	int _lastPlayerZone;
	int _lastBGStatus;
	int _lastLevel;
}

@end
