//
//  MPTaskLoot.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskLoot.h"
#import "MPTask.h"
#import "Mob.h"
#import "PatherController.h"
#import "MobController.h"
#import "BotController.h"
#import "MPActivityApproach.h"
#import "MPActivityLoot.h"



@interface MPTaskLoot (Internal)

- (void) clearLootActivity;
- (void) clearApproachActivity;

- (Mob *) mobToLoot;

@end


@implementation MPTaskLoot
@synthesize distance, selectedMob, approachActivity, lootActivity;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Loot";
		
		skin = NO;
		distance = 30.0;
		
		self.selectedMob = nil;
		
		self.approachActivity = nil;
		self.lootActivity = nil;
		
		state = LootStateApproaching;
	}
	return self;
}


- (void) setup {

	distance = [[self stringFromVariable:@"distance" orReturnDefault:@"30.0"] floatValue];
	skin = [self boolFromVariable:@"skin" orReturnDefault:NO];
}
	

- (void) dealloc
{
    [selectedMob autorelease];
	[approachActivity autorelease];
	[lootActivity autorelease];
	
    [super dealloc];
}

#pragma mark -

- (BOOL) isFinished {
	return NO;
}



- (MPLocation *) location {

	Mob *currentMob = [self mobToLoot];
	
	if ( currentMob == nil) 
		return nil;
	
	return (MPLocation *)[currentMob position];
}


- (void) restart {
	state = LootStateApproaching;
 }
 
 
 
 
- (BOOL) wantToDoSomething {
	
	// if we are currently INCOMBAT we don't want to do looting...
	if ([[patherController playerData] isInCombat]) return NO;
	
	
	// if we have a current lootActivity then we want to do something.
//	if (lootActivity != nil) return YES;
	
	Mob *lootMob = [self mobToLoot];
	float currentDistance;
	
	// if mob found
	if (lootMob != nil) {

		currentDistance = [self myDistanceToMob:lootMob];
		if (currentDistance > 4.90) {
		
			state = LootStateApproaching;
			
		} else {
		
			state = LootStateLooting;
		}
	}
	else {
		PGLog( @"[TaskLoot] No lootMob Found!  wtds = false");	
	}
	
		
	// if we found a mob then we want to do something.
	return (lootMob != nil);
}



- (MPActivity *) activity {

	Mob *lootMob = [self mobToLoot];
		
	switch (state) {
	
		default:
			break;
			
			
		case LootStateApproaching:
		
			// if attackTask active then
			if (lootActivity != nil) {
			
				[self clearLootActivity];
				
			} 
			
			// if approachTask not created then
			if (approachActivity == nil) {
			
				// create approachTask
				self.approachActivity = [MPActivityApproach approachUnit:lootMob withinDistance:4.9 forTask:self];
				
			}
			return (MPActivity *)approachActivity;
			break;
			
			
		case LootStateLooting:
		
			// if approachActivity created then
			if (approachActivity != nil) {
				[self clearApproachActivity];
			}
			
			// if attackTask not created then
			if (lootActivity == nil) {
				// create lootTask for lootMob
				self.lootActivity = [MPActivityLoot lootMob:lootMob andSkin:skin forTask:self];
			}
			
			return lootActivity;
			break;

	}
	
	// we really shouldn't get here.
	// return 
	return nil;
}



- (BOOL) activityDone: (MPActivity*)activity {

	PGLog(@"[TaskLoot] activityDone");
	
	// that activity is done so release it 
	if (activity == approachActivity) {
		[self clearApproachActivity];
	}
	
	if (activity == lootActivity) {
		[self clearLootActivity];
	}
	
	return YES; // ??
}

#pragma mark -
#pragma mark Helper Functions

- (void) clearBestTask {
	
	self.selectedMob = nil;
	
}


- (void) clearLootActivity {
	[lootActivity stop];
	[lootActivity autorelease];
	self.lootActivity = nil;
}

- (void) clearApproachActivity {
	[approachActivity stop];
	[approachActivity autorelease];
	self.approachActivity = nil;
}

- (Mob *) mobToLoot {

	if (self.selectedMob == nil) {
			
		NSArray *localMobs = [[patherController mobController] allMobs];
		
		float selectedDistance = INFINITY;
		float currentDistance = INFINITY;
		
		for ( Mob* mob in localMobs) {
			
			if (([mob isLootable]) || (skin && [mob isSkinnable])) {
				
				if (![patherController isLootBlacklisted:mob]) {
				
					currentDistance = [self myDistanceToMob:mob];
					if (currentDistance <= distance) {
						if ( currentDistance < selectedDistance ) {
							
							selectedDistance = currentDistance;
							self.selectedMob = mob;
						}
					}
				}
			}
		}
		
		// it seems like the MobController data is refreshed every few seconds. It is possible that a valid lootable
		// mob exists, but 
		// attempt to see if a lootable mob was recorded by BotController (and hasn't been updated in movController)
		// TO DO: switch this to a PatherController routine (initiated by Pull Task)
		if (selectedMob == nil) {
			self.selectedMob = [[patherController botController] mobToLoot];
		}
			
	}
	
	return selectedMob;  // the closest mob, or nil

}



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (selectedMob != nil) {
		
		[text appendFormat:@"  lootable mob found: %@",[selectedMob name]];
		
		switch (state){
				
			case LootStateApproaching:
				[text appendFormat:@"  approaching: (%0.2f) / 5.0", [self myDistanceToMob:selectedMob]];
				break;
				
			case LootStateLooting:
				[text appendFormat:@"  looting!"];
				break;
		}
		
	} else {
		[text appendString:@"No mobs of interest"];
	}
	
	return text;
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskLoot alloc] initWithPather:controller] autorelease];
}

@end
