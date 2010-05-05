//
//  MPCustomClassPG.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPCustomClassScrubDruid.h"
#import "MPCustomClass.h"

#import "Aura.h"
#import "AuraController.h"
#import "BlacklistController.h"
#import "Errors.h"
#import "Mob.h"
#import "MPItem.h"
#import "MPMover.h"
#import "MPSpell.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "Player.h"
#import "SpellController.h"
#import "Unit.h"


/*
@interface MPCustomClassScrubDruid (Internal)

// casting is straight cast
- (BOOL) castHeal:(Unit *)unit;
- (BOOL) castWrath:(Unit *)mob;


// dot's only apply if unit doesn't already have debuff
- (BOOL) dotMF:(Unit *)mob;


// hot's only apply if unit doesn't already have buff
- (BOOL) hotRejuv:(Unit *)unit;


// make sure given [unit] is targeted
- (void) targetUnit:(Unit *)unit;

@end
*/


@implementation MPCustomClassScrubDruid
@synthesize abolishPoison, curePoison, wrath, mf, motw, rejuv, healingTouch, thorns;
@synthesize autoAttack;
@synthesize drink;
@synthesize waitDrink;

- (id) initWithController:(PatherController*)controller {
	if ((self = [super initWithController:controller])) {
		
		self.abolishPoison = nil;
		self.curePoison = nil;
		self.wrath = nil;
		self.mf    = nil;
		self.motw  = nil;
		self.rejuv = nil;
		self.healingTouch = nil;
		self.thorns = nil;

		self.autoAttack = nil;
		
		self.drink = nil;
		
		self.waitDrink = [MPTimer timer:1000]; // 1s delay in between spamming drink
		[waitDrink forceReady];
		
	}
	return self;
}



- (void) dealloc
{
	[abolishPoison release];
	[curePoison release];
	[wrath release];
	[mf release];
	[motw release];
	[rejuv release];
	[healingTouch release];
	[thorns release];
	
	[autoAttack release];

	[drink release];
	
	[waitDrink release];
	
    [super dealloc];
}

#pragma mark -



- (NSString *) name {
	return @"ScrUb Druid";
}



- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob {
	
	// preCombatWithMob:atDistance:  is called numerous times for 
	// your CC to determine what to do on approaching your target (at various distances)
	
	// if I had a Trinket I wanted to pop before my opening move, this would be a good
	// place to do it (just make sure distance is pretty close to opening move)
	
	state = CCCombatPreCombat;
}



- (void) openingMoveWith: (Mob *)mob {

	// should do a SF or Wrath here
}



- (MPCombatState) combatActionsWith: (Mob *) mob {

	PlayerDataController *me = [PlayerDataController sharedController];
	
	
	// face target
	PGLog(@"     --> Facing Target");
	MPMover *mover = [MPMover sharedMPMover];
	MPLocation *targetLocation = (MPLocation *)[mob position];
	[mover moveTowards:targetLocation within:33.0f facing:targetLocation];

	
	//// make sure we stop here!
	
	//// check for LOS error and then do something to adjust for it.
	////  when adjustment complete, reset errorLOS
	
	
	
	
	PGLog(@"  Casting:");
	
	if (! [[SpellController sharedSpells] isGCDActive] ){
//	if ([timerGCD ready]) {
	
		if( ![me isCasting] ) {
			
			
			
			//// do my healing checks here:
			
			////
			//// Rejuvination Checks
			////
			
			// Rejuvination myself if health < 65%
			if ([me percentHealth] < 65) {
				if ([self castHOT:rejuv on:(Unit *)[me player]]) {
					return CombatStateInCombat;
				}
			}
			
			
			
			// I'm Balance Druid.  So in a party
			// expect a party healer.  My healing 
			// is just to assist them.
			//
			// Rejuvinate Party Members if health < 40%
			for( Player *player in listParty) {
				if ([player percentHealth] < 40) {
					if ([self castHOT:rejuv on:player]) {
						return CombatStateInCombat;
					}
				}
			}
			
			
			////
			//// Heal Checks
			////
			
			// heal myself if health < 40%
			if ([me percentHealth] < 40) {
				if ([self cast:healingTouch on:(Unit *)[me player]]) {
					return CombatStateInCombat;
				}
			}
			
			
			// Heal Party Members if health < 35%
			for( Player *player in listParty) {
				if ([player percentHealth] < 35) {
					if ([self cast:healingTouch on:player]) {
						return CombatStateInCombat;
					}
				}
			}
			
			
			
			////
			//// Remove Poison
			////
			
			// DispelTypeMagic
			// DispelTypeCurse
			// DispelTypePoison
			// DispelTypeDisease
			/*
			for (Player *player in listParty) {
				if ([auraController unit: player hasDebuffType: DispelTypePoison]) {
					if ([self cast:dispellPoison on player]) {
						return CombatStateInCombat;
					}
				}
			}
			 */
			// Heal Party Members if health < 35%
			for( Player *player in listParty) {
				if ([player percentHealth] < 35) {
					if ([self cast:healingTouch on:player]) {
						return CombatStateInCombat;
					}
				}
			}
			
			
			////
			////  Attacks here
			////
			
			// MoonFire DOT
			// if mobhealth >= 50% && myMana > 20%
			if (([mob percentHealth] >= 50) && ([me percentMana] > 20)){
				if ([self castDOT:mf on:mob]) {
					return CombatStateInCombat;
				} 
			}
			
			
			// Insect Swarm
			
			
			
			// Starfire
			
			
			// make sure we are swinging our weapon
			[self meleeUnit:mob];
			
			
			// Spam Wrath
			if ([self cast:wrath on:mob]){
				return CombatStateInCombat;
			}
			
		}
		
		
	}

	return CombatStateInCombat;
}



