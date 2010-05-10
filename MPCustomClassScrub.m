//
//  MPCustomClassScrub.m
//  Pocket Gnome
//
//  Created by codingMonkey on 4/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPCustomClassScrub.h"
#import "MPCustomClass.h"

#import "AuraController.h"
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

@implementation MPCustomClassScrub
@synthesize shootWand, meleeAttack;
@synthesize dispellPoison, dispellCurse, dispellMagic, dispellDisease;
@synthesize listBuffs, listSpells, listParty;
@synthesize timerGCD, timerRefreshParty, timerBuffCheck, timerSpellScan;

- (id) initWithController:(PatherController*)controller {
	if ((self = [super initWithController:controller])) {
		

		self.meleeAttack = nil;
		self.shootWand = nil;
		
		self.dispellPoison = nil;
		self.dispellCurse = nil;
		self.dispellMagic = nil;
		self.dispellDisease = nil;
		

		self.listBuffs = nil;
		self.listSpells = nil;
		self.listParty = nil;
		
		
		self.timerGCD =  [MPTimer timer:1000]; // 1 sec cooldown
		[timerGCD forceReady]; // start off ready
		
		self.timerRefreshParty = [MPTimer timer:300000];  // 5 minutes
		[timerRefreshParty forceReady];
		
		self.timerBuffCheck = [MPTimer timer:3000];  // every 3 seconds
		[timerBuffCheck forceReady];
		
		self.timerSpellScan = [MPTimer timer:300000]; // 5 minutes
		[timerSpellScan forceReady];
		
		errorLOS = NO;
		autoShooting = NO;
		autoAttacking = NO;
		
		state = CCCombatPreCombat;
	}
	return self;
}

- (void) dealloc
{
	[meleeAttack release];
	[shootWand release];
	
	[dispellPoison release];
	[dispellCurse release];
		
	[listBuffs release];
	[listSpells release];
	[listParty release];
	[timerGCD release];
	[timerRefreshParty release];
	[timerBuffCheck release];
	[timerSpellScan release];
	
    [super dealloc];
}

#pragma mark -



- (NSString *) name {
	return @"ScrUb Class";
}




- (MPCombatState) killTarget: (Mob*) mob {
	
	
	
	// if player isDead
	PlayerDataController *me = [PlayerDataController sharedController];
	if (([me isDead] ) || ([[me player] currentHealth] < 2) || ([me isGhost])) {
		return CombatStateDied;
	} // end if
	

	
	// switch state
	switch (state) {
			
		////
		//// This is our first action in combat.  Use this for any opening moves
		////
		case CCCombatPreCombat:
			currentMob = mob;
			
			if ([currentMob isDead] ) {
				
				PGLog(@" CCCombatPreCombat : given mob is already dead.... returning Mistake.");
				return CombatStateMistake;
			}
			
			
			
			//// Perform initial opening move here:
			[self openingMoveWith:mob];
			
			
			state = CCCombatCombat;
			return CombatStateInCombat;
			break;
			
			
			
			
			
		////
		//// We are now in combat performing "normal" combat operations  
		////
		case CCCombatCombat:

			//// 
			//// Check for Combat/Mob Status
			////
			
			//// if [mob isDead]
			if ([mob isDead]) {
				
				PGLog(@"  ccKillTarget: mob is Dead ");
				state = CCCombatPreCombat;  // reset my combat to do initial attack.
				
				NSArray *mobList = [self mobsAttackingMe];
				
				// if attackQueue is empty then all done.
				if ( [mobList count] < 1 ) {
					
					// return CombatSuccess
					return CombatStateSuccess;
					
				} else {
					// there are more to deal with:
					
					// currentMob = currentTarget
					self.currentMob = [mobList objectAtIndex:0]; // <-- choose by some criteria

					// return CombatSuccessWithAdd
					return CombatStateSuccessWithAdd;
					
				} // end if
				
			} // end if
			
			
			
			//// check for Evading => Bugged
			// if( ![unit isInCombat] || [unit isEvading] || ![unit isAttackable] ) {
			if( [mob isEvading] || ![mob isAttackable] ) { 
				return CombatStateBugged;
			}

			
	
			// if unit ended up blacklisted ... bail
			if ([[patherController blacklistController] isBlacklisted:mob]) {
				PGLog(@"   Mob ended up Blacklisted.  You can ask CombatController why ... ");
				return CombatStateBugged;
			}
			
			
			
			
			
			////
			//// all the status checks are passed, so attack!
			////
			
			
			return [self combatActionsWith:mob];


			
			break;
		default:
			break;
	}

	
	// shouldn't get to here!  One of the above should proc.
	return CombatStateDied;
}





