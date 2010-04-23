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

#import "CombatCountConditionController.h"


@implementation CombatCountConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"CombatCount" owner: self]) {
            PGLog(@"Error loading CombatCount.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    if( ([comparatorSegment selectedTag] == CompareLess) && ([valueText intValue] == 0)) {
        [comparatorSegment selectSegmentWithTag: CompareEqual];
        NSBeep();
    }
    
    if([valueText intValue] < 0) {
        [valueText setIntValue: 0];
    }
}

- (Condition*)condition {
    [self validateState: nil];
    
    int value = [valueText intValue];
    if(value < 0) value = 0;
    
    Condition *condition = [Condition conditionWithVariety: VarietyCombatCount 
                                                      unit: UnitPlayer
                                                   quality: QualityNone
                                                comparator: [comparatorSegment selectedTag]
                                                     state: value
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyCombatCount) return;
    
    [comparatorSegment selectSegmentWithTag: [condition comparator]];
    [valueText setStringValue: [NSString stringWithFormat: @"%d", [condition state]]];

    [self validateState: nil];
}

@end
