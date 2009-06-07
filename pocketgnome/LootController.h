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

@interface LootController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet InventoryController	*itemController;
	
	NSMutableDictionary	*_itemsLooted;
	NSMutableDictionary *_itemNameList;
	
	int		_lastLootedItem;
}

@property (readonly) NSMutableDictionary *itemsLooted;

@end
