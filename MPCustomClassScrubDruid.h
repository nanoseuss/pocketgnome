//
//  MPCustomClassScrubDruid.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCustomClass.h"

@class MPTimer;
@class Mob;
@class CombatController;
@class BotController;
@class MPSpell;
@class MPItem;


@interface MPCustomClassScrubDruid : MPCustomClass {

	MPSpell *autoAttack, *wrath, *mf, *motw, *rejuv, *healingTouch, *thorns;
	MPItem *drink;
	NSArray *listSpells, *listItems, *listParty;
	MPTimer *timerGCD, *timerRefreshParty, *timerBuffCheck, *timerSpellScan;
	BOOL errorLOS;
	MPCCCombatState state;
}
@property (retain) MPSpell *autoAttack, *wrath, *mf, *motw, *rejuv, *healingTouch, *thorns;
@property (retain) MPItem *drink;
@property (retain) NSArray *listSpells, *listItems, *listParty;
@property (retain) MPTimer *timerGCD, *timerRefreshParty, *timerBuffCheck, *timerSpellScan;

@end
