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

#import "RouteSet.h"
#import "SaveDataObject.h"
#import "RouteCollection.h"

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
		self.parent = nil;
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
	RouteSet *route = [[[RouteSet alloc] initWithName: name] autorelease];
	route.changed = YES;
    return route;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if ( self ) {
        self.name = [decoder decodeObjectForKey: @"Name"];
        self.routes = [decoder decodeObjectForKey: @"Routes"] ? [decoder decodeObjectForKey: @"Routes"] : [NSDictionary dictionary];
		self.parent = [decoder decodeObjectForKey: @"Parent"];
        
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
	[super encodeWithCoder:coder];
	
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: self.routes forKey: @"Routes"];
	[coder encodeObject: self.parent forKey: @"Parent"];
}

- (id)copyWithZone:(NSZone *)zone
{
    RouteSet *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
    
    copy.routes = self.routes;
	copy.changed = YES;
	copy.parent = self.parent;

    return copy;
}

- (void) dealloc
{
    self.name = nil;
    self.routes = nil;
	self.parent = nil;
    [super dealloc];
}

#pragma mark -

- (NSString*)description {
    return [NSString stringWithFormat: @"<RouteSet %@ %@>", [self name], [self UUID]];
}

@synthesize parent = _parent;
@synthesize name = _name;
@synthesize routes = _routes;

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


- (void)setParent:(RouteCollection*)myParent{
	
	//PGLog(@"SETTING PARENT OF %@ TO %@", self, myParent);
	[_parent release];
	_parent = [myParent retain];
	
}

@end
