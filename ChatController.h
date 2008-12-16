//
//  ChatController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/28/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;

@interface ChatController : NSObject {
    IBOutlet Controller *controller;
    
    CGEventSourceRef theSource;
}

- (void)tab;
- (void)enter;

- (void)jump;
- (void)releaseBody;
- (void)retrieveCorpse;

- (void)sendKeySequence: (NSString*)keySequence;
- (int)keyCodeForCharacter: (NSString*)character;

- (void)pressHotkey: (int)hotkey withModifier: (unsigned int)modifier;


@end
