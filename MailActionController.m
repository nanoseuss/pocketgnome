//
//  MailActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/22/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MailActionController.h"
#import "ActionController.h"

@implementation MailActionController : ActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"MailAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading MailAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
	
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Mail value:nil];
	
	[action setEnabled: self.enabled];
    
    return action;
}

@end
