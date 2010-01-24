//
//  InteractActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "InteractActionController.h"
#import "ActionController.h"

#import "Unit.h"
#import "Mob.h"
#import "Rule.h"

@implementation InteractActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_units = nil;
        if(![NSBundle loadNibNamed: @"InteractAction" owner: self]) {
            PGLog(@"Error loading InteractAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithUnits: (NSArray*)units{
    self = [self init];
    if (self != nil) {
        self.units = units;
		
		if ( [units count] == 0 ){
			PGLog(@"no mobs...");
			[self removeBindings];
			
			NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"No Mobs"] autorelease];
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"No Nearby mobs found" action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setTag:0];
			[menu addItem: item];
			
			[unitsPopUp setMenu:menu];	
		}
    }
    return self;
}

+ (id)interactActionControllerWithUnits: (NSArray*)units{
	return [[[InteractActionController alloc] initWithUnits: units] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [unitsPopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[unitsPopUp unbind: binding];
	}
}

@synthesize units = _units;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [unitsPopUp itemArray] ){
		if ( [(Unit*)[item representedObject] GUID]== [(NSNumber*)[action value] unsignedLongLongValue] ){
			[unitsPopUp selectItem:item];
			break;
		}
	}

	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Interact value:nil];
	
	// since we pass a rule w/a name if there are NO objects
	id object = [[unitsPopUp selectedItem] representedObject];
	id value = nil;
	if ( object != nil ){
		// store entry ID
		if ( [object isKindOfClass:[Mob class]] ){
			PGLog(@"saving as mob ");
			value = [NSNumber numberWithInt:[(Unit*)object entryID]];
		}
		// store GUID
		else{
			PGLog(@"saving as player ");
			value = [NSNumber numberWithUnsignedLongLong:[(Unit*)object GUID]];
		}
	}
	
	[action setEnabled: self.enabled];
	[action setValue: value];
    
    return action;
}

@end
