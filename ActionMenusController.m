//
//  ActionMenusController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 9/6/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "ActionMenusController.h"

#import "Controller.h"
#import "SpellController.h"
#import "InventoryController.h"
#import "MobController.h"
#import "NodeController.h"

#import "Macro.h"
#import "Spell.h"
#import "Item.h"
#import "Node.h"

@implementation ActionMenusController

static ActionMenusController *sharedMenus = nil;

+ (ActionMenusController *)sharedMenus {
	if (sharedMenus == nil)
		sharedMenus = [[[self class] alloc] init];
	return sharedMenus;
}

- (id) init {
    self = [super init];
	if(sharedMenus) {
		[self release];
		self = sharedMenus;
	} else if(self != nil) {
		sharedMenus = self;
    }
    return self;
}


#pragma mark -

- (NSArray*)scanMacrosFrom: (NSString*)macroFilePath {
    
    NSString *macroString = [NSString stringWithContentsOfFile: macroFilePath];
    NSScanner *scanner = [NSScanner scannerWithString: macroString];
    NSMutableArray *macroList = [NSMutableArray array];
    
    
    while(![scanner isAtEnd]) {
        if(![scanner scanString: @"MACRO" intoString: nil]) {
            // PGLog(@"Could not scan 'MACRO'. Done.");
            break;
        }
        int macroNum;
        if(![scanner scanInt: &macroNum]) {
            // PGLog(@"Could not scan int. Done.");
            break;
        }
        NSString *macroName;
        [scanner scanString: @" \"" intoString: nil];
        if(![scanner scanUpToString: @"\" " intoString: &macroName]) {
            // PGLog(@"Could not scan name. Done.");
            break;
        }
        macroName = [macroName stringByReplacingOccurrencesOfString: @"\"" withString: @""];
        
        // PGLog(@"Got macro \"%@\" (%d)", macroName, macroNum);
        
        if(![scanner scanUpToString: @"\n" intoString: nil]) {
            // PGLog(@"Couldnt find end of line.");
            break;
        }
        
        NSString *macroBody;
        if(![scanner scanUpToString: @"\r\nEND\r\n" intoString: &macroBody]) {
            // PGLog(@"Couldnt find END of macro.");
            break;
        }
        [scanner scanString: @"END" intoString: nil];
        
        // PGLog(@"Got macro body \"%@\"", macroBody);
        
        /*NSDictionary *macroDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   macroName,                           @"Name",
                                   [NSNumber numberWithInt: macroNum],  @"Number",
                                   macroBody,                           @"Body", nil];*/
        [macroList addObject: [Macro macroWithName: macroName number: [NSNumber numberWithInt: macroNum] body: macroBody isCharacter: NO]];
    }

    return macroList;
}

