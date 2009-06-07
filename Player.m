//
//  Player.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/25/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Player.h"
#import "WoWObject.h"

enum PlayerFlags
{
    PLAYER_FLAGS_GROUP_LEADER   = 0x00000001,
    PLAYER_FLAGS_AFK            = 0x00000002,
    PLAYER_FLAGS_DND            = 0x00000004,
    PLAYER_FLAGS_GM             = 0x00000008,
    PLAYER_FLAGS_GHOST          = 0x00000010,
    PLAYER_FLAGS_RESTING        = 0x00000020,
    PLAYER_FLAGS_FFA_PVP        = 0x00000080,
    PLAYER_FLAGS_UNK            = 0x00000100,               // show PvP in tooltip
    PLAYER_FLAGS_IN_PVP         = 0x00000200,
    PLAYER_FLAGS_HIDE_HELM      = 0x00000400,
    PLAYER_FLAGS_HIDE_CLOAK     = 0x00000800,
    PLAYER_FLAGS_UNK1           = 0x00001000,               // played long time
    PLAYER_FLAGS_UNK2           = 0x00002000,               // played too long time
    PLAYER_FLAGS_UNK3           = 0x00008000,               // strange visual effect (2.0.1), looks like PLAYER_FLAGS_GHOST flag
    PLAYER_FLAGS_UNK4           = 0x00020000,               // taxi benchmark mode (on/off) (2.0.1)
    PLAYER_UNK                  = 0x00040000,               // 2.0.8...
};


@interface Player (Internal)
- (UInt32)playerFlags;
@end

@implementation Player

+ (id)playerWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    return [[[Player alloc] initWithAddress: address inMemory: memory] autorelease];
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<%@ [%d] [%d%%] (0x%X)>", [self className], [self level], [self currentHealth], [self lowGUID]];
}


#pragma mark -


- (UInt32)playerFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self infoAddress] + PlayerField_Flags) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}

- (BOOL)isGM {
    if( ([self playerFlags] & (PLAYER_FLAGS_GM)) == (PLAYER_FLAGS_GM))
        return YES;
    return NO;
}

- (GUID)itemGUIDinSlot: (CharacterSlot)slot {
    if(slot < 0 || slot >= SLOT_MAX) return 0;
    
    GUID value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + PlayerField_CharacterSlot + sizeof(GUID)*slot) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        //if(GUID_HIPART(value) == HIGHGUID_ITEM) - As of 3.1.3 I had to comment out this - i'm not sure why
		return value;
    }
    return 0;
}

@end
