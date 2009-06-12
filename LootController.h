//
//  LootController.h
//  Pocket Gnome
//
//  Created by Josh on 6/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ItemLootedNotification @"ItemLootedNotification"

@class Controller;
@class InventoryController;
@class ChatController;

@interface LootController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet InventoryController	*itemController;
	IBOutlet ChatController			*chatController;
	
	NSMutableDictionary	*_itemsLooted;
	
	int		_lastLootedItem;
}

- (NSDictionary*)itemsLooted;
- (void)resetLoot;

- (BOOL)isLootWindowOpen;
- (void)acceptLoot;
@end
