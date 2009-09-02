//
//  MemoryViewController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MemoryAccess.h"

@class Controller;
@class OffsetController;

@interface MemoryViewController : NSView {
    IBOutlet Controller *controller;
	IBOutlet OffsetController *offsetController;
    IBOutlet id memoryTable;
    IBOutlet id memoryViewWindow;
    IBOutlet NSView *view;
    NSNumber *currentAddress;
    NSTimer *_refreshTimer;
	NSMutableDictionary *_lastValues;
    
    float refreshFrequency;
    int _displayFormat;
    int _displayCount;
    //id callback;
    
    id _wowObject;

    NSSize minSectionSize, maxSectionSize;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;    
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readwrite) float refreshFrequency;

- (void)showObjectMemory: (id)object;

- (void)setBaseAddress: (NSNumber*)address;

- (IBAction)setCustomAddress: (id)sender;
- (IBAction)clearTable: (id)sender;
- (IBAction)snapshotMemory: (id)sender;
- (IBAction)saveValues: (id)sender;
- (IBAction)clearValues: (id)sender;
- (IBAction)dumpOffsets: (id)sender;

- (int)displayFormat;
- (void)setDisplayFormat: (int)displayFormat;
@end
