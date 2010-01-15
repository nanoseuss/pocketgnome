//
//  WaypointActionEditor.m
//  Pocket Gnome
//
//  Created by Josh on 1/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "WaypointActionEditor.h"

#import "Waypoint.h"
#import "Procedure.h"
#import "Rule.h"

#import "Action.h"
#import "Condition.h"
#import "ConditionCell.h"
#import "ConditionController.h"

#import "DurabilityConditionController.h"
#import "InventoryConditionController.h"
#import "PlayerLevelConditionController.h"
#import "PlayerZoneConditionController.h"
#import "QuestConditionController.h"
#import "RouteRunTimeConditionController.h"
#import "RouteRunCountConditionController.h"
#import "InventoryFreeConditionController.h"

#import "SwitchRouteActionController.h"
#import "RepairActionController.h"

#import "WaypointController.h"

@implementation WaypointActionEditor

static WaypointActionEditor *sharedEditor = nil;

+ (WaypointActionEditor *)sharedEditor {
	if (sharedEditor == nil)
		sharedEditor = [[[self class] alloc] init];
	return sharedEditor;
}

- (id) init {
    self = [super init];
    if(sharedEditor) {
		[self release];
		self = sharedEditor;
    } if (self != nil) {
		sharedEditor = self;
		
		_waypoint = nil;
		_conditionList = [[NSMutableArray array] retain];
		_actionList = [[NSMutableArray array] retain];
		
        [NSBundle loadNibNamed: @"WaypointActionEditor" owner: self];
    }
    return self;
}


- (void)awakeFromNib {
    // set our column to use a Rule Cell
    NSTableColumn *column = [conditionTableView tableColumnWithIdentifier: @"Conditions"];
	[column setDataCell: [[[ConditionCell alloc] init] autorelease]];
	[column setEditable: NO];
	
	
    NSTableColumn *column2 = [actionTableView tableColumnWithIdentifier: @"Actions"];
	[column2 setDataCell: [[[ConditionCell alloc] init] autorelease]];
	[column2 setEditable: NO];
}

#pragma mark UI

- (IBAction)addCondition:(id)sender{
	
	int type = [[addConditionDropDown selectedItem] tag];
	
    ConditionController *newRule = nil;

	if ( type == VarietyInventory )				newRule = [[[InventoryConditionController alloc] init] autorelease];
	else if ( type == VarietyDurability )		newRule = [[[DurabilityConditionController alloc] init] autorelease];
	else if ( type == VarietyPlayerLevel )		newRule = [[[PlayerLevelConditionController alloc] init] autorelease];
	else if ( type == VarietyZone )				newRule = [[[PlayerZoneConditionController alloc] init] autorelease];
	else if ( type == VarietyQuestCompletion )	newRule = [[[QuestConditionController alloc] init] autorelease];
	else if ( type == VarietyRouteRunTime )		newRule = [[[RouteRunTimeConditionController alloc] init] autorelease];
	else if ( type == VarietyRouteRunCount )	newRule = [[[RouteRunCountConditionController alloc] init] autorelease];
	else if ( type == VarietyInventoryFree )	newRule = [[[InventoryFreeConditionController alloc] init] autorelease];
	
    if ( newRule ) {
        [_conditionList addObject: newRule];
        [conditionTableView reloadData];
        [conditionTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: [_conditionList count] - 1] byExtendingSelection: NO];
        
        //[sender selectItemWithTag: 0];
    }
	
}

- (void)addActionWithType:(int)type{
	ActionController *newAction = nil;
	
	if ( type == ActionType_Repair )				newAction = [[[RepairActionController alloc] init] autorelease];
	else if ( type == ActionType_SwitchRoute )		newAction = [SwitchRouteActionController switchRouteActionControllerWithRoutes:[waypointController routes]];
	//else if ( type == ActionType_SwitchRoute )		newAction = [[[SwitchRouteActionController alloc] init] autorelease];
	
    if ( newAction ) {
        [_actionList addObject: newAction];
        [actionTableView reloadData];
        [actionTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: [_actionList count] - 1] byExtendingSelection: NO];
        
        //[sender selectItemWithTag: 0];
    }
}

- (void)addActionWithAction:(Action*)action{
	
	if ( [action type] == ActionType_SwitchRoute ){
		ActionController *newAction = [SwitchRouteActionController switchRouteActionControllerWithRoutes:[waypointController routes]];
		[newAction setStateFromAction:action];
		[_actionList addObject:newAction];
	}
	else{
		[_actionList addObject: [ActionController actionControllerWithAction: action]];
	}
	
	// responsible for reloading outside of this function!
}



- (IBAction)addAction:(id)sender{
	[self addActionWithType:[[addActionDropDown selectedItem] tag]];
}

