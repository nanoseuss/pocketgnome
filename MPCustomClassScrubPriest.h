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

	MPSpell *fade, *heal, *pwShield, *pwFort, *renew, *resurrection, *smite, *swPain;
	MPSpell *shootWand;
	MPItem *drink;
	BOOL wandShooting;
	
}
@property (retain) MPSpell *fade, *heal, *pwShield, *pwFort, *renew, *resurrection, *smite, *swPain;
@property (retain) MPSpell *shootWand;
@property (retain) MPItem *drink;

- (void) openingMoveWith: (Mob *)mob;
- (MPCombatState) combatActionsWith: (Mob *) mob;

@end
