//
//  InventoryController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/27/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Item;

@class Controller;
@class PlayerDataController;
@class MemoryViewController;

@interface InventoryController : NSObject {
    IBOutlet Controller *controller;
    IBOutlet PlayerDataController *playerData;
    IBOutlet MemoryViewController *memoryViewController;

    IBOutlet NSView *view;
    IBOutlet NSTableView *itemTable;
	
	int _updateDurabilityCounter;

    NSMutableArray *_itemList, *_itemDataList;
	NSArray *_itemsPlayerIsWearing, *_itemsInBags;
    NSMutableDictionary *_itemNameList;
    NSSize minSectionSize, maxSectionSize;
	
	NSTimer *_updateTimer;
	float updateFrequency;
}

+ (InventoryController *)sharedInventory;

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property float updateFrequency;

// general
- (void)addAddresses: (NSArray*)addresses;
//- (BOOL)addItem: (Item*)item;
- (unsigned)itemCount;
- (void)resetInventory;

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

- (int)bagSpacesAvailable;
- (int)bagSpacesTotal;
- (BOOL)arePlayerBagsFull;

// Total number of marks (from all BG)
- (int)pvpMarks;

//- (NSMutableArray*)itemsInBags;
@end
