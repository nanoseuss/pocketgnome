//
//  InventoryController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/27/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "InventoryController.h"
#import "Controller.h"
#import "MemoryViewController.h"
#import "Offsets.h"
#import "Item.h"
#import "WoWObject.h"
#import "PlayerDataController.h"
#import "Player.h"

@interface InventoryController ()
- (void)reloadItemData;
@end

@implementation InventoryController

static InventoryController *sharedInventory = nil;

+ (InventoryController *)sharedInventory {
	if (sharedInventory == nil)
		sharedInventory = [[[self class] alloc] init];
	return sharedInventory;
}

- (id) init
{
    self = [super init];
	if(sharedInventory) {
		[self release];
		self = sharedInventory;
	} else if(self != nil) {
        sharedInventory = self;
        _itemList = [[NSMutableArray array] retain];
        _itemDataList = [[NSMutableArray array] retain];
		_itemsPlayerIsWearing = nil;
		_itemsInBags = nil;

		// set to 20 to ensure it updates right away
		_updateDurabilityCounter = 20;
		
		self.updateFrequency = 1.0f;

        // load in item names
        id itemNames = [[NSUserDefaults standardUserDefaults] objectForKey: @"ItemNames"];
        if(itemNames) {
            _itemNameList = [[NSKeyedUnarchiver unarchiveObjectWithData: itemNames] mutableCopy];            
        } else
            _itemNameList = [[NSMutableDictionary dictionary] retain];
        
        // notifications
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:) 
                                                     name: NSApplicationWillTerminateNotification 
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(itemNameLoaded:) 
                                                     name: ItemNameLoadedNotification 
                                                   object: nil];
      
        [NSBundle loadNibNamed: @"Items" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
	
	self.updateFrequency = [[NSUserDefaults standardUserDefaults] floatForKey: @"InventoryControllerUpdateFrequency"];
	[_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f target: self selector: @selector(reloadItemData) userInfo: nil repeats: YES];
    
    [itemTable setDoubleAction: @selector(itemTableDoubleClick:)];
    [itemTable setTarget: self];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize updateFrequency;

- (NSString*)sectionTitle {
    return @"Items";
}


- (void)setUpdateFrequency: (float)frequency {
    if(frequency < 0.5) frequency = 0.5;
    
    [self willChangeValueForKey: @"updateFrequency"];
    updateFrequency = [[NSString stringWithFormat: @"%.2f", frequency] floatValue];
    [self didChangeValueForKey: @"updateFrequency"];
    
    [[NSUserDefaults standardUserDefaults] setFloat: updateFrequency forKey: @"InventoryControllerUpdateFrequency"];
	
    [_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval: frequency target: self selector: @selector(reloadItemData) userInfo: nil repeats: YES];
}

#pragma mark -

- (void)applicationWillTerminate: (NSNotification*)notification {
    [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: _itemNameList] forKey: @"ItemNames"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)itemNameLoaded: (NSNotification*)notification {
    Item *item = (Item*)[notification object];
    
    NSString *name = [item name];
    if(name) {
        // PGLog(@"Saving item: %@", item);
        [_itemNameList setObject: name forKey: [NSNumber numberWithInt: [item entryID]]];
    }
}

#pragma mark -

- (Item*)itemForGUID: (GUID)guid {
	NSArray *itemList = [[_itemList copy] autorelease];

    for(Item *item in itemList) {
        if( [item GUID] == guid )
            return [[item retain] autorelease];
    }
    return nil;
}

- (Item*)itemForID: (NSNumber*)itemID {
    if( !itemID || [itemID intValue] <= 0) return nil;
	NSArray* itemList = [[_itemList copy] autorelease];
    for(Item *item in itemList) {
        if( [itemID isEqualToNumber: [NSNumber numberWithInt: [item entryID]]] )
            return [[item retain] autorelease];
    }
    return nil;
}

- (Item*)itemForName: (NSString*)name {
    if(!name || ![name length]) return nil;
    for(Item* item in _itemList) {
        if([item name]) {
            NSRange range = [[item name] rangeOfString: name 
                                               options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound && [item isValid])
                return [[item retain] autorelease];
        }
    }
    return nil;
}

- (NSString*)nameForID: (NSNumber*)itemID {
    NSString *name = [_itemNameList objectForKey: itemID];
    if(name) return name;
    return [NSString stringWithFormat: @"%@", itemID];
}

- (int)collectiveCountForItem: (Item*)refItem {
    if(![refItem isValid]) return 0;
    int count = 0;
    for(Item* item in _itemList) {
        if([item entryID] == [refItem entryID]) { // they are the same type of item
            count += [item count];
        }
    }
    //PGLog(@"Found count %d for item %@", count, refItem);
    return count;
}

- (int)collectiveCountForItemInBags: (Item*)refItem{
	if(![refItem isValid]) return 0;
    int count = 0;
    for(Item* item in [self itemsInBags]) {
        if([item entryID] == [refItem entryID]) { // they are the same type of item
            count += [item count];
        }
    }
    //PGLog(@"Found count %d for item %@", count, refItem);
    return count;
}

- (BOOL)trackingItem: (Item*)anItem {
    for(Item *item in _itemList) {
        if( [item isEqualToObject: anItem] )
            return YES;
    }
    return NO;
}

- (void)addAddresses: (NSArray*)addresses {
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    NSMutableArray *dataList = _itemList;
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(![memory isValid]) return;
    
    [self willChangeValueForKey: @"itemCount"];
	
    // enumerate current object addresses
    // determine which objects need to be removed
    for(WoWObject *obj in dataList) {
		
		NSNumber *address = [NSNumber numberWithInt:[obj baseAddress]];
		
		// update our object on if it's in the master list
		if ( ![addresses containsObject:address] ){
			obj.notInObjectListCounter = 0;
		}
		else{
			obj.notInObjectListCounter++;
		}
		
		// check if we should remove the object
        if(![obj isStale]) {
            [addressDict setObject: obj forKey: [NSNumber numberWithUnsignedLongLong: [obj baseAddress]]];
        } else {
            [objectsToRemove addObject: obj];
        }
    }

    // remove any if necessary
    if([objectsToRemove count]) {
        [dataList removeObjectsInArray: objectsToRemove];
    }
    
    // add new objects if they don't currently exist
	NSDate *now = [NSDate date];
    for(NSNumber *address in addresses) {
        if( ![addressDict objectForKey: address] ) {
            Item *item = [Item itemWithAddress: address inMemory: memory];
            
            // load item name
            NSNumber *itemID = [NSNumber numberWithInt: [item entryID]];
            if([_itemNameList objectForKey: itemID]) {
                [item setName: [_itemNameList objectForKey: itemID]];
            } else if(![item name]) {
                [item loadName];
            }
            
            [dataList addObject: item];            
        }
		else {
			[[addressDict objectForKey: address] setRefreshDate: now];
		}
    }
    
    [self didChangeValueForKey: @"itemCount"];
}


- (void)reloadItemData {

	// why do we only update on every 20th write?
	//	to save memory reads of course!
	if ( _updateDurabilityCounter == 20 ){

		// release the old arrays
		_itemsPlayerIsWearing = nil;
		_itemsInBags = nil;
	
		// grab the new ones
		_itemsPlayerIsWearing = [[self itemsPlayerIsWearing] retain];
		_itemsInBags = [[self itemsInBags] retain];
	
		_updateDurabilityCounter = 0;
	}
	_updateDurabilityCounter++;
	
	if( ![[itemTable window] isVisible])
		return;
	if ( ![playerData playerIsValid:self] )
		return;

	[self willChangeValueForKey: @"collectiveDurability"];
    [self willChangeValueForKey: @"averageItemDurability"];
    [self didChangeValueForKey: @"collectiveDurability"];
    [self didChangeValueForKey: @"averageItemDurability"];
	
    [_itemDataList removeAllObjects];

    NSSortDescriptor *nameDesc = [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease];
    [_itemList sortUsingDescriptors: [NSArray arrayWithObject: nameDesc]];
    
    for(Item *item in _itemList) {
        NSString *durString;
        NSNumber *minDur = [item durability], *maxDur = [item maxDurability], *durPercent = nil;
        if([maxDur intValue] > 0) {
            durString = [NSString stringWithFormat: @"%@/%@", minDur, maxDur];
            durPercent = [NSNumber numberWithFloat: [[NSString stringWithFormat: @"%.2f", 
                                                      (([minDur unsignedIntValue]*1.0)/[maxDur unsignedIntValue])*100.0] floatValue]];
        } else {
            durString = @"-";
            durPercent = [NSNumber numberWithFloat: 101.0f];
        }
		
		// where is the item?
		NSString *location = @"Bank";
		if ( [_itemsPlayerIsWearing containsObject:item] ){
			location = @"Wearing";
		}
		else if ( [_itemsInBags containsObject:item] ){
			location = @"Player Bag";
		}
		else if ( [item itemType] == ItemType_Money || [item itemType] == ItemType_Key ){
			location = @"Player";
		}
        
        [_itemDataList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                   item,                                                @"Item",
                                   ([item name] ? [item name] : @""),                   @"Name",
                                   [NSNumber numberWithUnsignedInt: [item cachedEntryID]],    @"ItemID",
                                   [NSNumber numberWithUnsignedInt: [item isBag] ? [item bagSize] : [item count]],      @"Count",
                                   [item itemTypeString],                               @"Type",
                                   [item itemSubtypeString],                            @"Subtype",
                                   durString,                                           @"Durability",
                                   durPercent,                                          @"DurabilityPercent",
								   location,											@"Location",
                                   nil]];
    }
    [_itemDataList sortUsingDescriptors: [itemTable sortDescriptors]];
    [itemTable reloadData];
    //PGLog(@"enumerateInventory took %.2f seconds...", [date timeIntervalSinceNow]*-1.0);
}

