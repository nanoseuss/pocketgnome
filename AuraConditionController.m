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

#import "AuraConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"


@implementation AuraConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"AuraCondition" owner: self]) {
            PGLog(@"Error loading AuraCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    // set visibility for dispel/aura components
    BOOL showDispel = (([qualityPopUp selectedTag] == QualityBuffType) || ([qualityPopUp selectedTag] == QualityDebuffType));
    [valueText setHidden: showDispel];
    [typeSegment setHidden: showDispel];
    [dispelTypePopUp setHidden: !showDispel];
}

- (Condition*)condition {
    [self validateState: nil];
    
    BOOL showDispel = (([qualityPopUp selectedTag] == QualityBuffType) || ([qualityPopUp selectedTag] == QualityDebuffType));
    
    id value = nil;
    if(!showDispel) {
        if( [typeSegment selectedTag] == TypeValue )
            value = [NSNumber numberWithInt: [valueText intValue]];
        if( [typeSegment selectedTag] == TypeString )
            value = [valueText stringValue];
    }
    
    Condition *condition = [Condition conditionWithVariety: VarietyAura 
                                                      unit: [[unitPopUp selectedItem] tag]
                                                   quality: [[qualityPopUp selectedItem] tag]
                                                comparator: [[comparatorPopUp selectedItem] tag]
                                                     state: [[dispelTypePopUp selectedItem] tag]
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyAura) return;
    
    //[unitSegment selectSegmentWithTag: [condition unit]];
    
    if(![unitPopUp selectItemWithTag: [condition unit]]) {
        [unitPopUp selectItemWithTag: UnitPlayer];
    }

    if(![qualityPopUp selectItemWithTag: [condition quality]]) {
        [qualityPopUp selectItemWithTag: QualityBuff];
    }
    
    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareExists];
    }
    
    if(![dispelTypePopUp selectItemWithTag: [condition state]]) {
        [dispelTypePopUp selectItemWithTag: StateMagic];
    }
    
    [typeSegment selectSegmentWithTag: [condition type]];
    
    NSString *valueString = nil;
    if( [[condition value] isKindOfClass: [NSString class]] )
        valueString = [condition value];
    else
        valueString = [[condition value] stringValue];
        
    [valueText setStringValue: valueString ? valueString :  @""];        
    
    [self validateState: nil];
    
    //if([condition type] == TypeValue)
    //else
    // [valueText setStringValue: [condition value]];
}

@end
