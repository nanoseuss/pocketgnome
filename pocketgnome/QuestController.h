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

@interface QuestController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet PlayerDataController      *playerDataController;
	
	NSMutableArray			*_playerQuests;
}

- (void)reloadPlayerQuests;

- (void)dumpQuests;

- (NSArray*)playerQuests;

@end
