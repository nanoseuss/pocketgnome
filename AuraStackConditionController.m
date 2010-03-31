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

#import "AuraStackConditionController.h"


@implementation AuraStackConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"AuraStackCondition" owner: self]) {
            PGLog(@"Error loading AuraStackCondition nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {

}

- (Condition*)condition {
    [self validateState: nil];
    
    int stackCount = [stackText intValue];
    
    id value = nil;
    if( [typeSegment selectedTag] == TypeValue )
        value = [NSNumber numberWithInt: [auraText intValue]];
    if( [typeSegment selectedTag] == TypeString )
        value = [auraText stringValue];
    
    Condition *condition = [Condition conditionWithVariety: VarietyAuraStack 
                                                      unit: [[unitPopUp selectedItem] tag]
                                                   quality: [[qualityPopUp selectedItem] tag]
                                                comparator: [[comparatorPopUp selectedItem] tag]
                                                     state: stackCount
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyAuraStack) return;
    
    if(![unitPopUp selectItemWithTag: [condition unit]]) {
        [qualityPopUp selectItemWithTag: UnitPlayer];
    }

    if(![qualityPopUp selectItemWithTag: [condition quality]]) {
        [qualityPopUp selectItemWithTag: QualityBuff];
    }
    
    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareMore];
    }
    
    [stackText setStringValue: [NSString stringWithFormat: @"%d", [condition state]]];
    [auraText setStringValue: [NSString stringWithFormat: @"%@", [condition value]]];
    
    [typeSegment selectSegmentWithTag: [condition type]];
    
    [self validateState: nil];
    
    //if([condition type] == TypeValue)
    //else
    // [valueText setStringValue: [condition value]];
}

@end
