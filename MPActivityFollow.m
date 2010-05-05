//
//  MPActivityFollow.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPActivityFollow.h"

#import "BotController.h"
#import "Mob.h"
#import "MovementController.h"
#import "MPCustomClass.h"
#import "MPMover.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "Position.h"
#import "SpellController.h"
#import "Spell.h"
#import "Unit.h"






@interface MPActivityFollow (Internal)

- (float) myDistanceToUnit:(Unit *)unit;
- (float) myDistanceToPosition:(Position *)position;
- (void) removeClosePositions;

@end






@implementation MPActivityFollow

@synthesize followUnit, lastPosition, mover, targetRoute, customClass;
@synthesize timerMountDelay;



- (id) initWithUnit: (Unit*)aUnit approachTo: (float) howClose maxDistance:(float) howFar shouldMount:(BOOL) mount andTask:(MPTask*)aTask {
	
	if ((self = [super initWithName:@"Follow" andTask:aTask])) {
		
		self.followUnit = aUnit	;
		approachTo = howClose;
		maxDistance = howFar;
		shouldMount = mount;
		
		lastHeading = 0;
		self.lastPosition = nil;
		
		self.mover = [MPMover sharedMPMover];
		self.targetRoute = [NSMutableArray array];
		
		self.customClass = [[task patherController] customClass];
		
		self.timerMountDelay = [MPTimer timer:2500]; // 2.5s
		[timerMountDelay forceReady];
		
		state = FollowStateInRange;
	}
	return self;
}


- (void) dealloc
{
    [followUnit release];
	[lastPosition release];
	[mover release];
	[targetRoute release];
	[customClass release];
	
	[timerMountDelay release];
	
    [super dealloc];
}




#pragma mark -

- (void) start {

	state = FollowStateInRange;
	if ((followUnit != nil)&& ([followUnit isValid])) {
		lastHeading = [followUnit directionFacing];
		self.lastPosition = [followUnit position];
		[targetRoute addObject:[followUnit position]];
	}
	
	
	
	////
	//// it is possible that we could have been interrupted
	//// and are restarting.  Perhaps we ran to attack a mob.
	////
	//// at this point, it makes sense to find the closest point
	//// in our targetRoute and begin following from there.
	////
	
	// search current route and find closest location
	Position *myPosition = [[PlayerDataController sharedController] position];
	
	Position *bestPosition = nil;
	float currentDistance, minDistance;
	minDistance = INFINITY;
	for( Position *pos in targetRoute) {
		currentDistance = [myPosition distanceToPosition:pos];
		if (currentDistance <= minDistance) {
			bestPosition = pos;
			minDistance = currentDistance;
		}
	}
	
	// now remove points up to the bestPosition
	while( [targetRoute objectAtIndex:0] != bestPosition) {
		[targetRoute removeObjectAtIndex:0];
	}
	
}


