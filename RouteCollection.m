/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

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
        self.routes = [decoder decodeObjectForKey: @"Routes"] ? [decoder decodeObjectForKey: @"Routes"] : [NSArray array];
		self.startUUID = [decoder decodeObjectForKey: @"StartUUID"];
		self.startRouteOnDeath = [[decoder decodeObjectForKey: @"StartRouteOnDeath"] boolValue];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder{
	[super encodeWithCoder:coder];
	
    [coder encodeObject: self.routes forKey: @"Routes"];
	[coder encodeObject: self.startUUID forKey: @"StartUUID"];
	[coder encodeObject: [NSNumber numberWithBool:self.startRouteOnDeath] forKey: @"StartRouteOnDeath"];
}

- (id)copyWithZone:(NSZone *)zone{
    RouteCollection *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
    
	PGLog(@"copy is changed?");
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
