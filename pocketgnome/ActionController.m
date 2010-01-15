//
//  ActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/14/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "ActionController.h"
#import "Action.h"

#import "RepairActionController.h"
#import "SwitchRouteActionController.h"

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
