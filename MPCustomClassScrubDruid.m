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
#import "Mob.h"
#import "BlacklistController.h"
#import "MPSpell.h"
#import "MPMover.h"
#import "Unit.h"


@implementation MPCustomClassScrubDruid
@synthesize wrath;

- (id) initWithController:(PatherController*)controller {
	if ((self = [super initWithController:controller])) {
		
		self.wrath = [MPSpell wrath];
		state = CCCombatPreCombat;
	}
	return self;
}

- (void) dealloc
{
    
	
    [super dealloc];
}

#pragma mark -



- (NSString *) name {
	return @"ScrUb Druid";
}



- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob {
	
	// Normally preCombatWithMob: atDistance: ] is called numerous times for 
	// your CC to determine what to do on approaching your target (at various distances)
	// however in PG, all that is handled with [botController preCombatWithMob:].
	// So here we simply call that 1x and then return.
	
	
	
	state = CCCombatPreCombat;
}

- (MPCombatState) killTarget: (Mob*) mob {
	
	
	
	// if player isDead
	PlayerDataController *me = [PlayerDataController sharedController];
	if (([me isDead] ) || ([me isGhost])) {
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
			
			// face target
			PGLog(@"     --> Facing Target");
			MPMover *mover = [MPMover sharedMPMover];
			MPLocation *targetLocation = (MPLocation *)[currentMob position];
			[mover moveTowards:targetLocation within:28.0f facing:targetLocation];
//			[mover action];
			
			//// make sure we stop here!
			
			
			
			// make sure I'm targeting the target:
			PlayerDataController *me = [PlayerDataController sharedController];
			if ([me targetID] != [currentMob GUID]) {
				PGLog(@"     --> Setting Target : myTarget[%ld]  mob[%ld]",[me targetID], [currentMob GUID]);
				[me setPrimaryTarget:currentMob];
			}
			
			
			// cast
			int error = [wrath cast];
			PGLog(@"    ---> wrath cast error[%d]", error);
			
			

			return CombatStateInCombat;
			break;
		default:
			break;
	}

	
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
