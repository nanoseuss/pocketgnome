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
    
    BOOL _shouldScan;
    NSMutableArray *_chatLog;
}

@property (readwrite, assign) BOOL shouldScan;

@end
