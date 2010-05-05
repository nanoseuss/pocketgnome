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


@interface MPCustomClassScrubPriest : MPCustomClassScrub {

	MPSpell *cureDisease, *devouringPlague, *dispelMagic, *fade, *flashHeal, *heal, *holyFire, *pwShield, *pwFort, *renew, *resurrection, *smite, *swPain;
	MPItem *drink;
	BOOL wandShooting;
	
}
@property (retain) MPSpell *cureDisease, *devouringPlague, *dispelMagic, *fade, *flashHeal, *heal, *holyFire, *pwShield, *pwFort, *renew, *resurrection, *smite, *swPain;
@property (retain) MPItem *drink;

- (void) openingMoveWith: (Mob *)mob;
- (MPCombatState) combatActionsWith: (Mob *) mob;

@end
