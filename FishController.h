//
//  FishController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/23/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SRRecorderControl;

@class Controller;
@class NodeController;
@class PlayerDataController;
@class MemoryAccess;
@class ChatController;
@class BotController;
@class InventoryController;
@class MemoryViewController;
@class LootController;

@class WoWObject;
@class PTHotKey;

@class Node;

@interface FishController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet NodeController			*nodeController;
	IBOutlet PlayerDataController	*playerController;
	IBOutlet ChatController			*chatController;
	IBOutlet BotController			*botController;
    IBOutlet InventoryController    *itemController;
	IBOutlet MemoryViewController	*memoryViewController;
	IBOutlet LootController			*lootController;
	
	IBOutlet NSButton				*applyLureCheckbox;
	IBOutlet NSButton				*killWoWCheckbox;
	IBOutlet NSButton				*showGrowlNotifications;
	IBOutlet NSButton				*useReinforcedCrates;
    IBOutlet NSView					*view;
	IBOutlet NSButton				*startStopButton;
	IBOutlet SRRecorderControl		*fishingRecorder;
	IBOutlet NSPopUpButton			*luresPopUpButton;
	IBOutlet NSTextField			*fishCaught;
	IBOutlet NSTextField			*status;
	IBOutlet NSTextField			*closeWoWTimer;
	IBOutlet NSTableView			*statisticsTableView;
	PTHotKey *startStopBotGlobalHotkey;
	
	BOOL _isFishing;
	BOOL _useCrate;
	int _applyLureAttempts;
	
	UInt64 _playerGUID;
	UInt64 _bobberGUID;
	
	NSDate *_startTime;
	
	int _totalFishLooted;
	
	WoWObject *_bobber;
	
    NSSize minSectionSize, maxSectionSize;
}

// Controller interface
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

- (IBAction)startStopFishing: (id)sender;
- (IBAction)showBobberStructure: (id)sender;

- (void)fishBegin;
- (void)clickBobber:(Node*)bobber;
- (BOOL)applyLure;

- (BOOL)isFishing;

@end
