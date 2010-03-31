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
#import "DurabilityConditionController.h"
#import "PlayerLevelConditionController.h"
#import "PlayerZoneConditionController.h"
#import "QuestConditionController.h"
#import "RouteRunCountConditionController.h"
#import "RouteRunTimeConditionController.h"
#import "InventoryFreeConditionController.h"
#import "MobsKilledConditionController.h"
#import "GateConditionController.h"
#import "StrandStatusConditionController.h"

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
    else if( [condition variety] == VarietyStatus ) {
        newController = [[StatusConditionController alloc] init];
    }
    else if( [condition variety] == VarietyAura ) {
        newController = [[AuraConditionController alloc] init];
    }
    else if( [condition variety] == VarietyDistance ) {
        newController = [[DistanceConditionController alloc] init];
    }
    else if( [condition variety] == VarietyInventory ) {
        newController = [[InventoryConditionController alloc] init];
    }
    else if( [condition variety] == VarietyComboPoints ) {
        newController = [[ComboPointConditionController alloc] init];
    }
    else if( [condition variety] == VarietyAuraStack ) {
        newController = [[AuraStackConditionController alloc] init];
    }
    else if( [condition variety] == VarietyTotem ) {
        newController = [[TotemConditionController alloc] init];
    }
    else if( [condition variety] == VarietyTempEnchant ) {
        newController = [[TempEnchantConditionController alloc] init];
    }
    else if( [condition variety] == VarietyTargetType ) {
        newController = [[TargetTypeConditionController alloc] init];
    }
    else if( [condition variety] == VarietyTargetClass ) {
        newController = [[TargetClassConditionController alloc] init];
    }
    else if( [condition variety] == VarietyCombatCount ) {
        newController = [[CombatCountConditionController alloc] init];
    }
    else if( [condition variety] == VarietyProximityCount ) {
        newController = [[ProximityCountConditionController alloc] init];
    }
	else if( [condition variety] == VarietySpellCooldown ) {
        newController = [[SpellCooldownConditionController alloc] init];
    }
	else if( [condition variety] == VarietyLastSpellCast ) {
        newController = [[LastSpellCastConditionController alloc] init];
    }
	else if( [condition variety] == VarietyRune ) {
        newController = [[RuneConditionController alloc] init];
    }
	
	// for waypoint actions
	else if ( [condition variety] == VarietyDurability )
		newController = [[DurabilityConditionController alloc] init];
	else if ( [condition variety] == VarietyPlayerLevel )
		newController = [[PlayerLevelConditionController alloc] init];
	else if ( [condition variety] == VarietyPlayerZone )
		newController = [[PlayerZoneConditionController alloc] init];
	else if ( [condition variety] == VarietyQuest  )
		newController = [[QuestConditionController alloc] init];
	else if ( [condition variety] == VarietyRouteRunCount )
		newController = [[RouteRunCountConditionController alloc] init];
	else if ( [condition variety] == VarietyRouteRunTime )
		newController = [[RouteRunTimeConditionController alloc] init];
	else if ( [condition variety] == VarietyInventoryFree )
		newController = [[InventoryFreeConditionController alloc] init];
	else if ( [condition variety] == VarietyMobsKilled )
		newController = [[MobsKilledConditionController alloc] init];
	else if ( [condition variety] == VarietyGate )
		newController = [[GateConditionController alloc] init];
	else if ( [condition variety] == VarietyStrandStatus )
		newController = [[StrandStatusConditionController alloc] init];
	
	
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