- (void) runningAction {
	
	// this method is called outside of combat so these should be "NO"
	autoShooting = NO;
	autoAttacking = NO;
	
	// make sure our spell list is updated
	if ([timerSpellScan ready] ) {
		
		for(MPSpell *spell in listSpells) {
			PGLog(@"reloading spell[%@]", [spell name]);
			[spell loadPlayerSettings];
		}
		[timerSpellScan reset];
	}
	
	// make sure our list of party members is updated
	if ([timerRefreshParty ready]) {
		
		self.listParty = [[PlayerDataController sharedController] partyMembers];
		
		PGLog(@" refreshing Party Members: count[%d]", [listParty count]);
		[timerRefreshParty reset];
	}
	
	
	// check everyone for Buffs
	
	if ([timerBuffCheck ready]) {
		
		PlayerDataController *me = [PlayerDataController sharedController];
		Unit *myCharacter = [me player];
		if( (![myCharacter isDead]) && ([myCharacter currentHealth] > 1)) {
			
			//// Check if party members have buffs
			for( Player* player in listParty) {

				if ([player isValid]) {
					
					if ((![player isDead]) && ([player currentHealth] > 1)) {
					
						if ([self player:player inRange:30]) {
						
							for (MPSpell *buff in listBuffs) {
							
								PGLog(@"checking party member buffs [%@]", [player name]);
								if( ![buff unitHasBuff:(Unit*)player]) {
									[me targetGuid:[player GUID]];
									//[me setPrimaryTarget:player];
									[buff cast];
									[timerBuffCheck reset];
									return;
								}
							}
							
							
							// decurse any curses/poisons/magic/disease
							if ([self decursePlayer:player]) {
								[timerBuffCheck reset];
								return;
							}
							
						}
						
					} // if player isValid
					
				} // if !player->isDead
			}
			
			
			
			//// personal buffs
		
			for (MPSpell *buff in listBuffs) {
				
				PGLog(@"checking my own buffs [%@]", [myCharacter name]);
				if( ![buff unitHasBuff:myCharacter]) {
					//[me setPrimaryTarget:myCharacter];
					[me targetGuid:[myCharacter GUID]];
					[buff cast];
					[timerBuffCheck reset];
					return;
				}
			}
			
			// decurse any curses/poisons/magic/disease
			if ([self decursePlayer:(Player *)myCharacter]) {
				[timerBuffCheck reset];
				return;
			}
		} // if !me->isDead
	
		[timerBuffCheck reset];
	}
	
	[self runningActionSpecial];
	
}



- (void) runningActionSpecial {
	// this should be overridden by subclasses if they need it.
}



- (void) setup {
	
	self.meleeAttack = [MPSpell autoAttack];
	self.shootWand = [MPSpell shootWand];
	
	self.listParty = [[PlayerDataController sharedController] partyMembers];
	
}



#pragma mark -
#pragma mark Cast Helpers


- (void) openingMoveWith: (Mob *)mob {

	// this should be used by subclasses to implement an
	// opening move
}


- (MPCombatState) combatActionsWith: (Mob *) mob {

	// this should be used by subclasses to implement 
	// their combat actions
	return CombatStateInCombat;
}


