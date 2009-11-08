//
//  Player.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/25/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Unit.h"


enum ePlayerFields {
	PlayerField_Flags                           = 0x3B0, // 3.1: need to verify this!

	// every 0x8 is the full 64-bit GUID of an item the player is wearing
    PlayerField_CharacterSlot                   = 0x4A8, // goes through 0x538
	PlayerField_BagStart						= 0x540, // 4 bag GUIDs will be listed starting here
	PlayerField_BackPackStart					= 0x560, // all items go through 0x5D8, these are the GUIDs of items in the backpack
	PlayerField_BankStart						= 0x5E0, // these items are in the bank (NOT in bags)
	PlayerField_BankBags						= 0x6F0, // these are the GUIDs of the BAGS in your bank
	PlayerField_Keys							= 0x758, // player keys
	PlayerField_Marks							= 0x858, // player marks/emblems (currency)

    // PlayerField_FarSight                     = 0xE68, // 3.1 unknown
    // PlayerField_ComboPoint_Target            = 0xE70, // 3.1 unknown

	PlayerField_Experience                      = 0x980,
	PlayerField_NextLevel_Experience            = 0x984,

	PlayerField_TrackResources					= 0xF94,	// 3.2.2b
	
    PlayerField_RestState_Experience            = 0x11DC, // rest experience remaining
    PlayerField_Coinage                         = 0x11E0, // in copper
	
    // 3.1 unknown
    // PlayerField_ManaRegen                       = 0x1870, // (float, per second)
    // PlayerField_ManaRegen_Combat                = 0x1874, // (float, per second)
    PlayerField_MaxLevel                        = 0x1380,
	
	PlayerField_Honor							= 0x138C,
	PlayerField_ArenaPoints						= 0x1390,
	PlayerField_Level							= 0x1394,		// speculation - not sure needs testing
	
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

@interface Player : Unit {
    UInt32 _nameEntryID;
}

+ (id)playerWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

// status
- (BOOL)isGM;

- (GUID)itemGUIDinSlot: (CharacterSlot)slot;    // invalid for other players

- (NSArray*)itemGUIDsInBackpack;
- (NSArray*)itemGUIDsOfBags;
- (NSArray*)itemGUIDsPlayerIsWearing;
@end
