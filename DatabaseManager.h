//
//  DatabaseManager.h
//  Pocket Gnome
//
//  Created by Josh on 4/12/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;

@interface DatabaseManager : NSObject {
	IBOutlet Controller *controller;

	NSMutableDictionary *_tables;
}

- (BOOL)getObjectForRow:(int)index withTable:(NSString*)table withStruct:(void*)obj withStructSize:(size_t)structSize;

@end
