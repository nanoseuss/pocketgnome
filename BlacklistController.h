//
//  BlacklistController.h
//  Pocket Gnome
//
//  Created by Josh on 12/13/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// created a controller for this, as I don't want to implement the exact same versions for Combat and for nodes

@class WoWObject;

@interface BlacklistController : NSObject {

	NSMutableArray *_blacklist;

}

- (void)blacklistObject: (WoWObject*)obj withCount:(int)count;
- (void)blacklistObject: (WoWObject*)obj;
- (BOOL)isBlacklisted: (WoWObject*)obj;
- (void)removeAllUnits;

@end
