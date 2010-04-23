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

#import "StatusConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"


@implementation StatusConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"StatusCondition" owner: self]) {
            PGLog(@"Error loading StatusCondition.nib.");
            previousState = 1;
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    if( ([[unitPopUp selectedItem] tag] != UnitPlayer) && ([stateSegment selectedTag] == StateIndoors)) {
        NSBeep();
        if(previousState == StateIndoors) {
            [unitPopUp selectItemWithTag: UnitPlayer];
        } else {
            [stateSegment selectSegmentWithTag: previousState];
        }
        return;
    }
    
    previousState = [stateSegment selectedTag];
}

- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyStatus 
                                                      unit: [[unitPopUp selectedItem] tag]
                                                   quality: QualityNone
                                                comparator: [comparatorSegment selectedTag] 
                                                     state: [stateSegment selectedTag]
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyStatus) return;
    
    if(![unitPopUp selectItemWithTag: [condition unit]]) {
        [unitPopUp selectItemWithTag: UnitPlayer];
    }
    [comparatorSegment selectSegmentWithTag: [condition comparator]];
    [stateSegment selectSegmentWithTag: [condition state]];
}

@end
