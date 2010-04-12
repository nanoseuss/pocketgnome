//
//  BotController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/14/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Mob;
@class Unit;
@class Rule;
@class Behavior;
@class WoWObject;
@class Waypoint;
@class Route;
@class RouteSet;
@class RouteCollection;
@class CombatProfile;
@class PvPBehavior;
@class Position;

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
@class ChatLogController;
@class Controller;
@class WaypointController;
@class ProcedureController;
@class QuestController;
@class CorpseController;
@class LootController;
@class FishController;
@class MacroController;
@class OffsetController;
@class MemoryViewController;
@class CombatProfileEditor;
@class BlacklistController;
@class StatisticsController;
@class BindingsController;
@class PvPController;

@class ScanGridView;

#define ErrorSpellNotReady				@"ErrorSpellNotReady"
#define ErrorTargetNotInLOS				@"ErrorTargetNotInLOS"
#define ErrorInvalidTarget				@"ErrorInvalidTarget"
#define ErrorTargetOutOfRange			@"ErrorTargetOutOfRange"
#define ErrorTargetNotInFront			@"ErrorTargetNotInFront"
#define ErrorMorePowerfullSpellActive	@"ErrorMorePowerfullSpellActive"

#define BotStarted						@"BotStarted"

// Hotkey set flags
#define	HotKeyStartStop				0x1
#define HotKeyInteractMouseover		0x2
#define HotKeyPrimary				0x4
#define HotKeyPetAttack				0x8

@interface BotController : NSObject {
    IBOutlet Controller             *controller;
    IBOutlet ChatController         *chatController;
	IBOutlet ChatLogController		*chatLogController;
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
	IBOutlet FishController			*fishController;
	IBOutlet MacroController		*macroController;
	IBOutlet OffsetController		*offsetController;
    IBOutlet WaypointController     *waypointController;
    IBOutlet ProcedureController    *procedureController;
	IBOutlet MemoryViewController	*memoryViewController;
	IBOutlet CombatProfileEditor	*combatProfileEditor;
	IBOutlet BlacklistController	*blacklistController;
	IBOutlet StatisticsController	*statisticsController;
	IBOutlet BindingsController		*bindingsController;
	IBOutlet PvPController			*pvpController;


	IBOutlet QuestController		*questController;
	IBOutlet CorpseController		*corpseController;

	IBOutlet Route					*Route;	// is this right?

    IBOutlet NSView *view;
    
	RouteCollection *_theRouteCollection;
    RouteSet *theRouteSet;
    Behavior *theBehavior;
    CombatProfile *theCombatProfile;
	PvPBehavior *_pvpBehavior;
    //BOOL attackPlayers, attackNeutralNPCs, attackHostileNPCs, _ignoreElite;
    //int _currentAttackDistance, _minLevel, _maxLevel, _attackAnyLevel;
    
	UInt32 _lastSpellCastGameTime;
	UInt32 _lastSpellCast;
    BOOL _doMining, _doHerbalism, _doSkinning, _doNinjaSkin, _doLooting, _doNetherwingEgg, _doFishing;
    int _miningLevel, _herbLevel, _skinLevel;
    float _gatherDist;
    BOOL _isBotting;
    BOOL _didPreCombatProcedure;
    NSString *_procedureInProgress;
	NSString *_evaluationInProgress;
	
	NSString *_lastProcedureExecuted;
    Mob *_mobToSkin;
    Unit *preCombatUnit;
	Unit *castingUnit;		// the unit we're casting on!

    NSMutableArray *_mobsToLoot;
    int _reviveAttempt, _ghostDance, _skinAttempt;
    NSSize minSectionSize, maxSectionSize;
	NSDate *startDate;
	int _lastActionErrorCode;
	UInt32 _lastActionTime;
	int _zoneBeforeHearth;
	UInt64 _lastCombatProcedureTarget;
	
	// healing shit
	BOOL _shouldFollow;
	Unit *_lastUnitAttemptedToHealed;
	BOOL _includeFriendly;
	BOOL _includeFriendlyPatrol;
	
	// improved loot shit
	WoWObject *_lastAttemptedUnitToLoot;
	NSMutableDictionary *_lootDismountCount;
	int _lootMacroAttempt;
	WoWObject *_unitToLoot;
	NSDate *lootStartTime;
	NSDate *skinStartTime;
	BOOL _lootUseItems;
	int _movingTowardMobCount;
	int _movingTowardNodeCount;
	
	NSMutableArray *_routesChecked;
	
	// fishing shit
	float _fishingGatherDistance;
	BOOL _fishingApplyLure;
	BOOL _fishingOnlySchools;
	BOOL _fishingRecast;
	BOOL _fishingUseContainers;
	int _fishingLureSpellID;
	
