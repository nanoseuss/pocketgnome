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
	NSDictionary *_offsetDictionary;
	
	IBOutlet Controller *controller;
	
	BOOL _offsetsLoaded;
}

- (unsigned long) offset: (NSString*)key;

- (NSArray*) offsetWithByteSignature: (NSString*)signature 
							withMask:(NSString*)mask 
					   withEmulation:(BOOL)emulatePPC;

@end
