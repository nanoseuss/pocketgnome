//
//  Battleground.m
//  Pocket Gnome
//
//  Created by Josh on 2/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "Battleground.h"
#import "RouteCollection.h"

@interface Battleground ()
@property (readwrite, retain) NSString *name;
@property (readwrite) int zone;
@end

@implementation Battleground

- (id) init{
    self = [super init];
    if ( self != nil ){
		
		_name = nil;
        _zone = -1;
		_enabled = YES;
		_routeCollection = nil;
		_changed = NO;
    }
    return self;
}

- (id)initWithName:(NSString*)name andZone:(int)zone{
	self = [self init];
    if (self != nil) {
		_name = [name retain];
		_zone = zone;
		_enabled = YES;	
	}
	return self;
}


+ (id)battlegroundWithName: (NSString*)name andZone: (int)zone {
    return [[[Battleground alloc] initWithName: name andZone: zone] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder{
	self = [self init];
	if ( self ) {
        _zone = [[decoder decodeObjectForKey: @"Zone"] intValue];
        _name = [[decoder decodeObjectForKey: @"Name"] retain];
		_enabled = [[decoder decodeObjectForKey: @"Enabled"] boolValue];
		self.routeCollection = [decoder decodeObjectForKey:@"RouteCollection"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeObject: [NSNumber numberWithInt:self.zone] forKey: @"Zone"];
    [coder encodeObject: self.name forKey: @"Name"];
	[coder encodeObject: [NSNumber numberWithBool:self.enabled] forKey: @"Enabled"];
	[coder encodeObject: self.routeCollection forKey:@"RouteCollection"];
}

- (id)copyWithZone:(NSZone *)zone{
    Battleground *copy = [[[self class] allocWithZone: zone] initWithName: self.name andZone:self.zone];
	
	_enabled = self.enabled;
	copy.routeCollection = self.routeCollection;

    return copy;
}

- (void) dealloc {
    self.name = nil;
    [super dealloc];
}

@synthesize zone = _zone;
@synthesize name = _name;
@synthesize enabled = _enabled;
@synthesize routeCollection = _routeCollection;
@synthesize changed = _changed;

- (NSString*)description{
	return [NSString stringWithFormat: @"<%@; Addr: 0x%X>", self.name, self];
}

#pragma mark Accessors

- (void)setRouteCollection:(RouteCollection *)rc{

	// only set changed to yes if it's a different RC!
	if ( ![[rc UUID] isEqualToString:[_routeCollection UUID]] ){
		self.changed = YES;
	}
	
	_routeCollection = [rc retain];
}

- (void)setName:(NSString*)name{
	_name = [[name copy] retain];
	self.changed = YES;
}

- (void)setEnabled:(BOOL)enabled{
	_enabled = enabled;
	self.changed = YES;
}

- (void)setChanged:(BOOL)changed{
	_changed = changed;
	//PGLog(@"%@ set to %d", self, changed);
}

@end

