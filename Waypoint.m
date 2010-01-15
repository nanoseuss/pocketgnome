//
//  Waypoint.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Waypoint.h"
#import "Action.h"
#import "Procedure.h"

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
		self.title = @"";
		self.procedure = [[Procedure alloc] init];
		self.actions = [NSArray array];
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
		self.title = [decoder decodeObjectForKey: @"Title"];
		self.procedure = [decoder decodeObjectForKey: @"Procedure"] ? [decoder decodeObjectForKey: @"Procedure"] : [[Procedure alloc] init];
		self.actions = [decoder decodeObjectForKey: @"Actions"] ? [decoder decodeObjectForKey: @"Actions"] : [NSArray array];

		
		// set actions
		/*NSArray *actionsTemp = [decoder decodeObjectForKey: @"Actions"];
		[_actions autorelease];
		if ( actionsTemp ) {
			_actions = [[NSMutableArray alloc] initWithArray: actionsTemp copyItems: YES];
		} else {
			_actions = nil;
		}*/
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.position forKey: @"Position"];
    [coder encodeObject: self.title forKey: @"Title"];
	[coder encodeObject: self.procedure forKey: @"Procedure"];
	[coder encodeObject: self.actions forKey: @"Actions"];

    // only encode the action if it is something other than normal
    if(self.action.type > ActionType_None) {
        [coder encodeObject: self.action forKey: @"Action"];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    Waypoint *copy = [[[self class] allocWithZone: zone] initWithPosition: self.position];
    copy.action = self.action;
	copy.title = self.title;
	copy.procedure = self.procedure;
	copy.actions = self.actions;
    
    return copy;
}

- (void) dealloc
{
    self.position = nil;
    self.action = nil;
	self.title = nil;
	self.actions = nil;
	self.procedure = nil;
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<Waypoint X: %.2f Y: %.2f Z: %.2f>", [self.position xPosition], [self.position yPosition], [self.position zPosition]];
}

@synthesize position = _position;
@synthesize action = _action;
@synthesize title = _title;
@synthesize procedure = _procedure;
@synthesize actions = _actions;


- (void)addAction: (Action*)action{
	
	if ( action != nil )
		[_actions addObject:action];
    else
        PGLog(@"addAction: failed; action is nil");
}

- (void)setActions: (NSArray*)actions {
    [_actions autorelease];
    if ( actions ) {
        _actions = [[NSMutableArray alloc] initWithArray: actions copyItems: YES];
    }
	else {
        _actions = [[NSMutableArray alloc] init];
    }
}

@end
