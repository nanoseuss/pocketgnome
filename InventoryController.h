//
//  InventoryController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/27/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ObjectController.h"

@class Item;

@class PlayerDataController;
@class MemoryViewController;
@class ObjectsController;

@interface InventoryController : ObjectController {
    IBOutlet MemoryViewController *memoryViewController;
	IBOutlet ObjectsController	*objectsController;
	
	int _updateDurabilityCounter;

	NSArray *_itemsPlayerIsWearing, *_itemsInBags;
    NSMutableDictionary *_itemNameList;
}

+ (InventoryController *)sharedInventory;

// general
- (unsigned)itemCount;

// query
- (Item*)itemForGUID: (GUID)guid;
- (Item*)itemForID: (NSNumber*)itemID;
- (Item*)itemForName: (NSString*)itemName;
- (NSString*)nameForID: (NSNumber*)itemID;

- (int)collectiveCountForItem: (Item*)item;
- (int)collectiveCountForItemInBags: (Item*)item;

- (float)averageItemDurability;
- (float)collectiveDurability;
- (float)averageWearableDurability;
- (float)collectiveWearableDurability;

// list
- (NSArray*)inventoryItems;
- (NSMenu*)inventoryItemsMenu;
- (NSMenu*)usableInventoryItemsMenu;
- (NSMenu*)prettyInventoryItemsMenu;
- (NSArray*)itemsPlayerIsWearing;
- (NSArray*)itemsInBags;
- (NSArray*)useableItems;

- (int)bagSpacesAvailable;
- (int)bagSpacesTotal;
- (BOOL)arePlayerBagsFull;

// Total number of marks (from all BG)
- (int)pvpMarks;

//- (NSMutableArray*)itemsInBags;
@end
