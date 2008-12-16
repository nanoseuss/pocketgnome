/*
 *  Offsets.h
 *  Pocket Gnome
 *
 *  Created by Jon Drummond on 12/15/07.
 *  Copyright 2007 Savory Software, LLC. All rights reserved.
 *
 */
 
#import "ObjectConstants.h"

#define VALID_WOW_VERSION   @"3.0.3"
#define PLAYER_LEVEL_CAP    70

// not valid for PPC!
// 3.0.2 valid
#define PLAYER_NAME_STATIC          ((IS_X86) ? 0x14A27E8 : 0x0)        // 3.0.2
                                             // 0x149E668 : 0x0)        // 3.0.2
                                             // 0xEB1C88 : 0xECAD68)    // 2.4.3
#define SERVER_NAME_STATIC          ((IS_X86) ? 0x14A2C46 : 0x0)        // 3.0.3
                                             // 0x149EAC6 : 0x0)        // 3.0.2
                                             // 0xEB1EA6 : 0xECAF7E)    // 2.4.3
#define ACCOUNT_NAME_STATIC         ((IS_X86) ? 0x14A2940 : 0x0)        // 3.0.3
                                             // 0x149E7C0 : 0x0)        // 3.0.2
                                             // 0xEB1DE0 : 0xECAEC0) // 2.4.3
                                             // 0xEB0B28 : 0xEC8D88  // 2.4.2
                                             // 0xEB0D46 : 0xEC8F9E  // 2.4.2
                                             // 0xEB0C80 : 0xEC8EE0  // 2.4.2

// 3.0.3 valid
#define PLAYER_GUID_STATIC          ((IS_X86) ? 0xB70980 : 0x0) // 3.0.2(0xB6C960)
#define OBJECT_LIST_PTR_STRUCT_ID   ((IS_X86) ? 0xB96C08 : 0x0) // 3.0.2(0xB92BC8)

// 2.4.2 valid
// NO LONGER VALID AS OF 3.0.2
#define PLAYER_STRUCT_PTR_STATIC    ((IS_X86) ? 0x9BA490 : 0x9E2460) // 2.4.3 (0x1DA0 : 0xD70);
                                             // 0x9BC230 : 0x9E31D0  // 2.4.2
                                             // 0x9B3210 : 0x9D81B0  // 2.4.1
                                                        // 0x9D91B0 2.4.0 // 0x5B350 diffPPC
                                 /* 0x96D3B0 2.3.3 Intel : 0x97DE60 2.3.3 PPC */
                                                        /* 0x97DE50 2.3.2 PPC */
                                                        /* 0x977E10 2.3.0 PPC */
              
enum eObjectBase {
   OBJECT_BASE_ID           = 0x0, // Type: Int32, Size: 1
   OBJECT_FIELDS_PTR        = 0x4, // Type: Int32, Size: 1
   OBJECT_FIELDS_END_PTR    = 0x8, // Type: Int32, Size: 1
   OBJECT_UNKNOWN1          = 0xC, // Type: Int32, Size: 1
   OBJECT_TYPE_ID           = 0x10, // Type: Int32, Size: 1
   OBJECT_GUID_LOW32        = 0x14, // Type: Int32, Size: 1
   OBJECT_STRUCT1_POINTER   = 0x18, // other struct ptr
   OBJECT_STRUCT2_POINTER   = 0x1C, // "parent?"
   // 0x20 is a duplicate of the value at 0x34
   OBJECT_STRUCT5_POINTER   = 0x24,
   OBJECT_GUID_ALL64        = 0x28, // GUID
   OBJECT_STRUCT3_POINTER   = 0x30, // "previous?"
   OBJECT_STRUCT4_POINTER   = 0x34, // "next?"
};

enum eObjectFields {
   OBJECT_FIELD_GUID                             = 0x0  , // Type: Guid , Size: 2
   OBJECT_FIELD_TYPE                             = 0x8  , // Type: Int32, Size: 1
   OBJECT_FIELD_ENTRY                            = 0xC  , // Type: Int32, Size: 1
   OBJECT_FIELD_SCALE_X                          = 0x10 , // Type: Float, Size: 1
   OBJECT_FIELD_PADDING                          = 0x14 , // Type: Int32, Size: 1
};


