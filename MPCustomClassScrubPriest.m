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
#import "MPMover.h"
#import "Player.h"
#import "Unit.h"
#import "MPTimer.h"
#import "Errors.h"

@implementation MPCustomClassScrubPriest
@synthesize fade, heal, pwFort, pwShield, renew, resurrection, smite, swPain;


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
	
    [super dealloc];
}

#pragma mark -



- (NSString *) name {
	return @"ScrUb Priest";
}



- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob {
	
	// preCombatWithMob:atDistance:  is called numerous times for 
	// your CC to determine what to do on approaching your target (at various distances)
	

	
	state = CCCombatPreCombat;
}



- (void) openingMoveWith: (Mob *)mob {

	// this should be used by subclasses to implement an
	// opening move
}


- (void) combatActionsWith: (Mob *) mob {

	// this should be used by subclasses to implement 
	// their combat actions
}






- (BOOL) rest {

	PlayerDataController *player = [PlayerDataController sharedController];
	
	// if !inCombat
	if (![player isInCombat]) {
		
		// if health < healthTrigger  || mana < manaTrigger
		if ( ([player percentHealth] <= 99 ) || ([player percentMana] <= 99) ) {
			
			PGLog(@"Should do something during Rest Phase");
			
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
	

}



#pragma mark -
#pragma mark Cast Helpers

/*
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
		[me setPrimaryTarget:unit];
	}

}
*/


#pragma mark -

+ (id) classWithController: (PatherController *) controller {
	
	return [[[MPCustomClassScrubPriest alloc] initWithController:controller] autorelease];
}
@end