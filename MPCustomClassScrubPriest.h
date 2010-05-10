//
//  MPCustomClassScrubPriest.h
//  Pocket Gnome
//
//  Created by codingMonkey on 4/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCustomClassScrub.h"

@class MPSpell;
@class MPItem;
@class MPTimer;


@interface MPCustomClassScrubPriest : MPCustomClassScrub {

	MPSpell *cureDisease, *devouringPlague, *dispelMagic, *fade, *flashHeal, *heal, *holyFire, *pwShield, *pwFort, *renew, *resurrection, *smite, *swPain;
	MPItem *drink;
	BOOL wandShooting;
	
	MPTimer *timerRunningAction;
	
}
@property (retain) MPSpell *cureDisease, *devouringPlague, *dispelMagic, *fade, *flashHeal, *heal, *holyFire, *pwShield, *pwFort, *renew, *resurrection, *smite, *swPain;
@property (retain) MPItem *drink;
@property (retain) MPTimer *timerRunningAction;

- (void) openingMoveWith: (Mob *)mob;
- (MPCombatState) combatActionsWith: (Mob *) mob;

@end
