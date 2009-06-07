//
//  LootController.m
//  Pocket Gnome
//
//  Created by Josh on 6/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LootController.h"

#import	"Controller.h"
#import "InventoryController.h"

#import "Item.h"
#import "Offsets.h"


// TO DO: Needs to remember all items in the loot window, not just the one :/  But it's a start!

@implementation LootController

- (id)init{
    self = [super init];
    if (self != nil) {
		
		_itemsLooted = [[NSMutableDictionary alloc] init];
		 _itemNameList = [[NSMutableDictionary alloc] init];
		_lastLootedItem = 0;
		
		// Fire off a thread to start monitoring our loot
		[NSThread detachNewThreadSelector: @selector(findLootWindow) toTarget: self withObject: nil];
		
        //[NSBundle loadNibNamed: @"Loot" owner: self];
    }
    return self;
}

- (void)dealloc {
	[_itemsLooted release];
	[_itemNameList release];
	
	[super dealloc];
}

@synthesize itemsLooted = _itemsLooted;

// Running in it's own thread!
- (void)findLootWindow{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	UInt32 lootedItem = 0;
	
	while ( 1 ){
		if([[controller wowMemoryAccess] loadDataForObject: self atAddress: ITEM_IN_LOOT_WINDOW Buffer: (Byte *)&lootedItem BufLength: sizeof(lootedItem)]) {
			
			// Then we have a NEW item
			if ( lootedItem > 0 && _lastLootedItem == 0 && _lastLootedItem != lootedItem ){
				_lastLootedItem = lootedItem;
				
				// Lets check to see if we have looted one of these items already!
				NSString *key = [NSString stringWithFormat:@"%d",lootedItem];
				NSNumber *lootCount = [_itemsLooted objectForKey:key];
				
				// We've already caught one of these!  Incremement!
				if ( lootCount != nil ){
					NSNumber *newCount = [NSNumber numberWithInt:[lootCount intValue]+1];
					[_itemsLooted setValue:newCount forKey:key];
					
					//PGLog(@"[Loot] Updating count to %d", [lootCount intValue]+1);
				}
				// New object!  Add it! Woohoo!
				else{
					[_itemsLooted setObject:[NSNumber numberWithInt:1] forKey:key];
					
					//PGLog(@"[Loot] Adding new item!  %@", [itemController nameForID: [NSNumber numberWithInt:lootedItem]]);
				}
				
				// Call our notifier!
				[[NSNotificationCenter defaultCenter] postNotificationName: ItemLootedNotification object: [NSNumber numberWithInt:lootedItem]];
			}
			else if ( lootedItem == 0 ){
				_lastLootedItem = 0;
			}
		}
		
		// Sleep for 0.1 seconds
		usleep(10000);
	}
	
	[pool drain];
}

@end
