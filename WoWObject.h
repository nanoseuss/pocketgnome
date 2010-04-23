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
#import "Position.h"

// from Mangos, ObjectDefines.h
#define GUID_HIPART(x)   (UInt32)((((UInt64)(x)) >> 48) & 0x0000FFFF)

#define GUID_LOW32(x)    (UInt32)(((UInt64)(x)) & 0x00000000FFFFFFFFULL)
#define GUID_HIGH32(x)    (UInt32)(((UInt64)(x) >> 32) & 0xFFFFFFFF00000000ULL)

enum HighGuid {
    HIGHGUID_ITEM           = 0x4580,   // 3.1, was 0x4000 before, 0x4100 in 3.1.1, 0x4580 in 3.1.2
    HIGHGUID_CONTAINER      = 0x4100,   // 3.1, was 0x4000 before
    HIGHGUID_PLAYER         = 0x1000,   // 3.1, was 0x0000 before
    HIGHGUID_GAMEOBJECT     = 0xF110,   // 3.1
    HIGHGUID_TRANSPORT      = 0xF120,   // unverified
    HIGHGUID_UNIT           = 0xF130,   // 3.1
    HIGHGUID_PET            = 0xF140,   // unverified
    HIGHGUID_VEHICLE        = 0xF150,   // unverified (or or 0xF550)
    HIGHGUID_DYNAMICOBJECT  = 0xF100,   // unverified
    HIGHGUID_CORPSE         = 0xF100,   // unverified (or 0xF101)
    HIGHGUID_MO_TRANSPORT   = 0x1FC0,   // unverified
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
	
	int _notInObjectListCounter;
    
    UInt32 cachedEntryID;
    GUID cachedGUID;
}

- (id)initWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;
+ (id)objectWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

@property (readwrite, retain) MemoryAccess *memoryAccess;
@property (readwrite, retain) NSDate *refreshDate;
@property (readwrite) int notInObjectListCounter;
@property (readonly) UInt32 cachedEntryID;
@property (readonly) GUID cachedGUID;

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
- (UInt32)cachedEntryID;

- (BOOL)isValid;
- (BOOL)isStale;
- (NSString*)name;
- (Position*)position; // placeholder, always returns nil

- (UInt32)baseAddress;
- (UInt32)infoAddress;
- (UInt32)prevObjectAddress;
- (UInt32)nextObjectAddress;

@end