//
//  LootController.h
//  Pocket Gnome
//
//  Created by Josh on 6/7/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ItemLootedNotification @"ItemLootedNotification"
#define AllItemsLootedNotification @"AllItemsLootedNotification"

@class Controller;
@class InventoryController;
@class ChatController;
@class PlayerDataController;

@interface LootController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet InventoryController	*itemController;
	IBOutlet ChatController			*chatController;
	IBOutlet PlayerDataController	*playerDataController;
	
	NSMutableDictionary	*_itemsLooted;
	
	int		_lastLootedItem;
	UInt32	_lastTimeItemWasLooted;
}

@property UInt32 lastTimeItemWasLooted;

- (NSDictionary*)itemsLooted;
- (void)resetLoot;

- (BOOL)isLootWindowOpen;
- (void)acceptLoot;
@end
