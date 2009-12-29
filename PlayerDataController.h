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
@class WoWObject;
@class MemoryAccess;

@class MobController;
@class CombatController;
@class Controller;
@class BotController;
@class SpellController;
@class MemoryViewController;
@class NodeController;
@class OffsetController;
@class MovementController;
@class MobController;

#define PlayerIsValidNotification           @"PlayerIsValidNotification"
#define PlayerIsInvalidNotification         @"PlayerIsInvalidNotification"

#define PlayerHasDiedNotification           @"PlayerHasDiedNotification"
#define PlayerHasRevivedNotification        @"PlayerHasRevivedNotification"
#define PlayerChangedTargetNotification     @"PlayerChangedTargetNotification"

#define PlayerEnteringCombatNotification    @"PlayerEnteringCombatNotification"
#define PlayerLeavingCombatNotification     @"PlayerLeavingCombatNotification"

#define ZoneStrandOfTheAncients		4384

#define BGNone			0
#define BGQueued		1
#define BGWaiting		2
#define BGActive		3

@interface PlayerDataController : NSObject <UnitPosition> {
    IBOutlet Controller				*controller;
    IBOutlet BotController			*botController;
    IBOutlet SpellController		*spellController;
    IBOutlet CombatController		*combatController;
    IBOutlet MemoryViewController	*memoryViewController;
	IBOutlet NodeController			*nodeController;
	IBOutlet OffsetController		*offsetController;
	IBOutlet MovementController		*movementController;
	IBOutlet MobController			*mobController;
	
    IBOutlet NSView *view;
    IBOutlet NSTextField *powerNameText;
	IBOutlet NSTableView *combatTable;
	IBOutlet NSTableView *healingTable;
    // IBOutlet NSTextField *stanceText; // 3.0.8 removed

    NSNumber *_baselineAddress;
    NSNumber *_playerAddress;
    BOOL _validState, _lastState;
	
	NSMutableArray *_combatDataList;
    NSMutableArray *_healingDataList;
	
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
@property (readonly) NSString *lastErrorMessage;

- (BOOL)playerIsValid;
- (BOOL)playerIsValid: (id)sender;
- (void)setStructureAddress: (NSNumber*)address;
- (NSNumber*)structureAddress;
- (UInt32)baselineAddress;
- (UInt32)infoAddress;

- (Player*)player;
- (UInt64)GUID;
- (UInt32)lowGUID;

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

- (Position*)corpsePosition;
- (Position*)position;
- (Position*)deathPosition;
- (float)directionFacing;
- (void)setDirectionFacing: (float)direction;
- (void)setMovementFlags:(UInt32)movementFlags;
- (UInt32)movementFlags;
- (UInt64)movementFlags64;
- (void)faceToward: (Position*)position;
- (float)speed;
- (float)speedMax;
- (float)maxGroundSpeed;
- (float)maxAirSpeed;
- (UInt32)copper;
- (UInt32)honor;
- (void)trackResources: (int)resource;

- (BOOL)setPrimaryTarget: (WoWObject*)target;
- (BOOL)setMouseoverTarget: (UInt64)targetID;
- (UInt64)targetID;
- (UInt64)mouseoverID;
- (UInt64)interactGUID;
- (UInt64)focusGUID;
- (UInt64)comboPointUID;

- (BOOL)isInCombat;
- (BOOL)isLooting;
- (BOOL)isCasting;
- (BOOL)isSitting;
- (BOOL)isHostileWithFaction: (UInt32)faction;
- (BOOL)isFriendlyWithFaction: (UInt32)faction;

- (BOOL)isIndoors;
- (BOOL)isOutdoors;

- (BOOL)isOnGround;

- (UInt32)spellCasting;
- (float)castTime;
- (float)castTimeRemaining;
- (UInt32)currentTime;

- (UInt32)factionTemplate;

- (int)haste;
//- (int)GCD;	// returned in milliseconds

- (IBAction)setPlayerDirectionInMemory: (id)sender;
- (IBAction)showPlayerStructure: (id)sender;
- (IBAction)showAuraWindow: (id)sender;
- (IBAction)showCooldownWindow: (id)sender;
- (IBAction)showCombatWindow: (id)sender;

- (void)refreshPlayerData;

- (int)battlegroundStatus;
- (UInt32)zone;
- (BOOL)isInBG:(int)zone;
- (BOOL)isOnBoatInStrand;
- (BOOL)isOnLeftBoatInStrand;
- (BOOL)isOnRightBoatInStrand;

@end
