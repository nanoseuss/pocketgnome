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
	
	[action setEnabled: self.enabled];
	[action setValue: [NSNumber numberWithUnsignedLongLong:[(Unit*)[[unitsPopUp selectedItem] representedObject] GUID]]];
    
    return action;
}

@end
