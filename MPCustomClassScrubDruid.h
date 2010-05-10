//
//  MPCustomClassScrubDruid.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCustomClassScrub.h"

@class MPSpell;
@class MPItem;
@class MPTimer;


@interface MPCustomClassScrubDruid : MPCustomClassScrub {

	MPSpell *abolishPoison, *curePoison, *insectSwarm, *wrath, *mf, *motw, *rejuv, *healingTouch, *removeCurse, *starfire, *thorns;
	MPSpell *autoAttack;
	MPItem *drink;
	MPTimer *waitDrink, *timerRunningAction;
}
@property (retain) MPSpell *autoAttack, *abolishPoison, *curePoison, *insectSwarm, *wrath, *mf, *motw, *rejuv, *healingTouch, *removeCurse, *starfire, *thorns;
@property (retain) MPItem *drink;
@property (retain) MPTimer *waitDrink, *timerRunningAction;

@end
