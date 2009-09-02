//
//  BotController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/14/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define USE_ITEM_MASK       0x80000000
#define USE_MACRO_MASK      0x40000000

@class Mob;
@class Unit;
@class Rule;
@class Behavior;
@class WoWObject;
@class Waypoint;
@class Route;
@class RouteSet;
@class CombatProfile;

@class PTHotKey;
@class SRRecorderControl;
@class BetterSegmentedControl;

@class PlayerDataController;
@class PlayersController;
@class InventoryController;
@class AuraController;
@class NodeController;
@class MovementController;
@class CombatController;
@class SpellController;
@class MobController;
@class ChatController;
@class Controller;
@class WaypointController;
@class ProcedureController;
@class QuestController;
@class CorpseController;
@class LootController;

@class ScanGridView;

#define ErrorSpellNotReady			@"ErrorSpellNotReady"
#define ErrorTargetNotInLOS			@"ErrorTargetNotInLOS"
#define ErrorInvalidTarget			@"ErrorInvalidTarget"
#define ErrorOutOfRange				@"ErrorOutOfRange"

@interface BotController : NSObject {
    IBOutlet Controller             *controller;
    IBOutlet ChatController         *chatController;
    IBOutlet PlayerDataController   *playerController;
    IBOutlet MobController          *mobController;
    IBOutlet SpellController        *spellController;
    IBOutlet CombatController       *combatController;
    IBOutlet MovementController     *movementController;
    IBOutlet NodeController         *nodeController;
    IBOutlet AuraController         *auraController;
    IBOutlet InventoryController    *itemController;
    IBOutlet PlayersController      *playersController;
	IBOutlet LootController			*lootController;

    IBOutlet WaypointController     *waypointController;
    IBOutlet ProcedureController    *procedureController;

	IBOutlet QuestController		*questController;
	
	IBOutlet CorpseController		*corpseController;
	
    IBOutlet NSView *view;
    
    RouteSet *theRoute;
    Behavior *theBehavior;
    CombatProfile *theCombatProfile;
    //BOOL attackPlayers, attackNeutralNPCs, attackHostileNPCs, _ignoreElite;
    //int _currentAttackDistance, _minLevel, _maxLevel, _attackAnyLevel;
    
    int _currentHotkeyModifier, _currentPetAttackHotkeyModifier;
    int _currentHotkey, _currentPetAttackHotkey;
	UInt32 _lastSpellCastGameTime;
    BOOL _doMining, _doHerbalism, _doSkinning, _doLooting;
	BOOL _doCheckForBrokenWeapons, _doLogOutOnFullInv;
    int _miningLevel, _herbLevel, _skinLevel;
    float _gatherDist;
    BOOL _isBotting;
    BOOL _didPreCombatProcedure;
    NSString *_procedureInProgress;
    Mob *_mobToSkin;
    Unit *preCombatUnit;
    NSMutableArray *_mobsToLoot;
    int _reviveAttempt, _skinAttempt;
    NSSize minSectionSize, maxSectionSize;
    NSDate *stopDate;
	NSDate *_botStarted;
	int _lastActionErrorCode;
	UInt32 _lastActionTime;
	
	// healing shit
	BOOL _shouldFollow;
	Unit *_lastUnitAttemptedToHealed;
    
	// improved loot shit
	WoWObject *_unitToLoot;
	UInt32 _lastAttemptedLoot;	// Store the time of our last try!
	
    // pvp shit
    BOOL _isPvPing;
    BOOL _pvpAutoRelease;
    BOOL _pvpPlayWarning, _pvpLeaveInactive;
    int _pvpCheckCount;
    IBOutlet NSButton *pvpStartStopButton;
    IBOutlet NSPanel *pvpBMSelectPanel;
    IBOutlet NSButton *pvpAutoReleaseCheckbox;
    IBOutlet NSImageView *pvpBannerImage;
    IBOutlet NSButton *pvpPlayWarningCheckbox, *pvpLeaveInactiveCheckbox, *pvpWaitForPreparationBuff;
	BOOL _pvpIsInBG;
	NSTimer *_pvpTimer;
	int _pvpMarks;
    
