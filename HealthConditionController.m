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
 
#import "HealthConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"

@implementation HealthConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"HealthCondition" owner: self]) {
            PGLog(@"Error loading HealthCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    // target health must be in %
    if( ([unitSegment selectedTag] == UnitTarget) && ([[qualityPopUp selectedItem] tag] == QualityHealth) ) {
        [typeSegment selectSegmentWithTag: TypePercent];
    }
    
    // pet happiness must be in %
    if( ([unitSegment selectedTag] == UnitPlayerPet) && ([[qualityPopUp selectedItem] tag] == QualityHappiness) ) {
        [typeSegment selectSegmentWithTag: TypePercent];
    }
}


- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyHealth 
                                                      unit: [unitSegment selectedTag] 
                                                   quality: [[qualityPopUp selectedItem] tag] // [qualitySegment selectedTag] 
                                                comparator: [comparatorSegment selectedTag] 
                                                     state: StateNone
                                                      type: [typeSegment selectedTag]
                                                     value: [NSNumber numberWithInt: [quantityText intValue]]];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyHealth) return;
    
    [unitSegment selectSegmentWithTag: [condition unit]];
    if(![qualityPopUp selectItemWithTag: [condition quality]]) {
        [qualityPopUp selectItemWithTag: 2];
    }
    //[qualitySegment selectSegmentWithTag: [condition quality]];
    [comparatorSegment selectSegmentWithTag: [condition comparator]];
    [typeSegment selectSegmentWithTag: [condition type]];
    
    [quantityText setStringValue: [[condition value] stringValue]];
}

@end
