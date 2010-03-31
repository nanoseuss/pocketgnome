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
#import "Action.h"

#import "RepairActionController.h"
#import "SwitchRouteActionController.h"
#import "SpellActionController.h"
#import "ItemActionController.h"
#import "MacroActionController.h"
#import "DelayActionController.h"
#import "JumpActionController.h"
#import "QuestTurnInActionController.h"
#import "QuestGrabActionController.h"
#import "InteractObjectActionController.h"
#import "InteractNPCActionController.h"
#import "CombatProfileActionController.h"
#import "VendorActionController.h"
#import "MailActionController.h"
#import "ReverseRouteActionController.h"
#import "JumpToWaypointActionController.h"

@implementation ActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.enabled = YES;
    }
    return self;
}

- (void) dealloc
{
    [view removeFromSuperview];
    [super dealloc];
}

+ (id)actionControllerWithAction: (Action*)action {
    ActionController *newController = nil;
	
    if ( [action type] == ActionType_Repair )
		newController = [[RepairActionController alloc] init];
	else if ( [action type] == ActionType_SwitchRoute )
		newController = [[SwitchRouteActionController alloc] init];
	else if ( [action type] == ActionType_Spell )
		newController = [[SpellActionController alloc] init];
	else if ( [action type] == ActionType_Item )
		newController = [[ItemActionController alloc] init];
	else if ( [action type] == ActionType_Macro )
		newController = [[MacroActionController alloc] init];
	else if ( [action type] == ActionType_Delay )
		newController = [[DelayActionController alloc] init];
	else if ( [action type] == ActionType_Jump )
		newController = [[JumpActionController alloc] init];
	else if ( [action type] == ActionType_QuestTurnIn )
		newController = [[QuestTurnInActionController alloc] init];
	else if ( [action type] == ActionType_QuestGrab )
		newController = [[QuestGrabActionController alloc] init];
	else if ( [action type] == ActionType_InteractNPC )
		newController = [[InteractNPCActionController alloc] init];
	else if ( [action type] == ActionType_InteractObject )
		newController = [[InteractObjectActionController alloc] init];	
	else if ( [action type] == ActionType_CombatProfile )
		newController = [[CombatProfileActionController alloc] init];
	else if ( [action type] == ActionType_Vendor )
		newController = [[VendorActionController alloc] init];
	else if ( [action type] == ActionType_Mail )
		newController = [[MailActionController alloc] init];
	else if ( [action type] == ActionType_ReverseRoute )
		newController = [[ReverseRouteActionController alloc] init];
	else if ( [action type] == ActionType_JumpToWaypoint )
		newController = [[JumpToWaypointActionController alloc] init];
	
    if(newController) {
        [newController setStateFromAction: action];
        return [newController autorelease];
    }
    
    return [[[ActionController alloc] init] autorelease];
}

@synthesize enabled = _enabled;
@synthesize delegate = _delegate;

- (NSView*)view {
    return view;
}

- (IBAction)validateState: (id)sender {
    return;
}

- (IBAction)disableAction: (id)sender {
    for(NSView *aView in [[self view] subviews]) {
        if( (aView != sender) && [aView respondsToSelector: @selector(setEnabled:)] ) {
            [(NSControl*)aView setEnabled: ![sender state]];
        }
    }
	
    self.enabled = ![sender state];
}

- (Action*)action {
    return nil;
    return [[[Action alloc] init] autorelease];
}

- (void)setStateFromAction: (Action*)action {
    self.enabled = [action enabled];
	
    if(self.enabled)    [disableButton setState: NSOffState];
    else                [disableButton setState: NSOnState];
	
    [self disableAction: disableButton];
}

- (void)removeBindings{
	
}

@end
