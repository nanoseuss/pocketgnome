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

#import "InventoryConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"


@implementation InventoryConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"InventoryCondition" owner: self]) {
            PGLog(@"Error loading InventoryCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    //[qualitySegment selectSegmentWithTag: QualityInventory];
}

- (Condition*)condition {
    [self validateState: nil];
    
    int quantity = [quantityText intValue];
    if(quantity < 0) quantity = 0;
    
    id value = nil;
    if( [typeSegment selectedTag] == TypeValue ) {
        NSString *string = [[itemText stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        value = [NSNumber numberWithInt: [string intValue]];
    }
    if( [typeSegment selectedTag] == TypeString )
        value = [itemText stringValue];
        
    Condition *condition = [Condition conditionWithVariety: VarietyInventory
                                                      unit: UnitPlayer 
                                                   quality: QualityInventory
                                                comparator: [[comparatorPopUp selectedItem] tag] 
                                                     state: quantity
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyInventory) return;
    
    [typeSegment selectSegmentWithTag: [condition type]];
    //[unitSegment selectSegmentWithTag: [condition unit]];
    //[qualitySegment selectSegmentWithTag: [condition quality]];
    //[comparatorSegment selectSegmentWithTag: [condition comparator]];

    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareMore];
    }
    
    // set quantity text with value from state variable
    [quantityText setStringValue: [NSString stringWithFormat: @"%d", [condition state]]];
    
    if( [[condition value] isKindOfClass: [NSString class]] )
        [itemText setStringValue: [condition value]];
    else
        [itemText setStringValue: [[condition value] stringValue]];
}

@end
