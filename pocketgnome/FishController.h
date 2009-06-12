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
@class SpellController;
@class MovementController;

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
	IBOutlet SpellController		*spellController;
	IBOutlet MovementController		*movementController;
	
	IBOutlet NSButton				*applyLureCheckbox;
	IBOutlet NSButton				*killWoWCheckbox;
	IBOutlet NSButton				*showGrowlNotifications;
	IBOutlet NSButton				*useContainers;
	IBOutlet NSButton				*faceSchool;
	IBOutlet NSButton				*recastIfMiss;
	IBOutlet NSButton				*hideOtherBobbers;
    IBOutlet NSView					*view;
	IBOutlet NSButton				*startStopButton;
	IBOutlet SRRecorderControl		*fishingRecorder;
	IBOutlet NSPopUpButton			*luresPopUpButton;
	IBOutlet NSTextField			*fishCaught;
	IBOutlet NSTextField			*status;
	IBOutlet NSTextField			*closeWoWTimer;
	IBOutlet NSTableView			*statisticsTableView;
	PTHotKey *startStopBotGlobalHotkey;
	
	//Checkbox options
	BOOL _optApplyLure;
	BOOL _optKillWow;
	BOOL _optShowGrowl;
	BOOL _optUseContainers;
	BOOL _optFaceSchool;
	BOOL _optRecast;
	BOOL _optHideOtherBobbers;
	
	BOOL _isFishing;
	BOOL _ignoreIsFishing;
	
	int _applyLureAttempts;
	int _totalFishLooted;
	int _useContainer;
	
	Node *_nearbySchool;
	
	UInt32 _fishingSpellID;
	UInt64 _playerGUID;

	Node *_bobber;
	
    NSSize minSectionSize, maxSectionSize;
}

// Controller interface
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

- (IBAction)startStopFishing: (id)sender;
- (IBAction)showBobberStructure: (id)sender;

- (IBAction)tmp: (id)sender;

- (BOOL)isFishing;
	
@end
