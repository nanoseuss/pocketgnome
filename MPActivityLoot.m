//
//  MPActivityLoot.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityLoot.h"
#import "BotController.h"
#import "BlacklistController.h"
#import "Errors.h"
#import "LootController.h"
#import "Mob.h"
//#import "MovementController.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "PlayerDataController.h"

@interface MPActivityLoot (Internal)

- (void) clickMob;
- (void) blackListMob: (Mob *)aMob;
- (BOOL) isCasting;
- (BOOL) isLootWindowOpen;

@end


@implementation MPActivityLoot
@synthesize lootMob, timeOut, timeToSkin, mover; 
//movementController;

- (id)  initWithMob:(Mob *) aMob andShouldSkin:(BOOL)doSkin andTask:(MPTask*)aTask  {
	
	if ((self = [super initWithName:@"Loot" andTask:aTask])) {
		self.lootMob = aMob;
		shouldSkin = doSkin;
		state = LootActivityNotStarted;
		self.timeOut = [MPTimer timer:2150];
		self.timeToSkin = [MPTimer timer:3750];
		attemptCount = 0;
		self.mover = [MPMover sharedMPMover];
//		self.movementController = [[task patherController] movementController];

	}
	return self;
}


- (void) dealloc
{
    [lootMob release];
	[timeOut release];
	[timeToSkin release];
	[mover release];
//	[movementController release];
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (lootMob == nil) {
		PGLog( @"[ActivityLoot] Error: ActivityLoot called with lootMob as NIL");
		return;
	}
	// if lootMob is in Distance
	float distanceToMob = [task myDistanceToMob:lootMob];
	if (distanceToMob <= 5.0 ) {
	
		// if lootMob isLootable  || ( lootMob is skinable && shouldSkin) 
		if ([lootMob isLootable] || ( [lootMob isSkinnable] && shouldSkin) ) {
			
			PGLog( @"[ActivityLoot] [start] clicking on Mob ... ");
		
			// face mob
			[mover faceLocation:(MPLocation *)[lootMob position]];
//			[movementController stopMovement];
//			[movementController turnTowardObject:lootMob];
			
			// mouse click on mob
			[self clickMob];
			
			
			// timeOut start
			[timeOut start];
			
			// if isLootable
			if ([lootMob isLootable]) {
				
				// start at beginning of process
				state = LootActivityNotStarted;
				return;
				
			} else {
			
				// else assume we are left to skin
				state = LootActivitySkinning;
				return;
			}
			
		} else {
		
			PGLog (@"[ActivityLoot] Error: we are in proper distance, but lootMob is not lootable [%d] or ( skinnable [%d] && shouldSkin [%d])", [lootMob isLootable], [lootMob isSkinnable], shouldSkin);
			
		} // end if
	
	} else{
		
		PGLog( @"[ActivityLoot]  Error: too far away to attempt loot!  MPTaskLoot -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be looting
	state = LootActivityFinished;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	
	int lastErrorID;
	
	// switch (state)
	switch (state) {
		case LootActivityNotStarted:
		// at this point we are expecting to do a Loot.  We should have already performed a click on the mob,
		// so now we wait for the loot window to appear.
		
		
			// if iscasting
			if ([self isCasting]) {
				/// hmmm ... shouldn't be casting when looting ... I guess we are skinning
				
				PGLog( @"[ActivityLoot] NotStarted: but player is casting ... I'm guessing no loot and we are skinning.");
				
				// timeOut restart
				[timeToSkin start];
				[timeOut reset];
				
				// attemptCount = 0; 
				attemptCount = 0;
				
				// switch to skinning
				state = LootActivitySkinning;
				
			} // end if
			
			// if lootWindow visible
			if ([self isLootWindowOpen]) {
			
				// Yeah! Got some lewt!
				PGLog(@"[ActivityLoot] loot Window Visible!");
				
				// state = looting
				state = LootActivityLooting;
				
				// lootController lootItems
//				[[[task patherController] lootController] acceptLoot];
				
				attemptCount = 0;
				
				[timeOut reset];

				
			} // end if
			
			// if timeOut ready
			if ([timeOut ready] ) {
			
				// if (attempt++) >= 3
				if (++attemptCount >= 3) {
				
					// blacklist mob
					[self blackListMob:lootMob];
					
					// logError (loot attempts timed out)
					PGLog(@"[ActivityLoot] Error: initial loot attempt failed after 3 tries ... no loot window appeared.");
					
					// state = finished
					state = LootActivityFinished;
					
				} // end if
				
				// mouseclick mob again
				[self clickMob];
				
				// timeOut reset
				[timeOut reset];
			} 
			return NO;
			break;
			
		case LootActivityLooting:
		// at this point, loot window appeared and we told it to loot all.  Now we wait until the loot window closes before 
		// moving on.

			
			lastErrorID = [[[task patherController] botController] errorValue:[[[task patherController] playerData] lastErrorMessage]];
			if ( lastErrorID == ErrInventoryFull ){
				// logError : unable to loot (perhaps inventory full?)
				PGLog( @"[ActivityLoot] Error: Looks like we have an INVENTORY FULL WARNING. --> finished.");
				
				// state = finished
				state = LootActivityFinished;
				
				attemptCount = 2; // no waiting
				
				// blacklist mob
				[self blackListMob:lootMob];
			}
			
			// if !lootWindow visible
			if (![self isLootWindowOpen] ) {
			
				PGLog( @"[ActivityLoot] lootWindow closed now ... check for skinning.");
				
				// verify loot ???
				// log successfulLoot
				
				// if shouldSkin
				if (shouldSkin) {
				
					// if mob isSkinnable  (<-- may take a few sec to register, but we should catch it before our attempCount runs out)
					if ([lootMob isSkinnable]) {
					
						PGLog(@"[ActivityLoot] Skinning wanted and mob is skinnable.  Lets give it a try...");
						
						// mouse click on mob again
						[self clickMob];
						
							
						// state = WaitForSkinningStart
						state = LootActivityWaitingForSkinningStart;
			
						[timeToSkin reset];
						[timeOut reset];
						
						attemptCount = 0;
						
						return NO;
						
					} else {
					
						if (attemptCount >= 1) { // it's been 2 sec, bail!
						
							PGLog( @"[ActivityLoot] Error: Waited for mob to become skinnable ... but never did.");
							state = LootActivityFinished;
//							return YES;
						
						}
					
					}// end if
					
				} else {
				
					PGLog(@"[ActivityLoot] No skinning wanted.  So finished.");
					
					state = LootActivityFinished;
					//[timeOut reset];
					attemptCount = 1; // no waiting ...
					
				} // end if shouldSkin
			} // end if
	
			// if timeOut ready
			if ([timeOut ready]) {
			
				// if attemptCount ++ > 3
				if (++attemptCount >= 3) {
				
					// logError : unable to loot (perhaps inventory full?)
					PGLog( @"[ActivityLoot] Error: loot window still open after 3 tries ... some problem");
					
					// state = finished
					state = LootActivityFinished;
					
					// blacklist mob
					[self blackListMob:lootMob];
					
					[timeOut reset];
					attemptCount = 0;
					
					return NO;
					
				} // end if
				
				// lootController lootItems : perhaps autoLoot isn't enabled, try the LootController then ...
				[[[task patherController] lootController] acceptLoot];
				
				[timeOut reset];
				
			} // end if
			
			return NO;
			break;
			
			
		case LootActivityWaitingForSkinningStart:
			
			// if isCasting
			if ([self isCasting] ) {
				
				PGLog( @"[ActivityLoot] Skinning Started ... now wait for finish.");
				
				// good, we've started skinning ... 
				state = LootActivitySkinning;
				
				[timeToSkin reset];
				[timeOut reset];
				attemptCount =0;
				return NO;
				
			}
			
			if ([self isLootWindowOpen] ) {
				
				PGLog(@"[ActivityLoot] Another Loot Window open ... assume skinning finished.");
				state = LootActivityFinished;
				
				[timeToSkin reset];
				[timeOut reset];
				attemptCount =0;
				return NO;
				
			}
			
			// if timeOut ready
			if ([timeToSkin ready]) {
				
				// if attemptCount ++ > 3
				if (++attemptCount >= 2) {
					
					// logError : unable to loot (perhaps inventory full?)
					PGLog( @"[ActivityLoot] Error: casting never started after clicking on mob ... bailing!");
					
					// state = finished
					state = LootActivityFinished;
					
					// blacklist mob
					[self blackListMob:lootMob];
					
					[timeOut reset];
					attemptCount = 1; // no waiting here ...
					return NO;
					
				} // end if
				
				// click on mob again ... 
				[self clickMob];
				
				[timeToSkin reset];
				
			} // end if
			
			return NO;
			break;
			
			
			
		case LootActivitySkinning:
		
			// if skinComplete
			if ( ![self isCasting] || ![lootMob isValid] || ![lootMob isSkinnable] || [self isLootWindowOpen] ) {
				// we are no longer in a state where we would be skinning ... so quit.
				
				PGLog(@"[ActivityLoot] Success: looks like we've finished skinning.");
				
				state = LootActivityFinished;
				
				// ok it seems like a mob remains "around" for a few seconds after it is finished looting/skinning
				// so we blacklist it here to make sure we don't retarget it right away.
				[self blackListMob:lootMob]; 
				
				attemptCount = 0;
				[timeOut reset];
				
//--->				// log skinSuccessful
				
				return NO;
			} // end if
			
			// if timeOut ready
			if ([timeToSkin ready]) {
				
				if (++ attemptCount >= 2) {
					// logError : Skinning timed out
					PGLog(@"[ActivityLoot] Error: waited > 6 sec for skinning to complete.  Let's move on.");
					
					state = LootActivityFinished;
					
					[self blackListMob:lootMob];
					[timeOut reset];
					attemptCount = 1; // no watiing
					
				} // endif
				[timeToSkin reset];
			} // end if
			break;

		case LootActivityFinished:
			
			// wait for loot window to close before finishing out... 
			if ([timeOut ready] ) {
				if ((![self isLootWindowOpen]) || (attemptCount >=1)) {
					PGLog(@"[ActivityLoot] Finishing and reporting Done!");
					[[[task patherController] botController] removeLootMob:lootMob]; // make sure this mob was removed from the list.
					return YES;
				}
				[timeOut reset];
				attemptCount ++;
			}
			break;


		default:
			break;
	}

	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
	
	attemptCount = 0;
	
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
/*	if (unit != nil) {
		
		Position *playerPosition = [playerDataController position];
		float currentDistance = [playerPosition distanceToPosition: [unit position]];
		
		[text appendFormat:@"  approaching [%@]  [%0.2f / %0.2f]", [unit name], currentDistance, distance];
		
	} else {
		[text appendString:@"  no unit to approach"];
	}
*/
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the lootMob
- (void) clickMob {
	[[[task patherController] botController] interactWithMouseoverGUID: [lootMob GUID]];
}


// send a blacklist command to the botController
- (void) blackListMob: (Mob *)aMob {
	[[[task patherController] blacklistController] blacklistObject:aMob];
	[[task patherController] lootBlacklistUnit:aMob];
}


// are we casting (like skinning?)
- (BOOL) isCasting {
	return [[[task patherController] playerData] isCasting];
}

// is the LootWindow open?
- (BOOL) isLootWindowOpen {
	return [[[task patherController] lootController] isLootWindowOpen];
}

#pragma mark -

+ (id)  lootMob:(Mob *)aMob andSkin: (BOOL) shouldSkin forTask:(MPTask *)aTask {
		
	return [[[MPActivityLoot alloc] initWithMob:aMob andShouldSkin:shouldSkin andTask:aTask] autorelease];
}


@end
