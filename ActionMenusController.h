//
//  ActionMenusController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 9/6/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class BotController;
@class SpellController;
@class InventoryController;

typedef enum ActionMenuTypes {
    MenuType_Spell      = 1,
    MenuType_Inventory  = 2,
    MenuType_Macro      = 3,
    
} ActionMenuType;

@interface ActionMenusController : NSObject {

    IBOutlet Controller *controller;
    IBOutlet BotController *botController;
    IBOutlet SpellController *spellController;
    IBOutlet InventoryController *inventoryController;
}

+ (ActionMenusController *)sharedMenus;

- (NSMenu*)menuType: (ActionMenuType)type actionID: (UInt32)actionID;

@end
