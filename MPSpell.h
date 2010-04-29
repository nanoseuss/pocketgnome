//
//  MPSpell.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class BotController;
@class Spell;
@class SpellController;
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
	int currentRank;
	NSString *name;
	Spell *mySpell;
	NSMutableArray *listIDs, *listBuffIDs;
	
	BotController *botController;
	SpellController *spellController;
	
}
@property (retain) Spell *mySpell;
@property (readwrite,retain) NSString *name;
@property (retain) NSMutableArray *listIDs, *listBuffIDs;
@property (retain) BotController *botController;
@property (retain) SpellController *spellController;

- (void) addID: (int) anID;
- (BOOL) canCast;
- (BOOL) cast;
- (void) scanForSpell;
- (void) loadPlayerSettings;


- (BOOL) unitHasBuff: (Unit *)unit;
- (BOOL) unitHasDebuff: (Unit *)unit;
- (BOOL) unitHasMyBuff: (Unit *)unit;
- (BOOL) unitHasMyDebuff: (Unit *)unit;



+ (id) spell;


+ (id) shootWand;


// Druid
+ (id) healingTouch;
+ (id) moonfire;
+ (id) motw;
+ (id) rejuvenation;
+ (id) thorns;
+ (id) wrath;


// Priest
+ (id) fade;
+ (id) flashHeal;
+ (id) heal;
+ (id) pwFort;
+ (id) pwShield;
+ (id) renew;
+ (id) resurrection;
+ (id) smite;
+ (id) swPain;


@end
