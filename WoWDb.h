//
//  WoWDb.h
//  Pocket Gnome
//
//  Created by Josh on 3/31/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WoWDb : NSObject {
	NSMutableDictionary *_tables;
}

@property (readonly, retain) NSDictionary *tables;

@end
