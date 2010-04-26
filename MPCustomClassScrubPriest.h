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


@interface MPCustomClassScrubPriest : MPCustomClassScrub {

	MPSpell *fade, *heal, *pwShield, *pwFort, *renew, *resurrection, *smite, *swPain;
}
@property (retain) MPSpell *fade, *heal, *pwShield, *pwFort, *renew, *resurrection, *smite, *swPain;

- (void) openingMoveWith: (Mob *)mob;
- (void) combatActionsWith: (Mob *) mob;

@end
