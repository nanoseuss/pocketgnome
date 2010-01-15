//
//  ConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "ConditionController.h"
#import "Condition.h"
#import "HealthConditionController.h"
#import "StatusConditionController.h"
#import "AuraConditionController.h"
#import "DistanceConditionController.h"
#import "InventoryConditionController.h"
#import "ComboPointConditionController.h"
#import "AuraStackConditionController.h"
#import "TotemConditionController.h"
#import "TempEnchantConditionController.h"
#import "TargetTypeConditionController.h"
#import "TargetClassConditionController.h"
#import "CombatCountConditionController.h"
#import "ProximityCountConditionController.h"
#import "SpellCooldownConditionController.h"
#import "LastSpellCastConditionController.h"
#import "RuneConditionController.h"

@implementation ConditionController


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

+ (id)conditionControllerWithCondition: (Condition*)condition {
    ConditionController *newController = nil;

    if( [condition variety] == VarietyHealth ) {
        newController = [[HealthConditionController alloc] init];
    }
    if( [condition variety] == VarietyStatus ) {
        newController = [[StatusConditionController alloc] init];
    }
    if( [condition variety] == VarietyAura ) {
        newController = [[AuraConditionController alloc] init];
    }
    if( [condition variety] == VarietyDistance ) {
        newController = [[DistanceConditionController alloc] init];
    }
    if( [condition variety] == VarietyInventory ) {
        newController = [[InventoryConditionController alloc] init];
    }
    if( [condition variety] == VarietyComboPoints ) {
        newController = [[ComboPointConditionController alloc] init];
    }
    if( [condition variety] == VarietyAuraStack ) {
        newController = [[AuraStackConditionController alloc] init];
    }
    if( [condition variety] == VarietyTotem ) {
        newController = [[TotemConditionController alloc] init];
    }
    if( [condition variety] == VarietyTempEnchant ) {
        newController = [[TempEnchantConditionController alloc] init];
    }
    
    
    if( [condition variety] == VarietyTargetType ) {
        newController = [[TargetTypeConditionController alloc] init];
    }
    if( [condition variety] == VarietyTargetClass ) {
        newController = [[TargetClassConditionController alloc] init];
    }
    if( [condition variety] == VarietyCombatCount ) {
        newController = [[CombatCountConditionController alloc] init];
    }
    if( [condition variety] == VarietyProximityCount ) {
        newController = [[ProximityCountConditionController alloc] init];
    }
	if( [condition variety] == VarietySpellCooldown ) {
        newController = [[SpellCooldownConditionController alloc] init];
    }
	if( [condition variety] == VarietyLastSpellCast ) {
        newController = [[LastSpellCastConditionController alloc] init];
    }
	if( [condition variety] == VarietyRune ) {
        newController = [[RuneConditionController alloc] init];
    }
	
    if(newController) {
        [newController setStateFromCondition: condition];
        return [newController autorelease];
    }
    
    return [[[ConditionController alloc] init] autorelease];
}

@synthesize enabled = _enabled;
@synthesize delegate = _delegate;

- (NSView*)view {
    return view;
}

- (IBAction)validateState: (id)sender {
    return;
}

- (IBAction)disableCondition: (id)sender {
    for(NSView *aView in [[self view] subviews]) {
        if( (aView != sender) && [aView respondsToSelector: @selector(setEnabled:)] ) {
            [(NSControl*)aView setEnabled: ![sender state]];
        }
    }

    self.enabled = ![sender state];
}

- (Condition*)condition {
    return nil;
    return [[[Condition alloc] init] autorelease];
}

- (void)setStateFromCondition: (Condition*)condition {
    self.enabled = [condition enabled];

    if(self.enabled)    [disableButton setState: NSOffState];
    else                [disableButton setState: NSOnState];

    [self disableCondition: disableButton];
}

@end
