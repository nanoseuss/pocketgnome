//
//  MPTaskDefend.m
//  Pocket Gnome
//
//  Created by admin on 10/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskDefend.h"
#import "MPTask.h"
#import "MPValue.h"

#import "MPActivityApproach.h"
#import "MPActivityAttack.h"
#import "PatherController.h"
#import "BotController.h"
#import "CombatProfile.h"
#import "MobController.h"
#import "PlayerDataController.h"
#import "CombatController.h"
#import "MPCustomClass.h"
#import "Mob.h"




@interface MPTaskDefend (Internal)


/*!
 * @function mobAttackingMe
 * @abstract Returns closest mob attacking you.  nil if none.
 * @discussion
 */
- (Mob *) mobAttackingMe;



/*!
 * @function clearAttackActivity
 * @abstract Properly shuts down the Attack Activity.
 * @discussion
 */
- (void) clearAttackActivity;



/*!
 * @function clearApproachActivity
 * @abstract Properly shuts down the Approach Activity.
 * @discussion
 */
- (void) clearApproachActivity;


@end



@implementation MPTaskDefend
@synthesize selectedMob;
@synthesize approachActivity;
@synthesize attackActivity;
@synthesize mobController;
@synthesize playerData;
@synthesize customClass;
@synthesize taskController;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Defend";
		

		approachActivity = nil;
		attackActivity = nil;
		
		attackDistance = [[[controller botController] theCombatProfile] attackRange];
		
		self.selectedMob = nil;
		
		state = PullStateSearching;
		
		self.mobController = [controller mobController];
		self.playerData = [controller playerData];
		self.customClass = [controller customClass];
		self.taskController = [controller taskController];
	}
	return self;
}

- (void) setup {
	
	
}



- (void) dealloc
{
	[selectedMob release];
	[approachActivity release];
	[attackActivity release];
	
	[mobController release];
	[playerData release];
	[customClass release];
	[taskController release];
	
    [super dealloc];
}

#pragma mark -




- (MPLocation *) location {
	
	Mob *currentMob = [self mobAttackingMe];
	
	if ( currentMob == nil) 
		return nil;
	
	return (MPLocation *)[currentMob position];
}


- (void) restart {
	state = PullStateSearching;
}


- (BOOL) wantToDoSomething {
	
	Mob *currentMob = [self mobAttackingMe];
	float currentDistance;
	
	// if mob not found
	if (currentMob == nil) {
		//PGLog (@" no PUll Mob found ... ");
		
		state = PullStateSearching;
	}
	
	switch (state) {
			
		default:
		case PullStateSearching:
			
			[taskController setInCombat:NO];
			
			// if currentMob found
			if (currentMob != nil) {
				
				currentDistance = [self myDistanceToMob:currentMob];
				
				// if distance to mob > combatDist
				if ( currentDistance > attackDistance ) {
					
					// phase = approaching
					state = PullStateApproaching;
					
				} else {
					
					// phase = attack
					state = PullStateAttacking;
					
					// Make sure we fire off a preCombat before hand:
					[customClass preCombatWithMob:currentMob atDistance:currentDistance];
					
				} // end if
				
			} // end if
			break;
			
			
		case PullStateApproaching:
			
			currentDistance = [self myDistanceToMob:currentMob];
			
			// if distance to mob < combatDist
			if (currentDistance <= attackDistance ) {
				//PGLog(@" distance achieved ... switching state.");
				// phase = attack
				state = PullStateAttacking;
			} // end if
			
			[customClass preCombatWithMob:currentMob atDistance:currentDistance];
			break;
			
		case PullStateAttacking:
			
			// if mob is dead  (shouldn't get here)
			if ([currentMob isDead]) {
				// maybe we got here because the selectedMob wasn't updated correctly
				self.selectedMob = nil;
				currentMob = nil;
				state = PullStateSearching;
				return [self wantToDoSomething];  // try again.
			} // end if
			
			// if mob != [attackTask mob] 
			if (currentMob != [attackActivity mob] ) {
				
				// notice: New Mob to Pull [mob name]
				PGLog( @"[Pather] Pull : new mob to defend [%@]", [currentMob name]);
				
				// phase = searching
				state = PullStateSearching;
				
				return [self wantToDoSomething];  // reeval searching condi
				
			} // end if
			break;
	}
	
	// if we found a mob then we want to do something.
	return (currentMob != nil);
}


- (BOOL) isFinished {
	return NO;
}


