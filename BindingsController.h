//
//  BindingsController.h
//  Pocket Gnome
//
//  Created by Josh on 1/28/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class ChatController;

@interface BindingsController : NSObject {
	
	IBOutlet Controller *controller;
	IBOutlet ChatController *chatController;

	NSMutableDictionary *_bindings;
}

- (void)doIt;

@end
