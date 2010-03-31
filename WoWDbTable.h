//
//  WoWDbTable.h
//  Pocket Gnome
//
//  Created by Josh on 3/31/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WoWDbRow;

typedef struct WoWClientDb {
    UInt32    _vtable;		// 0x0
    UInt32  isLoaded;		// 0x4
    UInt32  numRows;		// 0x8				// 49379
    UInt32  maxIndex;		// 0xC				// 74445
    UInt32  minIndex;		// 0x10				// 1
	UInt32  stringTablePtr;	// 0x14
	UInt32 _vtable2;		// 0x18
	// array of row pointers after this...
	UInt32 firstRow;		// 0x1C
	UInt32 row2;			// 0x20
	UInt32 row3;			// 0x24
	UInt32 row4;			// 0x28
	
} WoWClientDb;

@interface WoWDbTable : NSObject {
	UInt32 _tablePtr;
	WoWClientDb _nativeDb;
}

+ (id)WoWDbTableWithTablePtr: (UInt32)ptr;

- (BOOL)isLoaded;
- (UInt)numRows;
- (UInt)maxIndex;
- (UInt)minIndex;
- (WoWDbRow*)GetRow: (int)index;
- (WoWDbRow*)GetLocalizedRow: (int) index;


@end
