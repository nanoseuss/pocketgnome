//
//  MPTaskPull.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"
@class MPValue;
@class MPActivityApproach;
@class MPActivityAttack;
@class MPActivityWait;
@class MPTaskController;
@class MobController;
@class PlayerDataController;
@class MPCustomClass;
@class Mob;
@class MPTimer;


typedef enum PullState { 
    PullStateSearching   = 1, 
    PullStateApproaching = 2, 
    PullStateAttacking	 = 3,
	PullStateWrapup		 = 4
} MPPullState; 


/*!
 * @class      MPTaskPull
 * @abstract   Move towards nearby specified mobs and pull them.
 * @discussion 
 * (from http://wiki.ppather.net)
 * The Pull task has a couple of parameters. The first is the $Names. Here you can define the names 
 * of specific mobs you want to pull. The $Names is not a required parameter, you could just use factions.
 * 
 * $Factions is the factionid of the mobs you want to pull. If you have both $Names AND $Factions, then the 
 * mob must meet both criteria in order to be pulled. 
 *
 * $Ignore is a list of mobs to not pull (for example rare/elite). 
 *
 * $MinLevel and $MaxLevel are the levels of mobs that it should pull. In the example, it is based on $MyLevel 
 * so that they scale as you level up. If you are level 30, it will only pull mobs between levels 27 and 30. 
 * But if you level up and become 31, it will now pull mobs between the levels of 28 and 31. 
 *
 * $Distance is the distance from your character that PPather should look for mobs that match your criteria.
 *
 * 
 * The adds variables are there so you can keep yourself safe from pulling a monster with other mobs around it. 
 * Custom Classes often take care of this, however if they don't, PPather can. 
 *
 * If you set $SkipMobsWithAdds, it will look for $AddsDistance and $AddsCount. $AddsDistance and $AddsCount 
 * pretty much say, if there is $AddsCount number of mobs within $AddsDistance of the current target, don't 
 * pull it. If you define $SkipMobsWithAdds = true; but don't define $AddsDistance and $AddsCount, $AddsDistance 
 * defaults to 15, and $AddsCount defaults to 2.
 * <code>
 *	 Pull
 *	 {
 *		$Prio = 3;
 *		$Names = ["mob1","mob2"];
 *		$Ignore = ["this_mob"];
 *		$Factions = [7, 49, 256];
 *		$MinLevel = $MyLevel-3;
 *		$MaxLevel = $MyLevel;
 *		$Distance = 30;
 *		// The following parameters are rarely used:
 *		$SkipMobsWithAdds = true;
 *		$AddsDistance = 15;
 *		$AddsCount = 3;
 *	 }
 * </code>
 *		
 */
@interface MPTaskPull : MPTask {
	NSArray *names, *ignoreNames, *factions;
	MPValue *minLevel, *maxLevel;
	float mobDistance, attackDistance;
	
	BOOL skipMobsWithAdds;
	NSInteger addDistance, addCount;
	
	
	MPActivityApproach *approachActivity;
	MPActivityAttack *attackActivity;
	MPActivityWait *waitActivity;
	
	MobController *mobController;
	PlayerDataController *playerData;
	MPCustomClass *customClass;
	
	MPTaskController *taskController;
	
	Mob* selectedMob;
	
	MPTimer *timerWrapup;
	
	MPPullState state;
}

@property (readwrite,retain) NSArray *names, *ignoreNames, *factions;
@property (readwrite,retain) MPValue *minLevel, *maxLevel;
@property (readwrite) float mobDistance, attackDistance;
@property (retain) MPActivityApproach *approachActivity;
@property (retain) MPActivityAttack *attackActivity;
@property (retain) MPActivityWait *waitActivity;
@property (retain) MobController *mobController;
@property (retain) PlayerDataController *playerData;
@property (retain) MPCustomClass *customClass;
@property (retain) MPTaskController *taskController;
@property (retain) Mob *selectedMob;
@property (retain) MPTimer *timerWrapup;

#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
