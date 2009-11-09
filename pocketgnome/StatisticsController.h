//
//  StatisticsController.h
//  Pocket Gnome
//
//  Created by Josh on 10/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property float updateFrequency;

// interface
- (IBAction)resetStatistics:(id)sender;

@end