enum eCorpseFields {
   CORPSE_FIELD_OWNER                            = 0x18 , // Type: Guid , Size: 2
   CORPSE_FIELD_FACING                           = 0x20 , // Type: Float, Size: 1
   CORPSE_FIELD_POS_X                            = 0x24 , // Type: Float, Size: 1
   CORPSE_FIELD_POS_Y                            = 0x28 , // Type: Float, Size: 1
   CORPSE_FIELD_POS_Z                            = 0x2C , // Type: Float, Size: 1
   CORPSE_FIELD_DISPLAY_ID                       = 0x30 , // Type: Int32, Size: 1
   CORPSE_FIELD_ITEM                             = 0x34 , // Type: Int32, Size: 19
   CORPSE_FIELD_BYTES_1                          = 0x80 , // Type: Chars, Size: 1
   CORPSE_FIELD_BYTES_2                          = 0x84 , // Type: Chars, Size: 1
   CORPSE_FIELD_GUILD                            = 0x88 , // Type: Int32, Size: 1
   CORPSE_FIELD_FLAGS                            = 0x8C , // Type: Int32, Size: 1
   CORPSE_FIELD_DYNAMIC_FLAGS                    = 0x90 , // Type: Int32, Size: 1
   CORPSE_FIELD_PAD                              = 0x94 , // Type: Int32, Size: 1
};

// 2.4.3 valid
#define COMBO_POINTS_STATIC         ((IS_X86) ? 0xB720B0 : 0x0) // 3.0.3
                                             // 0xB6E06C : 0x0) // 3.0.2
                                             // 0x9AF048 : 0x9D7C6D) // 2.4.3
                                             // 0x9B1008 : 0x9D8C55) // 2.4.2
                                             // 0x9A8008 : 0x9CDC5D) // 2.4.1
#define COMBO_POINTS_TABLE_STATIC   ((IS_X86) ? 0xB720B0 : 0x0) // same as above on Intel
                                             // 0x9AF048 : 0x9D7C70) // 2.4.3
                                             // 0x9B1008 : 0x9D8C58) // 2.4.2
                                             // 0x9A8008 : 0x9CDC60) // 2.4.1
#define COMBO_POINT_VALUE           0x0   // appears 0xY000000 on PPC, Y on x86
#define COMBO_POINT_TARGET_UID      0x8   // 64 bit
// in 3.0.x, the current time appears globally +0xC after COMBO_POINTS_STATIC

// this is not used, and i'm currently not entirely sure what it means
// the name is just a guess.
#define PLAYER_LOGGED_IN    ((IS_X86) ? 0xB720DC : 0x0) // 3.0.3

// there's another interesting struct between combo points and targets
// but i don't know what it does yet

// 3.0.3 valid 
#define TARGET_TABLE_STATIC ((IS_X86) ? 0xB72170 : 0x0) // 3.0.3
                                     // 0xB6E128 3.0.2
                                     // 0x9AF0F8 : 0x9D7D20  // 2.4.3
                                     // 0x9B10C0 : 0x9D8D10) // 2.4.2
                                     // 0x9A80C0 : 0x9CDD18) // 2.4.1
                                                // 0x9CED18 in 2.4.0
                                                // 0x9744B8 in 2.3.3
                                                // 0x9744A8 in 2.3.2
                                                // 0x96e490 in 2.3.0
// {
    #define TARGET_FOCUS        0x00 /* GUID. 0xFFFFFFFF or 0 means invalid */
    #define TARGET_UNKNOWN1     0x10 /* GUID; possibly "2nd last" target*/
    #define TARGET_LAST         0x18 /* GUID */
    #define TARGET_CURRENT      0x20 /* GUID */
    #define TARGET_INTERACT     0x28 /* GUID */
    #define TARGET_MOUSEOVER    0x30 /* GUID */
// }

// 3.0.3 valid  
#define KNOWN_SPELLS_STATIC             ((IS_X86) ? 0x1553E80 : 0x0) // 3.0.3
                                                 // 0x154FB40 : 0x0) // 3.0.2
                                                // 0xF479E0 : 0xF60698  // 2.4.3
                                                // 0xF3F240 : 0xF57068  // 2.4.2
                                                // 0xF357E0 : 0xF4B398) // 2.4.1
                                 /* 0xED9D80 2.3.3 Intel : 0xEDB2E0 2.3.3 PPC */
                                                       /* 0xEDB2D0 in 2.3.2 */
                                                       /* 0xED1C10 in 2.3.0 */
#define KNOWN_SPELLS_TOP_RANK_STATIC    ((IS_X86) ? 0x1552E80 : 0x0) // 3.0.3
                                                 // 0x154EB40 : 0x0) // 3.0.2
                                                // 0xF469E0 : 0xF5F698) // 2.4.3
                                                // 0xF3E240 : 0xF56068  // 2.4.2
                                                // 0xF347E0 : 0xF4A398  // 2.4.1

// 3.0.3 valid
// static main hotbar ( uint32[12], spell ID)
#define HOTBAR_BASE_STATIC  ((IS_X86) ? 0x1545E20 : 0x0) // 3.0.3
                                     // 0x1541AE0 : 0x0) // 3.0.2
                                     // 0xF3A980 : 0xF53680) // 2.4.3
                                     // 0xF397E0 : 0xF51650) // 2.4.2
                                     // 0xF2FD80 : 0xF45980) // 2.4.1
