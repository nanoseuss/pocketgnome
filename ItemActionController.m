//
//  ItemActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "ItemActionController.h"
#import "ActionController.h"

#import "Item.h"
#import "Action.h"

@implementation ItemActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_items = nil;
        if(![NSBundle loadNibNamed: @"ItemAction" owner: self]) {
            PGLog(@"Error loading ItemAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithItems: (NSArray*)items{
    self = [self init];
    if (self != nil) {
        self.items = items;
    }
    return self;
}

+ (id)itemActionControllerWithItems: (NSArray*)items{
	NSMutableArray *arrayToSort = [NSMutableArray arrayWithArray:items];
    [arrayToSort sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease]]];
	return [[[ItemActionController alloc] initWithItems: arrayToSort] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [itemPopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[itemPopUp unbind: binding];
	}
}

@synthesize items = _items;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [itemPopUp itemArray] ){
		if ( [[(Item*)[item representedObject] ID] intValue] == [(NSNumber*)action.value intValue] ){
			[itemPopUp selectItem:item];
			break;
		}
	}
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Item value:nil];
	
	[action setEnabled: self.enabled];
	NSNumber *itemID = [[[itemPopUp selectedItem] representedObject] ID];
	[action setValue: itemID];
    
    return action;
}

@end
