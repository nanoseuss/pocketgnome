//
//  MPPullTask.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskPull.h"
#import "MPTask.h"
#import "MPValue.h"

#import "MPActivityApproach.h"
#import "MPActivityAttack.h"
#import "MPActivityWait.h"
#import "PatherController.h"
#import "BotController.h"
#import "CombatProfile.h"
#import "MobController.h"
#import "PlayerDataController.h"
#import "MPCustomClass.h"
#import "Mob.h"
#import "CombatController.h"
#import "BlacklistController.h"
#import "MPTimer.h"
#import "MPMover.h"




@interface MPTaskPull (Internal)


/*!
 * @function mobToPull
 * @abstract Returns closest valid mob to pull.  nil if none.
 * @discussion
 */
- (Mob *) mobToPull;

/*!
 * @function isValidTargetName
 * @abstract Does given mob match our name requirements?
 * @discussion
 */
- (BOOL) isValidTargetName: (Mob*)mob;


/*!
 * @function isValidFaction
 * @abstract Does given mob match our faction requirements?
 * @discussion
 */
- (BOOL) isValidFaction: (Mob*)mob;


/*!
 * @function isIgnored
 * @abstract Does given mob match an ignored mob name?
 * @discussion
 */
- (BOOL) isIgnored: (Mob*)mob;



/*!
 * @function tooManyAdds
 * @abstract Does given mob have too many adds near by?
 * @discussion
 */
- (BOOL) tooManyAdds: (Mob*)mob;



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



/*!
 * @function clearWaitActivity
 * @abstract Properly shuts down the Wait Activity.
 * @discussion
 */
- (void) clearWaitActivity;


@end


@implementation MPTaskPull

@synthesize names, ignoreNames, factions;
@synthesize minLevel, maxLevel;
@synthesize selectedMob;
@synthesize approachActivity;
@synthesize attackActivity;
@synthesize waitActivity;
@synthesize mobController;
@synthesize playerData;
@synthesize customClass;
@synthesize taskController;
@synthesize mobDistance, attackDistance;
@synthesize timerWrapup;


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Pull";
		
		names = nil;
		ignoreNames = nil;
		factions = nil;
		approachActivity = nil;
		attackActivity = nil;
		waitActivity = nil;
		
		
		attackDistance = [[[controller botController] theCombatProfile] engageRange];
		mobDistance = 30.0;
		
		self.selectedMob = nil;
		
		state = PullStateSearching;
		
		self.timerWrapup = [MPTimer timer:750];  // 3/4 sec delay to wait for loot to become active
		
		self.mobController = [controller mobController];
		self.playerData = [controller playerData];
		self.customClass = [controller customClass];
		self.taskController = [controller taskController];
	}
	return self;
}

- (void) setup {

	self.names = [self arrayStringsFromVariable:@"names" ];
	self.ignoreNames = [self arrayStringsFromVariable:@"ignore"];
	self.factions = [self arrayNumbersFromVariable:@"factions" withExpectedType:@"int"];
	self.minLevel = [self integerFromVariable:@"minlevel" orReturnDefault:[[[patherController botController] theCombatProfile] attackLevelMin]];
	self.maxLevel = [self integerFromVariable:@"maxlevel" orReturnDefault:[[[patherController botController] theCombatProfile] attackLevelMax]];
	mobDistance = [[self stringFromVariable:@"distance" orReturnDefault:@"30.0"] floatValue];
	
	skipMobsWithAdds = [self boolFromVariable:@"skipmobswithadds" orReturnDefault:NO];
	addDistance = (NSInteger)[[self integerFromVariable:@"addsdistance" orReturnDefault:15] value];
	addCount = (NSInteger)[[self integerFromVariable:@"addscount" orReturnDefault:2] value];
	
}
	


