//
//  QuestConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "QuestConditionController.h"


@implementation QuestConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"QuestCondition" owner: self]) {
            PGLog(@"Error loading QuestCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
	
}

@end
