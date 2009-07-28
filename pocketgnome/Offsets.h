/*
 *  Offsets.h
 *  Pocket Gnome
 *
 *  Created by Jon Drummond on 12/15/07.
 *  Copyright 2007 Savory Software, LLC. All rights reserved.
 *
 */
 
// heh this file should probably have a more fitting name
 
#import "ObjectConstants.h"

#define VALID_WOW_VERSION   @"3.1.3"
#define PLAYER_LEVEL_CAP    80

// not valid for PPC!
// 3.1.2 valid
#define PLAYER_NAME_STATIC          ((IS_X86) ? 0x139FEC8 : 0x0)		// 3.1.2
											 // 0x1374088 : 0x0)        // 3.1.1
											 // 0x1374028 : 0x0)        // 3.1.0
											 // 0x14A6B28 : 0x0)        // 3.0.9
                                             // 0x14A9B48 : 0x0)        // 3.0.8
                                             // 0x14A27E8 : 0x0)        // 3.0.3
                                             // 0x149E668 : 0x0)        // 3.0.2
                                             // 0xEB1C88 : 0xECAD68)    // 2.4.3



#define SERVER_NAME_STATIC          ((IS_X86) ? 0x13A05A6 : 0x0)		// 3.1.2
											 // 0x1374766 : 0x0)        // 3.1.1
											 // 0x1374706 : 0x0)        // 3.1.0
											 // 0x14A6F86 : 0x0)        // 3.0.9
                                             // 0x14A9FA6 : 0x0)        // 3.0.8                                     
                                             // 0x14A2C46 : 0x0)        // 3.0.3
                                             // 0x149EAC6 : 0x0)        // 3.0.2
                                             // 0xEB1EA6 : 0xECAF7E)    // 2.4.3




#define ACCOUNT_NAME_STATIC         ((IS_X86) ? 0x13A0020 : 0x0)		// 3.1.2
											 // 0x13741E0 : 0x0)        // 3.1.1
											 // 0x1374180 : 0x0)        // 3.1.0
											 // 0x14A6C80 : 0x0)        // 3.0.9
                                             // 0x14A9CA0 : 0x0)        // 3.0.8
                                             // 0x14A2940 : 0x0)        // 3.0.3
                                             // 0x149E7C0 : 0x0)        // 3.0.2
                                             // 0xEB1DE0 : 0xECAEC0) // 2.4.3
                                             // 0xEB0B28 : 0xEC8D88  // 2.4.2
                                             // 0xEB0D46 : 0xEC8F9E  // 2.4.2
                                             // 0xEB0C80 : 0xEC8EE0  // 2.4.2

// 3.1.2 valid	
#define PLAYER_GUID_STATIC          ((IS_X86) ? 0xAC9440 : 0x0)	// 3.1.2
											 // 0xAA3400 : 0x0) // 3.1.0 & 3.1.1
											 // 0xB75420 : 0x0) // 3.0.9
                                             // 0xB78420 : 0x0) // 3.0.8
                                             // 0xB70980 : 0x0) // 3.0.2(0xB6C960)
                       
// 3.1.2 valid
#define OBJECT_LIST_PTR_STRUCT_ID   ((IS_X86) ? 0xAED328 : 0x0) // 3.1.2
											 // 0xAC6F08 : 0x0) // 3.1.0 & 3.1.1
											 // 0xB9BBE8 : 0x0) // 3.0.9
                                             // 0xB9EBE8 : 0x0) // 3.0.8
                                             // 0xB96C08 : 0x0) // 3.0.3 (0xB92BC8)

// 3.1.2 valid
#define COMBO_POINTS_STATIC         ((IS_X86) ? 0xACB12C : 0x0) // 3.1.2
											 // 0xAA508C : 0x0) // 3.1.0 & 3.1.1
											 // 0xB76FD0 : 0x0) // 3.0.9
                                             // 0xB79FD0 : 0x0) // 3.0.8
                                             // 0xB720B0 : 0x0) // 3.0.3
                                             // 0xB6E06C : 0x0) // 3.0.2
                                             // 0x9AF048 : 0x9D7C6D) // 2.4.3
                                             // 0x9B1008 : 0x9D8C55) // 2.4.2
                                             // 0x9A8008 : 0x9CDC5D) // 2.4.1
#define COMBO_POINTS_TABLE_STATIC   ((IS_X86) ? 0xACB12C : 0x0) // same as above on Intel
#define COMBO_POINT_VALUE           0x0   // appears 0xY000000 on PPC, Y on x86
#define COMBO_POINT_TARGET_UID      0x4   // 64 bit
// in 3.0.x, the current time appears globally +0xC after COMBO_POINTS_STATIC

