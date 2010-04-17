//
//  MPCustomClassPG.h
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


@interface MPCustomClassScrubDruid : MPCustomClass {

	MPSpell *wrath;
	MPCCCombatState state;
}
@property (retain) MPSpell *wrath;

@end
