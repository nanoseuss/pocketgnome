//
//  WoWDbTable.m
//  Pocket Gnome
//
//  Created by Josh on 3/31/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "WoWDbTable.h"
#import "WoWDbRow.h"
#import "MemoryAccess.h"

#define WOW_USE_SPELL_UNPACK = 0xD2E300;

@implementation WoWDbTable

- (id) init{
	
    self = [super init];
    if ( self != nil ){
		_tablePtr = 0;
    }
    return self;
}

- (id)initWithTablePtr:(UInt32)ptr{
	self = [self init];
    if (self != nil) {
		_tablePtr = ptr;
		
		MemoryAccess *memory = [MemoryAccess sharedMemoryAccess];

		if ( memory && [memory isValid] && _tablePtr > 0x0 ){
			PGLog(@"loading table at 0x%X", _tablePtr);
			[memory loadDataForObject: self atAddress: _tablePtr Buffer:(Byte*)&_nativeDb BufLength: sizeof(_nativeDb)];
			PGLog(@" %d %d %d", _nativeDb.minIndex, _nativeDb.maxIndex, _nativeDb.numRows);
		}
	}
	return self;
}

+ (id)WoWDbTableWithTablePtr: (UInt32)ptr{
	return [[[WoWDbTable alloc] initWithTablePtr:ptr] autorelease];
}

#pragma mark -

- (BOOL)isLoaded{
	if ( _tablePtr == 0x0  )
		return NO;
	return _nativeDb.isLoaded;
}

- (UInt)numRows{
	if ( _tablePtr == 0x0  )
		return 0;
	return _nativeDb.numRows;
}

- (UInt)maxIndex{
	if ( _tablePtr == 0x0  )
		return 0;
	return _nativeDb.maxIndex;
}

- (UInt)minIndex{
	if ( _tablePtr == 0x0  )
		return 0;
	return _nativeDb.minIndex;
}

- (WoWDbRow*)GetRow: (int)index{
	if ( index >= [self minIndex] && index <= [self maxIndex] ){
		UInt32 rowAddress = _nativeDb.firstRow + ((index - [self minIndex]) * 4);
		return [[[WoWDbRow WoWDbRowWithPtr:rowAddress] retain] autorelease];
	}
	return [[[WoWDbRow WoWDbRowWithPtr:0] retain] autorelease];
}

- (UInt32)ClientDbUnpack: (UInt32)source andSize:(UInt32)size{
	
	
	return 0x0;
}

- (WoWDbRow*)GetLocalizedRow: (int)index{

	UInt32 clientDbPtr = _tablePtr - 0x18;
	WoWClientDb header;
	UInt32 rowPtr = 0x0;
	
	PGLog(@"now reading at 0x%X", clientDbPtr);
	
	MemoryAccess *memory = [MemoryAccess sharedMemoryAccess];
	
	if ( memory && [memory isValid] ){
		// load the new ptr
		[memory loadDataForObject: self atAddress: clientDbPtr Buffer:(Byte*)&header BufLength: sizeof(header)];

		// range check
		if ( index >= header.minIndex && index <= header.maxIndex ){
			UInt32 lpRow = 0;
			UInt32 address = header.firstRow + (index - header.minIndex);
			[memory loadDataForObject: self atAddress: address Buffer:(Byte*)&lpRow BufLength: sizeof(lpRow)];
			
			if ( 1 == 0 ){
				rowPtr = [self ClientDbUnpack:lpRow andSize:0x2C0];
				PGLog(@"SPELL!!! 0x%X  Ptr: 0x%X", lpRow, rowPtr);
			}
			else{
				PGLog(@"NOT SPELL!!! 0x%X", lpRow);
				
				Byte data[704] = {0};
				[memory loadDataForObject: self atAddress: lpRow Buffer:(Byte*)&data BufLength: sizeof(data)];
				data[703] = '0';
				NSString *str = [NSString stringWithUTF8String: (char*)data];
				if ( [str length] ) {
					PGLog(@"success in localizing? %@", str);
				}
			}
		}
	}
	
	return [[[WoWDbRow WoWDbRowWithPtr:rowPtr] retain] autorelease];
}

@end