- (MPActivity *) activity {
	
	Mob *currentMob = [self mobAttackingMe];
	
	switch (state) {
			
		default:
		case PullStateSearching:
			// shouldn't get here
			// clear out both activities
			[self clearAttackActivity];
			[self clearApproachActivity];
			return nil;
			break;
			
			
		case PullStateApproaching:
			
			// if attackTask active then
			if (attackActivity != nil) {
				
				[self clearAttackActivity];
				
			} 
			
			// if approachTask not created then
			if (approachActivity == nil) {
				
				// create approachTask
				self.approachActivity = [MPActivityApproach approachUnit:currentMob withinDistance:(attackDistance - 3) forTask:self];
				
			}
			return (MPActivity *)approachActivity;
			break;
			
			
		case PullStateAttacking:
			
			// if approachActivity created then
			if (approachActivity != nil) {
				[self clearApproachActivity];
			}
			
			// if currentMob != [attackTask mob] 
			if (attackActivity != nil) {
				if (currentMob != [attackActivity mob]) {
					
					// fighting wrong mob!! 
					[self clearAttackActivity];
				}
			}
			
			// if attackTask not created then
			if (attackActivity == nil) {
				// create attackTask for currentMob
				self.attackActivity = [MPActivityAttack attackMob:currentMob forTask:self];
			}
			
			return attackActivity;
			break;
			
	}
	
	// we really shouldn't get here.
	// return 
	return nil;
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	// that activity is done so release it 
//	if (activity == approachActivity) {
	if ([activity isEqualTo:approachActivity]) {
		[self clearApproachActivity];
	}
	
//	if (activity == attackActivity) {
	if ([activity isEqualTo:attackActivity]) {
		[self clearAttackActivity];
	}
	
	return YES; // ??
}


#pragma mark -
#pragma mark Helper Functions

- (void) clearBestTask {
	
	//	[self.selectedMob release];
	self.selectedMob = nil;
	
}

- (Mob *) mobAttackingMe {
	
	MPActivity *currentActivity;
	MPTask *currentTask;
	
	if (self.selectedMob == nil) {
//		if ([playerData isInCombat] ) {
			
			// if currentActivity != ActivityAttack ||  currentTask == Defend 
			currentActivity = [[patherController taskController] currentActivity];
			currentTask = [currentActivity task];
			
			if (    ( (attackActivity != nil) && (attackActivity == currentActivity)) ||
					( ![[currentActivity name] isEqualToString:@"Attack"] ) 
					
					) {
				
				[[patherController combatController] doCombatSearch];
				NSArray * listMobs =  [[patherController combatController] allAdds];
						
				// now we have a good list of options
				// let's pick the closest mob
				float selectedDistance = INFINITY;
				
				for(Mob *mob in listMobs) {
					
					if ([mob currentHealth] >= 1) {
						float currentDistance = [self myDistanceToMob:mob];
						
						PGLog(@" mobAttackingMe(): mob[%@] isDead[%d] distance[%0.2f]", [mob name], [mob isDead], currentDistance);
						if (currentDistance < selectedDistance) {
							PGLog (@"  ---> selected ");
							selectedDistance = currentDistance;
							self.selectedMob = mob;
						}
						
					} else {
					
						PGLog(@"[Defend][mobAttackingMe] : uh ... list of units attacking me includes a DEAD mob ... why?!?");
					}
					
				}
			
			} else {
				
				PGLog( @"[Defend][mobAttackingMe] : I'm in combat, but already an Attack Activity, so let it handle it. " );
				
			} // end if currentActivity || currentTask
//		} else {
//			PGLog (@" [Defend][mobAttackingMe] : I'm not in combat, so continue on... ");
//		}
	}
	
	return selectedMob;  // the closest mob, or nil
	
}





- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (selectedMob != nil) {
		
		[text appendFormat:@"  attacked by: %@",[selectedMob name]];
		
		switch (state){
			case PullStateSearching:
				[text appendFormat:@"  looking for mobs ..."];
				break;
				
			case PullStateApproaching:
				[text appendFormat:@"  approaching: (%0.2f) / (%0.2f)", [self myDistanceToMob:selectedMob], attackDistance];
				break;
				
			case PullStateAttacking:
				[text appendFormat:@"  attacking!\n   %@", selectedMob];
				break;
				
			case PullStateWrapup:
				[text appendFormat:@"  waiting for loot ...\n   %@", selectedMob];
				break;
		}
		
	} else {
		[text appendString:@"No mobs of interest"];
	}
	
	return text;
}



- (void) clearAttackActivity {
	[attackActivity stop];
	[attackActivity autorelease];
	self.attackActivity = nil;
	[taskController setInCombat:NO];
}

- (void) clearApproachActivity {
	[approachActivity stop];
	[approachActivity autorelease];
	self.approachActivity = nil;
}


#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskDefend alloc] initWithPather:controller] autorelease];
}
@end
