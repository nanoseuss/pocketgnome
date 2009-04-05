//
//  ChatLogController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/3/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;

@interface ChatLogController : NSObject {
    IBOutlet Controller *controller;
    
    IBOutlet NSView *view;
    IBOutlet NSTableView *chatLogTable;
    
    BOOL _shouldScan, _lastPassFoundChat;
    NSMutableArray *_chatLog;
    NSSize minSectionSize, maxSectionSize;
    NSDateFormatter *_timestampFormat;
    NSSortDescriptor *_passNumberSortDescriptor;
    NSSortDescriptor *_relativeOrderSortDescriptor;
}

// Controller interface
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

@property (readwrite, assign) BOOL shouldScan;
@property (readwrite, assign) BOOL lastPassFoundChat;

@end
