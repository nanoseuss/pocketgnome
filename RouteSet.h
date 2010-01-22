//
//  RouteSet.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/21/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Route.h"

#define PrimaryRoute        @"PrimaryRoute"
#define CorpseRunRoute      @"CorpseRunRoute"

@interface RouteSet : NSObject <NSCoding, NSCopying> {
    NSString *_name;
    NSMutableDictionary *_routes;
	
	BOOL _changed;	// use so we know if we should re-save or not
}

+ (id)routeSetWithName: (NSString*)name;

@property (readwrite, copy) NSString *name;
@property (readonly, retain) NSDictionary *routes;
@property (readwrite, assign) BOOL changed;

- (Route*)routeForKey: (NSString*)key;
- (void)setRoute: (Route*)route forKey: (NSString*)key;

@end