- (NSMenu*)createMacroMenu {
    
    // parse out macros for current player
    NSString *acctMacroPath = [[controller wtfAccountPath] stringByAppendingPathComponent: @"macros-cache.txt"];
    NSString *charMacroPath = [[controller wtfCharacterPath] stringByAppendingPathComponent: @"macros-cache.txt"];
    
    NSArray *globalList = nil, *localList = nil;
    
    if([[NSFileManager defaultManager] fileExistsAtPath: acctMacroPath])
        globalList = [self scanMacrosFrom: acctMacroPath];
    if([[NSFileManager defaultManager] fileExistsAtPath: charMacroPath]) {
        localList = [self scanMacrosFrom: charMacroPath];
        for(Macro *macro in localList) {
            [macro setIsCharacter: YES];
        }
    }
    
    // Generate the Macros menu
    NSMenu *macroMenu = [[[NSMenu alloc] initWithTitle: @"Macro Menu"] autorelease];
    
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Account Macros" action: nil keyEquivalent: @""] autorelease];
    [item setAttributedTitle: [[[NSAttributedString alloc] initWithString: @"Account Macros" 
                                                               attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
    [macroMenu addItem: item];
    
    if(globalList && [globalList count]) {
        for(Macro *macro in globalList) {
            item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ (%@)", macro.name, macro.number] action: nil keyEquivalent: @""] autorelease];
            [item setTag: [macro.number intValue]];
            [item setIndentationLevel: 1];
            [item setRepresentedObject: macro];
            [macroMenu addItem: item];
        }
    } else {
        item = [[[NSMenuItem alloc] initWithTitle: @"There are no available macros." action: nil keyEquivalent: @""] autorelease];
        [item setIndentationLevel: 1];
        [macroMenu addItem: item];
    }
    [macroMenu addItem: [NSMenuItem separatorItem]];
    
    item = [[[NSMenuItem alloc] initWithTitle: @"Character Macros" action: nil keyEquivalent: @""] autorelease];
    [item setAttributedTitle: [[[NSAttributedString alloc] initWithString: @"Character Macros" 
                                                               attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
    [macroMenu addItem: item];
    
    if(localList && [localList count]) {
        for(Macro *macro in localList) {
            item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ (%@)", macro.name, macro.number] action: nil keyEquivalent: @""] autorelease];
            [item setTag: [macro.number intValue]];
            [item setIndentationLevel: 1];
            [item setRepresentedObject: macro];
            [macroMenu addItem: item];
        }
    } else {
        item = [[[NSMenuItem alloc] initWithTitle: @"There are no available macros." action: nil keyEquivalent: @""] autorelease];
        [item setIndentationLevel: 1];
        [macroMenu addItem: item];
        item = [[[NSMenuItem alloc] initWithTitle: @"Please reload UI (or quit WoW) to save new macros." action: nil keyEquivalent: @""] autorelease];
        [item setIndentationLevel: 1];
        [macroMenu addItem: item];
    }
        
    return macroMenu;
}

- (NSMenu*)createInteractMenu {
    
    // Generate the Macros menu
    NSMenu *interactMenu = [[[NSMenu alloc] initWithTitle: @"Interact Menu"] autorelease];
    
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Interact with NPC" action: nil keyEquivalent: @""] autorelease];
    [item setAttributedTitle: [[[NSAttributedString alloc] initWithString: @"Interact with NPC" 
                                                               attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
	[item setIndentationLevel: 0];
	[item setTag: 1];
	[interactMenu addItem: item];
	//PGLog(@"interact menu %@", mobController);
	for(Mob *mob in [mobController mobsWithinDistance:8 levelRange:NSMakeRange(0,255) includeElite:YES includeFriendly:YES includeNeutral:YES includeHostile:NO]) {
		item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@", [mob name]] action: nil keyEquivalent: @""] autorelease];
		[item setTag: [mob entryID]];
		[item setIndentationLevel: 1];
		[item setRepresentedObject: mob];
		[interactMenu addItem: item];
	}
	
	
	item = [[[NSMenuItem alloc] initWithTitle: @"Interact with node" action: nil keyEquivalent: @""] autorelease];
    [item setAttributedTitle: [[[NSAttributedString alloc] initWithString: @"Interact with node" 
                                                               attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
	[item setIndentationLevel: 0];
	[item setTag: 2];
	[interactMenu addItem: item];
	
	for(Node *node in [nodeController nodesWithinDistance:8 ofType:AnyNode maxLevel:9000]) {
		item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@", [node name]] action: nil keyEquivalent: @""] autorelease];
		[item setTag: [node entryID]];
		[item setIndentationLevel: 1];
		[item setRepresentedObject: node];
		[interactMenu addItem: item];
	}
	
    return interactMenu;
}

#pragma mark -


- (NSMenu*)menuType: (ActionMenuType)type actionID: (UInt32)actionID {
    NSMenu *theMenu = nil;
    
    switch(type) {
        case MenuType_Spell:
            theMenu = [spellController playerSpellsMenu];
            break;
        case MenuType_Inventory:
            theMenu = [inventoryController prettyInventoryItemsMenu];
            break;
        case MenuType_Macro:
            theMenu = [self createMacroMenu];
            break;
        case MenuType_Interact:
            theMenu = [self createInteractMenu];
            break;
        default:
            return nil;
            break;
    }
    
    if(![theMenu itemWithTag: actionID]) {
        // theMenu = nil;
        
        if(type == MenuType_Spell) {
            //theMenu = [[[NSMenu alloc] initWithTitle: @"Spells"] autorelease];
            NSMenuItem *item = nil;
            Spell *spell = [spellController spellForID: [NSNumber numberWithInt: actionID]];
            if(spell && [spell name]) {
                item = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@: %@", [spell ID], [spell name]] action: nil keyEquivalent: @""];
            } else {
                item = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"Unknown Spell (%d)", actionID] action: nil keyEquivalent: @""];
            }
            [item setTag: actionID];
            [theMenu insertItem: [item autorelease] atIndex: 0];
            //[theMenu addItem: [item autorelease]];
        }
        
        // create temp item list
        if(type == MenuType_Inventory) {
            //theMenu = [[[NSMenu alloc] initWithTitle: @"Items"] autorelease];
            NSMenuItem *menuItem = nil;
            Item *item = [inventoryController itemForID: [NSNumber numberWithInt: actionID]];
            if(item && [item name]) {
                menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%d: %@", [item entryID], [item name]] action: nil keyEquivalent: @""];
            } else {
                menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"Unknown Item (%d)", actionID] action: nil keyEquivalent: @""];
            }
            [menuItem setTag: actionID];
            [theMenu insertItem: [menuItem autorelease] atIndex: 0];
            //[theMenu addItem: [menuItem autorelease]];
        }
        
        // create temp macro list
        if(type == MenuType_Macro) {
            //theMenu = [[[NSMenu alloc] initWithTitle: @"Macros"] autorelease];
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"Unknown Macro (%d)", actionID] action: nil keyEquivalent: @""];
            [menuItem setTag: actionID];
            [theMenu insertItem: [menuItem autorelease] atIndex: 0];
            //[theMenu addItem: [menuItem autorelease]];
        }
        
        // [resultActionDropdown selectItemWithTag: actionID];
    }
    
    return theMenu;
}

@end