// there's another interesting struct between combo points and targets
// but i don't know what it does yet

// 3.1.2 valid
#define TARGET_TABLE_STATIC ((IS_X86) ? 0xACB210 : 0x0) // 3.1.2
									 // 0xAA5170 : 0x0) // 3.1.0 & 3.1.1
									 // 0xB77090 : 0x0) // 3.0.9
                                     // 0xB7A090 : 0x0) // 3.0.8
                                     // 0xB72170 : 0x0) // 3.0.3
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
    #define TARGET_UNKNOWN1     0x10 /* GUID; possibly "2nd last" target  (as of 3.1.0 this is normally just 0)*/
    #define TARGET_LAST         0x18 /* GUID */
    #define TARGET_CURRENT      0x20 /* GUID */
    #define TARGET_INTERACT     0x28 /* GUID */
    #define TARGET_MOUSEOVER    0x30 /* GUID */
// }

// 3.1.2 valid
#define KNOWN_SPELLS_STATIC             ((IS_X86) ? 0x144BE80 : 0x0) // 3.1.2
												 // 0x1421040 : 0x0) // 3.1.1
												 // 0x141FFE0 : 0x0) // 3.1.0
												 // 0x1558240 : 0x0) // 3.0.9
                                                 // 0x155B260 : 0x0) // 3.0.8
                                                 // 0x1553E80 : 0x0) // 3.0.3
                                                 // 0x154FB40 : 0x0) // 3.0.2
                                                 // 0xF479E0 : 0xF60698  // 2.4.3
                                                 // 0xF3F240 : 0xF57068  // 2.4.2
                                                 // 0xF357E0 : 0xF4B398) // 2.4.1
                                 /* 0xED9D80 2.3.3 Intel : 0xEDB2E0 2.3.3 PPC */
                                                       /* 0xEDB2D0 in 2.3.2 */
                                                       /* 0xED1C10 in 2.3.0 */

// not used yet, but it might be useful for intelligently upgrading behaviors in the future
// it is located -0x1000 from KNOWN_SPELLS_STATIC
// #define KNOWN_SPELLS_TOP_RANK_STATIC    ((IS_X86) ? 0x1557240 : 0x0) // 3.0.9
                                                 // 0x155A260 : 0x0) // 3.0.8
                                                 // 0x1552E80 : 0x0) // 3.0.3
                                                 // 0x154EB40 : 0x0) // 3.0.2
                                                 // 0xF469E0 : 0xF5F698) // 2.4.3
                                                 // 0xF3E240 : 0xF56068  // 2.4.2
                                                 // 0xF347E0 : 0xF4A398  // 2.4.1

// 3.1.2 valid
// static main hotbar ( uint32[12], spell ID)
#define HOTBAR_BASE_STATIC  ((IS_X86) ? 0x143EE40 : 0x0) // 3.1.2
									 // 0x1413000 : 0x0) // 3.1.1
									 // 0x1412FA0 : 0x0) // 3.1.0
									 // 0x154A1E0 : 0x0) // 3.0.9
                                     // 0x154D200 : 0x0) // 3.0.8
                                     // 0x1545E20 : 0x0) // 3.0.3
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

// 3.1.2 valid
#define PLAYER_ON_BUILDING_STATIC       ((IS_X86) ? 0x114A5FC : 0x0)		// 3.1.2
												 // 0x111E81C : 0x0)        // 3.0.9
                                                 // 0x11F8F0C : 0x0)        // 3.0.9
                                                 // 0x11FBF2C : 0x0)        // 3.0.8
                                                 // 0x11F4D0C : 0x0)        // 3.0.3
                                                 // 0x11F0BAC : 0x0)        // 3.0.2
                                                 // 0xCAA0AC : 0xCC39EC)    // 2.4.2

// 3.1.2 valid
// as of 3.0.2, this value is 0 if a spell successfully cast
// if the spell did not cast, it contains the ID of the most recently failed spell
// only works for spells that play an error sound. not sure what makes this distinction.
//
#define LAST_SPELL_THAT_DIDNT_CAST_STATIC   ((IS_X86) ? 0x11730F0 : 0x0) // 3.1.2
													 // 0x11472B0 : 0x0) // 3.1.0
													 // 0x122BB98 : 0x0) // 3.0.9
                                                     // 0x122EBB8 : 0x0) // 3.0.8
                                                     // 0x1227C98 : 0x0) // 3.0.3
                                                     // 0x1223B38 : 0x0) // 3.0.2

#define LAST_SPELL_CAST						((IS_X86) ? 0x1513890 : 0x0) // 3.1.3

