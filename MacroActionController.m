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
#import "ActionController.h"
#import "MacroActionController.h"

#import "Action.h"
#import "Macro.h"

@implementation MacroActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_macros = nil;
        if(![NSBundle loadNibNamed: @"MacroAction" owner: self]) {
            PGLog(@"Error loading MacroAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithMacros: (NSArray*)macros{
    self = [self init];
    if (self != nil) {
        self.macros = macros;
    }
    return self;
}

+ (id)macroActionControllerWithMacros: (NSArray*)macros{
	NSMutableArray *arrayToSort = [NSMutableArray arrayWithArray:macros];
    [arrayToSort sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"nameWithType" ascending: YES] autorelease]]];
	return [[[MacroActionController alloc] initWithMacros: arrayToSort] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [macroPopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[macroPopUp unbind: binding];
	}
}

@synthesize macros = _macros;

- (void)setStateFromAction: (Action*)action{

	NSNumber *macroID = [[action value] objectForKey:@"MacroID"];
	NSNumber *instant = [[action value] objectForKey:@"Instant"];
	
	for ( NSMenuItem *item in [macroPopUp itemArray] ){
		if ( [[(Macro*)[item representedObject] number] intValue] == [macroID intValue] ){
			[macroPopUp selectItem:item];
			break;
		}
	}
	
	[instantButton setState:[instant boolValue]];
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Macro value:nil];
	
	[action setEnabled: self.enabled];
	
	NSNumber *macroID = [[[macroPopUp selectedItem] representedObject] number];
	NSNumber *instant = [NSNumber numberWithBool:[instantButton state]];
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
							macroID,		@"MacroID",
							instant,		@"Instant", nil];
	[action setValue: values];
    
    return action;
}


@end
