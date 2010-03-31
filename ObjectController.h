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
@class PlayerDataController;

@class MemoryAccess;
@class WoWObject;

// super class
@interface ObjectController : NSObject {
	
	IBOutlet Controller				*controller;
	IBOutlet PlayerDataController	*playerData;

	NSMutableArray *_objectList;
	NSMutableArray *_objectDataList;
	
	NSTimer *_updateTimer;
	
	IBOutlet NSView *view;
	NSSize minSectionSize, maxSectionSize;
	float _updateFrequency;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readwrite) float updateFrequency;

- (void)addAddresses: (NSArray*)addresses;

- (void)resetAllObjects;

//
// to be implemented by sub classes
//

- (NSArray*)allObjects;

- (void)refreshData;

- (unsigned int)objectCount;

- (unsigned int)objectCountWithFilters;

- (id)objectWithAddress:(NSNumber*) address inMemory:(MemoryAccess*)memory;

- (void)objectAddedToList:(WoWObject*)obj;

- (NSString*)updateFrequencyKey;

- (void)tableDoubleClick: (id)sender;

- (WoWObject*)objectForRowIndex:(int)rowIndex;

// for tables

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex;
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn;
- (void)sortUsingDescriptors:(NSArray*)sortDescriptors;

@end
