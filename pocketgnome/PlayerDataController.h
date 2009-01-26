//
//  PlayerDataController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/15/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Position.h"

@class Unit;
@class Player;
@class Position;
@class MemoryAccess;
@class MobController;
@class CombatController;

#define PlayerIsValidNotification           @"PlayerIsValidNotification"
#define PlayerIsInvalidNotification         @"PlayerIsInvalidNotification"

#define PlayerHasDiedNotification           @"PlayerHasDiedNotification"
#define PlayerHasRevivedNotification        @"PlayerHasRevivedNotification"
#define PlayerChangedTargetNotification     @"PlayerChangedTargetNotification"

//#define PlayerEnteringCombatNotification    @"PlayerEnteringCombatNotification"
//#define PlayerLeavingCombatNotification     @"PlayerLeavingCombatNotification"

@interface PlayerDataController : NSObject <UnitPosition> {
    id controller;
    id botController;
    id spellController;
    id combatController;
    id memoryViewController;
    IBOutlet NSView *view;
    IBOutlet NSTextField *powerNameText;
    // IBOutlet NSTextField *stanceText; // 3.0.8 removed

    NSNumber *_baselineAddress;
    NSNumber *_playerAddress;
    BOOL _validState, _lastState;
    
    Unit *_pet;
    unsigned _playerHealth, _playerMaxHealth;
    unsigned _playerMana, _playerMaxMana;
    float _xPosition, _yPosition, _zPosition;
    float _playerDirection, _playerSpeed;
    float _playerSpeedMin, _playerSpeedMax;
    float _updateFrequency;
    int savedLevel;
    Position *_deathPosition;
    NSSize minSectionSize, maxSectionSize;
    
    BOOL _lastCombatState, _wasDead;
    GUID _lastTargetID;
}

+ (PlayerDataController *)sharedController;

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property float updateFrequency;
@property (readonly) NSString *playerHeader;

@property (readonly) NSString *playerName;
@property (readonly) NSString *accountName;
@property (readonly) NSString *serverName;

- (BOOL)playerIsValid;
- (void)setStructureAddress: (NSNumber*)address;
- (NSNumber*)structureAddress;
- (UInt32)baselineAddress;
- (UInt32)infoAddress;

- (Player*)player;
- (UInt64)GUID;

- (BOOL)isDead;
- (BOOL)isGhost;
- (UInt32)level;
- (UInt32)health;
- (UInt32)maxHealth;
- (UInt32)mana;
- (UInt32)maxMana;
- (UInt32)percentHealth;
- (UInt32)percentMana;
- (UInt32)comboPoints;

@property (readwrite, retain) Unit *pet;

- (Position*)position;
- (Position*)deathPosition;
- (float)directionFacing;
- (void)setDirectionFacing: (float)direction;
- (UInt32)movementFlags;
- (void)faceToward: (Position*)position;
- (float)speed;
- (float)speedMax;
- (float)maxGroundSpeed;
- (float)maxAirSpeed;

- (BOOL)setPrimaryTarget: (UInt64)targetID;
- (BOOL)setMouseoverTarget: (UInt64)targetID;
- (UInt64)targetID;
- (UInt64)mouseoverID;
- (UInt64)interactGUID;
- (UInt64)comboPointUID;

- (BOOL)isInCombat;
- (BOOL)isLooting;
- (BOOL)isCasting;
- (BOOL)isSitting;
- (BOOL)isHostileWithFaction: (UInt32)faction;
- (BOOL)isFriendlyWithFaction: (UInt32)faction;

- (BOOL)isIndoors;
- (BOOL)isOutdoors;

- (UInt32)spellCasting;
- (float)castTime;
- (float)castTimeRemaining;
- (UInt32)currentTime;

- (IBAction)setPlayerDirectionInMemory: (id)sender;
- (IBAction)showPlayerStructure: (id)sender;
- (IBAction)showAuraWindow: (id)sender;

- (void)refreshPlayerData;


@end
