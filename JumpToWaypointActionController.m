//
//  JumpToWaypointActionController.m
//  Pocket Gnome
//
//  Created by Josh on 3/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "JumpToWaypointActionController.h"
#import "ActionController.h"

@implementation JumpToWaypointActionController

- (id)init
{
    self = [super init];
    if (self != nil){
		_waypoints = [[NSMutableArray array] retain];

        if(![NSBundle loadNibNamed: @"JumpToWaypointAction" owner: self]) {
            PGLog(@"Error loading JumpToWaypointAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithWaypoints: (int)waypoints{
    self = [self init];
    if (self != nil) {
		
		int i = 0;
		for ( ; i < waypoints; i++ ){
			[_waypoints addObject:[NSNumber numberWithInt:i]];
		}
		PGLog(@"0x%X TOTAL OF %d waypoints now!", self, [_waypoints count]);
    }
    return self;
}

+ (id)jumpToWaypointActionControllerWithTotalWaypoints: (int)waypoints{
	return [[[JumpToWaypointActionController alloc] initWithWaypoints: waypoints] autorelease];
}

@synthesize waypoints = _waypoints;

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [waypointsPopUpButton exposedBindings];
	for ( NSString *binding in bindings ){
		[waypointsPopUpButton unbind: binding];
	}
}

- (NSArray*)waypoints{

	PGLog(@"0x%X total: %d", self, [_waypoints count]);
	
	return _waypoints;
}

- (IBAction)validateState: (id)sender {
	
}

- (void)setStateFromAction: (Action*)action{
	
	/*NSNumber *spellID = [[action value] objectForKey:@"SpellID"];
	NSNumber *instant = [[action value] objectForKey:@"Instant"];
	
	for ( NSMenuItem *item in [spellPopUp itemArray] ){
		if ( [[(Spell*)[item representedObject] ID] intValue] == [spellID intValue] ){
			[spellPopUp selectItem:item];
			break;
		}
	}
	
	[spellInstantButton setState:[instant boolValue]];
	
	[super setStateFromAction:action];*/
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_JumpToWaypoint value:nil];
	
	[action setEnabled: self.enabled];
    
    return action;
}

@end
