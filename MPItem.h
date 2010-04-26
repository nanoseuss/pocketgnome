//
//  MPItem.h
//  Pocket Gnome
//
//  Created by codingMonkey on 4/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Item;
@class BotController;
@class InventoryController;
@class Unit;
/*!
 * @class      MPItem
 * @abstract   Represents a useable item.
 * @discussion 
 * 
 *		
 */
@interface MPItem : NSObject {

	UInt32 actionID;
	int currentID;  // for items that can scale: like "Drink"
	NSString *name;
	Item *myItem;
	NSMutableArray *listIDs;
	NSMutableDictionary *listBuffIDs;
	
	BotController *botController;
	InventoryController *inventoryController;
	

}
@property (readwrite,retain) NSString *name;
@property (retain) Item *myItem;
@property (retain) BotController *botController;
@property (retain) InventoryController *inventoryController;
@property (retain) NSMutableArray *listIDs;
@property (retain) NSMutableDictionary *listBuffIDs;



- (void) addID: (int) anID;
- (void) addID: (int) anID withBuffID: (int) buffID ;
- (void) addBuffID: (int) buffID forID: (int) anID;
- (BOOL) canUse;
- (void) loadPlayerItems;
- (void) scanForItem;
- (BOOL) use;
- (BOOL) unitHasBuff: (Unit *)unit;



+ (id) item;
+ (id) drink;

@end