- (BOOL) work{
	
	MPLocation *nextStep = nil;
	
	// if !unit.isValid
	if (![followUnit isValid]) {
		state = FollowStateLastKnownPosition;
	}
	
	
	if (shouldMount) {
	
		PlayerDataController *me = [PlayerDataController sharedController];
		Player *myPlayer = [me player];
		if ([followUnit isMounted]) {
			
			// If I'm not mounted, then mount
			if ((![myPlayer isMounted]) 
				&& (![me isCasting]) 
				&& (![me isInCombat]) 
				&& (![myPlayer isSwimming]) ) {
				
				int theMountType = 1;	// ground
				
				// air
				if ( ![followUnit isOnGround] ){
					theMountType = 2;
				}
				
				// time to mount!
				SpellController *spellController = [SpellController sharedSpells];
				Spell *mount = [spellController mountSpell:theMountType andFast:YES];
				if ( mount != nil ){
					PGLog(@"[Follow] Mounting...");
					
					if ([timerMountDelay ready]) { // timer to prevent recasting (and dismounting)
						
						[[[task patherController] botController] performAction:[[mount ID] intValue]];
						[timerMountDelay start];
					}
//					return NO;
				} else {
					PGLog(@"[Follow] couldn't find mount spell...");
				}
			}
			
		} else {
			
			// if I'm mounted then unmount
			if ([myPlayer isMounted]) {
				[[[task patherController] movementController] dismount];
				return NO;
			}
		}

	}
	/*
	 [aUnit isMounted]
	 
	 //if followUnit is !mounted but we are:
	 
	 if ( [[playerController player] isMounted] )
		 [movementController dismount];
	 
	 
	 
	 // mount?
	 if ( theCombatProfile.mountEnabled && [followTarget isMounted] && ![[playerController player] isMounted] && ![playerController isCasting] && ![[playerController player] isSwimming] && ![playerController isInCombat] ){
	 
	 int theMountType = 1;	// ground
	 
	 // air
	 if ( ![followTarget isOnGround] ){
	 theMountType = 2;
	 }
	 
	 // time to mount!
	 Spell *mount = [spellController mountSpell:theMountType andFast:YES];
	 if ( mount != nil ){
	 PGLog(@"[Follow] Mounting...");
	 
	 [self performAction:[[mount ID] intValue]];
	 
	 // Check our position again shortly!
	 [self performSelector: _cmd withObject: nil afterDelay: 2.0f];
	 return YES;
	 }
	 else{
	 // does this player have any mounts?
	 if ( [playerController mounts] > 0 && [spellController mountsLoaded] == 0 ){
	 PGLog(@"[Bot] Attempting to load mounts...");
	 
	 }					
	 }
	 }
	 
	 
	 */
		
	
	// if we are not mounting ... 
	if ([timerMountDelay ready]) {
		
		switch (state) {
				
				
			default:
			case FollowStateInRange:
				///
				/// We are in an acceptable range, so wait until followTarget
				/// gets > $MaxDistance away from me.
				///
				
				
				// our routines always expect at least 1 entry in TargetRoute
				if ([targetRoute count] == 0) {
					[targetRoute addObject:[followUnit position]];
				}
				
				
				// if (shouldmove) 
				if ([self myDistanceToUnit:followUnit] > maxDistance) {
					
					///
					/// oops, time to move
					///
					
					nextStep = (MPLocation *) [targetRoute objectAtIndex:0];
					// move to
					[mover moveTowards:nextStep  within:1.0f facing:nextStep];
					
					// state == approaching
					state = FollowStateApproaching;
					
				} else {
					
					///
					/// it's all good. Hang here and face our followTarget
					///
					
					[mover faceLocation: (MPLocation *)[followUnit position]];
				}// end if
				break;
			
				
				
			case FollowStateApproaching:
				
				///
				/// Trying to catch up to followTarget.
				///
				
				
				// if !shouldMove to Unit
				if ([self myDistanceToUnit:followUnit] <= approachTo) {
					
					///
					/// close enough, so take a rest.
					///
				
					// stop move
					[mover stopAllMovement];
					
					// state == InRange
					state = FollowStateInRange;
					
					return NO;
				} // end if
				
				
				// remove any unneeded positions
				[self removeClosePositions];
				
				
				// make sure we at least have 1 entry in our targetRoute array
				if ([targetRoute count] == 0) {
					[targetRoute addObject:[followUnit position]];
				}
				
				
				// do move
				nextStep = (MPLocation *)[targetRoute objectAtIndex:0];
				[mover moveTowards:nextStep within:1.0f facing:nextStep];
				break;
				
				
				
			case FollowStateLastKnownPosition:
				
				///
				/// Yikes!  FollowTarget has dissappeared. (entered instance?)
				/// we need to try to head to their last know location.
				/// 
				
				
				if ([followUnit isValid]) {
					
					///
					/// He's back.  Follow as normal.
					///
					
					state = FollowStateInRange;
					return [self work];
				}
				
				
				// remove any unneeded positions
				[self removeClosePositions];
				
				
				// if we still have a route to follow, finish it before moving
				// to last known location.
				nextStep = nil;
				if ([targetRoute count] > 0) {
					nextStep = (MPLocation *) [targetRoute objectAtIndex:0];
				} else {
					nextStep = (MPLocation *) lastPosition;
				}
				
				[mover moveTowards:nextStep within:1.0f facing:nextStep];
				break;

		}
	
	
	}
	
	
	if ([followUnit isValid]) {
		
		///
		/// OK, here we want to keep track of our followTarget and 
		/// mark where they are walking so we follow a similar path.
		/// This will help us navigate passages, doors, and bridges
		/// without falling off.
		///
		/// My trick here is to mark locations where the followTarget's
		/// direction has changed and run between those locations. If 
		/// their direction hasn't change, then we assume they are just 
		/// running in a straight line.
		///
		
		// if lastHeading != unit.heading
		if (lastHeading != [followUnit directionFacing]) {
			
			// if (distance from last added spot > XX)
			Position *lastRoutePosition = [targetRoute lastObject];
			float distanceFromLastPosition = [lastRoutePosition distanceToPosition:[followUnit position]];
			if (distanceFromLastPosition > 2.25f) {
				
				
				// targetRoute[] = [unit position]
				[targetRoute addObject:[followUnit position]];
				
				// lastHeading = unit.heading
				lastHeading = [followUnit directionFacing];
				
			}// end if
		}// end if
		
		
		///
		/// If it happens that the followUnit gets real close to us, 
		/// let's assume it is safe to start over from here and not 
		/// have to retrace all the other steps up to this point.
		///
		if ([self myDistanceToUnit:followUnit] <= 2.25f) {
			
			// we are close enough to clear our route and start over
			[targetRoute removeAllObjects];
		}
		
		// just keep track of the last known position of the followUnit
		self.lastPosition = [followUnit position];
	}
	
	
	[customClass runningAction]; // <--- spam running action here
	
	return NO;
}

- (void) stop{
	
	[mover stopAllMovement];
}


- (NSString *) description {
	NSMutableString *text = [NSMutableString stringWithFormat: @" activity[%@] \n   targetRoute[%d]", name, [targetRoute count]];
	if ([targetRoute count] > 0) {
		[text appendFormat:@"\n  <%@>", [targetRoute objectAtIndex:0]];
	}
	return text; 
}

#pragma mark -
#pragma mark Helper Methods


- (float) myDistanceToUnit:(Unit *)unit {
	return [self myDistanceToPosition: [unit position]];
}



- (float) myDistanceToPosition:(Position *)position {
	
	Position *playerPosition = [[PlayerDataController sharedController] position];
	return [playerPosition distanceToPosition: position];
}



- (void) removeClosePositions {
	
	// while (!shouldMOve to nextSpot) && (count targetRoute > 0)
	while (([targetRoute count] > 0) && ([self myDistanceToPosition:[targetRoute objectAtIndex:0]] <= 1.0f)) {
		[targetRoute removeObjectAtIndex:0];
	}

	
}


#pragma mark -

+ (id) follow:(Unit *) unit howClose:(float)howClose howFar:(float) howFar shouldMount:(BOOL)mount forTask:(MPTask *) task {
	
	return [[[MPActivityFollow alloc] initWithUnit:unit approachTo:howClose maxDistance:howFar shouldMount:mount andTask:task] autorelease];
}

@end
