//
//  Unit.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/29/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MemoryAccess.h"
#import "Position.h"

// from Mangos, ObjectDefines.h
#define GUID_HIPART(x)   (UInt32)((((UInt64)(x)) >> 48) & 0x0000FFFF)

#define GUID_LOW32(x)    (UInt32)(((UInt64)(x)) & 0x00000000FFFFFFFFULL);
#define GUID_HIGH32(x)    (UInt32)(((UInt64)(x) >> 32) & 0xFFFFFFFF00000000ULL);

enum HighGuid {
    HIGHGUID_ITEM           = 0x4000,                       // blizz 4000
    HIGHGUID_CONTAINER      = 0x4000,                       // blizz 4000
    HIGHGUID_PLAYER         = 0x0000,                       // blizz 0000
    HIGHGUID_GAMEOBJECT     = 0xF110,                       // blizz F110
    HIGHGUID_TRANSPORT      = 0xF120,                       // blizz F120 (for GAMEOBJECT_TYPE_TRANSPORT)
    HIGHGUID_UNIT           = 0xF130,                       // blizz F130
    HIGHGUID_PET            = 0xF140,                       // blizz F140
    HIGHGUID_DYNAMICOBJECT  = 0xF100,                       // blizz F100
    HIGHGUID_CORPSE         = 0xF101,                       // blizz F100
    HIGHGUID_MO_TRANSPORT   = 0x1FC0,                       // blizz 1FC0 (for GAMEOBJECT_TYPE_MO_TRANSPORT)
};

@protocol WoWObjectMemory
- (NSString*)descriptionForOffset: (UInt32)offset;

- (UInt32)memoryStart;
- (UInt32)memoryEnd;
@end

@interface WoWObject : NSObject <WoWObjectMemory> {
    NSNumber *_baseAddress, *_infoAddress;
    MemoryAccess *_memory;
    NSDate *_refresh;
    
    int cachedEntryID;
    GUID cachedGUID;
}

- (id)initWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;
+ (id)objectWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

@property (readwrite, retain) MemoryAccess *memoryAccess;
@property (readwrite, retain) NSDate *refreshDate;

- (BOOL)isEqualToObject: (WoWObject*)object;

- (UInt32)objectBaseID;
- (UInt32)objectTypeID;

- (BOOL)isNPC;
- (BOOL)isPlayer;
- (BOOL)isNode;

- (GUID)GUID;
- (UInt32)lowGUID;
- (UInt32)highGUID;
- (NSNumber*)ID;    // NSNumber version of [self entryID]
- (UInt32)typeMask;
- (UInt32)entryID;

- (BOOL)isValid;
- (BOOL)isStale;
- (NSString*)name;
- (Position*)position; // placeholder, always returns nil

- (UInt32)baseAddress;
- (UInt32)infoAddress;
- (UInt32)prevObjectAddress;
- (UInt32)nextObjectAddress;

@end