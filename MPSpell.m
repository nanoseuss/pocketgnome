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
#import "Aura.h"
#import "AuraController.h"


@implementation MPSpell
@synthesize mySpell, name, listIDs, listBuffIDs, botController, spellController;


- (id) init {
	
	if ((self = [super init])) {
		
		self.name = nil;
		self.mySpell = nil;
		spellID = 0;
		currentRank = 0;
		self.listIDs = [NSMutableArray array];
		self.listBuffIDs = [NSMutableArray array];
		
		
		self.botController = [[PatherController	sharedPatherController] botController];
		self.spellController = [SpellController sharedSpells];
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
	[spellController release];

    [super dealloc];
}


#pragma mark -



- (void) addID: (int) anID {

	[self.listIDs addObject:[NSNumber numberWithInt:anID]]; 
}



-(BOOL) canCast {

	if (mySpell == nil) {
		return NO;
	}
	
	
	return YES;
}


-(BOOL) cast {
	
	return [botController performAction:spellID];
	
}



- (void) scanForSpell {
	
	Spell *foundSpell = nil;
	
	
	// scan by registered ID's
	int rank = 1;
	int foundRank = 0;
	for( NSNumber *currID in listIDs ) {
		
		PGLog(@"    Rank %d : id[%d] ", rank, [currID intValue]);
		
		for(Spell *spell in  [spellController playerSpells]) {
			
			if ( [currID intValue] == [[spell ID] intValue]) {
				
				// we found this spell
				PGLog( @"       --> Found in player spells ");
				foundSpell = spell;
				foundRank = rank;
				break;
			}
		}
		
		rank ++;
		
	}
	
	
	if (foundSpell) {
		
		if (foundRank != currentRank) {
			PGLog(@"   UPDATED Spell:  %@ Rank %d", name, foundRank);
		}
		
		self.mySpell = foundSpell;
		spellID = [[foundSpell ID] intValue];
		currentRank = foundRank;
		
	} else {
		
		PGLog(@"     == Spell[%@] not found after scanning", name);
	}
	
	
}


- (void) loadPlayerSettings {
	
	self.mySpell = [spellController playerSpellForName:name];
	
	
	// if mySpell == nil
	if (mySpell == nil) {
		
		
		PGLog( @" spell[%@] not found by name ... scanning by IDs:", name);
		[self scanForSpell];
		
	} else {
		
		spellID = [[mySpell ID] intValue];
		currentRank = 0;
		int rank = 1;
		for( NSNumber *currID in listIDs ) {
			
			if ( [currID intValue] == spellID) {
				currentRank = rank;
				break;
			}
		}
	}
	
	PGLog(@"     == spellID[%@] id[%d] rank[%d]",name,  spellID, currentRank);
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


- (BOOL) unitHasMyBuff: (Unit *)unit {

	GUID myGUID = [[PlayerDataController sharedController] GUID];
	
	for(Aura *aura in [[AuraController sharedController] aurasForUnit: unit idsOnly: NO]) {
        if((aura.entryID == spellID) && (!aura.isDebuff) && (aura.guid = myGUID))
            return aura.stacks ? aura.stacks : YES;
    }
	return NO;
	
}



- (BOOL) unitHasMyDebuff: (Unit *)unit {
	
	GUID myGUID = [[PlayerDataController sharedController] GUID];
	
	for(Aura *aura in [[AuraController sharedController] aurasForUnit: unit idsOnly: NO]) {
        if((aura.entryID == spellID) && (aura.isDebuff) && (aura.guid = myGUID))
            return aura.stacks ? aura.stacks : YES;
    }
	return NO;
	
}


#pragma mark -



+ (id) spell {
	
	MPSpell *newSpell = [[MPSpell alloc] init];
	return [newSpell autorelease];
}




////
//// Druid Spells
////



+ (id) healingTouch {
	
	MPSpell *newSpell = [MPSpell spell];
	[newSpell setName:@"Healing Touch"];
	[newSpell addID:  5185];  // Rank 1
	[newSpell addID:  5186];  // Rank 2
	[newSpell addID:  5187];  // Rank 3
	[newSpell addID:  5188];  // Rank 4
	[newSpell addID:  5189];  // Rank 5
	[newSpell addID:  6778];  // Rank 6
	[newSpell addID:  8903];  // Rank 7
	[newSpell addID:  9758];  // Rank 8
	[newSpell addID:  9888];  // Rank 9
	[newSpell addID:  9889];  // Rank 10
	[newSpell addID: 25297];  // Rank 11
	[newSpell addID: 26978];  // Rank 12
	[newSpell addID: 26979];  // Rank 13
	[newSpell addID: 48377];  // Rank 14
	[newSpell addID: 48378];  // Rank 15
	[newSpell loadPlayerSettings];
	
	return newSpell;
}



+ (id) moonfire {
	
	MPSpell *newSpell = [MPSpell spell];
	[newSpell setName:@"Moonfire"];
	[newSpell addID:  8921];  // Rank 1
	[newSpell addID:  8924];  // Rank 2
	[newSpell addID:  8925];  // Rank 3
	[newSpell addID:  8926];  // Rank 4
	[newSpell addID:  8927];  // Rank 5
	[newSpell addID:  8928];  // Rank 6
	[newSpell addID:  8929];  // Rank 7
	[newSpell addID:  9833];  // Rank 8
	[newSpell addID:  9834];  // Rank 9
	[newSpell addID:  9835];  // Rank 10
	[newSpell addID: 26987];  // Rank 11
	[newSpell addID: 26988];  // Rank 12
	[newSpell addID: 48462];  // Rank 13
	[newSpell addID: 48463];  // Rank 14
	[newSpell loadPlayerSettings];
	
	return newSpell;
}



+ (id) motw {
	
	MPSpell *newSpell = [MPSpell spell];
	[newSpell setName:@"Mark of the Wild"];
	[newSpell addID: 1126];  // Rank 1
	[newSpell addID: 5232];  // Rank 2
	[newSpell addID: 6756];  // Rank 3
	[newSpell addID: 5234];  // Rank 4 (not a typo)
	[newSpell addID: 8907];  // Rank 5
	[newSpell addID: 9884];  // Rank 6
	[newSpell addID: 9885];  // Rank 7
	[newSpell addID:26990];  // Rank 8
	[newSpell addID:48469];  // Rank 9
	[newSpell loadPlayerSettings];
	
	return newSpell;
}



+ (id) rejuvenation {
	
	MPSpell *newSpell = [MPSpell spell];
	[newSpell setName:@"Rejuvenation"];
	[newSpell addID:  774];  // Rank 1
	[newSpell addID: 1058];  // Rank 2
	[newSpell addID: 1430];  // Rank 3
	[newSpell addID: 2090];  // Rank 4
	[newSpell addID: 2091];  // Rank 5
	[newSpell addID: 3627];  // Rank 6
	[newSpell addID: 8910];  // Rank 7
	[newSpell addID: 9839];  // Rank 8
	[newSpell addID: 9840];  // Rank 9
	[newSpell addID: 9841];  // Rank 10
	[newSpell addID:25299];  // Rank 11
	[newSpell addID:26981];  // Rank 12
	[newSpell addID:26982];  // Rank 13
	[newSpell addID:48440];  // Rank 14
	[newSpell addID:48441];  // Rank 15
	[newSpell loadPlayerSettings];
	
	return newSpell;
}



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
