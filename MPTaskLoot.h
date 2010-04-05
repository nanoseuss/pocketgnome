//
//  MPTaskLoot.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"
@class MPValue;
@class MPActivityApproach;
@class MPActivityLoot;

@class Mob;


typedef enum LootState { 
    LootStateApproaching   = 1, 
    LootStateLooting = 2
} MPLootState; 


/*!
 * @class      MPTaskLoot
 * @abstract   Loot nearby corpses
 * @discussion 
 * (from http://wiki.ppather.net)
 * Loots dead monsters, without this PPather will not loot anything. Will skin monsters if 
 * they are skinnable and $Skin is set to true. $Distance controls how far the toon will 
 * run from current position to loot or skin corpses, defaults to 30.
 *
 * Example
 * <code>
 *	Loot
 *	{
 *	    $Skin = true; // Allow skinning of mobs. Set to "false" to skip skinning
 *	    $Distance = 50; // Go this far to loot and skin mobs
 *	}
 * </code>
 *		
 */
@interface MPTaskLoot : MPTask {
	BOOL skin;
	float distance;
	
	Mob *selectedMob;
	
	MPActivityApproach *approachActivity;
	MPActivityLoot *lootActivity;
	
	MPLootState state;
}
@property (readwrite) float distance;
@property (retain) Mob *selectedMob;
@property (retain) MPActivityApproach *approachActivity;
@property (retain) MPActivityLoot *lootActivity;


#pragma mark -
#pragma mark Helper Functions




#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