- (void)resetInventory {
    [self willChangeValueForKey: @"itemCount"];
    [_itemList removeAllObjects];
    [self didChangeValueForKey: @"itemCount"];
}

- (unsigned)itemCount {
    return [_itemList count];
}

#pragma mark -

// this gets the average durability level over all items with durability
- (float)averageItemDurability {
    float durability = 0;
    int count = 0;
    for(Item *item in _itemList) {
        if([[item maxDurability] unsignedIntValue]) {
            durability += (([[item durability] unsignedIntValue]*1.0)/[[item maxDurability] unsignedIntValue]);
            count++;
        }
    }
    return [[NSString stringWithFormat: @"%.2f", durability/count*100.0] floatValue];
}

// this gets the durability average of everything as if it was one item
- (float)collectiveDurability {
    unsigned curDur = 0, maxDur = 0;
    for(Item *item in _itemList) {
        curDur += [[item durability] unsignedIntValue];
        maxDur += [[item maxDurability] unsignedIntValue];
    }
    return [[NSString stringWithFormat: @"%.2f", (1.0*curDur)/(1.0*maxDur)*100.0] floatValue];
}

- (float)averageWearableDurability{
    float durability = 0;
    int count = 0;
    for(Item *item in _itemsPlayerIsWearing) {
        if([[item maxDurability] unsignedIntValue]) {
            durability += (([[item durability] unsignedIntValue]*1.0)/[[item maxDurability] unsignedIntValue]);
            count++;
        }
    }
	
    return [[NSString stringWithFormat: @"%.2f", durability/count*100.0] floatValue];
}

