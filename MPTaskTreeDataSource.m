//
//  MPTaskTreeDataSource.m
//  TaskParser
//
//  Created by codingMonkey on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskTreeDataSource.h"
#import "MPTask.h"
#import "MPTaskController.h"

@implementation MPTaskTreeDataSource


// Data Source methods

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return (item == nil) ? 1 : [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return (item == nil) ? YES : ([item numberOfChildren] != 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return (item == nil) ? [MPTaskController rootTask] : [(MPTask *)item childAtIndex:index];  // is this 0 based?
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if (item == nil) {
		return @"empty";
	}

	// cells with active tasks get a green color text, others black
	id currCell = [tableColumn dataCell];
	if ([item isActive]){
		[currCell setTextColor:[NSColor colorWithCalibratedRed:0 green:0.55 blue:0 alpha:1.0]];
	} else {
		switch( [item currentStatus] ) {
				
			case TaskStatusFinished:
				[currCell setTextColor:[NSColor blackColor]];
				break;
			case TaskStatusNoWant:
				[currCell setTextColor:[NSColor blueColor]];
				break;
			case TaskStatusWant:
				[currCell setTextColor:[NSColor redColor]];
				break;
		}
	}
    return  [[tableColumn identifier] isEqualToString:@"Status"] ? (id)[item showStatusText] : (id)[item showStatusName];
}

// Delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}





@end
