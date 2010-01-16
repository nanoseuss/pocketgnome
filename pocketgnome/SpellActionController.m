//
//  SpellActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "SpellActionController.h"
#import "ActionController.h"

#import "Spell.h"
#import "Action.h"


@implementation SpellActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_spells = nil;
        if(![NSBundle loadNibNamed: @"SpellAction" owner: self]) {
            PGLog(@"Error loading SpellAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithSpells: (NSArray*)spells{
    self = [self init];
    if (self != nil) {
        self.spells = spells;
    }
    return self;
}

// sort
NSInteger alphabeticSort(id spell1, id spell2, void *context){
    return [[(Spell*)spell1 name] localizedCaseInsensitiveCompare:[(Spell*)spell2 name]];
}

+ (id)spellActionControllerWithSpells: (NSArray*)spells{
	NSMutableArray *arrayToSort = [NSMutableArray arrayWithArray:spells];
	[arrayToSort sortUsingFunction:alphabeticSort context:nil];
	return [[[SpellActionController alloc] initWithSpells: arrayToSort] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [spellPopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[spellPopUp unbind: binding];
	}
}

@synthesize spells = _spells;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [spellPopUp itemArray] ){
		if ( [[(Spell*)[item representedObject] ID] intValue] == [(NSNumber*)action.value intValue] ){
			[spellPopUp selectItem:item];
			break;
		}
	}
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Spell value:nil];
	
	[action setEnabled: self.enabled];
	
	NSNumber *spellID = [[[spellPopUp selectedItem] representedObject] ID];
	[action setValue: spellID];
    
    return action;
}

@end