- (BOOL) rest {

	PlayerDataController *player = [PlayerDataController sharedController];
	
	// if !inCombat
	if (![player isInCombat]) {
		
		// if health < healthTrigger  || mana < manaTrigger
		if ( ([player percentHealth] <= 99 ) || ([player percentMana] <= 99) ) {
			
/*
			PGLog(@"Aura List:");
			NSArray *listAuras = [[AuraController sharedController] aurasForUnit:[player player] idsOnly:NO];
			for( Aura *aura in listAuras){
				PGLog(@"    - entryID[%d]", [aura entryID]);
			}
*/
			if ([waitDrink ready]) {
				if ([drink canUse]){
					if (![drink unitHasBuff:[player player]]) {
						[drink use];
						[waitDrink start];
					}
				}
			}
			
			return NO; // must not be done yet ... 
			
		} // end if
	}
	return YES;
}



- (void) setup {

	[super setup];
	
	////
	//// Spells
	////
	self.abolishPoison = [MPSpell abolishPoison];
	self.curePoison = [MPSpell curePoison];
	self.wrath = [MPSpell wrath];
	self.mf    = [MPSpell moonfire];
	self.motw  = [MPSpell motw];
	self.rejuv = [MPSpell rejuvenation];
	self.healingTouch = [MPSpell healingTouch];
	self.thorns = [MPSpell thorns];
	
	
	NSMutableArray *spells = [NSMutableArray array];
	[spells addObject:abolishPoison];
	[spells addObject:curePoison];
	[spells addObject:wrath];
	[spells addObject:mf];
	[spells addObject:motw];
	[spells addObject:rejuv];
	[spells addObject:healingTouch];
	[spells addObject:thorns];
	self.listSpells = [spells copy];
	
	
	NSMutableArray *buffSpells = [NSMutableArray array];
	[buffSpells addObject:motw];
	[buffSpells addObject:thorns];
	self.listBuffs = [buffSpells copy];
	
	
	if ([abolishPoison canCast]) {
		self.dispellPoison = abolishPoison;
	} else {
		if ([curePoison canCast]) {
			self.dispellPoison = curePoison;
		}
	}
	
	
	
	////
	//// Physical
	////
	self.autoAttack = [MPSpell autoAttack];
	
	
	//// 
	//// Items
	////
	self.drink = [MPItem drink];
/*	
	NSMutableArray *items = [NSMutableArray array];
	[items addObject:drink];
	self.listItems = [items copy];
*/
}


/*
#pragma mark -
#pragma mark Cast Helpers


- (BOOL) dotMF:(Unit *)mob {

	int error = ErrNone;
	
	[self targetUnit:mob];
	
	if ([mf canCast]) {
							
		if (![mf unitHasDebuff:mob]) {
			
			error = [mf cast];
			if (!error) {
				[timerGCD start];
				return YES;
			} else {
//				[self markError: error];
				if (error == ErrTargetNotInLOS) {
					PGLog(@" Moonfire error: Line Of Sight.  ");
					errorLOS = YES;
				}
			}
			
		}
	} 
	return NO;
}



- (BOOL) hotRejuv:(Unit *)unit {

	int error = ErrNone;
	
	[self targetUnit:unit];
	
	if ([rejuv canCast]) {
PGLog(@" rejuv can cast");
							
		if (![rejuv unitHasBuff:unit]) {
			
			error = [rejuv cast];
			if (!error) {
				[timerGCD start];
				return YES;
			} else {
//				[self markError:error];
				if (error == ErrTargetNotInLOS) {
					PGLog(@" Rejuvination error: Line Of Sight.  ");
					errorLOS = YES;
				}
			}
			
} else {
PGLog(@" unit[%@] already has Rejuv buff.",[unit name]);
		}
	} 
	return NO;
}



- (BOOL) castHeal:(Unit *)unit {

	int error = ErrNone;
	
	[self targetUnit:unit];
	
	if ([healingTouch canCast]) {
							
		error = [healingTouch cast];
		if (!error) {
			[timerGCD start];
			return YES;
		} else {
//			[self markError:error];
			if (error == ErrTargetNotInLOS) {
				PGLog(@" Healing Touch error: Line Of Sight.  ");
				errorLOS = YES;
			}
		}

	} 
	return NO;
}



- (BOOL) castWrath:(Unit *)mob {

	int error = ErrNone;
	
	[self targetUnit:mob];
	
	if ([wrath canCast]) {
							
		error = [wrath cast];
		if (!error) {
			[timerGCD start];
			return YES;
		} else {
			if (error == ErrTargetNotInLOS) {
				PGLog(@" Wrath error: Line Of Sight.  ");
				errorLOS = YES;
			}
		}

	} 
	return NO;
}


- (void) targetUnit: (Unit *)unit {

	PlayerDataController *me = [PlayerDataController sharedController];
	if ([me targetID] != [unit GUID]) {
		PGLog(@"     --> Changing Target : myTarget[0x%X] -> mob[0x%X]",[me targetID], [unit lowGUID]);
		[me targetGuid:[unit GUID]];
//		[me setPrimaryTarget:unit];
	}

}

*/

#pragma mark -

+ (id) classWithController: (PatherController *) controller {
	
	return [[[MPCustomClassScrubDruid alloc] initWithController:controller] autorelease];
}
@end
