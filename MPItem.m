//
//  MPItem.m
//  Pocket Gnome
//
//  Created by codingMonkey on 4/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPItem.h"
#import "Item.h"
#import "InventoryController.h"
#import "BotController.h"
#import "PatherController.h"
#import "AuraController.h"


@implementation MPItem
@synthesize name, myItem, botController, inventoryController, listIDs, listBuffIDs;



- (id) init {
	
	if ((self = [super init])) {
		
		self.name = nil;
		self.myItem = nil;
		actionID = 0;
		currentID = 0;

		self.listIDs = [NSMutableArray array];
		self.listBuffIDs = [NSMutableDictionary dictionary];
		
		
		self.botController = [[PatherController	sharedPatherController] botController];
		self.inventoryController = [InventoryController sharedInventory];
	}
	return self;
}


- (void) dealloc
{
	[name release];
    [myItem release];
	[listIDs release];
	[listBuffIDs release];
	[botController release];
	[inventoryController release];
	
    [super dealloc];
}


#pragma mark -




- (void) addID: (int) anID {
	
	[self addID:anID withBuffID:0];
}
	
- (void) addID: (int) anID withBuffID: (int) buffID {
	
	[listIDs addObject:[NSNumber numberWithInt:anID]]; 
	
	if (buffID > 0) {
		[self addBuffID:buffID forID:anID];
	}
}


- (void) addBuffID: (int) buffID forID: (int) anID {

	NSNumber *valBuff = [NSNumber numberWithInt:buffID];
	NSNumber *valID = [NSNumber	numberWithInt:anID];
	[listBuffIDs setObject:valBuff forKey:valID];
	
}


-(BOOL) canUse {
	
	if (myItem == nil) {
		return NO;
	}
	
	
	return YES;
}


-(BOOL) use {
	
	return [botController performAction:(USE_ITEM_MASK + actionID)];
	
}



- (void) scanForItem {
	
	Item *foundItem = nil;
	
	int count = 0;
	
	// scan by registered ID's
//	int rank = 1;
//	int foundRank = 0;
	for( NSNumber *currID in listIDs ) {
		
		
		for(Item *item in  [inventoryController inventoryItems]) {
			
//			if ( [currID intValue] == [[item ID] intValue]) {
			if ( [currID isEqualToNumber:[NSNumber numberWithInt:[item entryID]]] ) {
				
				// we found this item
				PGLog( @"       --> item[%@]:: Found item [%@] id[%d] ",[self name], [item name], [item entryID]);
				
				count = [inventoryController collectiveCountForItemInBags: item];
				if (count > 0) {
					
					foundItem = item;
				} else {
					PGLog (@"       --> item[%@]:: Out of Stock!!! looking for other.", [item name]);
				}
				break;
			}
		}
		
	}
	
	
	if (foundItem) {
		
		if (foundItem != myItem) {
			PGLog(@"   [%@]:: UPDATED Item:  [%@]", name, [foundItem name]);
		
			self.myItem = foundItem;
			actionID = [foundItem entryID];
		}
		
	} else {
		
		PGLog(@"     == Item[%@]:: no item found after scanning", name);
	}
	
	
}





- (void) loadPlayerItems {
	
	self.myItem = [inventoryController itemForName:name];
	
	
	if (myItem == nil) {
		
		
		PGLog( @" item[%@] not found by name ... scanning by IDs:", name);
		[self scanForItem];
		
	} else {
		
		actionID = [myItem entryID] ;

	}
	
	PGLog(@"     == item[%@] actionID[%d] ",name,  actionID);
	// end if
}



#pragma mark -
#pragma mark Aura Checks


- (BOOL) unitHasBuff: (Unit *)unit {
	
	NSNumber *valBuff = [listBuffIDs objectForKey:[NSNumber numberWithInt:actionID]];
	
	if (valBuff == nil) return NO;
	
	int buffID = [valBuff intValue];
	return [[AuraController sharedController] unit:unit hasBuff:buffID];
	
}



#pragma mark -



+ (id) item {
	
	MPItem *newItem = [[MPItem alloc] init];
	return [newItem autorelease];
}




// attempt to compile a single item that scans for the best 
// drink you have in your inventory and drink that when resting:
+ (id) drink {
	
	MPItem *drink = [MPItem	item];
	[drink setName:@"Best Drink"];
	
	// add entries in the order from least to greatest,
	// because [loadPlayerSettings] will end with the last
	// match.
	
	[drink addID:  159 withBuffID:  430];  // Refreshing Spring Water
	[drink addID: 1179 withBuffID:  431];  // Ice Cold Milk  (lv 5)
	[drink addID: 1205 withBuffID:  432];  // Melon Juice (lv 15)
	[drink addID: 1708 withBuffID: 1133];  // Sweet Nectar (lv 25)
	[drink addID: 1645 withBuffID: 1135];  // Moonberry Juice (lv 35)
	[drink addID: 8766 withBuffID: 1137];  // Morning Glory Dew (lv 45)
//	[drink addID: ];  // 
	

	[drink loadPlayerItems];
	
	return drink;
}



@end
