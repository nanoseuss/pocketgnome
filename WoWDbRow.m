//
//  WoWDbRow.m
//  Pocket Gnome
//
//  Created by Josh on 3/31/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "WoWDbRow.h"
#import "MemoryAccess.h"


@implementation WoWDbRow

- (id) init{
	
    self = [super init];
    if ( self != nil ){
		_address = 0;
		_ownsMemory = NO;
    }
    return self;
}

- (id)initWithPtr:(UInt32)ptr andOwns:(BOOL)owns{
	self = [self init];
    if (self != nil) {
		_address = ptr;
		_ownsMemory = owns;
	}
	return self;
}

+ (id)WoWDbRowWithPtr: (UInt32)ptr{
	return [[[WoWDbRow alloc] initWithPtr:ptr andOwns:NO] autorelease];
}

+ (id)WoWDbRowWithPtr: (UInt32)ptr andOwns:(BOOL)owns{
	return [[[WoWDbRow alloc] initWithPtr:ptr andOwns:owns] autorelease];
}

- (NSString*)description{
	return [[[NSString stringWithFormat:@"Row: <0x%X>", _address] retain] autorelease];	
}

#pragma mark -

- (BOOL)isValid{
	return _address != 0x0;
}

// pass by reference to this function!!!
- (void)getFieldWithVoid:(voidPtr)obj andIndex:(uint)index{
	MemoryAccess *memory = [MemoryAccess sharedMemoryAccess];
	
	PGLog(@"is this valid? %d", [memory isValid]);
	
	if ( memory && [memory isValid] && [self isValid] ){
		[memory loadDataForObject: self atAddress: _address + (index*4) Buffer:(Byte*)&obj BufLength: sizeof(obj)];
		PGLog(@"object loaded successfully for index %d", index);
	}
	
}

@end
