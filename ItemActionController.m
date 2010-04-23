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
	
	NSNumber *itemID = [[action value] objectForKey:@"ItemID"];
	NSNumber *instant = [[action value] objectForKey:@"Instant"];
	
	for ( NSMenuItem *item in [itemPopUp itemArray] ){
		if ( [[(Item*)[item representedObject] ID] intValue] == [itemID intValue] ){
			[itemPopUp selectItem:item];
			break;
		}
	}
	
	[itemInstantButton setState:[instant boolValue]];
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Item value:nil];
	
	[action setEnabled: self.enabled];
	
	NSNumber *spellID = [[[itemPopUp selectedItem] representedObject] ID];
	NSNumber *instant = [NSNumber numberWithBool:[itemInstantButton state]];
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
							spellID,		@"ItemID",
							instant,		@"Instant", nil];
	[action setValue: values];
    
    return action;
}

@end
