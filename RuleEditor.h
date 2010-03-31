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

#import <Cocoa/Cocoa.h>
#import "Rule.h"

@class Controller;
@class BotController;

@class BetterSegmentedControl;

#define RuleEditorSaveRule      1
#define RuleEditorCancelRule    0

@interface RuleEditor : NSObject {
    IBOutlet Controller *controller;
    IBOutlet BotController *botController;
    IBOutlet id spellController;
    IBOutlet id inventoryController;

    IBOutlet id conditionMatchingSegment;
    IBOutlet id conditionResultTypeSegment;
	IBOutlet BetterSegmentedControl *conditionTargetType;
    
    IBOutlet id spellRuleTableView;
    IBOutlet id spellRuleTypeDropdown;
    
    IBOutlet NSPopUpButton *resultActionDropdown;
    IBOutlet id ruleNameText;
    IBOutlet id ruleEditorWindow;
	
	IBOutlet NSTextField *labelNoTarget;
    
    NSMutableArray *_conditionList;
    
    NSMenu *_spellsMenu, *_itemsMenu, *_macrosMenu, *_interactMenu;
    BOOL validSelection;
}

@property BOOL validSelection;

- (IBAction)addCondition:(id)sender;
- (IBAction)testCondition:(id)sender;
- (IBAction)testRule:(id)sender;
- (IBAction)saveRule:(id)sender;
- (IBAction)cancelRule:(id)sender;
- (IBAction)setResultType:(id)sender;

- (Rule*)rule;
- (void)initiateEditorForRule: (Rule*)rule;
- (NSWindow*)window;

@end