- (float)collectiveWearableDurability;{
    unsigned curDur = 0, maxDur = 0;
    for(Item *item in _itemsPlayerIsWearing) {
        curDur += [[item durability] unsignedIntValue];
        maxDur += [[item maxDurability] unsignedIntValue];
    }
    return [[NSString stringWithFormat: @"%.2f", (1.0*curDur)/(1.0*maxDur)*100.0] floatValue];
}

#pragma mark -

- (NSArray*)inventoryItems {
    return [[_itemList retain] autorelease];
}

- (NSMenu*)inventoryItemsMenu {
    
    NSMenuItem *menuItem;
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Items"] autorelease];
    for(Item *item in _itemList) {
        if( [item name]) {
            menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ - %d", [item name], [item entryID]] action: nil keyEquivalent: @""];
        } else {
            menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%d", [item entryID]] action: nil keyEquivalent: @""];
        }
        [menuItem setTag: [item entryID]];
        [menu addItem: [menuItem autorelease]];
    }
    
    if( [_itemList count] == 0) {
        menuItem = [[NSMenuItem alloc] initWithTitle: @"There are no available items." action: nil keyEquivalent: @""];
        [menuItem setTag: 0];
        [menu addItem: [menuItem autorelease]];
    }
    
    return menu;
}


- (NSMenu*)usableInventoryItemsMenu {
    
    // first, coalesce items
    NSMutableDictionary *coalescedItems = [NSMutableDictionary dictionary];
    for(Item *item in _itemList) {
        if( [item charges] > 0) {
            NSNumber *entryID = [NSNumber numberWithUnsignedInt: [item entryID]];
            NSMutableArray *list = nil;
            if( (list = [coalescedItems objectForKey: entryID]) ) {
                [list addObject: item];
            } else {
                [coalescedItems setObject: [NSMutableArray arrayWithObject: item] forKey: entryID];
            }
        }
    }
    
    // now sort those items so they are in alphabetical order
    NSMutableArray *nameMap = [NSMutableArray array];
    for(NSNumber *key in [coalescedItems allKeys]) {
        [nameMap addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                             [self nameForID: key],                 @"name", 
                             [self itemForID: key],                 @"item",
                             [coalescedItems objectForKey: key],    @"list", nil]];
    }
    [nameMap sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease]]];
   
    // finally generate the NSMenu from the sorted list of coalesced items 
    NSMenuItem *menuItem;
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Items"] autorelease];
    for(NSDictionary *dict in nameMap) {
        Item *keyItem = [dict objectForKey: @"item"];
        NSArray *itemList = [dict objectForKey: @"list"];
        int count = 0;
        for(Item *item in itemList) {
            count += [item count];
        }
        
        // if we have 0 of this item, don't include it
        if( count > 0 ) {
            int entryID = [keyItem entryID];
            if( [keyItem name] ) {
                menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ [x%d] (%d)", [keyItem name], count, entryID] action: nil keyEquivalent: @""];
            } else {
                menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%d [x%d]", entryID, count] action: nil keyEquivalent: @""];
            }
            [menuItem setTag: entryID];
            [menu addItem: [menuItem autorelease]];
        }
    }
    
    if( [_itemList count] == 0) {
        menuItem = [[NSMenuItem alloc] initWithTitle: @"There are no available items." action: nil keyEquivalent: @""];
        [menuItem setTag: 0];
        [menu addItem: [menuItem autorelease]];
    }
    
    return menu;
}

