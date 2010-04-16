//
//  MPSpell.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPSpell.h"
#import "Spell.h"
#import "SpellController.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "BotController.h"
#import "AuraController.h"


@implementation MPSpell
@synthesize mySpell, name, listIDs, listBuffIDs, botController;


- (id) init {
	
	if ((self = [super init])) {
		
		self.name = nil;
		self.mySpell = nil;
		spellID = 0;
		self.listIDs = [NSMutableArray array];
		self.listBuffIDs = [NSMutableArray array];
		
		
		self.botController = [[PatherController	sharedPatherController] botController];
	}
	return self;
}


- (void) dealloc
{
	[name release];
    [mySpell release];
	[listIDs release];
	[listBuffIDs release];
	[botController release];

    [super dealloc];
}


#pragma mark -



- (void) addID: (int) anID {

	[self.listIDs addObject:[NSNumber numberWithInt:anID]]; 
}



-(BOOL) cast {
	
	return [botController performAction:spellID];
	
}



- (void) loadPlayerSettings {
	SpellController *spellController = [SpellController sharedSpells];
	
	self.mySpell = [spellController playerSpellForName:name];
	
	
	// if mySpell == nil
	if (mySpell == nil) {
		
		Spell *foundSpell = nil;
		
		PGLog( @" spell[%@] not found by name ... scanning by IDs:", name);
		
		
		// scan by registered ID's
		int rank = 1;
		for( NSNumber *currID in listIDs ) {
			
			PGLog(@"    Rank %d : id[%d] ", rank, [currID intValue]);
			
			for(Spell *spell in  [spellController playerSpells]) {
				
				if ( [currID intValue] == [[spell ID] intValue]) {
					
					// we found this spell
					PGLog( @"       --> Found in player spells ");
					foundSpell = spell;
					break;
				}
			}
			
			rank ++;
			
		}
		
		if (foundSpell) {
			self.mySpell = foundSpell;
			spellID = [[foundSpell ID] intValue];
			
		} else {
		
			PGLog(@"     == Spell[%@] not found ", name);
		}
		
	} else {
		spellID = [[mySpell ID] intValue];
	}
	
	PGLog(@"     == spellID[%d]", spellID);
	// end if
}


#pragma mark -
#pragma mark Aura Checks


- (BOOL) unitHasBuff: (Unit *)unit {
	
	return [[AuraController sharedController] unit:unit hasBuff:spellID];
	
}


- (BOOL) unitHasDebuff: (Unit *)unit {
	
	return [[AuraController sharedController] unit:unit hasDebuff:spellID];
	
}


#pragma mark -



+ (id) spell {
	
	MPSpell *newSpell = [[MPSpell alloc] init];
	return [newSpell autorelease];
}




//
// Druid Spells
//


+ (id) thorns {
	
	MPSpell *newSpell = [MPSpell spell];
	[newSpell setName:@"Thorns"];
	[newSpell addID:  467];  // Rank 1
	[newSpell addID:  782];  // Rank 2
	[newSpell addID: 1075];  // Rank 3
	[newSpell addID: 8914];  // Rank 4
	[newSpell addID: 9756];  // Rank 5
	[newSpell addID: 9910];  // Rank 6
	[newSpell addID:26992];  // Rank 7
	[newSpell addID:53307];  // Rank 8
	[newSpell loadPlayerSettings];
	
	return newSpell;
}


+ (id) wrath {

	MPSpell *newSpell = [MPSpell spell];
	[newSpell setName:@"Wrath"];
	[newSpell addID: 5176];  // Rank 1
	[newSpell addID: 5177];  // Rank 2
	[newSpell addID: 5178];  // Rank 3
	[newSpell addID: 5179];  // Rank 4
	[newSpell addID: 5180];  // Rank 5
	[newSpell addID: 6780];  // Rank 6
	[newSpell addID: 8905];  // Rank 7
	[newSpell addID: 9912];  // Rank 8
	[newSpell addID:26984];  // Rank 9
	[newSpell addID:26985];  // Rank 10
	[newSpell addID:48459];  // Rank 11
	[newSpell addID:48461];  // Rank 12
	[newSpell loadPlayerSettings];
	
	return newSpell;
}


@end
