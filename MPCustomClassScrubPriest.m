//
//  MPCustomClassScrubPriest.m
//  Pocket Gnome
//
//  Created by codingMonkey on 4/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPCustomClassScrubPriest.h"
#import "MPCustomClass.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "Mob.h"
#import "BlacklistController.h"
#import "MPSpell.h"
#import "MPItem.h"
#import "MPMover.h"
#import "Player.h"
#import "Unit.h"
#import "MPTimer.h"
#import "Errors.h"
#import "SpellController.h"

@implementation MPCustomClassScrubPriest
@synthesize fade, heal, pwFort, pwShield, renew, resurrection, smite, swPain;
@synthesize drink;


- (id) initWithController:(PatherController*)controller {
	if ((self = [super initWithController:controller])) {
		
		self.fade = nil;
		self.heal    = nil;
		self.pwShield  = nil;
		self.pwFort = nil;
		self.renew = nil;
		self.resurrection = nil;
		self.smite = nil;
		self.swPain = nil;
		


		
		self.drink = nil;

	}
	return self;
}



- (void) dealloc
{
	[fade release];
	[heal release];
	[pwShield release];
	[pwFort release];
	[renew release];
	[resurrection release];
	[smite release];
	[swPain release];
	
	[drink release];
	
    [super dealloc];
}

#pragma mark -



- (NSString *) name {
	return @"ScrUb Priest";
}



- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob {
	
	// preCombatWithMob:atDistance:  is called numerous times for 
	// your CC to determine what to do on approaching your target (at various distances)
	
	if (distanceToMob <= 35) {
		if ([listParty count] <1) {
			[self castHOT:pwShield on:(Unit *)[[PlayerDataController sharedController] player]];
		}
	}
	
	state = CCCombatPreCombat;
}



- (void) openingMoveWith: (Mob *)mob {

	// open with Holy Fire
	wandShooting = NO;
	
	// or with Smite 
	if ([mob percentHealth] > 90) {
		if ([self cast:smite on:mob]){
			return;
		}
	}
}



- (MPCombatState) combatActionsWith: (Mob *) mob {

	PlayerDataController *me = [PlayerDataController sharedController];
	
	// face target
	PGLog(@"     --> Facing Target");
	MPMover *mover = [MPMover sharedMPMover];
	MPLocation *targetLocation = (MPLocation *)[mob position];
	[mover moveTowards:targetLocation within:33.0f facing:targetLocation];
	
	
	
	
	if (! [[SpellController sharedSpells] isGCDActive] ){
//	if ([timerGCD ready]) {
		PGLog( @"   timerGGD ready");
		
		if( ![me isCasting] ) {
			PGLog( @"   me !casting");
			
			
			//// do my healing checks here:
			
			////
			//// Renew Checks
			////
			
			// Renew myself if health < 80%
			if ([me percentHealth] < 80) {
				if ([self castHOT:renew on:(Unit *)[me player]]) {
					return CombatStateInCombat;
				}
			}
			
			
			
			// Renew Party Members if health < 80%
			for( Player *player in listParty) {
				if ([player percentHealth] < 80) {
					if ([self castHOT:renew on:player]) {
						return CombatStateInCombat;
					}
				}
			}
			
			
			////
			//// Heal Checks
			////
			
			// heal myself if health < 65%
			if ([me percentHealth] < 65) {
				if ([self cast:heal on:(Unit *)[me player]]) {
					return CombatStateInCombat;
				}
			}
			
			// Heal Party Members if health < 65%
			for( Player *player in listParty) {
				if ([player percentHealth] < 65) {
					if ([self cast:heal on:player]) {
						return CombatStateInCombat;
					}
				}
			}
			
			
			
			
			
			////
			//// Shield Checks
			////
			
			// shield myself if health < 65%
			if ([me percentHealth] < 65) {
				if ([self castHOT:pwShield on:(Unit *)[me player]]) {
					return CombatStateInCombat;
				}
			}
			
			// Heal Party Members if health < 65%
			for( Player *player in listParty) {
				if ([player percentHealth] < 65) {
					// treat as a HOT so we don't try to cast if buff is on
					if ([self castHOT:pwShield on:player]) {
						return CombatStateInCombat;
					}
				}
			}
			
			
			
			
			
			////
			////  Attacks here
			////
			
			// Shadow Word: Pain DOT
			// if mobhealth >= 50% && myMana > 35%
			if (([mob percentHealth] >= 50) && ([me percentMana] > 35)){
				if ([self castDOT:swPain on:mob]) {
					return CombatStateInCombat;
				} 
			}
			
			
			
			// Holy Fire
			
			
			// Devouring Plague
			
			
			// Spam Smite
			// check to see if we should be adding DMG (setting) if so:
			if ([listParty count] == 0) {
				if ([self cast:smite on:mob]){
					return CombatStateInCombat;
				}
			} else {
				[self wandUnit:mob];
/*				if (!autoShooting) {
					[self cast:shootWand on:mob];
					autoShooting = YES;
				}
*/
			}

			
			
			if (errorLOS) {
				errorLOS = NO;
				return CombatStateBugged;
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
			
			if ([drink canUse]){
				if (![drink unitHasBuff:[player player]]) {
					PGLog(@"   Drinking ...");
					[drink use];
				}
			}
			
			return NO; // must not be done yet ... 
			
		} // end if
	}
	return YES;
}




- (void) setup {
	
	[super setup];
	
	
	self.fade	   = [MPSpell fade];
	self.heal      = [MPSpell heal];
	self.pwShield  = [MPSpell pwShield];
	self.pwFort	   = [MPSpell pwFort];
	self.renew     = [MPSpell renew];
	self.resurrection = [MPSpell resurrection];
	self.smite     = [MPSpell smite];
	self.swPain    = [MPSpell swPain];

	
	
	NSMutableArray *spells = [NSMutableArray array];
	[spells addObject:fade];
	[spells addObject:heal];
	[spells addObject:pwShield];
	[spells addObject:pwFort];
	[spells addObject:renew];
	[spells addObject:resurrection];
	[spells addObject:smite];
	[spells addObject:swPain];
	self.listSpells = [spells copy];
	
	NSMutableArray *buffSpells = [NSMutableArray array];
	[buffSpells addObject:pwFort];
//	[buffSpells addObject:divineSpirit];
	self.listBuffs = [buffSpells copy];
	
	
	self.drink = [MPItem drink];
}



#pragma mark -
#pragma mark Cast Helpers



#pragma mark -

+ (id) classWithController: (PatherController *) controller {
	
	return [[[MPCustomClassScrubPriest alloc] initWithController:controller] autorelease];
}
@end