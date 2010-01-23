//
//  RouteSet.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/21/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "RouteSet.h"
#include <openssl/md5.h>

@interface RouteSet ()
@property (readwrite, retain) NSDictionary *routes;
@property (readwrite, retain) NSString *UUID;
@end

@implementation RouteSet

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.name = nil;
        self.routes = [NSMutableDictionary dictionary];
		_changed = NO;
		
		// create a new UUID
		CFUUIDRef uuidObj = CFUUIDCreate(nil);
		self.UUID = (NSString*)CFUUIDCreateString(nil, uuidObj);
		CFRelease(uuidObj);
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
		self.UUID = [decoder decodeObjectForKey: @"UUID"];
        self.routes = [decoder decodeObjectForKey: @"Routes"] ? [decoder decodeObjectForKey: @"Routes"] : [NSDictionary dictionary];
		
		if ( !self.UUID || [self.UUID length] == 0 ){
			PGLog(@"[RouteSet] No UUID found! Generating!");
			
			// create a new UUID
			CFUUIDRef uuidObj = CFUUIDCreate(nil);
			self.UUID = (NSString*)CFUUIDCreateString(nil, uuidObj);
			CFRelease(uuidObj);
			_changed = YES;
		}
        
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
	[coder encodeObject: self.UUID forKey: @"UUID"];
    [coder encodeObject: self.routes forKey: @"Routes"];
}

- (id)copyWithZone:(NSZone *)zone
{
    RouteSet *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
    
    copy.routes = self.routes;
	
	// create a new UUID
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	copy.UUID = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
    
    return copy;
}

- (void) dealloc
{
    self.name = nil;
    self.routes = nil;
	self.UUID = nil;
    [super dealloc];
}

#pragma mark -

- (NSString*)description {
    return [NSString stringWithFormat: @"<RouteSet %@>", [self name]];
}

@synthesize name = _name;
@synthesize routes = _routes;
@synthesize changed = _changed;
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