- (NSMenu*)prettyInventoryItemsMenu {
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Pretty Items"] autorelease];
    
    NSMenu *useItems = [self usableInventoryItemsMenu];
    NSMenu *allItems = [self inventoryItemsMenu];
    NSMenuItem *anItem;
    
    // make "Usable Items" header
    anItem = [[[NSMenuItem alloc] initWithTitle: @"Usable Items" action: nil keyEquivalent: @""] autorelease];
    [anItem setAttributedTitle: [[[NSAttributedString alloc] initWithString: @"Usable Items" 
                                                                 attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
    [anItem setTag: 0];
    [menu addItem: anItem];
    
    for(NSMenuItem *item in [useItems itemArray]) {
        NSMenuItem *newItem = [item copy];
        [newItem setIndentationLevel: 1];
        [menu addItem: [newItem autorelease]];
    }
    
    [menu addItem: [NSMenuItem separatorItem]];
    
    // make "All Items" header
    anItem = [[[NSMenuItem alloc] initWithTitle: @"All Items" action: nil keyEquivalent: @""] autorelease];
    [anItem setTag: 0];
    [anItem setAttributedTitle: [[[NSAttributedString alloc] initWithString: @"All Items" 
                                                                 attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
    [menu addItem: anItem];
    
    for(NSMenuItem *item in [allItems itemArray]) {
        NSMenuItem *newItem = [item copy];
        [newItem setIndentationLevel: 1];
        [menu addItem: [newItem autorelease]];
    }
    
    return menu;
}

- (int)pvpMarks{
	
	int stacks = 0;
	for ( Item *item in _itemList ){
		
		switch ( [item entryID] ){
			case 20560:		// Alterac Valley Mark of Honor
			case 20559:		// Arathi Basin Mark of Honor
			case 29024:		// Eye of Storm Mark of Honor
			case 47395:		// Isle of Conquest Mark of Honor
			case 42425:		// Strand of the Ancients Mark of Honor
			case 20558:		// Warsong Gulch Mark of Honor
				stacks += [item count];
				break;
		}
	}
	
	return stacks;	
}

// return an array of items for an array of guids
- (NSArray*)itemsForGUIDs: (NSArray*) guids{
	NSMutableArray *items = [NSMutableArray array];
	
	for ( NSNumber *guid in guids ){
		Item *item = [self itemForGUID:[guid longLongValue]];
		if ( item ){
			[items addObject:item];
		}
	}
	
	return items;	
}

// return ONLY the items the player is wearing (herro % durability calculation)
- (NSArray*)itemsPlayerIsWearing{
	NSArray *items = [self itemsForGUIDs:[[playerData player] itemGUIDsPlayerIsWearing]];
	return [[items retain] autorelease];	
}

// will return an array of type Item
- (NSArray*)itemsInBags{
	
	// will store all of our items
	NSMutableArray *items = [NSMutableArray array];
	
	// grab the GUIDs of our bags
	NSArray *GUIDsBagsOnPlayer = [[playerData player] itemGUIDsOfBags];
	
	// loop through all of our items to find
	for ( Item *item in _itemList ){
		NSNumber *itemContainerGUID = [NSNumber numberWithLongLong:[item containerUID]];
		
		if ( [GUIDsBagsOnPlayer containsObject:itemContainerGUID] ){
			[items addObject:item];
		}
	}
	
	// start with the GUIDs of the items in our backpack
	NSArray *backpackGUIDs = [[playerData player] itemGUIDsInBackpack];
	
	// loop through our backpack guids
	for ( NSNumber *guid in backpackGUIDs ){
		Item *item = [self itemForGUID:[guid longLongValue]];
		if ( item ){
			[items addObject:item];
		}
	}
	
	return [[items retain] autorelease];	
}

- (int)bagSpacesAvailable{
	return [self bagSpacesTotal] - [[self itemsInBags] count];	
}

- (int)bagSpacesTotal{
	
	// grab all of the bags ON the player
	NSArray *bagGUIDs = [[playerData player] itemGUIDsOfBags];
	int totalBagSpaces = 16; // have to start w/the backpack size!
	// loop through our backpack guids
	for ( NSNumber *guid in bagGUIDs ){
		Item *item = [self itemForGUID:[guid longLongValue]];
		if ( item ){
			totalBagSpaces += [item bagSize];
		}
	}
	
	return totalBagSpaces;
}

- (BOOL)arePlayerBagsFull{
	//PGLog(@"%d == %d", [self bagSpacesAvailable], [self bagSpacesTotal]);
	return [self bagSpacesAvailable] == 0;
}


#pragma mark -
#pragma mark TableView Delegate & Datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_itemDataList count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1) return nil;

    return [[_itemDataList objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [_itemDataList sortUsingDescriptors: [itemTable sortDescriptors]];
    [itemTable reloadData];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (void)itemTableDoubleClick: (id)sender {
    if( [sender clickedRow] == -1 ) return;
    
    [memoryViewController showObjectMemory: [[_itemDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Item"]];
    [controller showMemoryView];
}


@end
