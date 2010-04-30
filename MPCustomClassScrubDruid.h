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


@interface MPCustomClassScrubDruid : MPCustomClassScrub {

	MPSpell *wrath, *mf, *motw, *rejuv, *healingTouch, *thorns;
	MPSpell *autoAttack;
	MPItem *drink;
}
@property (retain) MPSpell *autoAttack, *wrath, *mf, *motw, *rejuv, *healingTouch, *thorns;
@property (retain) MPItem *drink;

@end
