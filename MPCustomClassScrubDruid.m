//
//  MPCustomClassPG.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPCustomClassScrubDruid.h"
#import "MPCustomClass.h"
#import "PatherController.h"
#import "PlayerDataController.h"


@implementation MPCustomClassScrubDruid


- (id) initWithController:(PatherController*)controller {
	if ((self = [super initWithController:controller])) {
		
	}
	return self;
}

- (void) dealloc
{
    
	
    [super dealloc];
}

#pragma mark -

- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob {
	
	// Normally preCombatWithMob: atDistance: ] is called numerous times for 
	// your CC to determine what to do on approaching your target (at various distances)
	// however in PG, all that is handled with [botController preCombatWithMob:].
	// So here we simply call that 1x and then return.
	
	
	
	
}

- (MPCombatState) killTarget: (Mob*) mob {
	
	
	
	// if player isDead
	PlayerDataController *me = [PlayerDataController sharedController];
	if (([me isDead] ) || ([me isGhost])) {
		return CombatStateDied;
	} // end if
	
/*	
	
	if ([mob isDead]) {
		

			
			PGLog(@"  ccKillTarget: mob is Dead && timer ready ... let's hope CC is updated");
			
			// if attackQueue is empty then all done.
			if ( ![[combatController combatList] count] ) {
				
				// return CombatSuccess
				return CombatStateSuccess;
				
			} else {
				// there are more to deal with:
				
				// if combatController has current attack target then mark that one
				if ( [combatController attackUnit] != nil) {
					
					// currentMob = currentTarget
					self.currentMob = (Mob *) [combatController attackUnit];
					
				} // end if
				
				// return CombatSuccessWithAdd
				return CombatStateSuccessWithAdd;
				
			} // end if
			
		
	} // end if
	
	
	
	
	
	
	// switch state
	switch (state) {
			
			
			// ideally, [MPCustomClassPG preCombatWithMob: atDistance:] should have been called numerous times before
			// we have [killTarget:mob] called.  Therefore, the 1st time through [killTarget] we initiate combat and switch us to 
			// the CCCombatCombat state.
			//
		case CCCombatPreCombat:
			currentMob = mob;
			isMobDead = NO; //[mob isDead];
			
			if ([currentMob isDead] ) {
				
				PGLog(@" CCCombatPreCombat : given mob is already dead.... returning Mistake.");
				return CombatStateMistake;
			}
			
			//tell combatController to start attacking!
			//[combatController disposeOfUnit:currentMob];  // <-- before rev 1.4.4
			[combatController stayWithUnit:mob withType:TargetEnemy];  // make sure mob is _attackUnit
			[botController actOnUnit:mob];
			
			
			//			[timerControllerStartup start];
			[timerEstablishPosition start];
			
			state = CCCombatCombat;
			return CombatStateInCombat;
			break;
			
			
			// During combat we want to make sure that PG's combatController has control.  
		case CCCombatCombat:
			// if timer ready
			//			if ([timerControllerStartup ready] ) {
			
			
			if (!establishedPosition) {
				if ([timerEstablishPosition ready]) {
					
					PGLog( @"  ---> establishing Player Position");
					[[patherController movementController] establishPlayerPosition];
					
					establishedPosition = YES;
				}
			}
			
			// Synchronization: CombatController and our Mob
			if (mob != [combatController castingUnit]) {
				
				// how did this happen?  
				// let's fix it:
				[combatController resetAllCombat];
				//					[botController cancelCurrentProcedure];
				[combatController stayWithUnit:mob withType:TargetEnemy];
				[botController actOnUnit:mob];
				return CCCombatCombat;  
				
			}
			
			// if ![mob isDead] && ![inCombat]
			if (![mob isDead] && ![combatController inCombat]) {
				
				// if I'm not attacking then tell combatController to attack!
				PGLog( @"CustomClassPG: i'm not in combat ... [botController actOnUnit:mob]");
				[combatController stayWithUnit:mob withType:TargetEnemy];
				[botController actOnUnit:mob];
				
				// timer reset
				[timerControllerStartup reset];
			} // end if
			
			
			// if [mob isDead]
			// NOTE: I've seen mobs with 1 health being reported as dead!
			//				if (([mob isDead])  && ([mob currentHealth] < 1) ) {
			if ([mob isDead]) {
				
				if (!isMobDead) {
					PGLog(@"  ccKillTarget: mob is Dead ... starting timer");
					// ok, sometimes our cc detects a dead mob before the [CombatController] does.
					// so in order to determine proper exit state (Success vs SuccessWithAdd) we
					// need to wait until [CombatController] registers a dead mob.
					// timerMobDied attempts to give the [CombatController] time to register.
					[timerMobDied start];
					isMobDead = YES;
				}
				
				if ([timerMobDied ready] ) {
					
					PGLog(@"  ccKillTarget: mob is Dead && timer ready ... let's hope CC is updated");
					state = CCCombatPreCombat;  // reset my combat to do initial attack.
					
					// if attackQueue is empty then all done.
					if ( ![[combatController combatList] count] ) {
						
						// return CombatSuccess
						return CombatStateSuccess;
						
					} else {
						// there are more to deal with:
						
						// if combatController has current attack target then mark that one
						if ( [combatController attackUnit] != nil) {
							
							// currentMob = currentTarget
							self.currentMob = (Mob *) [combatController attackUnit];
							
						} // end if
						
						// return CombatSuccessWithAdd
						return CombatStateSuccessWithAdd;
						
					} // end if
					
				} // end timerMobDied  ready
				
			} // end if
			
			//// check for Evading => Bugged
			/ *
			 // if the unit is either not in combat, or is evading
			 if( ![unit isInCombat] || [unit isEvading] || ![unit isAttackable] ) { 
			 if(botController.isBotting) PGLog(@"[Combat] -XX- Unit %@ not in combat.", unit);
			 [self blacklistUnit: unit];
			 return;
			 }
			 * /
			
	
			// if unit ended up blacklisted ... bail
			if ([[patherController blacklistController] isBlacklisted:mob]) {
				PGLog(@"   Mob ended up Blacklisted.  You can ask CombatController why ... ");
				return CombatStateBugged;
			}
			
			
			
			//			} // end if timer ready
			return CombatStateInCombat;
			break;
		default:
			break;
	}
*/
	
	// shouldn't get to here!  One of the above should proc.
	return CombatStateDied;
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



#pragma mark -

+ (id) classWithController: (PatherController *) controller {
	
	return [[[MPCustomClassScrubDruid alloc] initWithController:controller] autorelease];
}
@end
