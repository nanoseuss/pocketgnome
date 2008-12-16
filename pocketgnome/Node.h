//
//  Object.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/27/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WoWObject.h"
#import "Position.h"

#define NodeNameLoadedNotification @"NodeNameLoadedNotification"


typedef enum eGameObjectFlags {
    GAMEOBJECT_FLAG_IN_USE              = 1,    // disables interaction while animated
    GAMEOBJECT_FLAG_LOCKED              = 2,    // require key, spell, event, etc to be opened. Makes "Locked" appear in tooltip
    GAMEOBJECT_FLAG_CANT_TARGET         = 4,    // cannot interact (condition to interact)
    GAMEOBJECT_FLAG_TRANSPORT           = 8,    // any kind of transport? Object can transport (elevator, boat, car)
    GAMEOBJECT_FLAG_NEVER_DESPAWN       = 32,   // never despawn, typically for doors, they just change state
    GAMEOBJECT_FLAG_TRIGGERED           = 64,   // typically, summoned objects. Triggered by spell or other events
} NodeFlags;

@interface Node : WoWObject <UnitPosition> {
    NSString *_name;
    UInt32 _nameEntryID;
    
    // NSURLConnection *_connection;
    // NSMutableData *_downloadData;
}
+ (id)nodeWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

- (BOOL)validToLoot;

- (UInt32)nodeType;
- (NodeFlags)flags;

- (NSString*)stringForNodeType: (UInt32)typeID;
- (NSImage*)imageForNodeType: (UInt32)typeID;

// - (void)loadNodeName;

@end