- (void)clearTables{
	
	// remove all
	[_conditionList removeAllObjects];
	[conditionTableView reloadData];
	
	// for actions we need to remove bindings
	for ( id actionController in _actionList ){
		[actionController removeBindings];
	}

	[_actionList removeAllObjects];
	[actionTableView reloadData];
}

// editor opens! Load info for a given waypoint!
- (void)showEditorOnWindow: (NSWindow*)window withWaypoint: (Waypoint*)wp withAction:(int)type {
	
	_waypoint = [wp retain];
	
	[self clearTables];

	// valid waypoint (not sure why it wouldn't be)
	if ( wp ){
		// add description
		[waypointDescription setStringValue:[wp title]];

		// add any actions
		if ( [wp.actions count] > 0 ){
			for ( Action *action in wp.actions ) {
				[self addActionWithAction:action];
			}
		}
		// add a default
		else if ( type > ActionType_None && type <= ActionType_Max ){
			[self addActionWithType:type];
		}
		
		
		// add any conditions
		/*			
		 if( [rule isMatchAll] )
		 [conditionMatchingSegment selectSegmentWithTag: 0];
		 else
		 [conditionMatchingSegment selectSegmentWithTag: 1];
		 
		 */
		
		
		
		// get any conditions
		
		// get any actions
		/*if ( [wp.actions count] > 0 ){
			// add them
			PGLog(@"total actions: %d", [wp.actions count]);
			
		}
		// add a default
		else if ( type > ActionType_None && type <= ActionType_Max ){
			[self addNewAction:type];
		}
		
		// add rules
		if ( [wp.procedure.rules count] > 0 ){
			PGLog(@"we have rules! %d", [wp.procedure.rules count]);
		}*/
	}
	
	// reload tables
	[actionTableView reloadData];
	[conditionTableView reloadData];
	
	[NSApp beginSheet: editorPanel
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: [NSNumber numberWithInt:type]];
}

- (IBAction)closeEditor: (id)sender {
    [[sender window] makeFirstResponder: [[sender window] contentView]];
    [NSApp endSheet: editorPanel returnCode: NSOKButton];
    [editorPanel orderOut: nil];

	// pass the new wp back to waypoint controller? or do we need to since it was a pointer + not a copy?
}

- (IBAction)saveWaypoint: (id)sender{

	_waypoint.title = [waypointDescription stringValue];
	
	// save actions
	[_waypoint setActions:nil];
	for ( id actionController in _actionList ){
		[_waypoint addAction:[(ActionController*)actionController action]];
		PGLog(@"Saved action %@ with value %@", [(ActionController*)actionController action], [(ActionController*)actionController action].value);
	}
	
	/*
	
	
	PGLog(@"actions  title");
	
	Procedure *procedure = [Procedure procedureWithName:_waypoint.title];
	
	for ( Rule *rule in _conditionList ){
		[procedure addRule:rule];
	}
	
	_waypoint.procedure = procedure;*/
	
	[self closeEditor:sender];	
}

- (NSArray*)routes{
	return [waypointController routes];
}

#pragma mark -
#pragma mark TableView Delegate/DataSource

- (void) tableView:(NSTableView *) tableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
	if( [[tableColumn identifier] isEqualToString: @"Conditions"] ) {
		NSView *view = [[_conditionList objectAtIndex: row] view];
		[(ConditionCell*)cell addSubview: view];
	}
	else if( [[tableColumn identifier] isEqualToString: @"Actions"] ) {
		NSView *view = [[_actionList objectAtIndex: row] view];
		[(ConditionCell*)cell addSubview: view];
	}
}

// Methods from NSTableDataSource protocol
- (int) numberOfRowsInTableView:(NSTableView *) tableView{
	
	if ( tableView == conditionTableView )
		return [_conditionList count];
	else if ( tableView == actionTableView ){
		return [_actionList count];
	}
	
	return 0;
}

- (id) tableView:(NSTableView *) tableView objectValueForTableColumn:(NSTableColumn *) tableColumn row:(int) row{
	return @"";
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    //[self validateBindings];
}

- (void)tableView: (NSTableView*)tableView deleteKeyPressedOnRowIndexes: (NSIndexSet*)rowIndexes {
    if([rowIndexes count] == 0)   return;
    
	if ( tableView == conditionTableView ){
		int row = [rowIndexes lastIndex];
		while(row != NSNotFound) {
			[_conditionList removeObjectAtIndex: row];
			row = [rowIndexes indexLessThanIndex: row];
		}
		[conditionTableView reloadData];
	}
	else if ( tableView == actionTableView ){
		int row = [rowIndexes lastIndex];
		while(row != NSNotFound) {
			id actionController = [_actionList objectAtIndex:row];
			[actionController removeBindings];
			[_actionList removeObjectAtIndex: row];
			row = [rowIndexes indexLessThanIndex: row];
		}
		[actionTableView reloadData];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldTypeSelectForEvent:(NSEvent *)event withCurrentSearchString:(NSString *)searchString {
    return NO;
}

@end
