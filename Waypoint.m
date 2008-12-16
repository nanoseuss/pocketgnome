//
//  Waypoint.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Waypoint.h"
#import "Action.h"

@implementation Waypoint

- (id) init
{
    return [self initWithPosition: [Position positionWithX: -1 Y: -1 Z: -1]];
}

- (id)initWithPosition: (Position*)position {

    self = [super init];
    if (self != nil) {
        self.position = position;
        self.action = [Action action];
    }
    return self;
}


+ (id)waypointWithPosition: (Position*)position {
    Waypoint *waypoint = [[Waypoint alloc] initWithPosition: position];
    
    return [waypoint autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        [NSKeyedUnarchiver setClass: [Action class] forClassName: @"WaypointAction"];
        self.position = [decoder decodeObjectForKey: @"Position"];
        self.action = [decoder decodeObjectForKey: @"Action"] ? [decoder decodeObjectForKey: @"Action"] : [Action action];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.position forKey: @"Position"];
    
    // only encode the action if it is something other than normal
    if(self.action.type > ActionType_None) {
        [coder encodeObject: self.action forKey: @"Action"];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    Waypoint *copy = [[[self class] allocWithZone: zone] initWithPosition: self.position];
    copy.action = self.action;
    
    return copy;
}

- (void) dealloc
{
    self.position = nil;
    self.action = nil;
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<Waypoint X: %.2f Y: %.2f Z: %.2f>", [self.position xPosition], [self.position yPosition], [self.position zPosition]];
}

@synthesize position = _position;
@synthesize action = _action;


@end