	// new node detection shit
	BOOL _nodeIgnoreFriendly;
	BOOL _nodeIgnoreHostile;
	BOOL _nodeIgnoreMob;
	float _nodeIgnoreFriendlyDistance;
	float _nodeIgnoreHostileDistance;
	float _nodeIgnoreMobDistance;
	
	// new flying shit
	int _jumpAttempt;
	Position *_lastGoodFollowPosition;
	
	// mount correction (sometimes we can't mount)
	int _mountAttempt;
	NSDate *_mountLastAttempt;
	
    // pvp shit
    BOOL _isPvPing;
    BOOL _pvpPlayWarning, _pvpLeaveInactive;
    int _pvpAntiAFKCounter;
//    IBOutlet NSButton *pvpPlayWarningCheckbox, *pvpLeaveInactiveCheckbox;
	BOOL _pvpIsInBG;
	NSTimer *_pvpTimer;
	BOOL _attackingInStrand;
	BOOL _strandDelay;
	BOOL _waitingToLeaveBattleground;
	
	// auto join WG options
	NSTimer *_wgTimer;
	int _lastNumWGMarks;
	NSDate *_dateWGEnded;
	
	// anti afk options
	NSTimer *_afkTimer;
	int _afkTimerCounter;
	BOOL _lastPressedWasForward;
	
	// log out options
	NSTimer *_logOutTimer;
    
	// Party
	BOOL _leaderBeenWaiting;
	
	// Follow
	Route *followRoute;
	BOOL _followSuspended;
	Unit *followUnit;
	Unit *assistUnit;
	Unit *tankUnit;
	BOOL _followLastSeenPosition;
	
	int _lootScanIdleTimer;
	int _lootScanCycles;

	int _partyEmoteIdleTimer;
	int _partyEmoteTimeSince;
	NSString *_lastEmote;
	int _lastEmoteShuffled;

	BOOL _wasLootWindowOpen;
	
    // -----------------
    // -----------------
    
    IBOutlet NSButton *startStopButton;
    
    IBOutlet id attackWithinText;
    IBOutlet id routePopup;
    IBOutlet id behaviorPopup;
    IBOutlet id combatProfilePopup;
    IBOutlet id minLevelPopup;
    IBOutlet id maxLevelPopup;
	IBOutlet NSPopUpButton *pvpBehaviorPopUp;
    IBOutlet NSTextField *minLevelText, *maxLevelText;
    IBOutlet NSButton *anyLevelCheckbox;
    
	// Log Out options
	IBOutlet NSButton		*logOutOnBrokenItemsCheckbox;
	IBOutlet NSButton		*logOutOnFullInventoryCheckbox;
	IBOutlet NSButton		*logOutOnTimerExpireCheckbox;
	IBOutlet NSButton		*logOutAfterStuckCheckbox;
	IBOutlet NSButton		*logOutUseHearthstoneCheckbox;
	IBOutlet NSTextField	*logOutDurabilityTextField;
	IBOutlet NSTextField	*logOutAfterRunningTextField;
	
    IBOutlet NSButton *miningCheckbox;
    IBOutlet NSButton *herbalismCheckbox;
	IBOutlet NSButton *netherwingEggCheckbox;
    IBOutlet id miningSkillText;
    IBOutlet id herbalismSkillText;
    IBOutlet NSButton *skinningCheckbox;
	IBOutlet NSButton *ninjaSkinCheckbox;
    IBOutlet id skinningSkillText;
    IBOutlet id gatherDistText;
    IBOutlet NSButton *lootCheckbox;
	
	IBOutlet NSTextField *fishingGatherDistanceText;
	IBOutlet NSButton *fishingCheckbox;
	IBOutlet NSButton *fishingApplyLureCheckbox;
	IBOutlet NSButton *fishingOnlySchoolsCheckbox;
	IBOutlet NSButton *fishingRecastCheckbox;
	IBOutlet NSButton *fishingUseContainersCheckbox;
	IBOutlet NSButton *fishingLurePopUpButton;
	
	IBOutlet NSButton		*autoJoinWG;
	IBOutlet NSButton		*antiAFKButton;
	
	IBOutlet NSButton *combatDisableRelease;
	
	IBOutlet NSTextField *nodeIgnoreHostileDistanceText;
	IBOutlet NSTextField *nodeIgnoreFriendlyDistanceText;
	IBOutlet NSTextField *nodeIgnoreMobDistanceText;
	IBOutlet NSButton *nodeIgnoreHostileCheckbox;
	IBOutlet NSButton *nodeIgnoreFriendlyCheckbox;
	IBOutlet NSButton *nodeIgnoreMobCheckbox;
	