- (void) dealloc
{
    [names release];
	[ignoreNames release];
	[factions release];
	[minLevel release];
	[maxLevel release];
	[approachActivity release];
	[attackActivity release];
	[waitActivity release];
	
	[mobController release];
	[playerData release];
	[customClass release];
	[taskController release];
	[timerWrapup release];
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	return NO;
}



- (MPLocation *) location {

	Mob *currentMob = [self mobToPull];
	
	if ( currentMob == nil) 
		return nil;
	
	return (MPLocation *)[currentMob position];
}



- (void) restart {
	state = PullStateSearching;
 }

 

- (BOOL) wantToDoSomething {
PGLog( @"[Pull wtds]: ");
	
	Mob *currentMob = [self mobToPull];
	float currentDistance;
	
	// if mob not found
	if (state != PullStateWrapup) {
		if (currentMob == nil) {
PGLog (@" no PUll Mob found ... ");
if (state != PullStateSearching) {
PGLog(@"switching to PullStateSearching!!!");
}
			state = PullStateSearching;
		}
	}
	
	switch (state) {
	
		default:
		case PullStateSearching:
PGLog( @"   state[Searching]");
			
			[taskController setInCombat:NO];
			
			// if currentMob found
			if (currentMob != nil) {
			
				BOOL wantToApproach = [[MPMover sharedMPMover] shouldMoveTowards:(MPLocation *)[currentMob position] within:attackDistance facing:(MPLocation *)[currentMob position]];
				
				if (wantToApproach) {
					
					state = PullStateApproaching;
					
				} else {
				
					state = PullStateAttacking;
					[customClass preCombatWithMob:currentMob atDistance:currentDistance];

				}
				/*
				currentDistance = [self myDistanceToMob:currentMob];
				
				// if distance to mob > combatDist
				if ( currentDistance > attackDistance) {
PGLog( @"      mob [%@] found at distance %f : ==> Approaching", currentMob, currentDistance);
					// phase = approaching
					state = PullStateApproaching;
					
				} else {
PGLog( @"      mob [%@] found at distance %f : ==> ATTACK!!!", currentMob, currentDistance);
					// phase = attack
					state = PullStateAttacking;
					
					// Make sure we fire off a preCombat before hand:
					[customClass preCombatWithMob:currentMob atDistance:currentDistance];
					
				} // end if
				 
				 */
				
			} // end if
			break;
			
			
		case PullStateApproaching:
PGLog( @"   state[Approaching]");	


				BOOL wantToApproach = [[MPMover sharedMPMover] shouldMoveTowards:(MPLocation *)[currentMob position] within:attackDistance facing:(MPLocation *)[currentMob position]];
				if (!wantToApproach) {
				
					state = PullStateAttacking;
				}


		
			currentDistance = [self myDistanceToMob:currentMob];
/*
PGLog( @"      mob [%@] at distance %f ", currentMob, currentDistance);
			// if distance to mob < combatDist
			if (currentDistance <= attackDistance ) {  // now use Engage Range in combat profile
PGLog( @"         close enough!!! ===> ATTACK!!! ");
				// phase = attack
				state = PullStateAttacking;
			} // end if
*/
			
			[customClass preCombatWithMob:currentMob atDistance:currentDistance];
			break;
			
		case PullStateAttacking:
PGLog( @"   state[Attacking]");
			
			// if mob is dead  (shouldn't get here)
//			if ([currentMob isDead]) {
//				// maybe we got here because the selectedMob wasn't updated correctly
//				self.selectedMob = nil;
//				currentMob = nil;
//				state = PullStateSearching;
//				return [self wantToDoSomething];  // try again.
//			} // end if

			PGLog( @"      mob [%@] at health [%d] ", currentMob, [currentMob currentHealth]);

			// attempting to prevent the beginning to run off before looting becomes active
//			if (([currentMob isDead])&&([currentMob currentHealth] <1)) {
			if ([currentMob isDead]) {

PGLog( @"         mob finished: ===> Wait for Loot ");
				[timerWrapup start];
				
				state = PullStateWrapup;
				return [self wantToDoSomething];  // try again.
			} // end if
			
			
			// if distance to mob > combatDist
			currentDistance = [self myDistanceToMob:currentMob];
			if (currentDistance > attackDistance+ 3.0f ) { 
				state = PullStateApproaching;
			} // end if
			
			
			// if mob != [attackTask mob] 
			if (currentMob != [attackActivity mob] ) {
			
				// notice: New Mob to Pull [mob name]
				PGLog( @"[         : new mob to pull [%@]", [currentMob name]);
				
				// phase = searching
				state = PullStateSearching;
				
				return [self wantToDoSomething];  // reeval searching condi
				
			} // end if
			break;
			
		case PullStateWrapup:
PGLog( @"   state[Waiting]");
			// ok, now we have waited for looting to become active 
			if ([timerWrapup ready]) {
				// maybe we got here because the selectedMob wasn't updated correctly
				self.selectedMob = nil;
				currentMob = nil;
				state = PullStateSearching;
				
				PGLog( @"::::::: Pull : timerWrapup is Ready -> switching to PullStateSearching");
				
				
				return [self wantToDoSomething];  // try again.
			} // end if
		
			break;

	}
	
	// if we found a mob then we want to do something.
	return (currentMob != nil);
}



