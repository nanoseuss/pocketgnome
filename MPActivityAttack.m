//
//  MPActivityAttack.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityAttack.h"
#import "Mob.h"
#import "MPTaskController.h"
#import "MPCustomClass.h"
#import "MPTimer.h"


@implementation MPActivityAttack
@synthesize mob;
@synthesize customClass;
@synthesize taskController;
@synthesize waitForLoot;



- (id) initWithMob: (Mob*)aMob andTask:(MPTask*)aTask {
	
	if ((self = [super initWithName:@"Attack" andTask:aTask])) {

		self.mob = aMob	;
		state = AttackStateNotStarted;
		self.customClass = [[aTask patherController] customClass];
		self.waitForLoot = [MPTimer timer:1250];
	}
	return self;
}


- (void) dealloc
{
    [mob autorelease];
	[customClass autorelease];
	
    [super dealloc];
}




#pragma mark -


-(void) start {

}


- (BOOL) work {
	PGLog(@"[attack work]");
	switch (state) {
		default:
		case AttackStateNotStarted:
PGLog(@"   AttackStateNotStarted");		
			// dismount
			
			// face unit
			//[movementController turnTowardObject: unit]
			

			
			// state = Attacking
			state = AttackStateAttacking;
				
			break;
			
		case AttackStateAttacking:
PGLog(@"   AttackStateAttacking");
			// set inCombat flag
			[taskController setInCombat:YES];
			
			// result = customClass.killTarget(mob)
			MPCombatState result = [customClass killTarget:mob];
		
			// switch result
			switch (result) {
			
				// case Success
				case CombatStateSuccess:
					PGLog(@"    ccKillTarget result[%d]: Success", result );	
					// inCombat = false
					[taskController setInCombat:NO];
					
					// customClass.postCombat()
//					[customClass postCombat];
					
					// log kill
					state = AttackStateFinished;
					[waitForLoot start];
					
					break;
					
				// case SuccessWithAdd
				case CombatStateSuccessWithAdd:
					PGLog(@"    ccKillTarget result[%d]: Success With Add", result );	
					// log kill
					// mob = customClass.currentTarget()
					mob = [customClass currentMob];
					break;
					
				// case Died
				case CombatStateDied:
					PGLog(@"    ccKillTarget result[%d]: I Died", result );	
					// log death
					
					// inCombat = false
					[taskController setInCombat:NO];
					
					return YES; // <-- done
					break;
					
				// case Bugged:
				case CombatStateBugged:
					PGLog(@"    ccKillTarget result[%d]: Bugged", result );	
					// inCombat = false
					[taskController setInCombat:NO];
					
					// blackList(mob)
					
					return YES;  // <-- done
					break;
					
					
				// case Bugged:
				case CombatStateBuggedWithAdd:
					PGLog(@"    ccKillTarget result[%d]: Bugged With Add", result );	
					// blackList(mob)
					
					// mob = customClass.currentTarget()
					
					return NO; 
					break;
					
					
				// case Mistake: shouldn't have tried to attack (already Dead?)
				case CombatStateMistake:
					PGLog(@"    ccKillTarget result[%d]: Mistaken mob", result);
					return YES;
					break;
					
					
				default:
				case CombatStateInCombat:
					PGLog(@"    ccKillTarget result[%d]: InCombat", result );
					return NO;
					break;
			}
				
				
			// end switch
			break;
			
		case AttackStateFinished:
			if ([waitForLoot ready]) {
				return YES;
			}
			break;
	}
	
	return NO;
}


-(void) stop {
	PGLog(@"[attack stop]");
}


#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (mob != nil) {
	
		[text appendFormat:@"  attacking [%@]\n  ccState: ", mob];
		
	} else {
		[text appendString:@"  no unit to attack"];
	}
	
	return text;
}


#pragma mark -


+ (id) attackMob:(Mob*)aMob forTask: (MPTask*) aTask {
	return [[[MPActivityAttack alloc] initWithMob:aMob andTask:aTask] autorelease];
}

@end
