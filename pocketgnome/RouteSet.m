//
//  RouteSet.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/21/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "RouteSet.h"
#import "SaveDataObject.h"
#include <openssl/md5.h>

@interface RouteSet ()
@property (readwrite, retain) NSDictionary *routes;
@end

@implementation RouteSet

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.name = nil;
        self.routes = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithName: (NSString*)name {
    self = [self init];
    if(self != nil) {
        [self setName: name];
        
        [_routes setObject: [Route route] forKey: PrimaryRoute];
        [_routes setObject: [Route route] forKey: CorpseRunRoute];
    }
    return self;
}

+ (id)routeSetWithName: (NSString*)name {
    return [[[RouteSet alloc] initWithName: name] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.name = [decoder decodeObjectForKey: @"Name"];
        self.routes = [decoder decodeObjectForKey: @"Routes"] ? [decoder decodeObjectForKey: @"Routes"] : [NSDictionary dictionary];
        
        // make sure we have a route object for every type
        if( ![self routeForKey: PrimaryRoute])
            [self setRoute: [Route route] forKey: PrimaryRoute];
        if( ![self routeForKey: CorpseRunRoute])
            [self setRoute: [Route route] forKey: CorpseRunRoute];
        
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: self.routes forKey: @"Routes"];
}

- (id)copyWithZone:(NSZone *)zone
{
    RouteSet *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
    
    copy.routes = self.routes;
	copy.changed = YES;

    return copy;
}

- (void) dealloc
{
    self.name = nil;
    self.routes = nil;
    [super dealloc];
}

#pragma mark -

- (NSString*)description {
    return [NSString stringWithFormat: @"<RouteSet %@ %@>", [self name], [self UUID]];
}

@synthesize name = _name;
@synthesize routes = _routes;
@synthesize UUID = _UUID;

- (void)setRoutes: (NSDictionary*)routes {
    [_routes autorelease];
    if(routes) {
        _routes = [[NSMutableDictionary alloc] initWithDictionary: routes copyItems: YES];
    } else {
        _routes = nil;
    }
}

- (Route*)routeForKey: (NSString*)key {
    return [_routes objectForKey: key];
}

- (void)setRoute: (Route*)route forKey: (NSString*)key {
    if(!_routes) self.routes = [NSDictionary dictionary];
    if(route && key) {
        [_routes setObject: route forKey: key];
    }
}


@end
