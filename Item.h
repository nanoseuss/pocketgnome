/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import <Cocoa/Cocoa.h>
#import "MemoryAccess.h"
#import "WoWObject.h"

#define ItemNameLoadedNotification @"ItemNameLoadedNotification"

typedef enum {
	ItemType_Consumable     = 0,
	ItemType_Container,
	ItemType_Weapon,
	ItemType_Gem,
	ItemType_Armor,
	ItemType_Reagent,
	ItemType_Projectile,
	ItemType_TradeGoods,
	ItemType_Generic,
	ItemType_Recipe,
	ItemType_Money,
	ItemType_Quiver,
	ItemType_Quest,
	ItemType_Key,
	ItemType_Permanent,
	ItemType_Misc,
	ItemType_Glyph,
    ItemType_Max            = 16
} ItemType;

@interface Item : WoWObject {
    NSString *_name;
    
    NSURLConnection *_connection;
    NSMutableData *_downloadData;
}
+ (id)itemWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

- (NSString*)name;
- (void)setName: (NSString*)name;
- (void)loadName;

- (ItemType)itemType;
- (NSString*)itemTypeString;
+ (NSString*)stringForItemType: (ItemType)type;

- (NSString*)itemSubtypeString;

- (GUID)ownerUID;
- (GUID)containerUID;
- (GUID)creatorUID;
- (GUID)giftCreatorUID;
- (UInt32)count;
- (UInt32)duration;
- (UInt32)charges;
- (NSNumber*)durability;
- (NSNumber*)maxDurability;

- (UInt32)flags;
- (UInt32)infoFlags;
- (UInt32)infoFlags2;

// Enchantment info
- (UInt32)hasPermEnchantment;
- (UInt32)hasTempEnchantment;

- (BOOL)isBag;
- (BOOL)isSoulbound;

- (UInt32)bagSize;
- (UInt64)itemUIDinSlot: (UInt32)slotNum;

@end