- (void) targetUnit: (Unit *)unit {

	PlayerDataController *me = [PlayerDataController sharedController];
	if ([me targetID] != [unit GUID]) {
		PGLog(@"     --> Changing Target : myTarget[0x%X] -> mob[0x%X]",[me targetID], [unit lowGUID]);
		[me targetGuid:[unit GUID]];
	}

}



- (BOOL) cast: (MPSpell *) spell on:(Unit *)unit {
	
	int error = ErrNone;
	
	[self targetUnit:unit];
	
	if ([spell canCast]) {
		
		error = [spell cast];
		if (!error) {
			[timerGCD start];
			autoShooting = NO;  // autoShooting is turned off when a cast is successful 
			return YES;
		} else {
			//			[self markError:error];
			if (error == ErrTargetNotInLOS) {
				PGLog(@" %@ error: Line Of Sight.  ", [spell name]);
				errorLOS = YES;
			}
		}
		
	} 
	return NO;
}



- (BOOL) castDOT:(MPSpell *)spell on:(Unit *)unit {
	
	int error = ErrNone;
	
	[self targetUnit:unit];
	
	if ([spell canCast]) {
		
		if (![spell unitHasMyDebuff:unit]) {
			
			error = [spell cast];
			if (!error) {
				[timerGCD start];
				autoShooting = NO;  // autoShooting is turned off when a cast is successful
				return YES;
			} else {
				//				[self markError:error];
				if (error == ErrTargetNotInLOS) {
					PGLog(@" %@ error: Line Of Sight.  ", [spell name]);
					errorLOS = YES;
				}
			}
		}
	} 
	return NO;
}



- (BOOL) castHOT:(MPSpell *)spell on:(Unit *)unit {
	
	int error = ErrNone;
	
	[self targetUnit:unit];
	
	if ([spell canCast]) {
		
		if (![spell unitHasMyBuff:unit]) {
			
			error = [spell cast];
			if (!error) {
				[timerGCD start];
				autoShooting = NO;
				return YES;
			} else {
				//	[self markError:error];
				if (error == ErrTargetNotInLOS) {
					PGLog(@" %@ error: Line Of Sight.  ", [spell name]);
					errorLOS = YES;
				}
			}
		}
	} 
	return NO;
}



- (BOOL) decursePlayer: (Player *)player {
	
	AuraController *auraController = [AuraController sharedController];
	
	//// check for poison debuff
	if (dispellPoison != nil) {
		if ([auraController unit: player hasDebuffType: DispelTypePoison]) {
			if ([self cast:dispellPoison on:player]) {
				return YES;
			}
		}	
	}
	
	
	//// check for curse
	if (dispellCurse != nil) {
		if ([auraController unit: player hasDebuffType: DispelTypeCurse]) {
			if ([self cast:dispellCurse on:player]) {
				return YES;
			}
		}	
	}
	
	
	//// check for magic
	if (dispellMagic != nil) {
		if ([auraController unit: player hasDebuffType: DispelTypeMagic]) {
			if ([self cast:dispellMagic on:player]) {
				return YES;
			}
		}	
	}
	
	
	//// check for disease
	if (dispellDisease != nil) {
		if ([auraController unit: player hasDebuffType: DispelTypeDisease]) {
			if ([self cast:dispellDisease on:player]) {
				return YES;
			}
		}	
	}
	
	
	return NO;
}



- (BOOL) meleeUnit:(Unit *)unit {
	
	[self targetUnit:unit];
	
	if (!autoAttacking) {
		[self cast:meleeAttack on:unit];
		autoAttacking = YES;
	}
	return autoAttacking;
}



- (BOOL) player: (Player *)player inRange:(float)distance {
	

	Position *playerPosition = [player position];
	PlayerDataController *me = [PlayerDataController sharedController];
	if ([playerPosition distanceToPosition:[me position]]<= distance) {
		return YES;
	}
	return NO;
}


- (BOOL) wandUnit:(Unit *)unit {
	
	[self targetUnit:unit];
	
	if (!autoShooting) {
		[self cast:shootWand on:unit];
		autoShooting = YES;
	}
	return autoShooting;
}


@end
