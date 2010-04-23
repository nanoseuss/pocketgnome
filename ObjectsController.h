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

@class Controller;
@class MemoryViewController;
@class NodeController;
@class PlayersController;
@class InventoryController;
@class MobController;
@class MovementController;
@class PlayerDataController;

enum Tabs{
	Tab_Players = 0,
	Tab_Mobs,
	Tab_Items,
	Tab_Nodes,	
};

// really just a helper class for our new Objects tab
@interface ObjectsController : NSObject {
	IBOutlet Controller				*controller;
	IBOutlet MemoryViewController	*memoryViewController;
	IBOutlet NodeController			*nodeController;
	IBOutlet PlayersController		*playersController;
	IBOutlet InventoryController	*itemController;
	IBOutlet MobController			*mobController;
	IBOutlet MovementController		*movementController;
	IBOutlet PlayerDataController	*playerController;
	
	IBOutlet NSPopUpButton *moveToNodePopUpButton, *moveToMobPopUpButton;
	
	IBOutlet NSTableView *itemTable, *playersTable, *nodeTable, *mobTable;
	
	IBOutlet NSTabView *tabView;
	
	IBOutlet NSView *view;
	
	NSTimer *_updateTimer;
	
	int _currentTab;		// currently selected tab
	
	NSSize _minSectionSize, _maxSectionSize;
	float _updateFrequency;
	
	NSString *_mobFilterString;
	NSString *_nodeFilterString;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property float updateFrequency;

// tables
@property (readonly) NSTableView *itemTable;
@property (readonly) NSTableView *playersTable;
@property (readonly) NSTableView *nodeTable;
@property (readonly) NSTableView *mobTable;

- (BOOL)isTabVisible:(int)tab;

- (void)loadTabData;

- (NSString*)nameFilter;

// TO DO: this should change based on what tab we are viewing!
- (int)objectCount;

// TO DO: when we reload the table, STAY WITH SELECTED ROW!


- (IBAction)filter: (id)sender;
- (IBAction)refreshData: (id)sender;
- (IBAction)updateTracking: (id)sender;
- (IBAction)moveToStart: (id)sender;
- (IBAction)moveToStop: (id)sender;
- (IBAction)resetObjects: (id)sender;
- (IBAction)targetObject: (id)sender;
- (IBAction)faceObject: (id)sender;
- (IBAction)reloadNames: (id)sender;

@end
