//
//  RouteSet.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/21/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Route.h"
#import "SaveDataObject.h"

#define PrimaryRoute        @"PrimaryRoute"
#define CorpseRunRoute      @"CorpseRunRoute"

@interface RouteSet : SaveDataObject {
    NSString *_name;
    NSMutableDictionary *_routes;
}

+ (id)routeSetWithName: (NSString*)name;

@property (readwrite, copy) NSString *name;
@property (readonly, retain) NSDictionary *routes;

- (Route*)routeForKey: (NSString*)key;
- (void)setRoute: (Route*)route forKey: (NSString*)key;

@end
