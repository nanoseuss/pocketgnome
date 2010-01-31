//
//  BindingsController.m
//  Pocket Gnome
//
//  Created by Josh on 1/28/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "BindingsController.h"

#import "Controller.h"
#import "PlayerDataController.h"
#import "ChatController.h"

#import "MemoryAccess.h"

@interface BindingsController (Internal)
- (void)getKeyBindings;
@end

@implementation BindingsController

- (id) init{
    self = [super init];
    if (self != nil) {
		
		_bindings = [[NSMutableDictionary dictionary] retain];
		
		// Notifications
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(playerIsValid:) 
													 name: PlayerIsValidNotification 
												   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsInvalid:) 
                                                     name: PlayerIsInvalidNotification 
                                                   object: nil];
    }
    return self;
}

- (void) dealloc{
	[_bindings release]; _bindings = nil;
    [super dealloc];
}

#pragma mark Notifications

- (void)playerIsValid: (NSNotification*)not {
	[self getKeyBindings];
}

- (void)playerIsInvalid: (NSNotification*)not {
	[_bindings removeAllObjects];
}

#pragma mark Key Bindings Scanner

typedef struct WoWBinding {
    UInt32 nextBinding;		// 0x0
	UInt32 unknown1;		// 0x4	pointer to a list of something
	UInt32 keyPointer;		// 0x8
	UInt32 unknown2;		// 0xC	usually 0
	UInt32 unknown3;		// 0x10	usually 0
	UInt32 unknown4;		// 0x14	usually 0
	UInt32 unknown5;		// 0x18	usually 0
	UInt32 cmdPointer;		// 0x1C
} WoWBinding;

- (void)getKeyBindings{
	
	// remove all previous bindings since we're grabbing new ones!
	[_bindings removeAllObjects];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	UInt32 offset = 0xC82FE0, bindingsManager = 0, structPointer = 0, firstStruct = 0;
	WoWBinding bindingStruct;
	
	// find the address of our key bindings manager
	if ( [memory loadDataForObject: self atAddress: offset Buffer: (Byte*)&bindingsManager BufLength: sizeof(bindingsManager)] && bindingsManager ){
		
		// load the first struct
		[memory loadDataForObject: self atAddress: bindingsManager + 0xB4 Buffer: (Byte*)&firstStruct BufLength: sizeof(firstStruct)];
		
		structPointer = firstStruct;

		// loop through all structs!
		while ( [memory loadDataForObject: self atAddress: structPointer Buffer: (Byte*)&bindingStruct BufLength: sizeof(bindingStruct)] && bindingStruct.nextBinding > 0x0 && !(bindingStruct.nextBinding & 0x1) ){

			//PGLog(@"[Binding] Struct found at 0x%X", structPointer);

			// initiate our variables
			NSString *key = nil;
			NSString *cmd = nil;
			char tmpKey[64], tmpCmd[64];
			tmpKey[63] = 0;
			tmpCmd[63] = 0;

			
			if ( [memory loadDataForObject: self atAddress: bindingStruct.keyPointer Buffer: (Byte *)&tmpKey BufLength: sizeof(tmpKey)-1] ){
				key = [NSString stringWithUTF8String: tmpKey];  // will stop after it's first encounter with '\0'
				//PGLog(@"[Binding] Key %@ found at 0x%X", key, bindingStruct.keyPointer);
			}
			
			if ( [memory loadDataForObject: self atAddress: bindingStruct.cmdPointer Buffer: (Byte *)&tmpCmd BufLength: sizeof(tmpCmd)-1] ){
				cmd = [NSString stringWithUTF8String: tmpCmd];  // will stop after it's first encounter with '\0'
				//PGLog(@"[Binding] Command %@ found at 0x%X", cmd, bindingStruct.cmdPointer);
			}
			
			// add it
			if ( [key length] && [cmd length] ){
				[_bindings setObject:cmd forKey:key];
			}
			
			//PGLog(@"[Bindings] Code %d for %@", [chatController keyCodeForCharacter:key], key);
			
			// we already made it through the list! break!
			if ( firstStruct == bindingStruct.nextBinding ){
				break;
			}
			
			// load the next one
			structPointer = bindingStruct.nextBinding;
		}
	}
	
	PGLog(@"[Bindings] Total found: %d", [_bindings count]);
	PGLog(@"%@", _bindings);
	
}

- (void)doIt{
	[self getKeyBindings];
}



#pragma mark Helpers
@end
