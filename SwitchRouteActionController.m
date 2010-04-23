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

#import "SwitchRouteActionController.h"
#import "ActionController.h"

#import "RouteSet.h"

@implementation SwitchRouteActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
		_routes = nil;
        if(![NSBundle loadNibNamed: @"SwitchRouteAction" owner: self]) {
            PGLog(@"Error loading SwitchRouteAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}
	
- (id) initWithRoutes: (NSArray*)routes{
    self = [self init];
    if (self != nil) {
        self.routes = routes;
		
		if ( [routePopUp numberOfItems] > 0 ){
			[routePopUp selectItemAtIndex:0];
			//[routePopUp removeItemWithTitle:@"No Value"];
		}
    }
    return self;
}


+ (id)switchRouteActionControllerWithRoutes: (NSArray*)routes{
	return [[[SwitchRouteActionController alloc] initWithRoutes: routes] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [routePopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[routePopUp unbind: binding];
	}
	/*
	[routePopUp unbind:NSSelectedValueBinding];
	[routePopUp unbind:NSContentObjectBinding];
	[routePopUp unbind:NSContentValuesBinding];
	[routePopUp unbind:NSContentBinding];*/
}

@synthesize routes = _routes;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [routePopUp itemArray] ){
		
		//PGLog(@"not equal? %@ %@", [(RouteSet*)[item representedObject] UUID], action.value);
		
		if ( [[(RouteSet*)[item representedObject] UUID] isEqualToString:action.value] ){
			//PGLog(@"ZOMG EQUAL!");
			[routePopUp selectItem:item];
			break;
		}
	}
		
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_SwitchRoute value:nil];
	
	[action setEnabled: self.enabled];
	[action setValue: [[[routePopUp selectedItem] representedObject] UUID]];
    
    return action;
}

@end
