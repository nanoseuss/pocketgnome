//
//  MPTaskAssist.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/21/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPTaskAssist.h"
#import "MPTaskPull.h"
#import "MPTask.h"
#import "MPValue.h"

#import "Controller.h"
#import "MobController.h"
#import "MPTimer.h"
#import "PlayersController.h"
#import "PlayerDataController.h"
#import "Unit.h"



@interface MPTaskPull (Internal)
- (void) scanAssistUnits;
@end


@implementation MPTaskAssist
@synthesize assistNames, assistUnits, timerUpdateList;


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Assist";
		
		self.assistNames = nil;
		self.assistUnits = nil;
		
		self.timerUpdateList = [MPTimer timer:60000];  // 1 min interval
		[timerUpdateList forceReady];
		
	}
	return self;
}



- (void) setup {
	
	self.assistNames = [self arrayStringsFromVariable:@"names" ];
	
}




- (void) dealloc
{
    [assistNames release];
	[assistUnits release];
	[timerUpdateList release];
	
    [super dealloc];
}


#pragma mark -




- (BOOL) wantToDoSomething {

	//// check to see if we have our list of Assist units properly setup
	
	// if timerUpdateAssistUnits ready
	if([timerUpdateList ready] ) {
		
		// if we haven't found all our assistNames as units
		if ([assistUnits count] != [assistNames count]) {
			
			// scan for units and add to listAssistUnits
			[self scanAssistUnits];
			
		} // end if
		
		// restart timer
		[timerUpdateList start];
		
	} // end if
	
	return [super wantToDoSomething];
}




- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
PGLog(@"description...");
	
	[text appendFormat:@"Assist\n"];
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


#pragma mark -
#pragma mark Helper Functions

-(void) scanAssistUnits {
	
	// if names have been given
	if ((assistNames != nil) && ([assistNames count] > 0)) {
		PGLog(@"Scanning Assist Units ... ");
	
		// build list of all units nearby: NPC and players
		NSString *unitName = nil;
		NSMutableArray *tempUnits = [NSMutableArray array];
		
		[[Controller sharedController] traverseNameList];
		
		NSArray *allMobs = [[MobController sharedController] allMobs];
		NSArray *allPlayers = [[PlayersController sharedPlayers] friendlyPlayers];
		NSMutableArray *allUnits = [NSMutableArray arrayWithArray:allPlayers];
		[allUnits addObjectsFromArray:allMobs];
		
		// for each unit
		for( Mob *mob in allUnits) {
			// get name
	
			if ([mob isPlayer]) {
				unitName = [[PlayersController sharedPlayers] playerNameWithGUID:[mob GUID]];
			} else {
				unitName = [mob name];
			}
			
			// for each assist name
			for( NSString *guyName in assistNames) {
				
				// if assist.name == unitName
				if ([guyName isEqualToString:unitName]) {
					// ad unit to listAssistUnits
					[tempUnits addObject:mob];
					PGLog(@"ScanningAssistUnits: added [%@]", unitName);
					
				} // end if
			} // next
		} // next unit
		
		if ([tempUnits count] > 0) {
			self.assistUnits = nil;
			self.assistUnits = [tempUnits copy];
		}
	
	} else { 
		
		NSArray *listParty = [[PlayerDataController sharedController] partyMembers];
		if ([listParty count] > 0) {
			PGLog(@"No Assist Names Give.  But I'm in a party.  I'll just help them all out.");
		} else {
		
			PGLog( @"No Assist Names Given!  Don't know who to assist!");
		}
	} 
}


- (Mob *) mobToPull {
	
	GUID targetID = 0;
	
	if (selectedMob == nil) {
		
		if ( assistUnits != nil) {
			
			//// always scan our Assist list and choose the 1st target.  This way if our MT 
			//// changes target then so will we.
			
			// foreach listAssistUnits as guy
			for( Unit *guy in assistUnits) {
				
				if ([guy isValid]) {
					
					// if guy in combat
					if ([guy isInCombat]) {
//PGLog(@" Assist: mobToPull: assistUnit[%@] is in combat", [guy name]);
						// if guy has a target
						targetID = [guy targetID];
						if (targetID != 0) {
							// selectedMob = guy.target
							self.selectedMob = [[MobController sharedController] mobWithGUID: targetID];
							break;
						} // end if
					} // end if
				}
			} // next
			
		} else {
			
			
			//// no assist Names were given, so try to scan through Party and 
			//// return any mobs being attacked there:
			NSArray *listParty = [[PlayerDataController sharedController] partyMembers];
			if ([listParty count] > 0) {
				
				for(Player* player in listParty) {
					if ([player isValid]) {
						if([player isInCombat]) {
							targetID = [player targetID];
							if (targetID != 0) {
								self.selectedMob = [[MobController sharedController] mobWithGUID: targetID];
								break;
							}
						}
					}
				}
			}
		
			
		} // end if assistUnits != nil
		
	} // end if selectedMob == nil
	
	return selectedMob;  // the closest mob, or nil
	
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskAssist alloc] initWithPather:controller] autorelease];
}

@end
