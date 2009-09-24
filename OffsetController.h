//
//  OffsetController.h
//  Pocket Gnome
//
//  Created by Josh on 9/1/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;

@interface OffsetController : NSObject {

	NSMutableDictionary *offsets;
	
	IBOutlet Controller *controller;
}

- (void)dumpOffsets;

- (unsigned long) offset: (NSString*)key;

@end
