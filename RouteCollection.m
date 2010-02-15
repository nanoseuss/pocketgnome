//
//  RouteCollection.m
//  Pocket Gnome
//
//  Created by Josh on 2/11/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "RouteCollection.h"
#import "SaveDataObject.h"

#import "RouteSet.h"

@interface RouteCollection ()
@property (readwrite, retain) NSMutableArray *routes;
@property (readwrite, copy) NSString *startUUID;
@end

@implementation RouteCollection

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.name = nil;
        self.routes = [NSMutableArray array];
		self.startUUID = nil;
		self.startRouteOnDeath = NO;
    }
    return self;
}

- (id)initWithName: (NSString*)name {
    self = [self init];
    if ( self != nil ){
        [self setName: name];
    }
    return self;
}

+ (id)routeCollectionWithName: (NSString*)name {
	RouteCollection *rc = [[[RouteCollection alloc] initWithName: name] autorelease];
	rc.changed = YES;
    return rc;
}

- (id)initWithCoder:(NSCoder *)decoder{
	self = [super initWithCoder:decoder];
	if ( self ) {
        self.name = [decoder decodeObjectForKey: @"Name"];
        self.routes = [decoder decodeObjectForKey: @"Routes"] ? [decoder decodeObjectForKey: @"Routes"] : [NSArray array];
		self.startUUID = [decoder decodeObjectForKey: @"StartUUID"];
		self.startRouteOnDeath = [[decoder decodeObjectForKey: @"StartRouteOnDeath"] boolValue];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder{
	[super encodeWithCoder:coder];
	
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: self.routes forKey: @"Routes"];
	[coder encodeObject: self.startUUID forKey: @"StartUUID"];
	[coder encodeObject: [NSNumber numberWithBool:self.startRouteOnDeath] forKey: @"StartRouteOnDeath"];
}

- (id)copyWithZone:(NSZone *)zone{
    RouteCollection *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
    
	copy.changed = YES;
	copy.startUUID = self.startUUID;
	copy.startRouteOnDeath = self.startRouteOnDeath;

	// add copies! Not originals! (we want a new UUID)
	for ( RouteSet *route in self.routes ){
		[copy addRouteSet:[route copy]];
	}
	
    return copy;
}

- (void) dealloc{
    self.name = nil;
    self.routes = nil;
	self.startUUID = nil;
    [super dealloc];
}

@synthesize routes = _routes;
@synthesize name = _name;
@synthesize startUUID = _startUUID;
@synthesize startRouteOnDeath = _startRouteOnDeath;

#pragma mark -

- (NSString*)description {
    return [NSString stringWithFormat: @"<RouteCollection %@ %@>", [self name], [self UUID]];
}

- (void)moveRouteSet:(RouteSet*)route toLocation:(int)index{

	RouteSet *routeToMove = nil;
	for ( RouteSet *tmp in _routes ){
		if ( [[tmp UUID] isEqualToString:[route UUID]] ){
			routeToMove = [tmp retain];
			break;
		}
	}
	
	// route found! remove + re insert!
	if ( routeToMove ){
		[_routes removeObject:routeToMove];
		[_routes insertObject:routeToMove atIndex:index];
	}
}

- (void)addRouteSet:(RouteSet*)route{
	
	// make sure it doesn't exist already! (in theory this should never happen)
	for ( RouteSet *tmp in _routes ){
		if ( [[tmp UUID] isEqualToString:[route UUID]] ){
			return;
		}
	}
	
	if ( route && ![_routes containsObject:route] ){
		route.parent = self;
		[_routes addObject:route];
		self.changed = YES;
	}
}

- (BOOL)removeRouteSet:(RouteSet*)route{
	
	for ( RouteSet *tmp in _routes ){
		if ( [[tmp UUID] isEqualToString:[route UUID]] ){
			[_routes removeObject:tmp];
			self.changed = YES;
			return YES;
		}
	}
	
	return NO;	
}

- (BOOL)containsRouteSet:(RouteSet*)route{
	return NO;
}

#pragma mark Starting Route stuff

- (RouteSet*)startingRoute{
	
	for ( RouteSet *route in _routes ){
		if ( [self.startUUID isEqualToString:[route UUID]] ){
			return route;
		}
	}
	
	return nil;
}

- (void)setStartRoute:(RouteSet*)route{
	
	if ( route ){
		self.startUUID = [route UUID];
	}
	else{
		self.startUUID = nil;
	}
	
	self.changed = YES;
}

- (BOOL)isStartingRoute:(RouteSet*)route{

	if ( [[route UUID] isEqualToString:_startUUID] ){
		return YES;
	}
	
	return NO;
}

#pragma mark Accessors

// so we can set changed to yes!
- (void)setStartRouteOnDeath:(BOOL)val{
	self.changed = YES;
	_startRouteOnDeath = val;
}

@end
