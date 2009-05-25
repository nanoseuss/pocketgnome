//
//  Corpse.h
//  Pocket Gnome
//
//  Created by Josh on 5/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WoWObject.h"

@class Position;

enum eCorpseBaseFields {
    CorpseField_OwnerGUID                 = 0x18,  // 3.1.2	
	
	CorpseField_XLocation                 = 0xE0,
    CorpseField_YLocation                 = 0xE4,
    CorpseField_ZLocation                 = 0xE8,
	CorpseField_Rotation				  = 0xEC,
	
};


@interface Corpse : WoWObject {

}

+ (id)corpseWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

- (UInt32) parentLowGUID;

- (Position*)position;

@end
