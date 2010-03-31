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

#import "CombatProfileActionController.h"
#import "ActionController.h"

#import "CombatProfile.h"

@implementation CombatProfileActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_profiles = nil;
        if(![NSBundle loadNibNamed: @"CombatProfileAction" owner: self]) {
            PGLog(@"Error loading CombatProfileAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithProfiles: (NSArray*)profiles{
    self = [self init];
    if (self != nil) {
        self.profiles = profiles;
    }
    return self;
}

+ (id)combatProfileActionControllerWithProfiles: (NSArray*)profiles{
	return [[[CombatProfileActionController alloc] initWithProfiles: profiles] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [profilePopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[profilePopUp unbind: binding];
	}
}

@synthesize profiles = _profiles;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [profilePopUp itemArray] ){
		if ( [[(CombatProfile*)[item representedObject] UUID] isEqualToString:action.value] ){
			[profilePopUp selectItem:item];
			break;
		}
	}
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_CombatProfile value:nil];
	
	[action setEnabled: self.enabled];
	[action setValue: [[[profilePopUp selectedItem] representedObject] UUID]];
	
	PGLog(@"saving combat profile with %@", [[[profilePopUp selectedItem] representedObject] UUID]);
    
    return action;
}


@end
