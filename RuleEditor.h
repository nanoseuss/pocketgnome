//
//  RuleEditor.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Rule.h"

@class Controller;
@class BotController;

#define RuleEditorSaveRule      1
#define RuleEditorCancelRule    0

@interface RuleEditor : NSObject {
    IBOutlet Controller *controller;
    IBOutlet BotController *botController;
    IBOutlet id spellController;
    IBOutlet id inventoryController;

    IBOutlet id conditionMatchingSegment;
    IBOutlet id conditionResultTypeSegment;
    
    IBOutlet id spellRuleTableView;
    IBOutlet id spellRuleTypeDropdown;
    
    IBOutlet id resultActionDropdown;
    IBOutlet id ruleNameText;
    IBOutlet id ruleEditorWindow;
    
    NSMutableArray *_conditionList;
    
    NSMenu *_spellsMenu, *_itemsMenu, *_macrosMenu;
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
