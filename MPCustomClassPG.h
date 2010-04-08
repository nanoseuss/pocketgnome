//
//  MPCustomClassPG.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCustomClass.h"

@class MPTimer;
@class Mob;
@class CombatController;
@class BotController;


typedef enum CCCombatState { 
    CCCombatPreCombat	= 1,	// performing initial prep
	CCCombatCombat	= 2		// get em!
} MPCCCombatState; 


@interface MPCustomClassPG : MPCustomClass {
	BOOL sentPreCombat, sentRegen, isMobDead, establishedPosition;
	MPTimer *timerControllerStartup; // give things a few sec to register in combat
	MPTimer *timerMobDied; // give a few sec for CombatController to register dead mob
	MPTimer *timerEstablishPosition; // give a few sec after engaging to call an establish Position
	CombatController *combatController;
	BotController *botController;
	MPCCCombatState state;
}
@property (retain) MPTimer *timerControllerStartup;
@property (retain) MPTimer *timerMobDied, *timerEstablishPosition;
@property (retain) CombatController *combatController;
@property (retain) BotController *botController;

@end