#define BAR1_OFFSET         0x0     // main hotbar
#define BAR2_OFFSET         0x30    // 2nd hotbar
#define BAR3_OFFSET         0x60    // 3rd hotbar (right bar 1)
#define BAR4_OFFSET         0x90    // 4th hotbar (right bar 2)
#define BAR5_OFFSET         0xC0    // 5th hotbar (bottom right)
#define BAR6_OFFSET         0xF0    // 6th hotbar (bottom left)
#define BAR7_OFFSET         0x120   // 7th hotbar (form: ie, shadowform, battle stance)
#define BAR8_OFFSET         0x150   // 8th hotbar (form2: defensive stance)
#define BAR9_OFFSET         0x180   // 9th hotbar (form3? beserker stance?)
#define BAR10_OFFSET        0x1B0   // 10th hotbar (unknown)
                                                
                                                // 0xF3EEC0 2.4.1 PPC
                                                // 0xED7980 2.3.3 PPC
                                                // 0xED7970 2.3.2 PPC

// 3.0.3 valid  
#define PLAYER_ON_BUILDING_STATIC           ((IS_X86) ? 0x11F4D0C : 0x0)        // 3.0.3
                                                     // 0x11F0BAC : 0x0)        // 3.0.2
                                                     // 0xCAA0AC : 0xCC39EC)    // 2.4.2

// both of these are busted in 3.0.2
/* is the number of the last spell we tried to cast, nomatter if it went off or didn't */
// shows up when you click a 'white' labeled spell
// #define LAST_SPELL_ATTEMPTED_CAST_STATIC    ((IS_X86) ? 0xCE8DD0 : 0xD03760) // 2.4.3
                                                     // 0xCE8650 : 0xD02138) // 2.4.2
                                                     // 0xCDEFF0 : 0xCF6858) // 2.4.1
                                                                // 0xCF6DA0 2.4.0
                                                                // 0xC94980 2.3.3

/* goes 0 if a spell fails (most of the time), spell id if it cast or started casting */
// #define LAST_SPELL_ACTUALLY_CAST_STATIC     ((IS_X86) ? 0xCECEF0 : 0xD07874) // 2.4.3
                                                     // 0xCE2D10 : 0xCFA56C) // 2.4.2
                                                     // 0xCE2D10 : 0xCFA56C) // 2.4.1
                                                                // 0xC9869C 2.3.3
// 3.0.2 valid
// as of 3.0.2, this value is 0 if a spell successfully cast
// if the spell did not cast, it contains the ID of the most recently failed spell
#define LAST_SPELL_THAT_DIDNT_CAST_STATIC   ((IS_X86) ? 0x1227C98 : 0x0) // 3.0.3
                                                     // 0x1223B38 : 0x0) // 3.0.2

// 3.0.3 valid 
#define REFRESH_DELAY           ((IS_X86) ? 0x123B5E0 : 0x0) // 3.0.3
                                         // 0x1237480 : 0x0) // 3.0.2
// {
    #define REFRESH_MAX_FPS     ((IS_X86) ? 0x08 : 0x0)  // /console maxfps, /console maxfpsbk
// }

// 3.0.3 valid
/* 1 if it's open, 0 if it's not */
#define CHAT_BOX_OPEN_STATIC    ((IS_X86) ? 0xBF4500 : 0x0) // 3.0.3
                                         // 0xBF03A0 : 0x0) // 3.0.2
                                         // 0xA294C0 : 0xA42F08) // 2.4.3
                                         // 0xA2A5A0 : 0xA43158) // 2.4.2 
                                         // 0xA20F40 : 0xA37880) // 2.4.1 
                                         // 0xA37DD0 2.4.1 PPC
                                         // 0x9D79E0 2.3.3 PPC


//#define MOVEMENT_FLAGS                              0xC10
// 0x80000001 - move forward
// 0x80000002 - move backward
// 0x80000004 - strafe left
// 0x80000008 - strafe right

// 0x80000010 - turn left
// 0x80000020 - turn left

// 0x80001000 - jumping

// 0x80200000 - swimming

// 0x81000000 - air mounted, on the ground
// 0x83000400 - air mounted, in the air
// 0x83400400 - air mounted, going up (spacebar)
// 0x83800400 - air mounted, going down (sit key)

/*
#define PLAYER_BUFFS_OFFSET   0xC0   
#define PLAYER_DEBUFFS_OFFSET 0x160 
#define PLAYER_BUFF_SLOTS     40
#define PLAYER_DEBUFF_SLOTS   16

#define MOB_BUFFS_OFFSET        0xC0
#define MOB_DEBUFFS_OFFSET      0x100
#define MOB_BUFF_SLOTS          16
#define MOB_DEBUFF_SLOTS        40
*/