    // -----------------
    // -----------------
    
    IBOutlet NSButton *startStopButton;
    
    IBOutlet id attackWithinText;
    IBOutlet id routePopup;
    IBOutlet id behaviorPopup;
    IBOutlet id combatProfilePopup;
    IBOutlet id minLevelPopup;
    IBOutlet id maxLevelPopup;
    IBOutlet NSTextField *minLevelText, *maxLevelText;
    IBOutlet NSButton *anyLevelCheckbox;
    
    IBOutlet NSButton *miningCheckbox;
	IBOutlet NSButton *brokenWeaponsCheckbox;
	IBOutlet NSButton *fullInventoryCheckbox;
    IBOutlet NSButton *herbalismCheckbox;
    IBOutlet id miningSkillText;
    IBOutlet id herbalismSkillText;
    IBOutlet NSButton *skinningCheckbox;
    IBOutlet id skinningSkillText;
    IBOutlet id gatherDistText;
    IBOutlet NSButton *lootCheckbox;
	IBOutlet NSButton *mountCheckbox;
	IBOutlet NSPopUpButton *mountType;
    
    IBOutlet id atkPlayersCheckbox;
    IBOutlet id atkNeutralNPCsCheckbox;
    IBOutlet id atkHostileNPCsCheckbox;
    IBOutlet id ignoreEliteCheckbox;
    
    IBOutlet NSPanel *hotkeyHelpPanel;
    IBOutlet NSPanel *lootHotkeyHelpPanel;
    IBOutlet SRRecorderControl *shortcutRecorder;
    IBOutlet SRRecorderControl *petAttackRecorder;
    IBOutlet SRRecorderControl *startstopRecorder;
	IBOutlet SRRecorderControl *mouseOverRecorder;
    PTHotKey *StartStopBotGlobalHotkey;
    
    IBOutlet NSTextField *statusText;
	IBOutlet NSTextField *runningTimer;
    IBOutlet NSWindow *overlayWindow;
    IBOutlet ScanGridView *scanGrid;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (assign) BOOL isBotting;
@property (retain) NSString *procedureInProgress;

@property (readonly, retain) RouteSet *theRoute;
@property (readonly, retain) Behavior *theBehavior;
@property (readonly, retain) CombatProfile *theCombatProfile;

- (void)testRule: (Rule*)rule;

// Input from CombatController
- (void)playerEnteringCombat;
- (void)playerLeavingCombat;
- (void)attackUnit: (Unit*)unit;
- (void)addingUnit: (Unit*)unit;
- (void)finishUnit: (Unit*)unit wasInAttackQueue: (BOOL)wasInQueue;

// Input from MovementController;
- (void)reachedUnit: (WoWObject*)unit;
- (BOOL)shouldProceedFromWaypoint: (Waypoint*)waypoint;
- (void)finishedRoute: (Route*)route;
- (BOOL)evaluateSituation;

- (IBAction)startBot: (id)sender;
- (IBAction)stopBot: (id)sender;
- (IBAction)startStopBot: (id)sender;
- (IBAction)testHotkey: (id)sender;

- (void)updateRunningTimer;

- (IBAction)editCombatProfiles: (id)sender;
- (IBAction)updateStatus: (id)sender;
- (IBAction)hotkeyHelp: (id)sender;
- (IBAction)closeHotkeyHelp: (id)sender;
- (IBAction)lootHotkeyHelp: (id)sender;
- (IBAction)closeLootHotkeyHelp: (id)sender;

// PvP shit
- (IBAction)pvpStartStop: (id)sender;
- (IBAction)pvpBMSelectAction: (id)sender;
- (IBAction)pvpTestWarning: (id)sender;

// Little more flexibility - casts spells! Uses items/macros!
- (BOOL)performAction: (int32_t)actionID;
- (int)errorValue: (NSString*)errorMessage;
- (BOOL)interactWithMouseoverGUID: (UInt64) guid;
- (void)interactWithMob:(UInt32)entryID;
- (NSArray*)availableUnitsToHeal;

- (void) updateRunningTimer;

@end