	IBOutlet NSButton *lootUseItemsCheckbox;
    
    IBOutlet NSPanel *hotkeyHelpPanel;
    IBOutlet NSPanel *lootHotkeyHelpPanel;
	IBOutlet NSPanel *gatheringLootingPanel;
    IBOutlet SRRecorderControl *startstopRecorder;
    PTHotKey *StartStopBotGlobalHotkey;
    
    IBOutlet NSTextField *statusText;
	IBOutlet NSTextField *runningTimer;
    IBOutlet NSWindow *overlayWindow;
    IBOutlet ScanGridView *scanGrid;
}

@property (readonly) NSButton *logOutAfterStuckCheckbox;
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readwrite, assign) BOOL isBotting;
@property (assign) BOOL isPvPing;
@property (retain) NSString *procedureInProgress;
@property (retain) NSString *evaluationInProgress;

@property (readonly, retain) RouteCollection *theRouteCollection;
@property (readwrite, retain) RouteSet *theRouteSet;
@property (readonly, retain) Behavior *theBehavior;
@property (readonly, retain) PvPBehavior *pvpBehavior;
@property (readwrite, retain) CombatProfile *theCombatProfile;
@property (readonly, retain) Unit *preCombatUnit;
@property (readonly, retain) NSDate *lootStartTime;
@property (readonly, retain) NSDate *skinStartTime;
@property (readonly, retain) Unit *castingUnit;
@property (readonly, retain) Unit *followUnit;
@property (readonly, retain) Unit *assistUnit;
@property (readonly, retain) Unit *tankUnit;
@property (readwrite, assign) BOOL followSuspended;
@property (readonly, retain) Route *followRoute;

@property (readwrite, assign) BOOL wasLootWindowOpen;

- (void)testRule: (Rule*)rule;

- (BOOL)performProcedureMobCheck: (Unit*)target;
- (BOOL)lootScan;
- (void)resetLootScanIdleTimer;

// Input from CombatController
//- (void)addingUnit: (Unit*)unit;

// Input from CombatController
- (void)actOnUnit: (Unit*)unit;

// Input from MovementController;
//- (void)reachedUnit: (WoWObject*)unit;
- (void)cancelCurrentEvaluation;
- (void)cancelCurrentProcedure;
- (BOOL)combatProcedureValidForUnit: (Unit*)unit;
- (void)finishedRoute: (Route*)route;
- (BOOL)evaluateSituation;
- (BOOL)evaluateForPVP;
- (BOOL)evaluateForGhost;
- (BOOL)evaluateForParty;
- (BOOL)evaluateForFollow;
- (BOOL)evaluateForCombatContinuation;
- (BOOL)evaluateForRegen;
- (BOOL)evaluateForLoot;
- (BOOL)evaluateForCombatStart;
- (BOOL)evaluateForMiningAndHerbalism;
- (BOOL)evaluateForFishing;
- (BOOL)evaluateForPatrol;

// Party stuff
- (BOOL)isOnAssist;
- (BOOL)isTankUnit;
- (BOOL)leaderWait;
- (void)followRouteClear;
- (void)jumpIfAirMountOnGround;
- (NSString*)randomEmote;
- (NSString*)emoteGeneral;
- (NSString*)emoteFriend;
- (NSString*)emoteSexy;

// Follow stuff
- (void)followRouteClear;
- (BOOL)followMountNow;
- (BOOL)followMountCheck;

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
- (IBAction)gatheringLootingOptions: (id)sender;
- (IBAction)gatheringLootingSelectAction: (id)sender;

// test stuff
- (IBAction)test: (id)sender;
- (IBAction)test2: (id)sender;
- (IBAction)maltby: (id)sender;
- (IBAction)login: (id)sender;

// Little more flexibility - casts spells! Uses items/macros!
- (BOOL)performAction: (int32_t)actionID;
- (int)errorValue: (NSString*)errorMessage;
- (BOOL)interactWithMouseoverGUID: (UInt64) guid;
- (void)interactWithMob:(UInt32)entryID;
- (void)interactWithNode:(UInt32)entryID;
- (void)logOut;

- (void)logOutWithMessage:(NSString*)message;
	
// for new action/conditions
- (BOOL)evaluateRule: (Rule*)rule withTarget: (Unit*)target asTest: (BOOL)test;

- (void) updateRunningTimer;

- (UInt8)isHotKeyInvalid;

// from movement controller (for new WP actions!)
- (void)changeCombatProfile:(CombatProfile*)profile;

@end
