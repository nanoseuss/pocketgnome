//
//  WoWDbRow.h
//  Pocket Gnome
//
//  Created by Josh on 3/31/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WoWDbRow : NSObject {
	UInt32 _address;
	BOOL _ownsMemory;
}

+ (id)WoWDbRowWithPtr: (UInt32)ptr;
+ (id)WoWDbRowWithPtr: (UInt32)ptr andOwns:(BOOL)owns;

- (BOOL)isValid;
- (void)getFieldWithVoid:(voidPtr)obj andIndex:(uint)index;

@end
