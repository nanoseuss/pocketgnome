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

#import "InteractObjectActionController.h"
#import "ActionController.h"

#import "Node.h"

@implementation InteractObjectActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_objects = nil;
        if(![NSBundle loadNibNamed: @"InteractObjectAction" owner: self]) {
            PGLog(@"Error loading InteractObjectAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithZeObjects: (NSArray*)objects{
    self = [self init];
    if (self != nil) {
        self.objects = objects;
		
		if ( [objects count] == 0 ){
			[self removeBindings];
			
			NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"No Objects"] autorelease];
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"No nearby nodes were found" action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setTag:0];
			[menu addItem: item];
			
			[objectsPopUp setMenu:menu];	
		}
    }
    return self;
}

+ (id)interactObjectActionControllerWithObjects: (NSArray*)objects{
	return [[[InteractObjectActionController alloc] initWithZeObjects: objects] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [objectsPopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[objectsPopUp unbind: binding];
	}
}

@synthesize objects = _objects;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [objectsPopUp itemArray] ){
		if ( [(Node*)[item representedObject] GUID] == [(NSNumber*)[action value] unsignedLongLongValue] ){
			[objectsPopUp selectItem:item];
			break;
		}
	}

	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_InteractObject value:nil];
	
	id object = [[objectsPopUp selectedItem] representedObject];
	id value = [NSNumber numberWithInt:[(Node*)object entryID]];
	
	[action setEnabled: self.enabled];
	[action setValue: value];
    
    return action;
}

@end