- (MPActivity *) activity {

	Mob *currentMob = [self mobToPull];
		
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
			
			// if wait task active then
			if (waitActivity != nil) {
				[self clearWaitActivity];
			} 
			
			// if approachTask not created then
			if (approachActivity == nil) {
			
				// create approachTask
				float howClose = (attackDistance  > 5.0f) ? (attackDistance -2.5): 4.0f;
				self.approachActivity = [MPActivityApproach approachUnit:currentMob withinDistance:howClose forTask:self];
				
			}
			return (MPActivity *)approachActivity;
			break;
			
			
		case PullStateAttacking:
		
			// if approachActivity created then
			if (approachActivity != nil) {
				[self clearApproachActivity];
			}
			
			// if wait task active then
			if (waitActivity != nil) {
				[self clearWaitActivity];
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
			
			
		case PullStateWrapup:
			
			if (approachActivity != nil) {
				[self clearApproachActivity];
			}
			
			if (attackActivity != nil) {
				[self clearAttackActivity];
			}
			
			if (waitActivity == nil) {
				self.waitActivity = [MPActivityWait waitIndefinatelyForTask:self];
			}
			return waitActivity;
			break;

	}
	
	// we really shouldn't get here.
	// return 
	return nil;
}



- (BOOL) activityDone: (MPActivity*)activity {

	// that activity is done so release it 
	if (activity == approachActivity) {
		[self clearApproachActivity];
	}
	
	if (activity == attackActivity) {
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



- (Mob *) mobToPull {

	if (self.selectedMob == nil) {
		
		
		
		// if our attackTask isn't active then
		MPActivity *currentActivity = [taskController currentActivity];
		if (((attackActivity == nil) && (approachActivity == nil)) || ((currentActivity != attackActivity) && (currentActivity != approachActivity))) {
		
			float selectedDistance = INFINITY;  // distance of the closest mob we have found
			
			NSInteger low = (NSInteger) [minLevel value];
			NSInteger high = (NSInteger) [maxLevel value];
			NSArray *localMobs = [mobController mobsWithinDistance:mobDistance levelRange:NSMakeRange(low, (high-low) +1) includeElite:YES includeFriendly:NO includeNeutral:YES includeHostile:YES];

			
			// of the mobs in our level and distance find those that match the names/factions:
			for(Mob *mob in localMobs) {

//	PGLog(@"  mobToPull(): evaluating mob: %@  at dist[%0.2f]", mob, [self myDistanceToMob:mob] );

				if ([mob currentHealth] >= 1 ) {  // I've noticed mobs with 1 health reported as isDead!!!
				
					if (![[patherController blacklistController] isBlacklisted:mob] ) {
				
						if ( [self isValidTargetName:mob] && [self isValidFaction:mob] && ![self isIgnored:mob] ) {
						
							// if not too many adds
							if (![self tooManyAdds:mob] ) {
							
								float currentDistance = [self myDistanceToMob:mob]; 
								
								if (currentDistance < selectedDistance) {
									selectedDistance = currentDistance;
									self.selectedMob = mob;
								}
								
							} // end if
						 } 
					} else {
						
						PGLog(@"   ---> mob is found to be blacklisted by CombatController! ignore.");
					}
				 }
			
			}
		
		
		// else 
		} else {
		
			if (attackActivity != nil) {
				PGLog (@" [mobToPull] : keeping same selectedMob as current attackActivity ... ");
				
				// let's make sure we keep the same mob as our attackTask until it determines
				// it's done.  (this is to make sure we synchronize properly between PPather and [CombatController]
				self.selectedMob = [attackActivity mob];
			} else {
				PGLog(@" [mobToPull] : keeping same selectedMob as current approach Activity ... ");
				self.selectedMob = (Mob *) [approachActivity unit];
			}
			
		} // end if our attackClass isn't active

		
	} // end if selectedMob == nil
	
	return selectedMob;  // the closest mob, or nil

}



- (BOOL) isValidTargetName: (Mob*)mob {
	
	if ([names count] == 0) {
		return YES;
	} else {
	
		for( NSString *mobName in names) {
//PGLog (@"mobName[%@] vs mob->name[%@]", mobName, [mob name]);
			if ([mobName isEqualToString:[mob name]] ) {
				return YES;
			}
		}
	}
	return NO;
}



- (BOOL) isValidFaction: (Mob*)mob {
	
	if ([factions count] == 0) {
		return YES;
	} else {
	
		for( NSNumber *mobFaction in factions) {
			if ((UInt32)[mobFaction intValue] == [mob factionTemplate] ) {
				return YES;
			}
		}
	}
	return NO;
}



- (BOOL) isIgnored: (Mob*)mob {
	
	if ([ignoreNames count] == 0) {
		return NO;
	} else {
	
		for( NSString *mobName in ignoreNames) {
			if ([mobName isEqualToString:[mob name]] ) {
				return YES;
			}
		}
	}
	return NO;
}



- (BOOL) tooManyAdds: (Mob*)mob {
	
	if (!skipMobsWithAdds) {
		// ok, we don't care so 
		return NO;
	} else {
	
		// level range:  
		// we might only want to pull levels between minLevel and maxLevel, but for considering adds
		// we'll try to consider a larger range of levels (ignoring levels -5 from your already low count)
		NSInteger low =  (NSInteger) [minLevel value] - 5;
		NSInteger high = (NSInteger) [maxLevel value] + 20;
		if (low <= 0) low = 1;
		
		NSArray *localMobs = [mobController mobsWithinDistance:addDistance levelRange:NSMakeRange(low, (high-low) +1) includeElite:YES includeFriendly:NO includeNeutral:NO includeHostile:YES];
		
		if ([localMobs count] >= addCount) {
			return YES;
		} else {
			return NO;
		}
	}
	return NO;
}



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (selectedMob != nil) {
		
		[text appendFormat:@"  mob found: %@",[selectedMob name]];
		
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
				[text appendFormat:@"  waiting for loot!\n   %@", selectedMob];
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
//	[taskController setInCombat:NO];  // moving to clearWaitActivity to pause for looting
}



- (void) clearApproachActivity {
	[approachActivity stop];
	[approachActivity autorelease];
	self.approachActivity = nil;
}



- (void) clearWaitActivity {
	[waitActivity stop];
	[waitActivity autorelease];
	self.waitActivity = nil;
	[taskController setInCombat:NO];
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskPull alloc] initWithPather:controller] autorelease];
}

@end
