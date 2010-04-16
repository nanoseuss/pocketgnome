//
//  MPSpell.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Spell;
@class BotController;
@class Unit;


/*!
 * @class      MPSpell
 * @abstract   Represents a basic spell.
 * @discussion 
 * 
 *		
 */
@interface MPSpell : NSObject {
	UInt32 spellID;
	NSString *name;
	Spell *mySpell;
	NSMutableArray *listIDs, *listBuffIDs;
	
	BotController *botController;
	
}
@property (retain) Spell *mySpell;
@property (readwrite,retain) NSString *name;
@property (retain) NSMutableArray *listIDs, *listBuffIDs;
@property (retain) BotController *botController;

- (void) addID: (int) anID;
- (BOOL) cast;
- (void) loadPlayerSettings;


- (BOOL) unitHasBuff: (Unit *)unit;
- (BOOL) unitHasDebuff: (Unit *)unit;

+ (id) spell;
+ (id) thorns;
+ (id) wrath;

@end
