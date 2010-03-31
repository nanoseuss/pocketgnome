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

#import "InteractNPCActionController.h"
#import "ActionController.h"

#import "Unit.h"
#import "Mob.h"

@implementation InteractNPCActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_units = nil;
        if(![NSBundle loadNibNamed: @"InteractNPCAction" owner: self]) {
            PGLog(@"Error loading InteractNPCAction.nib.");
            
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

+ (id)interactNPCActionControllerWithUnits: (NSArray*)units{
	return [[[InteractNPCActionController alloc] initWithUnits: units] autorelease];
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
    
    Action *action = [Action actionWithType:ActionType_InteractNPC value:nil];
	
	id object = [[unitsPopUp selectedItem] representedObject];
	id value = [NSNumber numberWithInt:[(Mob*)object entryID]];
	
	[action setEnabled: self.enabled];
	[action setValue: value];
    
    return action;
}

@end
