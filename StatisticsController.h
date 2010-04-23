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

@interface StatisticsController : NSObject {
	IBOutlet Controller *controller;
	IBOutlet PlayerDataController *playerController;
	
	// player statistics
	IBOutlet NSTextField	*moneyText;
	IBOutlet NSTextField	*experienceText;
	IBOutlet NSTextField	*itemsLootedText;
	IBOutlet NSTextField	*mobsKilledText;
	IBOutlet NSTextField	*honorGainedText;
	
	// mmory operations
	IBOutlet NSTextField	*memoryReadsText;
	IBOutlet NSTextField	*memoryWritesText;
	IBOutlet NSTableView	*memoryOperationsTable;
	
	IBOutlet NSView *view;
	
    NSSize minSectionSize, maxSectionSize;
	float _updateFrequency;
	UInt32 _startCopper;	// store the amount of copper when the bot started
	UInt32 _startHonor;
	int _lootedItems;		// total number of looted items
	int _mobsKilled;		// total number of mobs we've killed!
	
	// store our mob ID w/the # of kills (MEANT FOR QUESTS!)
	NSMutableDictionary *_mobsKilledDictionary;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property float updateFrequency;

// interface
- (IBAction)resetStatistics:(id)sender;

// for quests
- (void)resetQuestMobCount;
- (int)killCountForEntryID:(int)entryID;

@end
