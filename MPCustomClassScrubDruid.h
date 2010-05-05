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

	MPSpell *abolishPoison, *curePoison, *wrath, *mf, *motw, *rejuv, *healingTouch, *thorns;
	MPSpell *autoAttack;
	MPItem *drink;
	MPTimer *waitDrink;
}
@property (retain) MPSpell *autoAttack, *abolishPoison, *curePoison, *wrath, *mf, *motw, *rejuv, *healingTouch, *thorns;
@property (retain) MPItem *drink;
@property (retain) MPTimer *waitDrink;

@end