// 3.1.2 valid 
#define REFRESH_DELAY           ((IS_X86) ? 0x1517A88 : 0x0) // 3.1.2
										 // 0x115B740 : 0x0) // 3.1.1
										 // 0x1142F4C : 0x0) // 3.1.0
										 // 0x123F8C0 : 0x0) // 3.0.9
                                         // 0x12428E0 : 0x0) // 3.0.8
                                         // 0x123B5E0 : 0x0) // 3.0.3
                                         // 0x1237480 : 0x0) // 3.0.2

// 3.1.2 valid
/* 1 if it's open, 0 if it's not */
#define CHAT_BOX_OPEN_STATIC    ((IS_X86) ? 0xB49DA0 : 0x0) // 3.1.2
										 // 0xB1DFC0 : 0x0) // 3.1.1
										 // 0xB1DF60 : 0x0) // 3.1.0
										 // 0xBF8700 : 0x0) // 3.0.9
                                         // 0xBFB720 : 0x0) // 3.0.8
                                         // 0xBF4500 : 0x0) // 3.0.3
                                         // 0xBF03A0 : 0x0) // 3.0.2
                                         // 0xA294C0 : 0xA42F08) // 2.4.3
                                         // 0xA2A5A0 : 0xA43158) // 2.4.2 
                                         // 0xA20F40 : 0xA37880) // 2.4.1 
                                         // 0xA37DD0 2.4.1 PPC
                                         // 0x9D79E0 2.3.3 PPC


#define ChatLog_Start			((IS_X86) ? 0x13A0E3C : 0x0) // 3.1.2
										 // 0x1374FB0 : 0x0) // 3.1.1


// 3.1.2 valid
#define CAMERA_PTR				((IS_X86) ? 0x139FE44 : 0x0)
#define CAMERA_OFFSET			((IS_X86) ? 0x782C : 0x0)

// 3.1.2 valid - ONLY valid if the player has released
#define CORPSE_STATIC_X			((IS_X86) ? 0x13FA5C0 : 0x0)
#define CORPSE_STATIC_Y			((IS_X86) ? 0x13FA5C4 : 0x0)
#define CORPSE_STATIC_Z			((IS_X86) ? 0x13FA5C8 : 0x0)

// 3.1.2 valid
#define ON_MOUSE_OVER_GUID     ((IS_X86) ? 0xAC6140 : 0x0) // Return the Object GUID of the item under your mouse, who said fishing ?

// 3.1.3 valid
#define ITEM_IN_LOOT_WINDOW	   ((IS_X86) ? 0x143E124 : 0x0 )	// This will ONLY appear while the window is open!
																// Similar version is at 0x011713F - this will REMAIN set if the loot window is closed w/o looting, only difference
// {
#define LOOT_QUANTITY			0x8
#define LOOT_INDEX				0x14
#define LOOT_NEXT				0x20
// }

// Current zone the player is in (ID)
#define PLAYER_CURRENT_ZONE		((IS_X86) ? 0xACA618 : 0x0 )	// Also ACB1CC

// **************************** NOT USED/DATED ******************************************* //


// 3.1.2
#define CORPSE_STATIC_X_RADAR	((IS_X86) ? 0x1301160 : 0x0)
#define CORPSE_STATIC_Y_RADAR	((IS_X86) ? 0x1301164 : 0x0)

// 3.1.2  valid
#define LAST_RED_ERROR_MESSAGE     ((IS_X86) ? 0x013FA620 : 0x0) // Red text error in wow interface

// 3.1.2. valid
#define REFRESH_MAX_FPS     ((IS_X86) ? 0x118768C : 0x0) // 3.1.2 /console maxfps, /console maxfpsbk

// 2.4.2 valid
// NO LONGER VALID AS OF 3.0.2
#define PLAYER_STRUCT_PTR_STATIC    ((IS_X86) ? 0x9BA490 : 0x9E2460) // 2.4.3 (0x1DA0 : 0xD70);
// 0x9BC230 : 0x9E31D0  // 2.4.2
// 0x9B3210 : 0x9D81B0  // 2.4.1
// 0x9D91B0 2.4.0 // 0x5B350 diffPPC
/* 0x96D3B0 2.3.3 Intel : 0x97DE60 2.3.3 PPC */
/* 0x97DE50 2.3.2 PPC */
/* 0x977E10 2.3.0 PPC */


// this is not used, and i'm currently not entirely sure what it means
// the name is just a guess, but it appears to apply.
#define PLAYER_LOGGED_IN    ((IS_X86) ? 0xAA50B4 : 0x0) // 3.1.0				(not 100% sure - but consistent on game close)
// 0xB76FFC : 0x0) // 3.0.9
// 0xB79FFC : 0x0) // 3.0.8 Also: 0xB723E2
// 0xB720DC : 0x0) // 3.0.3


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
