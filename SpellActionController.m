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
	
	NSNumber *spellID = [[action value] objectForKey:@"SpellID"];
	NSNumber *instant = [[action value] objectForKey:@"Instant"];
	
	for ( NSMenuItem *item in [spellPopUp itemArray] ){
		if ( [[(Spell*)[item representedObject] ID] intValue] == [spellID intValue] ){
			[spellPopUp selectItem:item];
			break;
		}
	}
	
	[spellInstantButton setState:[instant boolValue]];
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Spell value:nil];
	
	[action setEnabled: self.enabled];
	
	NSNumber *spellID = [[[spellPopUp selectedItem] representedObject] ID];
	NSNumber *instant = [NSNumber numberWithBool:[spellInstantButton state]];
	
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
							spellID,		@"SpellID",
							instant,		@"Instant", nil];

	[action setValue: values];
    
    return action;
}

@end
