//
//  FishController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/23/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//
//  Eventually I'll integrate GoneFishing.
//

#import <Cocoa/Cocoa.h>


@class SRRecorderControl;

@class Controller;
@class NodeController;
@class PlayerDataController;
@class MemoryAccess;
@class ChatController;

@class Node;

@interface FishController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet NodeController			*nodeController;
	IBOutlet PlayerDataController	*playerController;
	IBOutlet ChatController			*chatController;
	
    IBOutlet NSView *view;
	IBOutlet NSButton *startStopButton;
	IBOutlet SRRecorderControl *fishingRecorder;
	
	BOOL _isFishing;
	
    NSSize minSectionSize, maxSectionSize;
}


// Controller interface
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;


- (IBAction)startStopFishing: (id)sender;

- (void)fishBegin;
- (void)clickBobber:(Node*)bobber;

- (BOOL)moveMouseToWoWCoordsWithX: (float)x Y:(float)y Z:(float)z;

@end
