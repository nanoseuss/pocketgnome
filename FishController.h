/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

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
	IBOutlet BotController			*botController;
    IBOutlet InventoryController    *itemController;
	IBOutlet LootController			*lootController;
	IBOutlet SpellController		*spellController;
	IBOutlet MovementController		*movementController;
	
	BOOL _optApplyLure;
	BOOL _optUseContainers;
	BOOL _optRecast;
	int _optLureItemID;
	
	BOOL _isFishing;
	BOOL _ignoreIsFishing;
	
	int _applyLureAttempts;
	int _totalFishLooted;
	int _castNumber;
	int _lootAttempt;
	
	UInt32 _fishingSpellID;
	UInt64 _playerGUID;
	
	Node *_nearbySchool;
	//Node *_bobber;
	NSDate *_castStartTime;
	
	NSMutableArray *_facedSchool;
}

@property (readonly) BOOL isFishing;

- (void)fish: (BOOL)optApplyLure 
  withRecast:(BOOL)optRecast 
	 withUse:(BOOL)optUseContainers 
	withLure:(int)optLureID
  withSchool:(Node*)nearbySchool;

- (void)stopFishing;

- (Node*)nearbySchool;

@end
