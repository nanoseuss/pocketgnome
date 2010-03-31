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

#import "JumpToWaypointActionController.h"
#import "ActionController.h"

@implementation JumpToWaypointActionController

- (id)init
{
    self = [super init];
    if (self != nil){
		_maxWaypoints = 0;

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
		_maxWaypoints = waypoints;
    }
    return self;
}

+ (id)jumpToWaypointActionControllerWithTotalWaypoints: (int)waypoints{
	return [[[JumpToWaypointActionController alloc] initWithWaypoints: waypoints] autorelease];
}

- (IBAction)validateState: (id)sender {
	
	if ( [waypointNumTextView intValue] > _maxWaypoints || [waypointNumTextView intValue] < 1 ){
		[waypointNumTextView setStringValue:@"1"];
	}
}

- (void)setStateFromAction: (Action*)action{
	
	[waypointNumTextView setIntValue:[[action value] intValue]];
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_JumpToWaypoint value:nil];
	
	[action setEnabled: self.enabled];
	[action setValue: [waypointNumTextView stringValue]];
    
    return action;
}

@end
