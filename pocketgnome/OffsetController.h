//
//  OffsetController.h
//  Pocket Gnome
//
//  Created by Josh on 9/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;

@interface OffsetController : NSObject {

	IBOutlet Controller *controller;
}

- (void)dumpOffsets;

@end
