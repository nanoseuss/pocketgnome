/*
 *  OldConstants.h
 *  Pocket Gnome
 *
 *  Created by Jon Drummond on 5/20/08.
 *  Copyright 2008 Savory Software, LLC. All rights reserved.
 *
 */


// 2.4.2 valid
#define GENERIC_UNIT_IDENTIFIER ((IS_X86) ? 0xA00000 : 0x9E0000)
                                          
// player ID 25 0x95E0 0xB060
#define PLAYER_STRUCT_SIGNATURE     ((IS_X86) ? 0xA1ADE8 : 0x9FACD0) // 2.4.2 (8278)
                                             // 0xA11808 : 0x9EFC70  // 2.4.1 (8125)
                                                        // 0x9F01C8 2.4.0 (8089)
                                 /* 0x9C7188 2.3.3 Intel : 0x993EA8 2.3.3 PPC */
                                                       /* 10043032 2.3.2 PPC */
                                                       // 10018392 2.3.0 PPC

// skeleton ID 129
#define SKELETON_IDENTIFIER ((IS_X86) ? 0xA1AFA8 : 0x9FAE78) // 2.4.2

// mob ID 9
#define MOB_IDENTIFIER  ((IS_X86) ? 0xA1CA68 : 0x9FC8D0)  // 2.4.2
                                //  0xA13488 : 0x9F1870)  // 2.4.1
                     // 0x9F1DC8 // 0x5C288 diff
                     // 0x995B40 2.3.3 PPC
                     // 10050352 2.3.2 PPC
                     // 10025608 2.3.0 PPC

// node ID 33
#define NODE_IDENTIFIER ((IS_X86) ? 0xA1C188 : 0x9FBFF8) // 2.4.2
                                 // 0xA12BA8 : 0x9F0F98) // 2.4.1
                      // 0x9F14F0) // 0x5C3C0 diff
                      // 0x995130 2.3.3 PPC
                      // 10047776 2.3.2 PPC
                      // 10023048 2.3.0 PPC

// item ID 3                      
#define ITEM_IDENTIFIER ((IS_X86) ? 0xA1C988 : 0x9FC800) // 2.4.2
                                 // 0xA133A8 : 0x9F17A0) // 2.4.1
                     // 0x9F1CF8 2.4.0 PPC / 0x5C280 diff
                     // 0x995A78 2.3.3 PPC
                     // 10050152 2.3.2 PPC
                     // 10025408 2.3.0 PPC

// bag ID 7
#define BAG_IDENTIFIER  ((IS_X86) ? 0xA1B248 : 0x9FB108) // 2.4.2
                                 // 0xA11C68 : 0x9F00A8) // 2.4.1
                     // 0x9F0600) // 0x5C2F8 diff
                     // 0x994308 2.3.3 PPC
                     // 10044152 2.3.2 PPC
                     // 10019528 2.3.0 PPC

