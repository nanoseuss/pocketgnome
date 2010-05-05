//
//  MPPullTask.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskFollow.h"

#import "BlacklistController.h"
#import "BotController.h"
#import "CombatController.h"
#import "CombatProfile.h"
#import "Controller.h"
#import "Mob.h"
#import "MobController.h"
#import "MPActivityFollow.h"
#import "MPCustomClass.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "MPValue.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "PlayersController.h"
#import "Player.h"
#import "Unit.h"






@interface MPTaskFollow (Internal)


/*!
 * @function unitToFollow
 * @abstract Returns closest valid unit to follow.
 * @discussion
 */
- (Unit *) unitToFollow;


/*!
 * @function clearActivityFollow
 * @abstract Properly shuts down the Follow Activity.
 * @discussion
 */
- (void) clearActivityFollow;


@end


@implementation MPTaskFollow

// Synthesize variables here:
@synthesize activityFollow, listNames, unitToFollow;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		
		name = @"Follow";
		
		approachTo = 10.0f;
		maxDistance = 15.0f;
		shouldMount = YES;
		
		self.activityFollow = nil;
		self.listNames = nil;
		self.unitToFollow = nil;
		
	}
	return self;
}

- (void) setup {
	
	self.listNames = [self arrayStringsFromVariable:@"names" ];
	approachTo = [[self stringFromVariable:@"approachto" orReturnDefault:@"10.0"] floatValue];
	maxDistance = [[self stringFromVariable:@"maxdistance" orReturnDefault:@"15.0"] floatValue];
	shouldMount = [self boolFromVariable:@"shouldmount" orReturnDefault:YES];
}



- (void) dealloc
{
    [activityFollow release];
    [listNames release];
	[unitToFollow release];
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	return NO;
}



- (MPLocation *) location {
	
	Unit *target = [self unitToFollow];
	
	if ( target == nil) 
		return nil;
	
	return (MPLocation *)[target position];
}



- (void) restart {
	
}



- (BOOL) wantToDoSomething {

	// if we found a unit to follow then we want to do something.
	return ([self unitToFollow] != nil);
}



- (MPActivity *) activity {
	
	Unit *followTarget = [self unitToFollow];
	
	
	if ( activityFollow != nil) {
		// if activity following different unit
		//if (followTarget != [activityFollow followUnit]) {
		if (![followTarget isEqualToObject:[activityFollow followUnit]]) {
			
			PGLog(@"Clearing activityFollow");
			
			// clear follow activity
			[self clearActivityFollow];
		}
	}
	
	
	// if follow activity not created then
	if (activityFollow == nil) {
		
		// create follow activity
		self.activityFollow = [MPActivityFollow follow:followTarget howClose:approachTo howFar:maxDistance shouldMount:shouldMount forTask:self];
	}
	
	
	return (MPActivity *)activityFollow;
	
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	// that activity is done so release it 
	if (activity == activityFollow) {
		[self clearActivityFollow];
	}
	
	
	return YES; // ??
}


#pragma mark -
#pragma mark Helper Functions



- (void) clearBestTask {
	
	// if we have a unit that isn't valid anymore, then clear it's reference.
	if (unitToFollow != nil) {
		
		if (![unitToFollow isValid]) {
			self.unitToFollow = nil;
		}
	}
 
}



- (Unit *) unitToFollow {
	
	if (unitToFollow == nil) {
		
		// if name is given
		if ((listNames != nil) && ([listNames count] > 0)) {
			
			NSString *unitName = nil;
			
			[[Controller sharedController] traverseNameList];
			//PGLog(@"  Total Names [%d]", [[PlayersController sharedPlayers] totalNames] );
			
			// for All units nearby
			NSArray *allMobs = [[MobController sharedController] allMobs];
			NSArray *allPlayers = [[PlayersController sharedPlayers] friendlyPlayers];
			
			//PGLog(@"  allMobs count[%d]", [allMobs count]);
			//PGLog(@"  allPlayers count[%d]", [allPlayers count]);
			
			NSMutableArray *allUnits = [NSMutableArray arrayWithArray:allPlayers];
			[allUnits addObjectsFromArray:allMobs];
			
			//PGLog(@"  allUnits count[%d]", [allUnits count]);
			for( Mob *mob in allUnits) {
				
				if ([mob isPlayer]) {
					
					unitName = [[PlayersController sharedPlayers] playerNameWithGUID:[mob GUID]];
					//PGLog(@" player[%@]", unitName);
				} else {
					unitName = [mob name];
					//PGLog(@" mob[%@]", [mob name]);
				}
				
			
				// for each name given
				for( NSString *givenName in listNames) {
					
					PGLog (@"comparing [%@] == [%@]", givenName, unitName);
					// if unit.name == given.name
					if ([givenName isEqualToString:unitName]) {
						
						PGLog( @"    Found Follow Unit[%@]", unitName);
						
						// unitToFollow = unit;
						self.unitToFollow = (Unit *) mob;
						
						return unitToFollow;
						
					} // end if
				} // next name
			} // next unit nearby
			
		} else {
			
			NSArray *listParty = [[PlayerDataController sharedController] partyMembers];
			if ([listParty count] > 0) {
				
				for( Player *player in listParty) {
					if ([player isValid]) {
					
						if (unitToFollow == nil) {
							self.unitToFollow = player;
						} else {
							
							// if unitToFollow isn't a standard tank class
							UnitClass uclass = [unitToFollow unitClass];
							if ((uclass != UnitClass_Warrior) && 
								(uclass != UnitClass_Paladin) &&
								(uclass != UnitClass_Druid)) {
								self.unitToFollow = player;
							}
						}
					}
				}	
				
			} else {
				PGLog(@" No follow name given, && no party members ... I don't know what to do!");
			}
			
		} // end if names given
		
	} // end if unitToFollow == nil
	
	return unitToFollow;  // the closest unit, or nil
	
}








- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (unitToFollow != nil) {
		if ([unitToFollow isValid]) {
		
			NSString *unitName;
			if ([unitToFollow isPlayer]) {
				unitName = [[PlayersController sharedPlayers] playerNameWithGUID:[unitToFollow GUID]];
			} else {
				unitName = [unitToFollow name];
			}
			
			[text appendFormat:@"  following: %@\n",unitName];
			
			[text appendFormat:@"    (%0.2f) / (%0.2f) / (%0.2f)", approachTo, [self myDistanceToMob:(Mob *)unitToFollow],maxDistance];
			
		}
		
	} else {
		[text appendFormat:@"   searching for [%@]",listNames];
	}
	
	return text;
}




- (void) clearActivityFollow {
	[activityFollow stop];
	[activityFollow autorelease];
	self.activityFollow = nil;
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskFollow alloc] initWithPather:controller] autorelease];
}

@end
