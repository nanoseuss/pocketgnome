//
//  LootController.m
//  Pocket Gnome
//
//  Created by Josh on 6/7/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "LootController.h"

#import	"Controller.h"
#import "InventoryController.h"
#import "ChatController.h"
#import "PlayerDataController.h"
#import "OffsetController.h"

#import "Item.h"
#import "Offsets.h"


// TO DO: Needs to remember all items in the loot window, not just the one :/  But it's a start!

@implementation LootController

- (id)init{
    self = [super init];
    if (self != nil) {
		
		_itemsLooted = [[NSMutableDictionary alloc] init];
		_lastLootedItem = 0;
		
		// Fire off a thread to start monitoring our loot
		[NSThread detachNewThreadSelector: @selector(findLootWindow) toTarget: self withObject: nil];
    }
    return self;
}

@synthesize lastTimeItemWasLooted = _lastTimeItemWasLooted;

- (void)dealloc {
	[_itemsLooted release];
	[super dealloc];
}

- (void)resetLoot{
	[_itemsLooted removeAllObjects];
}

- (NSDictionary*)itemsLooted{
	// We could probably just do dictionaryWithDictionary here, as I beleive this is autoreleased
	// We want to return a copy since a thread is updating the original array and we don't want to be enumerating it while it's updated! (or crash ftl)
	return [[[NSDictionary alloc] initWithDictionary:_itemsLooted] autorelease];
}

- (void)addItem: (int)itemID Quantity:(int)quantity{
	// Lets check to see if we have looted one of these items already!
	NSString *key = [NSString stringWithFormat:@"%d",itemID];
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
	
	_lastTimeItemWasLooted = [playerDataController currentTime];

	[self performSelectorOnMainThread: @selector(itemLooted:)
						   withObject: key
						waitUntilDone: NO];
}

// Running in it's own thread!
- (void)findLootWindow{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	UInt32 lootedItem = 0;
	UInt32 quantity = 0;
	
	MemoryAccess *memory = nil;
	while ( 1 ){
		memory = [controller wowMemoryAccess];
		unsigned long offset = [offsetController offset:@"ITEM_IN_LOOT_WINDOW"];
		if( memory && [memory loadDataForObject: self atAddress: offset Buffer: (Byte *)&lootedItem BufLength: sizeof(lootedItem)]) {
			
			// Then we have a NEW item
			if ( lootedItem > 0 && _lastLootedItem == 0 && _lastLootedItem != lootedItem ){
				_lastLootedItem = lootedItem;
				
				// Grab the quantity!
				[memory loadDataForObject: self atAddress: offset + LOOT_QUANTITY Buffer: (Byte *)&quantity BufLength: sizeof(quantity)];
				
				// Add our item!
				[self addItem:lootedItem Quantity:quantity];
				
				// Are there more to add?
				int i = 1;
				while ([memory loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) Buffer: (Byte *)&lootedItem BufLength: sizeof(lootedItem)] && lootedItem > 0 ){
					// Grab the quantity!
					[memory loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) + LOOT_QUANTITY Buffer: (Byte *)&quantity BufLength: sizeof(quantity)];
					
					// Add our item!
					[self addItem:lootedItem Quantity:quantity];
					
					//PGLog(@"[Loot] Adding an additional item! Item:%d Quantity:%d Slot:%d", lootedItem, quantity, i);
					
					i++;
				}
				
				[self performSelectorOnMainThread: @selector(allItemsLooted)
									withObject: nil
									waitUntilDone: NO];
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

// This should really be called "item is in the window" vs. looted.  No checks are done here to see if the item makes it into your bag
- (void) itemLooted: (NSNumber *) itemID{
	// Call our notifier!
	[[NSNotificationCenter defaultCenter] postNotificationName: ItemLootedNotification object: itemID];
}

- (void) allItemsLooted{
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(allItemsLooted) object: nil];
	
	// Only call our notifier if the loot window isn't open!
	if ( ![self isLootWindowOpen] ){
		[[NSNotificationCenter defaultCenter] postNotificationName: AllItemsLootedNotification object: nil];
	}
	// Lets check again shortly!
	else{
		[self performSelector: @selector(allItemsLooted) withObject: nil afterDelay: 0.1f];
	}
}

#define MAX_ITEMS_IN_LOOT_WINDOW			10		// I don't actually know if this is correct, just an estimate
- (BOOL)isLootWindowOpen{
	UInt32 lootWindowOpen;
	int itemsInWindow = 0, i=0;
	MemoryAccess *memory = [controller wowMemoryAccess];
	while( [memory loadDataForObject: self atAddress: [offsetController offset:@"ITEM_IN_LOOT_WINDOW"] + (LOOT_NEXT * (i)) Buffer: (Byte *)&lootWindowOpen BufLength: sizeof(lootWindowOpen)] && i < MAX_ITEMS_IN_LOOT_WINDOW ){
		if ( lootWindowOpen > 0 ){
			itemsInWindow++;
		}
		
		i++;
	}
	
	if( itemsInWindow > 0 ) {
		return YES;
	}	
	
	return NO;
}

// auto loot? PLAYER_AUTOLOOT{INT} = [Pbase + 0xD8] + 0x1010
- (void)acceptLoot{
	UInt32 item;
	int i = 0;
	unsigned long offset = [offsetController offset:@"ITEM_IN_LOOT_WINDOW"];
	MemoryAccess *memory = [controller wowMemoryAccess];
	while ( [memory loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) Buffer: (Byte *)&item BufLength: sizeof(item)] && i < MAX_ITEMS_IN_LOOT_WINDOW ) {
		if ( item > 0 ){
			// Loot the item!
			[chatController enter];             // open/close chat box
            usleep(100000);
			[chatController sendKeySequence: [NSString stringWithFormat: @"/script LootSlot(%d);%c", i+1, '\n']];
			usleep(500000);
		
			// Check to see if the item is still in memory - if it is then it's a BoP item!  Lets loot it!
			if ( [[controller wowMemoryAccess] loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) Buffer: (Byte *)&item BufLength: sizeof(item)] && item > 0 ){	
				[chatController enter];             // open/close chat box
				usleep(100000);
				[chatController sendKeySequence: [NSString stringWithFormat: @"/script ConfirmLootSlot(%d);%c", i+1, '\n']];
				usleep(500000);
			}
			
			// do it again for the next slot (sometimes the first slot is money! we don't know how to determine this)
			[chatController enter];             // open/close chat box
            usleep(100000);
			[chatController sendKeySequence: [NSString stringWithFormat: @"/script LootSlot(%d);%c", i+2, '\n']];
			usleep(500000);
			
			// Check to see if the item is still in memory - if it is then it's a BoP item!  Lets loot it!
			if ( [[controller wowMemoryAccess] loadDataForObject: self atAddress: offset + (LOOT_NEXT * (i)) Buffer: (Byte *)&item BufLength: sizeof(item)] && item > 0 ){	
				[chatController enter];             // open/close chat box
				usleep(100000);
				[chatController sendKeySequence: [NSString stringWithFormat: @"/script ConfirmLootSlot(%d);%c", i+2, '\n']];
				usleep(500000);
			}
		}
		
		i++;
	}
}

@end
