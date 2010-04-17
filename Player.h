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
#import "Unit.h"


enum ePlayerFields {
	PlayerField_Flags                           = 0x3B0, // 3.1: need to verify this!

	// every 0x8 is the full 64-bit GUID of an item the player is wearing
    PlayerField_CharacterSlot                   = 0x510, // 
	PlayerField_BagStart						= 0x5A8, // 4 bag GUIDs will be listed starting here
	PlayerField_BackPackStart					= 0x5C8, // all items go through 0x5D8, these are the GUIDs of items in the backpack
	PlayerField_BankStart						= 0x648, // these items are in the bank (NOT in bags)
	PlayerField_BankBags						= 0x758, // these are the GUIDs of the BAGS in your bank
	PlayerField_Keys							= 0x7C0, // player keys
	PlayerField_Marks							= 0x8C0, // player marks/emblems (currency)

    // PlayerField_FarSight                     = 0xE68, // 3.1 unknown
    // PlayerField_ComboPoint_Target            = 0xE70, // 3.1 unknown

	PlayerField_Experience                      = 0x9E8,
	PlayerField_NextLevel_Experience            = 0x9EC,
	
	PlayerField_QuestInfo						= 0xFF4,	// pointer to a struct (not just quest info...)

	PlayerField_TrackResources					= 0xF94,	// 3.2.2b
	
    PlayerField_RestState_Experience            = 0x1244, // rest experience remaining
    PlayerField_Coinage                         = 0x1248, // in copper
	
    // 3.1 unknown
    // PlayerField_ManaRegen                       = 0x1870, // (float, per second)
    // PlayerField_ManaRegen_Combat                = 0x1874, // (float, per second)
    PlayerField_MaxLevel                        = 0x1380,
	
	PlayerField_Honor							= 0x13F4,
	PlayerField_ArenaPoints						= 0x13F8,
	PlayerField_Level							= 0x13FC,		// speculation - not sure needs testing
	
	PlayerField_QuestStart						= 0x1A30,	// Every 0x10 is another quest ID.. Keep going til you hit 0, that is the full quest list
	
	PlayerField_Haste							= 0x2B00,
};

enum ePlayer_TrackResources_Fields {
	TrackObject_All			= -1,
	TrackObject_None		= 0x0,
	TrackObject_Herbs		= 0x2,
	TrackObject_Minerals	= 0x4,
	TrackObject_Treasure	= 0x20,
	TrackObject_Treasure2	= 0x1000,
	TrackObject_Fish		= 0x40000,
};

enum ePlayer_VisibleItem_Fields {
    VisibleItem_CreatorGUID                     = 0x0,
    VisibleItem_EntryID                         = 0x8,
    VisibleItem_Enchant                         = 0x10,
    // other unknown properties follow
    
    VisibleItem_Size                            = 0x40,
};

typedef enum eCharacterSlot { 
    SLOT_HEAD = 0,
    SLOT_NECK = 1,
    SLOT_SHOULDERS = 2,
    SLOT_SHIRT = 3, 
    SLOT_CHEST = 4, 
    SLOT_WAIST = 5,
    SLOT_LEGS = 6,
    SLOT_FEET = 7, 
    SLOT_WRISTS = 8,
    SLOT_HANDS = 9,
    SLOT_FINGER1 = 10, 
    SLOT_FINGER2 = 11, 
    SLOT_TRINKET1 = 12,
    SLOT_TRINKET2 = 13,
    SLOT_BACK = 14,
    SLOT_MAIN_HAND = 15, 
    SLOT_OFF_HAND = 16, 
    SLOT_RANGED = 17,
    SLOT_TABARD = 18,
    SLOT_EMPTY = 19,
    SLOT_MAX,
} CharacterSlot;

//typedef enum {
//    UnitBloc_Alliance       = 3,
//    UnitBloc_Horde          = 5,
//} UnitBloc;

@class PlayersController;

@interface Player : Unit {
    UInt32 _nameEntryID;
	
	IBOutlet PlayersController *playersController;
}

+ (id)playerWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

// status
- (BOOL)isGM;

- (GUID)itemGUIDinSlot: (CharacterSlot)slot;    // invalid for other players

- (NSArray*)itemGUIDsInBackpack;
- (NSArray*)itemGUIDsOfBags;
- (NSArray*)itemGUIDsPlayerIsWearing;

- (NSString*)name;
@end
