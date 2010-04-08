//
//  BotController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/14/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "BotController.h"

#import "Controller.h"
#import "ChatController.h"
#import "PlayerDataController.h"
#import "MobController.h"
#import "SpellController.h"
#import "NodeController.h"
#import "CombatController.h"
#import "MovementController.h"
#import "AuraController.h"
#import "WaypointController.h"
#import "ProcedureController.h"
#import "InventoryController.h"
#import "PlayersController.h"
#import "QuestController.h"
#import "CorpseController.h"
#import "LootController.h"
#import "ChatLogController.h"
#import "FishController.h"
#import "MacroController.h"
#import "OffsetController.h"
#import "MemoryViewController.h"
#import "CombatProfileEditor.h"
#import "EventController.h"
#import "BlacklistController.h"
#import "StatisticsController.h"
#import "BindingsController.h"
#import "PvPController.h"

#import "ChatLogEntry.h"
#import "BetterSegmentedControl.h"
#import "Behavior.h"
#import "RouteCollection.h"
#import "RouteSet.h"
#import "Condition.h"
#import "Mob.h"
#import "Unit.h"
#import "Player.h"
#import "Item.h"
#import "Offsets.h"
#import "PTHeader.h"
#import "CGSPrivate.h"
#import "Macro.h"
#import "CombatProfileEditor.h"
#import "CombatProfile.h"
#import "Errors.h"
#import "PvPBehavior.h"
#import "Battleground.h"

#import "ScanGridView.h"
#import "TransparentWindow.h"

#import <Growl/GrowlApplicationBridge.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <ScreenSaver/ScreenSaver.h>

#define DeserterSpellID		26013
#define HonorlessTargetSpellID	2479 
#define HonorlessTarget2SpellID 46705
#define IdleSpellID		43680
#define InactiveSpellID		43681
#define PreparationSpellID	44521
#define WaitingToRezSpellID	2584
#define HearthstoneItemID		6948
#define HearthStoneSpellID		8690

#define RefreshmentTableID		193061	// "Refreshment Table"
#define SoulwellID				193169	// "Soulwell"


// For strand of the ancients
#define StrandFlagpole					191311
#define StrandAllianceBanner			191310
#define StrandAllianceBannerAura		180100
#define StrandHordeBanner				191307
#define StrandeHordeBannerAura			180101
#define StrandAntipersonnelCannon		27894
#define StrandBattlegroundDemolisher	28781
#define StrandPrivateerZierhut			32658		// right boat
#define StrandPrivateerStonemantle		32657		// left boat

@interface BotController ()

@property (readwrite, retain) Behavior *theBehavior;
@property (readwrite, retain) PvPBehavior *pvpBehavior;
@property (readwrite, retain) NSDate *lootStartTime;
@property (readwrite, retain) NSDate *skinStartTime;

@property (readwrite, retain) NSDate *startDate;
@property (readwrite, retain) Mob *mobToSkin;
@property (readwrite, retain) WoWObject *unitToLoot;
@property (readwrite, retain) WoWObject *lastAttemptedUnitToLoot;
@property (readwrite, retain) Unit *preCombatUnit;
@property (readwrite, retain) Unit *castingUnit;
@property (readwrite, retain) Unit *followUnit;
@property (readwrite, retain) Unit *assistUnit;
@property (readwrite, retain) Unit *tankUnit;

@property (readwrite, retain) RouteCollection *theRouteCollection;

// pvp
@property (readwrite, assign) BOOL pvpPlayWarning;
@property (readwrite, assign) BOOL pvpLeaveInactive;
@property (readwrite, assign) int pvpAntiAFKCounter;

@property (readwrite, assign) BOOL doLooting;
@property (readwrite, assign) float gatherDistance;





@end

@interface BotController (Internal)

- (void)timeUp: (id)sender;

- (void)preRegen;
- (void)evaluateRegen: (NSDictionary*)regenDict;

- (void)performProcedureWithState: (NSDictionary*)state;
- (void)playerHasDied: (NSNotification*)noti;

// pvp
- (void)pvpStop;
- (void)pvpStart;
- (void)pvpAntiAFK;
- (void)pvpGetBGInfo;

- (void)rePop: (NSNumber *)count;

- (void)skinMob: (Mob*)mob;
- (void)skinToFinish;
- (BOOL)unitValidToHeal: (Unit*)unit;
- (void)lootNode: (WoWObject*) unit;
- (void)resetLootScanTimer;

- (BOOL)mountNow;

- (BOOL)scaryUnitsNearNode: (WoWObject*)node doMob:(BOOL)doMobCheck doFriendy:(BOOL)doFriendlyCheck doHostile:(BOOL)doHostileCheck;

- (BOOL)combatProcedureValidForUnit: (Unit*)unit;

- (void)executeRegen: (BOOL)delay;

- (NSString*)isRouteSetSound: (RouteSet*)route;

// new pvp
- (void)pvpQueueOrStart;
- (void)pvpQueueBattleground;
- (BOOL)pvpSetEnvironmentForZone;


@end


@implementation BotController

+ (void)initialize {
    
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithBool:NO],		@"UsePvPBehavior",
								   [NSNumber numberWithBool:YES],		@"UseRoute",
								   [NSNumber numberWithBool: YES],	@"AttackAnyLevel",
								   [NSNumber numberWithFloat: 50.0],	@"GatheringDistance",
								   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoJoin",
								   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoQueue",
								   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoRelease",
								   [NSNumber numberWithInt: NSOnState], @"PvPPlayWarningSound",
								   [NSNumber numberWithInt: NSOnState], @"PvPLeaveWhenInactive",
								   [NSNumber numberWithInt:0],			@"MovementType",
								   [NSNumber numberWithInt: NSOffState],@"DoLogOutCheck",
								   [NSNumber numberWithInt:20],		    @"LogOutOnBrokenItemsPercentage",
								   [NSNumber numberWithBool:NO],		@"DisableReleasingOnDeath",
								   nil];
	
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];
}

- (id)init {
	self = [super init];
    if (self == nil) return self;
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasDied:) name: PlayerHasDiedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasRevived:) name: PlayerHasRevivedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerIsInvalid:) name: PlayerIsInvalidNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(auraGain:) name: BuffGainNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(auraFade:) name: BuffFadeNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(itemsLooted:) name: AllItemsLootedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(itemLooted:) name: ItemLootedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(whisperReceived:) name: WhisperReceived object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(eventZoneChanged:) name: EventZoneChanged object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(eventBattlegroundStatusChange:) name: EventBattlegroundStatusChange object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(unitDied:) name: UnitDiedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerEnteringCombat:) name: PlayerEnteringCombatNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerLeavingCombat:) name: PlayerLeavingCombatNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(unitEnteredCombat:) name: UnitEnteredCombat object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachedObject:) name: ReachedObjectNotification object: nil];
	
	_theRouteCollection = nil;
	_pvpBehavior = nil;
	_procedureInProgress = nil;
	_evaluationInProgress = nil;
	_lastProcedureExecuted = nil;
	_didPreCombatProcedure = NO;
	_lastSpellCastGameTime = 0;
	self.startDate = nil;
	_unitToLoot = nil;
	_mobToSkin = nil;
	_wasLootWindowOpen = NO;
	_shouldFollow = YES;
	_lastUnitAttemptedToHealed = nil;
	_pvpIsInBG = NO;
	self.lootStartTime = nil;
	self.skinStartTime = nil;
	_lootMacroAttempt = 0;
	_zoneBeforeHearth = -1;
	_attackingInStrand = NO;
	_strandDelay = NO;
	_jumpAttempt = 0;
	_includeFriendly = NO;
	_includeFriendlyPatrol = NO;
	_lastSpellCast = 0;
	_mountAttempt = 0;
	_movingTowardMobCount = 0;
	_movingTowardNodeCount = 0;
	_lootDismountCount = [[NSMutableDictionary dictionary] retain];
	_mountLastAttempt = nil;
	castingUnit	= nil;
	followUnit	= nil;
	assistUnit	= nil;
	tankUnit	= nil;
	
	_lootScanIdleTimer = 0;

	self.partyFollowSuspended = NO;
	_stepAttempts = 0;
	
	_routesChecked = [[NSMutableArray array] retain];
	_mobsToLoot = [[NSMutableArray array] retain];
	_followSteps = [[NSMutableArray array] retain];
	_badWaypoints = [[NSMutableArray array] retain];
	_lastAttemptedStep = nil;
	_stepAttempts = 0;
	
	// wipe pvp options
	self.isPvPing = NO;
	self.pvpLeaveInactive = NO;
	self.pvpPlayWarning = NO;
	_pvpAntiAFKCounter = 0;
	
	// anti afk
	_lastPressedWasForward = NO;
	_afkTimerCounter = 0;
	
	// wg stuff
	_lastNumWGMarks = 0;
	_dateWGEnded = nil;
	
	_logOutTimer = nil;
	
	// Every 15 seconds we'll want to send clicks!
	_wgTimer = [NSTimer scheduledTimerWithTimeInterval: 15.0f target: self selector: @selector(wgTimer:) userInfo: nil repeats: YES];
	
	// Every 30 seconds for an anti-afk
	_afkTimer = [NSTimer scheduledTimerWithTimeInterval: 30.0f target: self selector: @selector(afkTimer:) userInfo: nil repeats: YES];
	
	
	[NSBundle loadNibNamed: @"Bot" owner: self];
	
	return self;
}

- (void)dealloc {
	[_routesChecked release]; _routesChecked = nil;
	[_mobsToLoot release]; _mobsToLoot = nil;	
	[super dealloc];
}

- (void)awakeFromNib {
	self.minSectionSize = [self.view frame].size;
	self.maxSectionSize = [self.view frame].size;
    
	[startstopRecorder setCanCaptureGlobalHotKeys: YES];
	
	// remove old key bindings
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HotkeyCode"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HotkeyFlags"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PetAttackCode"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PetAttackFlags"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MouseOverTargetCode"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MouseOverTargetFlags"];
	
    KeyCombo combo2 = { NSCommandKeyMask, kSRKeysEscape };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopCode"])
		combo2.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopFlags"])
		combo2.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopFlags"] intValue];
	
    [startstopRecorder setDelegate: self];
    [startstopRecorder setKeyCombo: combo2];
	
    // set up overlay window
    [overlayWindow setLevel: NSFloatingWindowLevel];
    if([overlayWindow respondsToSelector: @selector(setCollectionBehavior:)])
		[overlayWindow setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];
	
	//pvpBehaviorPopUp
    
	// auto select if we need to
	if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"PvPBehavior"] == nil ) 
		if ( [[pvpController behaviors] count] ) [pvpBehaviorPopUp selectItemAtIndex:0];
	
    [self updateStatus: nil];
}

@synthesize theRouteCollection = _theRouteCollection;
@synthesize theRouteSet;
@synthesize theBehavior;
@synthesize pvpBehavior = _pvpBehavior;
@synthesize theCombatProfile;
@synthesize lootStartTime;
@synthesize skinStartTime;

@synthesize logOutAfterStuckCheckbox;
@synthesize view;
@synthesize isBotting = _isBotting;
@synthesize isPvPing = _isPvPing;
@synthesize procedureInProgress = _procedureInProgress;
@synthesize evaluationInProgress = _evaluationInProgress;
@synthesize mobToSkin = _mobToSkin;
@synthesize unitToLoot = _unitToLoot;
@synthesize wasLootWindowOpen = _wasLootWindowOpen;
@synthesize lastAttemptedUnitToLoot = _lastAttemptedUnitToLoot;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize preCombatUnit;
@synthesize castingUnit;
@synthesize followUnit;
@synthesize assistUnit;
@synthesize tankUnit;
@synthesize pvpPlayWarning = _pvpPlayWarning;
@synthesize pvpLeaveInactive = _pvpLeaveInactive;
@synthesize pvpAntiAFKCounter = _pvpAntiAFKCounter;

@synthesize startDate;
@synthesize doLooting	    = _doLooting;
@synthesize gatherDistance  = _gatherDist;
@synthesize partyFollowSuspended  = _partyFollowSuspended;


- (NSString*)sectionTitle {
	return @"Start/Stop Bot";
}

- (CombatProfileEditor*)combatProfileEditor {
	return [CombatProfileEditor sharedEditor];
}

#pragma mark -

int DistanceFromPositionCompare(id <UnitPosition> unit1, id <UnitPosition> unit2, void *context) {
	Position *position = (Position*)context; 
	float d1 = [position distanceToPosition: [unit1 position]];
	float d2 = [position distanceToPosition: [unit2 position]];
	if (d1 < d2) return NSOrderedAscending;
	else if (d1 > d2) return NSOrderedDescending;
	else return NSOrderedSame;
}

#pragma mark -

- (void)testRule: (Rule*)rule {
	Unit *unit = [mobController playerTarget];
	if(!unit) unit = [playersController playerTarget];
	log(LOG_RULE, @"Testing rule with target: %@", unit);
	BOOL result = [self evaluateRule: rule withTarget: unit asTest: YES];
	NSRunAlertPanel(TRUE_FALSE(result), [NSString stringWithFormat: @"%@", rule], @"Okay", NULL, NULL);
}

- (BOOL)evaluateRule: (Rule*)rule withTarget: (Unit*)target asTest: (BOOL)test {
	// Determine whether or not the given target should have a rule applied
    int numMatched = 0, needToMatch = 0;
    if ([rule isMatchAll]) for(Condition *condition in [rule conditions]) if ( [condition enabled]) needToMatch++;
	
    if (needToMatch == 0) needToMatch = 1;
    
	Player *thePlayer = [playerController player];
	
	// target checks
	if ( [rule target] != TargetNone ){
		if ( ([rule target] == TargetFriend || [rule target] == TargetPet ) && ![playerController isFriendlyWithFaction: [target factionTemplate]] ){
//			log(LOG_DEV, @"[Rule] %@ isn't friendly! Bailing!", target);
			return NO;
		}
		
		if ( ([rule target] == TargetEnemy || [rule target] == TargetAdd) && [playerController isFriendlyWithFaction: [target factionTemplate]] ){
//			log(LOG_DEV, @"[Rule] @% isn't an enemy! Bailing!", target);
			return NO;
		}
		
		// set the correct target if it's self
		if ( [rule target] == TargetSelf ) {
			target = thePlayer;
		}
		
		// if this is an add and the rule is not for adds then return no
		// this can not exclude picking up an add when our target dies
		if ([rule target] != TargetAdd && [[self procedureInProgress] isEqualToString: CombatProcedure] && !test) {
			GUID targetID = [playerController targetID];
			Unit *targetUnit = [[MobController sharedController] mobWithGUID: targetID];
			if (targetUnit) {
				// Make sure our current target is alive, in combat and hostile
				if (targetUnit != target && [targetUnit isInCombat] && ![targetUnit isDead] && [playerController isHostileWithFaction: [targetUnit factionTemplate]]) {
					if ([target isKindOfClass: [Mob class]] && [targetUnit isKindOfClass: [Mob class]]) {
						NSArray *addList = [combatController allAdds];
						for ( Unit *potentialMatch in addList ) {
							if (target == potentialMatch) {
								log(LOG_DEV, @"[Rule] Target is an add, non add rules do not apply");
								return NO;
							}
						}
					}
				}
			}
		}
		
	}
	
	// check to see if we can even cast this spell
	if ( [[rule action] type] == ActionType_Spell && ![spellController isUsableAction:[[rule action] actionID]] ){
		log(LOG_RULE, @"Action %d isn't usable!", [[rule action] actionID]);
		return NO;
	}
	
	// check to see if the spell is on cooldown, obviously the rule will fail!
	if ( [[rule action] type] == ActionType_Spell ){
		if ( [spellController isSpellOnCooldown:[[rule action] actionID]] ){
			log(LOG_DEV, @"[Rule] Failed, spell is on cooldown!");
			return NO;
		}
	}
    
    for ( Condition *condition in [rule conditions] ) {
		if(![condition enabled]) continue;
		//		log(LOG_CONDITION, @"Checking condition: %@", condition);
		BOOL conditionEval = NO;
		if ([condition unit] == UnitTarget && !target) goto loopEnd;
		if ([condition unit] == UnitFriend && !target) goto loopEnd;
		if ([condition unit] == UnitNone && 
			[condition variety] != VarietySpellCooldown && 
			[condition variety] != VarietyLastSpellCast && 
			[condition variety] != VarietyPlayerLevel && 
			[condition variety] != VarietyPlayerZone && 
			[condition variety] != VarietyQuest && 
			[condition variety] != VarietyRouteRunCount && 
			[condition variety] != VarietyRouteRunTime && 
			[condition variety] != VarietyInventoryFree && 
			[condition variety] != VarietyDurability &&
			[condition variety] != VarietyMobsKilled && 
			[condition variety] != VarietyGate && 
			[condition variety] != VarietyStrandStatus) 
			goto loopEnd;
		
		switch ([condition variety]) {
			case VarietyNone:;
				log(LOG_ERROR, @"%@ in %@ is of an unknown type.", condition, rule);
				break;
				
			case VarietyHealth:;
				log(LOG_CONDITION, @"Doing Health/Power condition...");	
				int qualityValue = 0;
				if( [condition unit] == UnitPlayer ) {
					log(LOG_CONDITION, @"Checking player... type %d", [condition type]);
					if( ![playerController playerIsValid:self] || ![thePlayer isValid]) goto loopEnd;
					if( [condition quality] == QualityHealth ) qualityValue = ([condition type] == TypeValue) ? [thePlayer currentHealth] : [thePlayer percentHealth];
					else if ([condition quality] == QualityPower ) qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPower] : [thePlayer percentPower];
					else if ([condition quality] == QualityMana ) qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Mana] : [thePlayer percentPowerOfType: UnitPower_Mana];
					else if ([condition quality] == QualityRage ) qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Rage] : [thePlayer percentPowerOfType: UnitPower_Rage];
					else if ([condition quality] == QualityEnergy ) qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Energy] : [thePlayer percentPowerOfType: UnitPower_Energy];
					else if ([condition quality] == QualityHappiness ) qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Happiness] : [thePlayer percentPowerOfType: UnitPower_Happiness];
					else if ([condition quality] == QualityFocus ) qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Focus] : [thePlayer percentPowerOfType: UnitPower_Focus];
					else if ([condition quality] == QualityRunicPower ) qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_RunicPower] : [thePlayer percentPowerOfType: UnitPower_RunicPower];
					else goto loopEnd;
				} else {
					// get unit as either target or player's pet or friend
					Unit *aUnit = ([condition unit] == UnitTarget || [condition unit] == UnitFriend) ? target : [playerController pet];
					if( ![aUnit isValid]) goto loopEnd;
					if( [condition quality] == QualityHealth ) qualityValue = ([condition type] == TypeValue) ? [aUnit currentHealth] : [aUnit percentHealth];
					else if ([condition quality] == QualityPower ) qualityValue = ([condition type] == TypeValue) ? [aUnit currentPower] : [aUnit percentPower];
					else if ([condition quality] == QualityMana ) qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Mana] : [aUnit percentPowerOfType: UnitPower_Mana];
					else if ([condition quality] == QualityRage ) qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Rage] : [aUnit percentPowerOfType: UnitPower_Rage];
					else if ([condition quality] == QualityEnergy ) qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Energy] : [aUnit percentPowerOfType: UnitPower_Energy];
					else if ([condition quality] == QualityHappiness ) qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Happiness] : [aUnit percentPowerOfType: UnitPower_Happiness];
					else if ([condition quality] == QualityFocus ) qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Focus] : [aUnit percentPowerOfType: UnitPower_Focus];
					else if ([condition quality] == QualityRunicPower ) qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_RunicPower] : [aUnit percentPowerOfType: UnitPower_RunicPower];
					else goto loopEnd;
				}
				
				// now we have the value of the quality
				if( [condition comparator] == CompareMore) { 
					conditionEval = ( qualityValue > [[condition value] unsignedIntValue] ) ? YES : NO;
					log(LOG_CONDITION, @"	%d > %@ is %d", qualityValue, [condition value], conditionEval);
				} else if ([condition comparator] == CompareEqual) {
					conditionEval = ( qualityValue == [[condition value] unsignedIntValue] ) ? YES : NO;
					log(LOG_CONDITION, @"	%d = %@ is %d", qualityValue, [condition value], conditionEval);
				} else if ([condition comparator] == CompareLess) {
					conditionEval = ( qualityValue < [[condition value] unsignedIntValue] ) ? YES : NO;
					log(LOG_CONDITION, @"	%d > %@ is %d", qualityValue, [condition value], conditionEval);
				} else goto loopEnd;
				break;
				
				
			case VarietyStatus:;
				log(LOG_CONDITION, @"Doing Status condition...");	
				// check alive status
				if( [condition state] == StateAlive ) {
					if( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? ![playerController isDead] : ![playerController isDead];
					else if( [condition unit] == UnitTarget || [condition unit] == UnitFriend ) conditionEval = ( [condition comparator] == CompareIs ) ? ![target isDead] : [target isDead];
					else if( [condition unit] == UnitPlayerPet) {
						if (playerController.pet == nil) conditionEval = ([condition comparator] == CompareIs) ? NO : YES;
						else conditionEval = ( [condition comparator] == CompareIs ) ? ![playerController.pet isDead] : [playerController.pet isDead];
					} else goto loopEnd;
					log(LOG_CONDITION, @"	Alive? %d", conditionEval);
				}
				
				// check combat status
				if( [condition state] == StateCombat ) {
					if( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? [combatController inCombat] : ![combatController inCombat];
					else if( [condition unit] == UnitTarget || [condition unit] == UnitFriend ) conditionEval = ( [condition comparator] == CompareIs ) ? [target isInCombat] : ![target isInCombat];
					else if( [condition unit] == UnitPlayerPet) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isInCombat] : ![playerController.pet isInCombat];
					else goto loopEnd;
					log(LOG_CONDITION, @"	Combat? %d", conditionEval);
				}
				
				// check casting status
				if( [condition state] == StateCasting ) {
					if( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController isCasting] : ![playerController isCasting];
					else if( [condition unit] == UnitTarget || [condition unit] == UnitFriend ) conditionEval = ( [condition comparator] == CompareIs ) ? [target isCasting] : ![target isCasting];
					else if( [condition unit] == UnitPlayerPet) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isCasting] : ![playerController.pet isCasting];
					goto loopEnd;
					log(LOG_CONDITION, @"	Casting? %d", conditionEval);
				}

				// check swimming status
				if( [condition state] == StateSwimming ) {
					if ( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? [[playerController player]isSwimming] : ![[playerController player]isSwimming];
					else if( [condition unit] == UnitTarget || [condition unit] == UnitFriend ) conditionEval = ( [condition comparator] == CompareIs ) ? [target isSwimming] : ![target isSwimming];
					else if( [condition unit] == UnitPlayerPet) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isSwimming] : ![playerController.pet isSwimming];
					goto loopEnd;
					log(LOG_CONDITION, @"	Swimming? %d", conditionEval);
				}

				// check targeting me status
				if( [condition state] == StateTargetingMe ) {
					/*
					if( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? ( [[playerController player] targetID] == [playerController player] GUID] ) : ( [[playerController player] targetID] != [playerController player] GUID]);
					else if( [condition unit] == UnitTarget || [condition unit] == UnitFriend ) conditionEval = ( [condition comparator] == CompareIs ) ? [target isSwimming] : ![target isSwimming];
					else if( [condition unit] == UnitPlayerPet) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isSwimming] : ![playerController.pet isSwimming];
					goto loopEnd;
					log(LOG_CONDITION, @"	Targeting me? %d", conditionEval);
					 */
				}
				
				// IS THE UNIT MOUNTED?
				if( [condition state] == StateMounted ) {
					if (test) log(LOG_CONDITION, @"Doing State IsMounted condition...");
					Unit *aUnit = nil;
					if( [condition unit] == UnitPlayer)		aUnit = thePlayer;
					else if( [condition unit] == UnitTarget || [condition unit] == UnitFriend )	   aUnit = target;
					else if( [condition unit] == UnitPlayerPet) aUnit = playerController.pet;
					if (test) log(LOG_CONDITION, @" --> Testing unit %@", aUnit);
					
					if ([aUnit isValid]) {
						conditionEval = ( [condition comparator] == CompareIs ) ? [aUnit isMounted] : ![aUnit isMounted];
						if (test) log(LOG_CONDITION, @" --> Unit is mounted? %@", YES_NO(conditionEval));
					} else {
						if (test) log(LOG_CONDITION, @" --> Unit is invalid.");
					}
				}
				
				break;
				
			case VarietyAura:;
				log(LOG_CONDITION, @"-- Checking aura condition --");
				unsigned spellID = 0;
				NSString *dispelType = nil;
				BOOL doDispelCheck = ([condition quality] == QualityBuffType) || ([condition quality] == QualityDebuffType);
				// sanity checks
				if(!doDispelCheck) {
					if( [condition type] == TypeValue) spellID = [[condition value] unsignedIntValue];
					
					if( ([condition type] == TypeValue) && !spellID) {
						// invalid spell ID
						goto loopEnd;
					} else if( [condition type] == TypeString && (![condition value] || ![[condition value] length])) {
						// invalid spell name
						goto loopEnd;
					}
				} else {
					if( ([condition state] < StateMagic) || ([condition state] > StatePoison)) {
						// invalid dispel type
						goto loopEnd;
					} else {
						if([condition state] == StateMagic)	dispelType = DispelTypeMagic;
						if([condition state] == StateCurse)	dispelType = DispelTypeCurse;
						if([condition state] == StatePoison)	dispelType = DispelTypePoison;
						if([condition state] == StateDisease)	dispelType = DispelTypeDisease;
					}
				}
				
				log(LOG_CONDITION, @"  Searching for spell '%@'", [condition value]);
				
				Unit *aUnit = nil;
				if( [condition unit] == UnitPlayer ) {
					if( ![playerController playerIsValid:self]) goto loopEnd;
					aUnit = thePlayer;
				} else {
					aUnit = ([condition unit] == UnitTarget || [condition unit] == UnitFriend) ? target : [playerController pet];
				}
				
				if( [aUnit isValid]) {
					if( [condition quality] == QualityBuff ) {
						if([condition type] == TypeValue)
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasBuff: spellID] : ![auraController unit: aUnit hasBuff: spellID];
						if([condition type] == TypeString)
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasBuffNamed: [condition value]] : ![auraController unit: aUnit hasBuffNamed: [condition value]];
					} else if([condition quality] == QualityDebuff) {
						if([condition type] == TypeValue)
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasDebuff: spellID] : ![auraController unit: aUnit hasDebuff: spellID];
						if([condition type] == TypeString)
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasDebuffNamed: [condition value]] : ![auraController unit: aUnit hasDebuffNamed: [condition value]];
					} else if([condition quality] == QualityBuffType) {
						conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasBuffType: dispelType] : ![auraController unit: aUnit hasBuffType: dispelType];
					} else if([condition quality] == QualityDebuffType) {
						conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasDebuffType: dispelType] : ![auraController unit: aUnit hasDebuffType: dispelType];
					}
				} else goto loopEnd;
				break;
				
			case VarietyAuraStack:;
				spellID = 0;
				dispelType = nil;
				log(LOG_CONDITION, @"Doing Aura Stack condition...");		
				// sanity checks
				if(([condition type] != TypeValue) && ([condition type] != TypeString)) {
					if(test) log(LOG_CONDITION, @" --> Invalid condition type.");
					goto loopEnd;
				}
				if( [condition type] == TypeValue) {
					spellID = [[condition value] unsignedIntValue];
					if(spellID == 0) { // invalid spell ID
						if(test) log(LOG_CONDITION, @" --> Invalid spell number");
						goto loopEnd;
					} else {
						if(test) log(LOG_CONDITION, @" --> Scanning for aura %u", spellID);
					}
				}
				if( [condition type] == TypeString) {
					if( ![[condition value] isKindOfClass: [NSString class]] || ![[condition value] length] ) {
						if(test) log(LOG_CONDITION, @" --> Invalid or blank Spell name.");
						goto loopEnd;
					} else {
						if(test) log(LOG_CONDITION, @" --> Scanning for aura \"%@\"", [condition value]);
					}
				}
				
				aUnit = nil;
				if( [condition unit] == UnitPlayer ) {
					if( ![playerController playerIsValid:self]) goto loopEnd;
					aUnit = thePlayer;
				} else {
					aUnit = ([condition unit] == UnitTarget || [condition unit] == UnitFriend) ? target : [playerController pet];
				}
				
				if( [aUnit isValid]) {
					log(LOG_CONDITION, @"Testing unit %@ for %d", aUnit, spellID);
					int stackCount = 0;
					if( [condition quality] == QualityBuff ) {
						if([condition type] == TypeValue)   stackCount = [auraController unit: aUnit hasBuff: spellID];
						if([condition type] == TypeString)  stackCount = [auraController unit: aUnit hasBuffNamed: [condition value]];
					} else if([condition quality] == QualityDebuff) {
						if([condition type] == TypeValue)   stackCount = [auraController unit: aUnit hasDebuff: spellID];
						if([condition type] == TypeString)  stackCount = [auraController unit: aUnit hasDebuffNamed: [condition value]];
					}
					
					if([condition comparator] == CompareMore) conditionEval = (stackCount > [condition state]);
					if([condition comparator] == CompareEqual) conditionEval = (stackCount == [condition state]);
					if([condition comparator] == CompareLess) conditionEval = (stackCount < [condition state]);
					if(test) log(LOG_CONDITION, @" --> Found %d stacks for result %@", stackCount, (conditionEval ? @"TRUE" : @"FALSE"));
					// conditionEval = ([condition comparator] == CompareMore) ? (stackCount > [condition state]) : (([condition comparator] == CompareEqual) ? (stackCount == [condition state]) : (stackCount < [condition state]));
				} else goto loopEnd;
				
				break;
				
			case VarietyDistance:;
				if( [condition unit] == UnitTarget && [condition quality] == QualityDistance && target) {
					float distanceToTarget = [[(PlayerDataController*)playerController position] distanceToPosition: [target position]];
					log(LOG_CONDITION, @"-- Checking distance condition --");
					
					if( [condition comparator] == CompareMore) {
						conditionEval = ( distanceToTarget > [[condition value] floatValue] ) ? YES : NO;
						log(LOG_CONDITION, @"  %f > %@ is %d", distanceToTarget, [condition value], conditionEval);
					} else if([condition comparator] == CompareEqual) {
						conditionEval = ( distanceToTarget == [[condition value] floatValue] ) ? YES : NO;
						log(LOG_CONDITION, @"  %f = %@ is %d", distanceToTarget, [condition value], conditionEval);
					} else if([condition comparator] == CompareLess) {
						conditionEval = ( distanceToTarget < [[condition value] floatValue] ) ? YES : NO;
						log(LOG_CONDITION, @"  %f < %@ is %d", distanceToTarget, [condition value], conditionEval);
					} else goto loopEnd;
				}
				
				break;
				
			case VarietyInventory:;
				if( [condition unit] == UnitPlayer && [condition quality] == QualityInventory) {
					log(LOG_CONDITION, @"-- Checking inventory condition --");
					Item *item = ([condition type] == TypeValue) ? [itemController itemForID: [condition value]] : [itemController itemForName: [condition value]];
					int totalCount = [itemController collectiveCountForItemInBags: item];
					if( [condition comparator] == CompareMore) conditionEval = (totalCount > [condition state]) ? YES : NO;
					if( [condition comparator] == CompareEqual) conditionEval = (totalCount == [condition state]) ? YES : NO;		    
					if( [condition comparator] == CompareLess) conditionEval = (totalCount < [condition state]) ? YES : NO;
				}
				break;
				
			case VarietyComboPoints:;
				log(LOG_CONDITION, @"Doing Combo Points condition...");			
				UInt32 class = [thePlayer unitClass];
				if( (class != UnitClass_Rogue) && (class != UnitClass_Druid) ) {
					log(LOG_CONDITION, @" --> You are not a rogue or druid, noob.");
					goto loopEnd;
				}			
				if( ([condition unit] == UnitPlayer) && ([condition quality] == QualityComboPoints) && target) {
					// either we have no CP target, or our CP target matched our current target
					UInt64 cpUID = [playerController comboPointUID];
					if( (cpUID == 0) || ([target GUID] == cpUID)) {
						int comboPoints = [playerController comboPoints];
						log(LOG_CONDITION, @" --> Found %d combo points.", comboPoints);					
						if( [condition comparator] == CompareMore) {
							conditionEval = ( comboPoints > [[condition value] intValue] ) ? YES : NO;
							log(LOG_CONDITION, @" --> %d > %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
						} else if([condition comparator] == CompareEqual) {
							conditionEval = ( comboPoints == [[condition value] intValue] ) ? YES : NO;
							log(LOG_CONDITION, @" --> %d = %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
						} else if([condition comparator] == CompareLess) {
							conditionEval = ( comboPoints < [[condition value] intValue] ) ? YES : NO;
							log(LOG_CONDITION, @" --> %d < %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
						} else goto loopEnd;
					}
				}
				break;
				
			case VarietyTotem:;		
				log(LOG_CONDITION, @"Doing Totem condition...");
				if( ![condition value] || ![[condition value] length] || ![[condition value] isKindOfClass: [NSString class]] ) {
					if(test) log(LOG_CONDITION, @" --> Invalid totem name.");
					goto loopEnd;
				}
				if( ([condition unit] != UnitPlayer) || ([condition quality] != QualityTotem)) {
					log(LOG_CONDITION, @" --> Invalid condition parameters.");
					goto loopEnd;
				}
				if( [thePlayer unitClass] != UnitClass_Shaman ) {
					log(LOG_CONDITION, @" --> You are not a shaman, noob.");
					goto loopEnd;
				}
				
				// we need to rescan the mob list before we check for active totems
				// [mobController enumerateAllMobs];
				BOOL foundTotem = NO;
				for(Mob* mob in [mobController allMobs]) {
					if( [mob isTotem] && ([mob createdBy] == [playerController GUID]) ) {
						NSRange range = [[mob name] rangeOfString: [condition value] options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
						if(range.location != NSNotFound) {
							foundTotem = YES;
							log(LOG_CONDITION, @" --> Found totem %@ matching \"%@\".", mob, [condition value]);
							break;
						}
					}
				}		
				if(!foundTotem && test) log(LOG_CONDITION, @" --> No totem found with name \"%@\"", [condition value]);
				conditionEval = ([condition comparator] == CompareExists) ? foundTotem : !foundTotem;		
				break;			
				
			case VarietyTempEnchant:;
				log(LOG_CONDITION, @"Doing Temp Enchant condition...");		
				Item *item = [itemController itemForGUID: [thePlayer itemGUIDinSlot: ([condition quality] == QualityMainhand) ? SLOT_MAIN_HAND : SLOT_OFF_HAND]];
				log(LOG_CONDITION, @" --> Got item %@.", item);
				BOOL hadEnchant = [item hasTempEnchantment];
				conditionEval = ([condition comparator] == CompareExists) ? hadEnchant : !hadEnchant;
				log(LOG_CONDITION, @" --> Had enchant? %@. Result is %@.", YES_NO(hadEnchant), TRUE_FALSE(conditionEval));
				break;
				
			case VarietyTargetType:;
				log(LOG_CONDITION, @"Doing Target Type condition...");		
				if([condition quality] == QualityNPC) {
					conditionEval = [target isNPC];
					log(LOG_CONDITION, @" --> Is NPC? %@", YES_NO(conditionEval));
				}
				if([condition quality] == QualityPlayer) {
					conditionEval = [target isPlayer];
					log(LOG_CONDITION, @" --> Is Player? %@", YES_NO(conditionEval));
				}
				break;
				
			case VarietyTargetClass:;
				log(LOG_CONDITION, @"Doing Target Class condition...");
				if([condition quality] == QualityNPC) {
					conditionEval = ([target creatureType] == [condition state]);
					log(LOG_CONDITION, @" --> Unit Creature Type %d == %d? %@", [condition state], [target creatureType], YES_NO(conditionEval));
				}
				if([condition quality] == QualityPlayer) {
					conditionEval = ([target unitClass] == [condition state]);
					log(LOG_CONDITION, @" --> Unit Class %d == %d? %@", [condition state], [target unitClass], YES_NO(conditionEval));
				}
				break;
				
			case VarietyCombatCount:;
				log(LOG_CONDITION, @"Doing Combat Count condition...");
				int unitsAttackingMe = [[combatController combatList] count];
				log(LOG_CONDITION, @" --> Found %d units attacking me.", unitsAttackingMe);
				if( [condition comparator] == CompareMore) {
					conditionEval = ( unitsAttackingMe > [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d > %d is %@.", unitsAttackingMe, [condition state], TRUE_FALSE(conditionEval));
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( unitsAttackingMe == [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d = %d is %@.", unitsAttackingMe, [condition state], TRUE_FALSE(conditionEval));
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( unitsAttackingMe < [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d < %d is %@.", unitsAttackingMe, [condition state], TRUE_FALSE(conditionEval));
				} else goto loopEnd;
				break;
				
			case VarietyProximityCount:;
				log(LOG_CONDITION, @"Doing Proximity Count condition...");
				float distance = [[condition value] floatValue];
				// get list of all possible targets
				NSArray *allTargets = [combatController enemiesWithinRange:distance];
				int inRangeCount = [allTargets count];
				log(LOG_CONDITION, @" --> Found %d total units.", [allTargets count]);		
				// compare with specified number of units
				if( [condition comparator] == CompareMore) {
					conditionEval = ( inRangeCount > [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d > %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( inRangeCount == [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d = %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( inRangeCount < [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d < %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
				} else goto loopEnd;
				break;
				
			case VarietySpellCooldown:;
				log(LOG_CONDITION, @"Doing Spell Cooldown condition...");
				BOOL onCD = NO;
				
				// checking by spell ID
				if ( [condition type] == TypeValue ){
					unsigned spellID = [[condition value] unsignedIntValue];
					if ( !spellID ) goto loopEnd;
					// check
					onCD = [spellController isSpellOnCooldown:spellID];
					conditionEval = ( [condition comparator] == CompareIs ) ? onCD : !onCD;
					log(LOG_CONDITION, @" Spell %d is (not? %d) on cooldown? %d", spellID, [condition comparator] == CompareIsNot, onCD);
				}
				// checking by spell ID
				else if ( [condition type] == TypeString ){
					// sanity check
					if ( ![condition value] || ![[condition value] length] ) goto loopEnd;					
					Spell *spell = [spellController spellForName:[condition value]];
					if ( spell && [spell ID] ){
						onCD = [spellController isSpellOnCooldown:[[spell ID] unsignedIntValue]];
						conditionEval = ( [condition comparator] == CompareIs ) ? onCD : !onCD;
						log(LOG_CONDITION, @" Spell %@ is (not? %d) on cooldown? %d", spell, [condition comparator] == CompareIsNot, conditionEval);
					}
				}
				break;
				
			case VarietyLastSpellCast:;
				log(LOG_CONDITION, @"Doing Last Spell Cast condition...");
				// checking by spell ID
				if ( [condition type] == TypeValue ){
					unsigned spellID = [[condition value] unsignedIntValue];
					if ( !spellID ) goto loopEnd;
					// check
					BOOL spellCast = (_lastSpellCast == spellID);
					conditionEval = ( [condition comparator] == CompareIs ) ? spellCast : !spellCast;
					if(test) log(LOG_GENERAL, @" Spell %d %d was%@ the last spell cast? %d", spellID, _lastSpellCast, (([condition comparator] == CompareIs ) ? @"" : @" not"), conditionEval);
				}
				// checking by spell ID
				else if ( [condition type] == TypeString ){
					// sanity check
					if ( ![condition value] || ![[condition value] length] ) goto loopEnd;
					Spell *spell = [spellController spellForName:[condition value]];
					if ( spell && [spell ID] ){
						BOOL spellCast = (_lastSpellCast == [[spell ID] unsignedIntValue]);
						conditionEval = ( [condition comparator] == CompareIs ) ? spellCast : !spellCast;
						if(test) log(LOG_GENERAL, @" Spell %d %d was%@ the last spell cast? %d", [[spell ID] unsignedIntValue], _lastSpellCast, (([condition comparator] == CompareIs ) ? @"" : @" not"), conditionEval);
					}
				}
				break;
				
			case VarietyRune:;
				if(test) log(LOG_GENERAL, @"Doing Rune condition...");
				// get our rune type
				int runeType = RuneType_Blood;
				if ( [condition quality] == QualityRuneUnholy ) runeType = RuneType_Unholy;
				else if ( [condition quality] == QualityRuneFrost ) runeType = RuneType_Frost;
				else if ( [condition quality] == QualityRuneDeath ) runeType = RuneType_Death;
				
				// quality value
				int runesAvailable = [playerController runesAvailable:runeType];
				// now we have the value of the quality
				if( [condition comparator] == CompareMore) {
					conditionEval = ( runesAvailable > [[condition value] unsignedIntValue] ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d > %@ is %d", runesAvailable, [condition value], conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( runesAvailable == [[condition value] unsignedIntValue] ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d = %@ is %d", runesAvailable, [condition value], conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( runesAvailable < [[condition value] unsignedIntValue] ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d < %@ is %d", runesAvailable, [condition value], conditionEval);
				} else goto loopEnd;
				if (test) log(LOG_GENERAL, @" Checking type %d - is %d equal to %@", runeType, [playerController runesAvailable:runeType], [condition value]);
				break;
				
			case VarietyPlayerLevel:;
				if(test) log(LOG_GENERAL, @"Doing Player level condition...");
				int level = [[condition value] intValue];
				int playerLevel = [playerController level];
				
				// check level
				if( [condition comparator] == CompareMore) {
					conditionEval = ( playerLevel > level ) ? YES : NO;
					//log(LOG_GENERAL, @"  %d > %d is %d", playerLevel, level, conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( playerLevel == level ) ? YES : NO;
					//log(LOG_GENERAL, @"  %d = %d is %d", playerLevel, level, conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( playerLevel < level ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d < %d is %d", playerLevel, level, conditionEval);
				} else goto loopEnd;
				break;
				
			case VarietyPlayerZone:;
				if(test) log(LOG_GENERAL, @"Doing Player zone condition...");
				int zone = [[condition value] intValue];
				int playerZone = [playerController zone];
				// check zone
				if( [condition comparator] == CompareIs) {
					conditionEval = ( zone == playerZone ) ? YES : NO;
					log(LOG_GENERAL, @"  %d = %d is %d", zone, playerZone, conditionEval);
				} else if([condition comparator] == CompareIsNot) {
					conditionEval = ( zone != playerZone ) ? YES : NO;
					log(LOG_GENERAL, @"  %d != %d is %d", zone, playerZone, conditionEval);
				} else goto loopEnd;
				break;
				
			case VarietyInventoryFree:;
				if(test) log(LOG_GENERAL, @"Doing free inventory condition...");				
				int freeSpaces = [[condition value] intValue];
				int totalFree = [itemController bagSpacesAvailable];
				
				// check free spaces
				if( [condition comparator] == CompareMore) {
					conditionEval = ( totalFree > freeSpaces ) ? YES : NO;
					//log(LOG_GENERAL, @"  %d > %d is %d", totalFree, freeSpaces, conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( totalFree == freeSpaces ) ? YES : NO;
					//log(LOG_GENERAL, @"  %d = %d is %d", totalFree, freeSpaces, conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( totalFree < freeSpaces ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d < %d is %d", totalFree, freeSpaces, conditionEval);
				} else goto loopEnd;
				
				break;
				
			case VarietyDurability:;
				log(LOG_CONDITION, @"Doing durability condition...");
				float averageDurability = [itemController averageWearableDurability];
				float durabilityPercentage = [[condition value] floatValue];
				log(LOG_CONDITION, @"%0.2f %0.2f", averageDurability, durabilityPercentage);
				// generally means we haven't updated our arrays yet in inventoryController
				if ( averageDurability == 0 ) goto loopEnd;
				// check free spaces
				if( [condition comparator] == CompareMore) {
					conditionEval = ( averageDurability > durabilityPercentage ) ? YES : NO;
					log(LOG_CONDITION, @"  %0.2f > %0.2f is %d", averageDurability, durabilityPercentage, conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( averageDurability == durabilityPercentage ) ? YES : NO;
					log(LOG_CONDITION, @"  %0.2f = %0.2f is %d", averageDurability, durabilityPercentage, conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( averageDurability < durabilityPercentage ) ? YES : NO;
					log(LOG_CONDITION, @"	%0.2f < %0.2f is %d", averageDurability, durabilityPercentage, conditionEval);
				} else goto loopEnd;
				break;
				
			case VarietyMobsKilled:;
				log(LOG_CONDITION, @"Doing mobs killed condition...");
				int entryID = [[condition value] intValue];
				int killCount = [condition state];
				int realKillCount = [statisticsController killCountForEntryID:entryID];				
				// check free spaces
				if( [condition comparator] == CompareMore) {
					conditionEval = ( realKillCount > killCount ) ? YES : NO;
					log(LOG_CONDITION, @"  %d > %d is %d", realKillCount, killCount, conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( realKillCount == killCount ) ? YES : NO;
					log(LOG_CONDITION, @"  %d = %d is %d", realKillCount, killCount, conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( realKillCount < killCount ) ? YES : NO;
					log(LOG_CONDITION, @"  %d < %d is %d", realKillCount, killCount, conditionEval);
				} else goto loopEnd;
				
				break;
				
			case VarietyGate:;
				log(LOG_CONDITION, @"Doing gate condition...");
				// grab our gate ID
				int quality = [condition quality];
				int gateEntryID = 0;
				if ( quality == QualityBlueGate ) gateEntryID = StrandGateOfTheBlueSapphire;
				else if ( quality == QualityGreenGate ) gateEntryID = StrandGateOfTheGreenEmerald;
				else if ( quality == QualityPurpleGate ) gateEntryID = StrandGateOfThePurpleAmethyst;
				else if ( quality == QualityRedGate ) gateEntryID = StrandGateOfTheRedSun;
				else if ( quality == QualityYellowGate) gateEntryID = StrandGateOfTheYellowMoon;
				else if ( quality == QualityChamber) gateEntryID = StrandChamberOfAncientRelics;
				Node *gate = [nodeController nodeWithEntryID:gateEntryID];
				if ( !gate ) goto loopEnd;				
				BOOL destroyed = ([gate objectHealth] == 0) ? YES : NO;
				if ( [condition comparator] == CompareIs ) {
					conditionEval = destroyed;
					log(LOG_CONDITION, @"  %d is destroyed? %d", gateEntryID, conditionEval);
				} else if ( [condition comparator] == CompareIsNot ) {
					conditionEval = !destroyed;
					log(LOG_CONDITION, @"  %d is not destroyed? %d", gateEntryID, conditionEval);
				} else goto loopEnd;
				break;
				
			case VarietyStrandStatus:;
				log(LOG_CONDITION, @"Doing battleground status condition...");
				if ( [condition quality] == QualityAttacking ){
					conditionEval = _attackingInStrand;
					log(LOG_CONDITION, @"  checking if we're attacking in strand? %d", conditionEval);
				} else if ( [condition quality] == QualityDefending ){
					conditionEval = !_attackingInStrand;
					log(LOG_CONDITION, @"  checking if we're defending in strand? %d", conditionEval);
				} else goto loopEnd;
				break;
				
			default:;
				log(LOG_CONDITION, @"checking for %d", [condition variety]);
				break;
		}
		
	loopEnd:
		if(conditionEval) numMatched++;
		// shortcut bail if we can
		if ([rule isMatchAll]) {
			if(!conditionEval) return NO;
		} else {
			if(conditionEval) return YES;
		}
	}
	
	if(numMatched >= needToMatch) return YES;
	return NO;
}

#define RULE_EVAL_DELAY_SHORT	0.25f
#define RULE_EVAL_DELAY_NORMAL	0.5f
#define RULE_EVAL_DELAY_LONG	0.5f

- (void)cancelCurrentProcedure {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
	[_lastProcedureExecuted release]; _lastProcedureExecuted = nil;
	if ( self.procedureInProgress ) _lastProcedureExecuted = [NSString stringWithString:self.procedureInProgress];
	[self setProcedureInProgress: nil];
	
	// Reset the evaluation as well
	self.evaluationInProgress = nil;

}

- (void)finishCurrentProcedure: (NSDictionary*)state {	
	log(LOG_PROCEDURE, @"Finishing Procedure: %@", [state objectForKey: @"Procedure"]);
    
    // make sure we're done casting before we end the procedure
    if( [playerController isCasting] ) {
		float timeLeft = [playerController castTimeRemaining];
		if( timeLeft <= 0 ) {
			[self performSelector: _cmd withObject: state afterDelay: 0.1f];
		} else {
			log(LOG_PROCEDURE, @"Still casting (%.2f remains): Delaying procedure end.", timeLeft);
			[self performSelector: _cmd withObject: state afterDelay: timeLeft];
			return;
		}
		return;
    }

    [self cancelCurrentProcedure];
    
    // when we finish PreCombat, re-evaluate the situation
    if([[state objectForKey: @"Procedure"] isEqualToString: PreCombatProcedure]) {
		log(LOG_DEV, @"[Eval] After PreCombat");
		self.evaluationInProgress = nil;
		[self evaluateSituation];
		return;
    }

	// when we finish PostCombat, go back to evaluation
    if ([[state objectForKey: @"Procedure"] isEqualToString: PostCombatProcedure]) {
		log(LOG_DEV, @"[Eval] After PostCombat");
		self.evaluationInProgress = nil;
		[self evaluateSituation];
		return;
	}

    if ( [[state objectForKey: @"Procedure"] isEqualToString: RegenProcedure] ) {
		if ( [[state objectForKey: @"ActionsPerformed"] intValue] > 0 ) {
			self.evaluationInProgress = @"Regen";
			log(LOG_REGEN, @"Starting regen!");
			[self performSelector: @selector(monitorRegen:) withObject: [[NSDate date] retain] afterDelay: 0.1f];
		} else {
			// or if we didn't regen, go back to evaluate
			log(LOG_PROCEDURE, @"No regen, back to evaluate");
			self.evaluationInProgress = nil;
			[self evaluateSituation];
		}
	}

    // if we did the Patrolling procdure, go back to evaluate
    if([[state objectForKey: @"Procedure"] isEqualToString: PatrollingProcedure]) {
		// Pause a moment for a potential mount cast
		usleep(800000);
		
		// If we're mounted let's do what ever cool thing our jump action activates whether we're air mounted or not.
		if ( [[playerController player] isMounted] && ![[playerController player] isSwimming] ) {
			[movementController jump];
			usleep(300000);
		}

		self.evaluationInProgress = nil;
		[self evaluateSituation];
	}
	
	if([[state objectForKey: @"Procedure"] isEqualToString: CombatProcedure]) {
		log(LOG_DEV, @"Combat completed, moving to PostCombat (in combat? %d)", [playerController isInCombat]);
		[self performSelector: @selector(performProcedureWithState:) 
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys: PostCombatProcedure,		  @"Procedure", [NSNumber numberWithInt: 0],	  @"CompletedRules", nil]
				   afterDelay: 0.1f ];
	}
}

- (void)performProcedureWithState: (NSDictionary*)state {
	log(LOG_DEV, @"performProcedureWithState called");

	// player dead?
	if ( [playerController isDead] ) {
		log(LOG_PROCEDURE, @"Player is dead! Aborting!");
		self.evaluationInProgress = nil;
		[self cancelCurrentProcedure];
		return;
	}

    // if there's another procedure running, we gotta stop it
    if( self.procedureInProgress && ![self.procedureInProgress isEqualToString: [state objectForKey: @"Procedure"]]) {
		[self cancelCurrentProcedure];
		log(LOG_PROCEDURE, @"Cancelling a previous procedure to begin %@.", [state objectForKey: @"Procedure"]);
    }
	
    if (![self procedureInProgress]) {
		[self setProcedureInProgress: [state objectForKey: @"Procedure"]];
		
		log(LOG_DEV, @"No Procedure in progress, setting it to: %@", self.procedureInProgress);

		if ( ![[self procedureInProgress] isEqualToString: CombatProcedure] ) {
			if( [[self procedureInProgress] isEqualToString: PreCombatProcedure]) {
				[controller setCurrentStatus: @"Bot: Pre-Combat Phase"];
			} else 
			if ( [[self procedureInProgress] isEqualToString: PostCombatProcedure]) {
				[controller setCurrentStatus: @"Bot: Post-Combat Phase"];
			} else 
			if( [[self procedureInProgress] isEqualToString: RegenProcedure]) {
				[controller setCurrentStatus: @"Bot: Regen Phase"];
				self.evaluationInProgress = @"Regen";
			} else 
			if( [[self procedureInProgress] isEqualToString: PatrollingProcedure]) {
				[controller setCurrentStatus: @"Bot: Patrolling Phase"];
				self.evaluationInProgress = @"Patrol";
			}
		}
    }
	
	if ( [[self procedureInProgress] isEqualToString: CombatProcedure]) {
		log(LOG_DEV, @"Requested procedure is %@", self.procedureInProgress);
		NSArray *combatList = [combatController combatList];
		int count =		[combatList count];
		if (count == 1)	[controller setCurrentStatus: [NSString stringWithFormat: @"Bot: Player in Combat (%d unit)", count]];
		else		[controller setCurrentStatus: [NSString stringWithFormat: @"Bot: Player in Combat (%d units)", count]];
	}
    
    Procedure *procedure = [self.theBehavior procedureForKey: [state objectForKey: @"Procedure"]];
    Unit *target = [state objectForKey: @"Target"];
	Unit *originalTarget = target;
    int completed = [[state objectForKey: @"CompletedRules"] intValue];
    int attempts = [[state objectForKey: @"RuleAttempts"] intValue];
	int actionsPerformed = [[state objectForKey: @"ActionsPerformed"] intValue];
	int inCombatNoAttack = [[state objectForKey: @"InCombatNoAttack"] intValue];
	NSMutableDictionary *rulesTried = [state objectForKey: @"RulesTried"];

	if ( rulesTried == nil ) {
		//	log(LOG_PROCEDURE, @"Creating dictionary to track our tried rules!");
		rulesTried = [[NSMutableDictionary dictionary] retain];
	}
    
	if ( [blacklistController isBlacklisted: target] ) {
		// Looks like they got blacklisted in the casting process
		[self finishCurrentProcedure: state];
		return;
	}
	

	// If this is a continuation of regen from a bot start durring regen
	if ([[self procedureInProgress] isEqualToString: RegenProcedure] ) {

		// Only do this if we currently have an eating or drinking buff
		if ([auraController unit: [playerController player] hasBuffNamed: @"Food"] || [auraController unit: [playerController player] hasBuffNamed: @"Drink"]) {
			BOOL eatClear = NO;
			// check health
			if ( [playerController health] == [playerController maxHealth] ) eatClear = YES;
			// no buff for eating anyways
			else if ( ![auraController unit: [playerController player] hasBuffNamed: @"Food"] ) eatClear = YES;
		
			BOOL drinkClear = NO;
			// check mana
			if ( [playerController mana] == [playerController maxMana] ) drinkClear = YES;
			// no buff for drinking anyways
			else if ( ![auraController unit: [playerController player] hasBuffNamed: @"Drink"] ) drinkClear = YES;

			// we're not done eating/drinking
			if ( !eatClear || !drinkClear ) {
				self.evaluationInProgress = @"Regen";
				[self finishCurrentProcedure: state];
				return;
			}
		}
	}

    // have we completed all the rules?
    int ruleCount = [procedure ruleCount];
    if ( !procedure /*|| completed >= ( ruleCount * 2 )*/ ) {
		[self finishCurrentProcedure: state];
		return;
    }
    
    // delay our next rule until we can cast
    if( [playerController isCasting] ) {
		
		// try to be smart about how long we wait
		float delayTime = [playerController castTimeRemaining]/2.0f;
		if(delayTime < RULE_EVAL_DELAY_LONG) delayTime = RULE_EVAL_DELAY_LONG;
		log(LOG_DEV, @"Player is casting, waiting %.2f to perform next rule.", delayTime);
		[self performSelector: _cmd withObject: state afterDelay: delayTime];
		return;
    }

	// We don't want to cast if our GCD is active!
	if ( [spellController isGCDActive] ) {
		log(LOG_DEV, @"GCD is active, trying again shortly...");
		[self performSelector: _cmd withObject: state afterDelay: RULE_EVAL_DELAY_SHORT];
		return;
	}

	// Check the mob if we're in combat and it's our target
	if ( [[self procedureInProgress] isEqualToString: CombatProcedure] ) {
		if ( ![self performProcedureMobCheck:target] ) {
			[combatController cancelAllCombat];
			[self finishCurrentProcedure: state];
			return;
		}
		
		[playerController faceToward: [target position]];
		[combatController stayWithUnit:target withType: TargetEnemy];
	}
	
    // have we exceeded our maximum attempts on this rule?
    if ( attempts > 3 ) {
		log(LOG_PROCEDURE, @"Exceeded maximum (3) attempts on action %d (%@). Skipping.", [[procedure ruleAtIndex: completed] actionID], [[spellController spellForID:[NSNumber numberWithInt:[[procedure ruleAtIndex: completed] actionID]]] name]);
		[self performSelector: _cmd withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
												 [state objectForKey: @"Procedure"],		@"Procedure",
												 [NSNumber numberWithInt: completed+1],		@"CompletedRules",
												 [NSNumber numberWithInt: inCombatNoAttack],		@"InCombatNoAttack",
												 target,						@"Target",  nil] afterDelay: RULE_EVAL_DELAY_SHORT];
		return;
    }

	Rule *rule = nil;
	int i = 0;
	BOOL matchFound = NO;
	BOOL wasResurrected = NO;
	BOOL wasFriend = NO;
	
	// priority system for combat
	if ( [[self procedureInProgress] isEqualToString: CombatProcedure] ) {

		NSArray *adds = nil;
		NSArray *friends = nil;
		
		for ( i = 0; i < ruleCount; i++ ) {
			rule = [procedure ruleAtIndex: i];
				
			log(LOG_RULE, @"Evaluating rule %@", rule);
				
			// make sure our rule hasn't continuously failed!
			NSString *triedRuleKey = [NSString stringWithFormat:@"%d_0x%qX", i, [target GUID]];
			NSNumber *tries = [rulesTried objectForKey:triedRuleKey];
			
			if ( tries ) {
				if ( [tries intValue] > 3 ){
					log(LOG_RULE, @"Rule %d failed after %@ attempts!", i, tries);
					continue;
				}
			}
				
			// then set the target to ourself
			if ( [rule target] == TargetSelf ){
				target = [playerController player];
				if ( [self evaluateRule: rule withTarget: target asTest: NO] ){
					// do something
					log(LOG_RULE, @"Match for %@ with target %@", rule, target);
					matchFound = YES;
					break;
				}
			}
				
			// no target
			else if ( [rule target] == TargetNone ){
				if ( [self evaluateRule: rule withTarget: target asTest: NO] ){
					// do something
					log(LOG_RULE, @"Match for %@", rule);
					matchFound = YES;
					break;
				}
			}
				
			// add
			// only check for an add if we don't have one already!
			else if ( [rule target] == TargetAdd ) {
				
				if (!adds) adds = [combatController allAdds];
				for ( target in adds ){
					if ( [self evaluateRule: rule withTarget: target asTest: NO] ){
						// do something
						log(LOG_RULE, @"Match for %@ with add %@", rule, target);
						matchFound = YES;
						break;
					}
				}
			}
				
			// pet
			else if ( [rule target] == TargetPet ){
				target = [playerController pet];
					
				if ( [self evaluateRule: rule withTarget: target asTest: NO] ){
					// do something
					log(LOG_RULE, @"Pet match for %@ %@", rule, target);
					matchFound = YES;
					break;
				}
			}

			// enemy
			else if ( [rule target] == TargetEnemy ) {
				target = originalTarget;
				
				if ([self evaluateRule: rule withTarget: target asTest: NO] ) {
					log(LOG_RULE, @"Enemy match for %@ %@", rule, target);
					matchFound = YES;
					break;
				}
			}

			// friends
			else if ( [rule target] == TargetFriend ) {
					 
				if (!friends) friends = [combatController friendlyUnits];

				for ( target in friends ) {
					
					// If we're in a combat procedure and our friend isn't in combat then fuk em
					if ( ![target isInCombat] ) continue;

					if ( [self evaluateRule: rule withTarget: target asTest: NO] ){
						// do something
						log(LOG_RULE, @"Friend match for %@ with unit %@", rule, target);
						matchFound = YES;
						break;
					}
				}
			}

			if ( matchFound ) break;
		}
	} else {

	// old-school for non-combat (just goes in order)
		
		log(LOG_DEV, @"Non combat search");
		
		float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
		float attackRange = ( theCombatProfile.attackRange > theCombatProfile.engageRange ) ? theCombatProfile.attackRange : theCombatProfile.engageRange;
		
		for ( i = completed; i < ruleCount; i++) {
			rule = [procedure ruleAtIndex: i];
			
			if( [self evaluateRule: rule withTarget: target asTest: NO] ) {
				log(LOG_DEV, @"Found match for non-combat with rule %@", rule);
				wasFriend = YES;
				matchFound = YES;
				break;
			}
			
			// Check For Friendlies in Patrolling
			if ([rule target] == TargetFriend && _includeFriendlyPatrol &&  [[self procedureInProgress] isEqualToString: PatrollingProcedure]) {
				NSArray *units = [combatController validUnitsWithFriendly:_includeFriendlyPatrol onlyHostilesInCombat:NO];
				for ( target in units ) {
					
					if ( ![target isValid] ) continue;
					
					if (![playerController isFriendlyWithFaction: [target factionTemplate]] ) continue;

					if ([[playerController position] verticalDistanceToPosition: [target position]] > vertOffset) continue;
					
					// range changes if the unit is friendly or not
					float distanceToTarget = [[playerController position] distanceToPosition:[target position]];
					float range = ([playerController isFriendlyWithFaction: [target factionTemplate]] ? theCombatProfile.healingRange : attackRange);
					if ( distanceToTarget > range ) continue;

					if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
						log(LOG_DEV, @"Found match for patrolling with rule %@", rule);
						matchFound = YES;
						wasFriend = YES;
						break;
					}
				}

				if ( matchFound ) break;
				
				// Raise the dead?
				if ( !matchFound && theCombatProfile.healingEnabled && _includeFriendlyPatrol) {
					NSMutableArray *units = [NSMutableArray array];
					[units addObjectsFromArray: [playersController allPlayers]];
					
					for ( target in units ){
						if ( ![target isPlayer] || ![target isDead] ) continue;

						if ( [blacklistController isBlacklisted: target] ) continue;

						if ( [[playerController position] distanceToPosition:[target position]] > theCombatProfile.healingRange ) continue;							
						
						if ([[playerController position] verticalDistanceToPosition: [target position]] > vertOffset) continue;
						
						// player: make sure they're not a ghost
						NSArray *auras = [auraController aurasForUnit: target idsOnly: YES];
						if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ) {
							continue;
						}
						
						if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
							log(LOG_DEV, @"Found match for resurrection in patrolling with rule %@", rule);
							matchFound = YES;
							wasResurrected = YES;
							break;
						}
					}

					if ( matchFound ) break;
				}
				
			}
			
		}
		
		completed = i;
	}
	
	// take the action here
	if ( matchFound && rule ) {
	
		if ( [rule target] == TargetNone || [rule target] == TargetSelf) {
			log(LOG_PROCEDURE, @"%@ %@", [combatController unitHealthBar:[playerController player]], [playerController player] );
			log(LOG_PROCEDURE, @"	%@", rule );
		} else {
			log(LOG_COMBAT, @"%@ %@", [combatController unitHealthBar:target], target );
			log(LOG_COMBAT, @"	%@", rule );
		}
		
		// send in pet if needed
		if ( [self.theBehavior usePet] && [playerController pet] && ![[playerController pet] isDead] && [rule target] == TargetEnemy )
			if ( [[self procedureInProgress] isEqualToString: PreCombatProcedure] || [[self procedureInProgress] isEqualToString: CombatProcedure] ) 
				[bindingsController executeBindingForKey:BindingPetAttack];
		
		if ( [rule resultType] > 0 ) {			
			int32_t actionID = [rule actionID];
			
			if ( actionID > 0 ) {
				BOOL canPerformAction = YES;
				// if we are using an item or macro, apply a mask to the item number
				switch([rule resultType]) {
					case ActionType_Item: 
						actionID = (USE_ITEM_MASK + actionID);
						break;
					case ActionType_Macro:
						actionID = (USE_MACRO_MASK + actionID);
						break;
					case ActionType_Spell:
						canPerformAction = ![spellController isSpellOnCooldown: actionID];
						break;
					default:
						break;
				}
				
				// lets do the action
				if ( canPerformAction ){
					
					// target if needed!
					if ( [rule target] == TargetEnemy ) {
						log(LOG_DEV, @"Enemy already targeted.");
					} else
					
					if ( [rule target] == TargetAdd ) {
						log(LOG_DEV, @"Targeting Add.");
//						[combatController stayWithUnit:target withType:[rule target]];
					} else

					// target yourself
					if ( [rule target] == TargetSelf ) {
						if ( [playerController targetID] != [[playerController player] GUID] ) {
							log(LOG_DEV, @"Targeting self.");
							[playerController targetGuid:[[playerController player] GUID]];
						}
					} else 

					if ( [rule target] == TargetFriend ) {
						self.castingUnit = target;
						if ( [playerController targetID] != [target GUID]) {
							log(LOG_DEV, @"Targeting friend.");
							[playerController targetGuid:[target GUID]];
						}
					}
					
					if ( [rule target] != TargetNone ) {
						self.castingUnit = target;
						if ( [playerController targetID] != [target GUID]) { 
							log(LOG_DEV, @"Targeting something else.");
							[playerController targetGuid:[target GUID]];
						}
					}
					
					// Let the target change set in (generally this shouldn't be needed, but I've noticed sometimes the target doesn't switch)
					usleep([controller refreshDelay]);
										
					// do it!
					int actionResult = [self performAction:actionID];
					log(LOG_DEV, @"Action %u taken with result: %d", actionID, actionResult);
					
					// error of some kind :/
					if ( actionResult != ErrNone ){
						log(LOG_DEV, @"Attempted to do %u on %@ %d %d times", actionID, target, attempts, completed);
						if ( originalTarget == target ) log(LOG_DEV, @"Same target");
						
						NSString *triedRuleKey = [NSString stringWithFormat:@"%d_0x%qX", i, [target GUID]];
						log(LOG_DEV, @"Looking for key %@", triedRuleKey);
						
						NSNumber *tries = [rulesTried objectForKey:triedRuleKey];
						
						if ( tries ){
							int t = [tries intValue];
							tries = [NSNumber numberWithInt:t+1];
						} else {
							tries = [NSNumber numberWithInt:1];
						}
						
						log(LOG_DEV, @"Setting tried %@ with value %@", triedRuleKey, tries);
						[rulesTried setObject:tries forKey:triedRuleKey];
					}
					// success!
					else {
						completed++;
						actionsPerformed++;
					}
				} else {
					log(LOG_PROCEDURE, @"Unable to perform action %d", actionID);
				}
			} else {
				log(LOG_PROCEDURE, @"No action to take");
			}
		} else {
			log(LOG_PROCEDURE, @"No result type");
		}
		
		// Set a delay for patrol to help mounting
		BOOL needToPause = NO;

//		if ( [[self procedureInProgress] isEqualToString: PatrollingProcedure]) {
//			needToPause = YES;
//		}
		// if we found a match, try again until we can't anymore!
		[self performSelector: _cmd
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
								[state objectForKey: @"Procedure"],				@"Procedure",
								[NSNumber numberWithInt: completed],		@"CompletedRules",
								[NSNumber numberWithInt: attempts+1],			@"RuleAttempts",			// but increment attempts
								rulesTried,										@"RulesTried",				// track how many times we've tried each rule
								[NSNumber numberWithInt:actionsPerformed],		@"ActionsPerformed",
								target,											@"Target", nil]
				   afterDelay: (needToPause ? 0.5f : 0.1f)];
		
		log(LOG_DEV, @"Rule executed, trying for more rules!");

		// If we resurected them lets give them a moment to repop before we assess them again
		if (wasResurrected && [playerController isFriendlyWithFaction: [target factionTemplate]] && [target isValid]) {

			log(LOG_DEV, @"Adding resurrection CD to %@", target);

			[blacklistController blacklistObject:target withReason:Reason_RecentlyResurrected];

			// Let's retarget ourselves so it doesn't look like we're in love
//			[playerController targetGuid:[[playerController player] GUID]];

		}
		// The idea is that this will improve decision making for healers and keep the bot from looking stupid
		if (wasFriend && [target isValid] && target != assistUnit && target != tankUnit &&
			[playerController isFriendlyWithFaction: [target factionTemplate]]
			) {

			// If they were a friendly then lets put them on the friend GCD so we don't double heal or buff.
			log(LOG_DEV, @"Adding friend GCD to %@", target);
			[blacklistController blacklistObject:target withReason:Reason_RecentlyHelpedFriend];

			// Let's retarget ourselves so it doesn't look like we're in love
//			[playerController targetGuid:[[playerController player] GUID]];

		}

		return;
	}
	
	// still in combat with people! But not able to cast! (probably b/c insufficient rage/mana/etc...) Keep trying while we're in combat!
	if ( [[self procedureInProgress] isEqualToString: CombatProcedure] && [[combatController combatList] count] > 0 && inCombatNoAttack < 75 ) {
		
		log(LOG_DEV, @"Still in combat... No Combat: %d", inCombatNoAttack);
		
		inCombatNoAttack++;
		
		BOOL validCombatUnit = NO;
		for ( Unit *unit in [combatController combatList] ){
			if ( ![blacklistController isBlacklisted:unit] ) validCombatUnit = YES;
			log(LOG_DEV, @" %@", unit);
		}
		
		if ( validCombatUnit ) {
			log(LOG_DEV, @"Valid unit to attack in the combat list yay!");
			[self performSelector: _cmd
					   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
									[state objectForKey: @"Procedure"],				@"Procedure",
									[NSNumber numberWithInt: attempts+1],			@"RuleAttempts",			// but increment attempts
									rulesTried,										@"RulesTried",				// track how many times we've tried each rule
									[NSNumber numberWithInt:actionsPerformed],		@"ActionsPerformed",
									[NSNumber numberWithInt: inCombatNoAttack],		@"InCombatNoAttack",
									nil,											@"Target", nil]
					   afterDelay: 0.1f];
			return;
		} else {
			log(LOG_PROCEDURE, @"Combat list units are blacklisted! Ignoring...");
		}
	}

	log(LOG_DEV, @"Done with Procedure!");

	[self finishCurrentProcedure: state];
}

- (BOOL)performProcedureMobCheck: (Unit*)target {
	// This is a pre cast check for targets.
	// returns true if the mob is good to go
	if (!target || target == nil) return NO;

	// Dismount if mounted, if we've gotten this far it should be safe to do so
	if ( [[playerController player] isMounted] ) [movementController dismount];
	
	// only do this for hostiles
	if ( ![playerController isHostileWithFaction: [target factionTemplate]] ) return YES;
	
	// Doube check so we don't wast casts
	if ( [target isDead] ) return NO;

	if ( !self.theBehavior.meleeCombat && [movementController isMoving]) {
		log(LOG_PROCEDURE, @"Stopping movement to cast on %@.", target);
		[movementController stopMovement];
	}

	return YES;
}

- (BOOL)performAction: (int32_t) actionID{
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	if ( !memory ) return NO;
	
	int barOffset = [bindingsController barOffsetForKey:BindingPrimaryHotkey];
	if ( barOffset == -1 ){
		log(LOG_ERROR, @"Unable to execute spells! Ahhhhh! Issue with bindings!");
		return NO;
	}
	
	UInt32 oldActionID = 0;
	UInt32 cooldown = [controller refreshDelay]*2;
	
	// save the old spell + write the new one
	[memory loadDataForObject: self atAddress: ([offsetController offset:@"HOTBAR_BASE_STATIC"] + barOffset) Buffer: (Byte *)&oldActionID BufLength: sizeof(oldActionID)];
	[memory saveDataForAddress: ([offsetController offset:@"HOTBAR_BASE_STATIC"] + barOffset) Buffer: (Byte *)&actionID BufLength: sizeof(actionID)];
	
	// write gibberish to the error location
	char string[3] = {'_', '_', '\0'};
	[[controller wowMemoryAccess] saveDataForAddress: [offsetController offset:@"LAST_RED_ERROR_MESSAGE"] Buffer: (Byte *)&string BufLength:sizeof(string)];
	
	// wow needs time to process the spell change
	usleep(cooldown);
	
	// send the key command
	[bindingsController executeBindingForKey:BindingPrimaryHotkey];
	_lastSpellCastGameTime = [playerController currentTime];
	
	// make sure it was a spell and not an item/macro
	if ( !((USE_ITEM_MASK & actionID) || (USE_MACRO_MASK & actionID)) ){
		_lastSpellCast = actionID;
	}
	else {
		_lastSpellCast = 0;
	}
	
	// wow needs time to process the spell change before we change it back
	usleep(cooldown*2);
	
	// then save our old action back
	[memory saveDataForAddress: ([offsetController offset:@"HOTBAR_BASE_STATIC"] + barOffset) Buffer: (Byte *)&oldActionID BufLength: sizeof(oldActionID)];
	
	// We don't want to check lastAttemptedActionID if it's not a spell!
	BOOL wasSpellCast = YES;
	if ( (USE_ITEM_MASK & actionID) || (USE_MACRO_MASK & actionID) ){
		wasSpellCast = NO;
	}
	
	// give WoW time to write to memory in case the spell didn't cast
	usleep(cooldown);
	
	_lastActionTime = [playerController currentTime];
	
	BOOL errorFound = NO;
	if ( ![[playerController lastErrorMessage] isEqualToString:@"__"] ){
		errorFound = YES;
	}
	
	// check for an error
	if ( ( wasSpellCast && [spellController lastAttemptedActionID] == actionID ) || errorFound ){
		
		int lastErrorMessage = [self errorValue:[playerController lastErrorMessage]];
		_lastActionErrorCode = lastErrorMessage;
		log(LOG_PROCEDURE, @"%@ %@ Spell %d didn't cast: %@", [combatController unitHealthBar: castingUnit], castingUnit,  actionID, [playerController lastErrorMessage] );
		
		// do something?
		if ( lastErrorMessage == ErrSpellNot_Ready){
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorSpellNotReady object: nil];
		}
		else if ( lastErrorMessage == ErrTargetNotInLOS ) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorTargetNotInLOS object: nil];
		}
		else if ( lastErrorMessage == ErrInvalidTarget ){
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorInvalidTarget object: nil];
		}
		else if ( lastErrorMessage == ErrTargetOutRange ){
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorTargetOutOfRange object: nil];
		}
		else if ( lastErrorMessage == ErrMorePowerfullSpellActive ){
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorMorePowerfullSpellActive object: nil];
		}
		else if ( lastErrorMessage == ErrCantAttackMounted || lastErrorMessage == ErrYouAreMounted ){
			if ( ![playerController isOnGround] ){
				[movementController dismount];
			}
		}
		// do we need to log out?
		else if ( lastErrorMessage == ErrInventoryFull ){
			if ( [logOutOnFullInventoryCheckbox state] )
				[self logOutWithMessage:@"Inventory full, closing game"];
		}
		else if ( lastErrorMessage == ErrTargetNotInFrnt || lastErrorMessage == ErrWrng_Way ) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorTargetNotInFront object: nil];
		}
		
		log(LOG_DEV, @"Action taken! Result: %d", lastErrorMessage);
		
		return lastErrorMessage;
	}
	
	log(LOG_DEV, @"Action taken successfully!");
	
	return ErrNone;
}

- (void)monitorRegen: (NSDate*)start{
	
	if ( [playerController isInCombat] ){
		log(LOG_FUNCTION, @"monitorRegen");
		[self evaluateSituation];
		return;
	}
	
	Unit *player = [playerController player];
	BOOL eatClear = NO, drinkClear = NO;
	
	// check health
	if ( [playerController health] == [playerController maxHealth] ) eatClear = YES;
	// no buff for eating anyways
	else if ( ![auraController unit: player hasBuffNamed: @"Food"] ) eatClear = YES;
	
	// check mana
	if ( [playerController mana] == [playerController maxMana] ) drinkClear = YES;
	// no buff for drinking anyways
	else if ( ![auraController unit: player hasBuffNamed: @"Drink"] ) drinkClear = YES;
	
	float timeSinceStart = [[NSDate date] timeIntervalSinceDate: start];
	
	// we're done eating/drinking! continue
	if ( eatClear && drinkClear ) {
		log(LOG_REGEN, @"Finished after %0.2f seconds", timeSinceStart);
		if ([[playerController player] isSitting]) [movementController stepForward];
		self.evaluationInProgress = nil;
		[self evaluateSituation];
		return;
	} else 
		// should we be done?
		if ( timeSinceStart > 30.0f ) {
			log(LOG_REGEN, @"Ran for 30, done, regen too long!?");
			self.evaluationInProgress = nil;
			[self evaluateSituation];
			return;
		}
	[self performSelector: _cmd withObject: start afterDelay: 1.0f];
}

#pragma mark -
#pragma mark Loot Helpers

- (void)resetLootScanIdleTimer {
	if ( !self.doLooting ) return;
	_lootScanIdleTimer = 0;
}

- (Mob*)mobToLoot {
	
	if ( !self.doLooting ) return nil;
	
	// if our loot list is empty scan for missed mobs
    if ( ![_mobsToLoot count] ) return nil;
	
	Mob *mobToLoot = nil;
	// sort the loot list by distance
	[_mobsToLoot sortUsingFunction: DistanceFromPositionCompare context: [playerController position]];
	
	// find a valid mob to loot
	for ( mobToLoot in _mobsToLoot ) {
		if ( mobToLoot && [mobToLoot isValid] ) {
			if ( ![blacklistController isBlacklisted:mobToLoot] ) return mobToLoot;
			else log(LOG_BLACKLIST, @"Found unit to loot but it's blacklisted! %@", mobToLoot);
		}
	}
	return nil;
}

- (BOOL)lootScan {

	if ( !self.doLooting ) return NO;
	
	if (self.unitToLoot || self.mobToSkin) return NO;
	
	log(LOG_DEV, @"Scanning for missed mobs to loot.");
	
	NSArray *mobs = [mobController mobsWithinDistance: self.gatherDistance MobIDs:nil position:[playerController position] aliveOnly:NO];
	
	for (Mob *mob in mobs) {
		
		if (_doSkinning && _doNinjaSkin && [mob isSkinnable] && mob != self.mobToSkin && ![_mobsToLoot containsObject: mob] && ![blacklistController isBlacklisted:mob]) {
			log(LOG_LOOT, @"[NinjaSkin] Adding %@ to skinning list.", mob);
			[_mobsToLoot addObject: mob];
			return YES;
		}
		
		if ([mob isLootable] && ![mob isSkinnable] && [mob isDead] && ![_mobsToLoot containsObject: mob] && ![blacklistController isBlacklisted:mob]) {
			log(LOG_LOOT, @"[LootScan] Adding %@ to loot list.", mob);
			[_mobsToLoot addObject: mob];
			return YES;
		}
	}
	return NO;
}

- (void)lootUnit: (WoWObject*) unit{

	// are we still in the air?  shit we can't loot yet!
	if ( ![[playerController player] isOnGround] ) {
		
		// once the macro failed, so dismount if we need to
		if ( [[playerController player] isMounted] ) [movementController dismount];
		
		NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[unit cachedGUID]];
		NSNumber *count = [_lootDismountCount objectForKey:guid];
		if ( !count ) count = [NSNumber numberWithInt:1]; else count = [NSNumber numberWithInt:[count intValue] + 1];
		[_lootDismountCount setObject:count forKey:guid];
		
		log(LOG_DEV, @"Player is still in the air, waiting to loot. Attempt %@", count);
		
		[self performSelector:@selector(lootUnit:) withObject:unit afterDelay:0.1f];
		return;
	}
	
	// player moving, wait to loot
	if ( [movementController isMoving] ){
		log(LOG_DEV, @"Still moving, waiting to loot");
		[self performSelector:@selector(lootUnit:) withObject:unit afterDelay:0.1f];
		return;
	}
	
	BOOL isNode = [unit isKindOfClass: [Node class]];

	self.wasLootWindowOpen	= NO;

	// looting?
	Position *playerPosition = [playerController position];
	float distanceToUnit = [playerController isOnGround] ? [playerPosition distanceToPosition2D: [unit position]] : [playerPosition distanceToPosition: [unit position]];
	[movementController turnTowardObject: unit];
		
	self.lastAttemptedUnitToLoot = unit;

	if ( ![unit isValid] || ( distanceToUnit > 5.0f ) ) {
		log(LOG_LOOT, @"Unit not within 5 yards (%d) or is invalid (%d), unable to loot - removing %@ from list", distanceToUnit > 5.0f, ![unit isValid], unit );
		// remove from list
		if ( ![unit isKindOfClass: [Node class]] ) [_mobsToLoot removeObject: unit];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return;
	}
			
	if ( [[playerController player] isMounted] ) [movementController dismount];

	self.lootStartTime = [NSDate date];
	self.unitToLoot = unit;
	self.mobToSkin = (Mob*)unit;

	[blacklistController incrementAttemptForObject:unit];
	
	if ( !isNode && _doSkinning) {
		
		if ( self.mobToSkin && [self.mobToSkin isSkinnable] ) {
			log(LOG_LOOT, @"Using Skin instead of loot : %@m", unit);
			[self skinToFinish];
			return;
		}
	}
	
	// Lets do this instead of the loot hotkey!
	[self interactWithMouseoverGUID: [unit GUID]];

	// If we do skinning and it may become skinnable
	if (!_doSkinning || ![self.mobToSkin isKindOfClass: [Mob class]] || ![self.mobToSkin isNPC])  self.mobToSkin = nil;


	// verify delays
	float delayTime = 1.5;
	if (isNode) delayTime = 4.5;
	
	log(LOG_LOOT, @"Looting : %@m", unit);
	
	// In the off chance that no items are actually looted
	[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: delayTime];
}

- (void)skinToFinish {
	self.evaluationInProgress = @"Loot";
	
	// Up to skinning 100, you can find out the highest level mob you can skin by: ((Skinning skill)/10)+10.
	// From skinning level 100 and up the formula is simply: (Skinning skill)/5.
	int canSkinUpToLevel = 0;
	if (_skinLevel <= 100) canSkinUpToLevel = (_skinLevel/10)+10; else canSkinUpToLevel = (_skinLevel/5);
	
	if ( canSkinUpToLevel >= [self.mobToSkin level] ) {
		_skinAttempt = 0;
		[self skinMob:self.mobToSkin];
		return;
	} else {
		log(LOG_LOOT, @"The mob is above your max %@ level (%d).", ((_doSkinning) ? @"skinning" : @"herbalism"), canSkinUpToLevel);
		[[NSNotificationCenter defaultCenter] postNotificationName: AllItemsLootedNotification object: [NSNumber numberWithInt:0]];
	}
	
}

// It actually takes 1.2 - 2.0 seconds for [mob isSkinnable] to change to the correct status, this makes me very sad as a human, seconds wasted!
- (void)skinMob: (Mob*)mob {
    float distanceToUnit = [[playerController position] distanceToPosition2D: [mob position]];
	
	// We tried for 2.0 seconds, lets bail
	if ( _skinAttempt++ > 20 ) {
		log(LOG_LOOT, @"[Skinning] Mob is not valid (%d), not skinnable (%d) or is too far away (%d)", ![mob isValid], ![mob isSkinnable], distanceToUnit > 5.0f );
		
		// We'll give this a blacklist
		[blacklistController blacklistObject: mob withReason:Reason_RecentlySkinned];
		
		[_mobsToLoot removeObject: mob];
		self.mobToSkin = nil;
		self.unitToLoot = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return;
	}
	
	// Set to null so our loot notifier realizes we shouldn't try to skin again :P
	self.mobToSkin = nil;
	self.skinStartTime = [NSDate date];
	
	// Not able to skin :/
	if( ![mob isValid] || ![mob isSkinnable] || distanceToUnit > 5.0f ) {
		log(LOG_LOOT, @"[Skinning] Mob is not valid (%d), not skinnable (%d) or is too far away (%d)", ![mob isValid], ![mob isSkinnable], distanceToUnit > 5.0f );
		
		// We'll give this a blacklist
		[blacklistController blacklistObject: mob withReason:Reason_RecentlySkinned];
		
		[_mobsToLoot removeObject: mob];
		
		self.mobToSkin = nil;
		self.unitToLoot = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return;
    }
	
	[controller setCurrentStatus: @"Bot: Skinning"];
	
	log(LOG_LOOT, @"Skinning!");
	
	// Lets interact w/the mob!
	[self interactWithMouseoverGUID: [mob GUID]];
	
	// In the off chance that no items are actually looted
	[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: 5.0f];
	
}

// Sometimes there isn't an item to loot!  So we'll use this to fire off the notification
- (void)verifyLootSuccess {
	self.evaluationInProgress = @"Loot";

	// Check if the player is casting still (herbalism/mining/skinning)
	if ( [playerController isCasting] ) {
		[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: 0.1f];
		return;
	}

	log(LOG_DEV, @"Verifying loot succes...");
	
	// Is the loot window stuck being open?
	if ( [lootController isLootWindowOpen] && _lootMacroAttempt < 3 ) {
		self.wasLootWindowOpen	= YES;
		log(LOG_LOOT, @"Loot window open? ZOMG lets close it!");
		_lootMacroAttempt++;
		[lootController acceptLoot];
		[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: 1.0f];
		return;
	} else 
	if ( _lootMacroAttempt >= 3 ) {
		log(LOG_LOOT, @"Attempted to loot %d times, moving on...", _lootMacroAttempt);
	}
	
	// fire off notification (sometimes needed if the mob only had $$, or the loot failed)
	log(LOG_DEV, @"Firing off loot success");

	[[NSNotificationCenter defaultCenter] postNotificationName: AllItemsLootedNotification object: [NSNumber numberWithInt:0]];
}

// This is called when all items have actually been looted (the loot window will NOT be open at this point)
- (void)itemsLooted: (NSNotification*)notification {
	if ( !self.isBotting ) return;

	BOOL wasNode = NO;
	
	// If this event fired, we don't need to verifyLootSuccess! We ONLY need verifyLootSuccess when a body has nothing to loot!
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(verifyLootSuccess) object: nil];

	// This lets us know that the LAST loot was just from us looting a corpse (vs. via skinning or herbalism)
	if ( self.unitToLoot ) {
		NSDate *currentTime = [NSDate date];
		
		int attempts = [blacklistController attemptsForObject:self.unitToLoot];
		
		// Unit was looted, remove from list!
		if ( [self.unitToLoot isKindOfClass: [Node class]] ){
			log(LOG_DEV, @"Node looted in %0.2f seconds after %d attempt%@", [currentTime timeIntervalSinceDate: self.lootStartTime], attempts, attempts == 1 ? @"" : @"s");
			// Allow the node to fade
			wasNode =YES;
		} else {
			log(LOG_DEV, @"Mob looted in %0.2f seconds after %d attempt%@. %d mobs to loot remain", [currentTime timeIntervalSinceDate: self.lootStartTime], attempts, attempts == 1 ? @"" : @"s", [_mobsToLoot count]);
		}
		
		// Loot success is firing even when we miss so I'll disable this here
		
		// clear the attempts since it was successful
//		[blacklistController clearAttemptsForObject:self.unitToLoot];
		
	}
	
	// Here from looting, but need to skin!
	if ( self.unitToLoot && self.mobToSkin ) {
		self.wasLootWindowOpen = NO;
		
		// Pause for a moment for the unit to become skinnable
		[self performSelector: @selector(skinToFinish) withObject: nil afterDelay: 1.0f];
		return;
	}

	// Here from skinning!
	else if ( self.mobToSkin ) {

		NSDate *currentTime = [NSDate date];

		log(LOG_LOOT, @"Skinning completed in %0.2f seconds", [currentTime timeIntervalSinceDate: self.skinStartTime]);
		
		// We'll give this a blacklist so we don't try to reskin due to ninja skin
		if (_doNinjaSkin) [blacklistController blacklistObject: self.mobToSkin withReason:Reason_RecentlySkinned];
		
		[_mobsToLoot removeObject: self.mobToSkin];
		self.mobToSkin = nil;
	}
	
	if ( self.unitToLoot ) {
		[_mobsToLoot removeObject: self.unitToLoot];
		self.unitToLoot = nil;
	}

	if (!self.unitToLoot && !self.mobToSkin) {
		// We're done!	
		NSDate *currentTime = [NSDate date];
		log(LOG_LOOT, @"All looting completed in %0.2f seconds", [currentTime timeIntervalSinceDate: self.lootStartTime]);
		
		// Reset our attempt variables!
		_lootMacroAttempt = 0;
		self.lastAttemptedUnitToLoot = nil;
	}

	float delay = 0.8;

	// If this was the last item in the list
	if ( ![_mobsToLoot count] && !wasNode) {
		
		// This is only a temp solution, but it also solves the bugged casting position after you have looted
//		[movementController stepForward];
		
		// reset the loot scanner!
		[self resetLootScanIdleTimer];
		
		// Since we stepped forward we can ignore the delay
//		delay = 0.1;
	}

	// Allow the lute to fade
	if (wasNode) delay = 0.6;

	self.wasLootWindowOpen = NO;
	self.evaluationInProgress = nil;
	
	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: delay];
}

// called when ONE item is looted
- (void)itemLooted: (NSNotification*)notification {
	
	if ( !self.isBotting ) return;
	
	self.evaluationInProgress = @"Loot";

	log(LOG_LOOT, @"Looted %@", [notification object]);
	
	// should we try to use the item?
	if ( _lootUseItems ){		
		int itemID = [[notification object] intValue];
		
		// crystallized <air|earth|fire|shadow|life|water> or mote of <air|earth|fire|life|mana|shadow|water>
		if ( ( itemID >= 37700 && itemID <= 37705 ) || ( itemID >= 22572 && itemID <= 22578 ) ) {
			log(LOG_DEV, @"Useable item looted, checking to see if we have > 10 of %d", itemID);			
			Item *item = [itemController itemForID:[notification object]];
			if ( item ) {
				int collectiveCount = [itemController collectiveCountForItem:item];
				if ( collectiveCount >= 10 ) {					
					log(LOG_LOOT, @"We have more than 10 of %@, using!", item);
					[self performAction:itemID + USE_ITEM_MASK];					
				}
			}
		}
	}
	
}

#pragma mark -
#pragma mark [Input] CombatController

- (void)unitEnteredCombat: (NSNotification*)notification {
	
	if (![self isBotting]) return;
	
	Unit *unit = [notification object];
	
	log(LOG_COMBAT, @"%@ %@ entered combat!", [combatController unitHealthBar:unit], unit);

	// If we're supposed to ignore combat while flying
	if (self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted]) {
		log(LOG_DEV, @"Ignoring combat with %@ since we're set to ignore combat while flying.", unit);
		return;
	}

	// start a combat procedure if we're not in one!
	if ( ![self.procedureInProgress isEqualToString: CombatProcedure] ) {
		
		self.evaluationInProgress = nil;
		
		// If it's a player attacking us lets attack the player!		
		if ( [unit isPlayer] ) {
			
			log(LOG_COMBAT, @"%@ %@ has jumped me, Targeting Player!", [combatController unitHealthBar:unit], unit);
			[self cancelCurrentProcedure];
			[self actOnUnit:unit];
			
			return;

		}

		log(LOG_COMBAT, @"Looks like an ambush, taking action!");
		[self cancelCurrentProcedure];
		[self actOnUnit:unit];
		return;

	} 
	
	// We are already in combat
	
	// If it's a player attacking us and we're on a mob then lets attack the player!
	if ( ( [[combatController castingUnit] isKindOfClass: [Mob class]] || [[combatController castingUnit] isPet] ) &&
			[combatController combatEnabled] &&
			!theCombatProfile.healingEnabled &&
			[unit isPlayer]) {
		log(LOG_COMBAT, @"%@ %@ has jumped me, Targeting Player!", [combatController unitHealthBar:unit], unit);

		[self cancelCurrentProcedure];
		[self actOnUnit:unit];
		return;
	}
	
	log(LOG_DEV, @"Already in combat procedure! Not acting on unit");
	return;
}

- (void)playerEnteringCombat: (NSNotification*)notification {
	if (![self isBotting]) return;
	[controller setCurrentStatus: @"Bot: Player in Combat"];
	log(LOG_COMBAT, @"Entering combat");
	self.evaluationInProgress = nil;
	[blacklistController clearAttempts];
	[self evaluateSituation];
}

- (void)playerLeavingCombat: (NSNotification*)notification {
	if(![self isBotting]) return;
	_didPreCombatProcedure = NO;

	[combatController cancelAllCombat];
	
	// Reset the loot scan idle timer
	[self resetLootScanIdleTimer];
	
	if ( [playerController isDead] ) return;

	log(LOG_COMBAT, @"Left combat! Current procedure: %@  Last executed: %@", self.procedureInProgress, _lastProcedureExecuted);
	return;
}

#pragma mark Combat

- (BOOL)includeFriendlyInCombat {	
	// should we include friendly units?
	
	if ( self.theCombatProfile.healingEnabled ) return YES;
	
	// if we have friendly spells in our Combat Behavior lets return true
	Procedure *procedure = [self.theBehavior procedureForKey: CombatProcedure];
    int i;
    for ( i = 0; i < [procedure ruleCount]; i++ ) {
		Rule *rule = [procedure ruleAtIndex: i];
		if ( [rule target] == TargetFriend ) return YES;
	}
	return NO;
}

- (BOOL)includeFriendlyInPatrol {	
	// should we include friendly units?
	
	// if we have friendly spells in our Patrol Behavior lets return true
	Procedure *procedure = [self.theBehavior procedureForKey: PatrollingProcedure];
    int i;
    for ( i = 0; i < [procedure ruleCount]; i++ ) {
		Rule *rule = [procedure ruleAtIndex: i];
		if ( [rule target] == TargetFriend ) return YES;
	}
	return NO;
}

- (BOOL)combatProcedureValidForUnit: (Unit*)unit {
	Procedure *procedure = [self.theBehavior procedureForKey: CombatProcedure];
    int ruleCount = [procedure ruleCount];
    if ( !procedure || ruleCount == 0 ) return NO;
	
	Rule *rule = nil;
	int i;
	BOOL matchFound = NO;
	for ( i = 0; i < ruleCount; i++ ) {
		rule = [procedure ruleAtIndex: i];
		log(LOG_RULE, @"Evaluating rule %@ for %@", rule, unit);
		if ( [self evaluateRule: rule withTarget: unit asTest: NO] ) {
			matchFound = YES;
			break;
		}
	}
	
	// Check to see if we should loot or do more combat
	BOOL doCombatProcedure = YES;
	
	if ( self.doLooting && [_mobsToLoot count] && ![playerController isInCombat]) {
		NSArray *inCombatUnits = [combatController validUnitsWithFriendly:_includeFriendly onlyHostilesInCombat:YES];
		
		// we can break out of this procedure early!
		if ( [inCombatUnits count] == 0 && !theCombatProfile.partyEnabled){
			doCombatProcedure = NO;
			log(LOG_LOOT, @"Skipping combat to loot (%d mobs left to loot).", [_mobsToLoot count]);
		} else 
			if (theCombatProfile.partyEnabled) {
				doCombatProcedure = NO;
				if ( [self isOnAssist] && assistUnit && [assistUnit isValid] && [assistUnit isInCombat]) doCombatProcedure = YES;
				if ( [self isTankUnit] && tankUnit && [tankUnit isValid] && [tankUnit isInCombat]) doCombatProcedure = YES;
			}
	}
	return matchFound && doCombatProcedure;
}

// this function will actually fire off our combat procedure if needed!
- (void)actOnUnit: (Unit*)unit {
	if ( ![self isBotting] ) return;
	
	// in theory we should never be here
	if ( [blacklistController isBlacklisted:unit] ) {
		float distance = [[playerController position] distanceToPosition2D: [unit position]];
		log(LOG_BLACKLIST, @"Ambushed by a blacklisted unit??  Ignoring %@ at %0.2f away", unit, distance);
		return;
	}
	
	log(LOG_DEV, @"Acting on unit %@", unit);
	
    if( ![[self procedureInProgress] isEqualToString: CombatProcedure] ) {
		
		// I notice that readyToAttack is set here, but not used?? hmmm (older revisions are the same)
		BOOL readyToAttack = NO;

		// check to see if we are supposed to be in melee range
		if ( self.theBehavior.meleeCombat) {
			float distance = [[playerController position] distanceToPosition2D: [unit position]];
			// not in range, continue moving!
			if ( distance > 5.0f ){
				log(LOG_DEV, @"Still %0.2f away, moving to %@", distance, unit);
				[movementController moveToObject:unit];		//andNotify:YES
			}
			// we're in range
			else{
				log(LOG_DEV, @"In range, attacking!");
				readyToAttack = YES;
				//[movementController stopMovement];
			}
		} else {
			UInt32 movementFlags = [playerController movementFlags];
			if ( movementFlags & MovementFlag_Forward || movementFlags & MovementFlag_Backward ){
				log(LOG_DEV, @"Don't need to be in melee, stopping movement");
				[movementController stopMovement];
			}
			readyToAttack = YES;
		}
		
		log(LOG_DEV, @"Starting combat procedure (current: %@) for target %@", [self procedureInProgress], unit);
		// cancel current procedure
		[self cancelCurrentProcedure];
		
		// start the combat procedure
		[self performProcedureWithState: [NSDictionary dictionaryWithObjectsAndKeys: 
										  CombatProcedure,		    @"Procedure",
										  [NSNumber numberWithInt: 0],	    @"CompletedRules",
										  unit,				    @"Target", nil]];
	}

	return;
}

- (void)unitDied: (NSNotification*)notification{

	Unit *unit = [notification object];
	
	log(LOG_DEV, @"Unit %@ killed %@", unit, [unit class]);
	
	[combatController cancelAllCombat];
	
	// unit dead, reset!
	if ( !self.evaluationInProgress ) [movementController resetMoveToObject];

	if ( [unit isNPC] ) log(LOG_DEV, @"NPC Died, flags: %d %d", [(Mob*)unit isTappedByMe], [(Mob*)unit isLootable] );
	
	if ( self.doLooting && [unit isNPC] ) {
		// Reset the loot scan idle timer
		[self resetLootScanIdleTimer];
		
		if ( ( [(Mob*)unit isTappedByMe] || [(Mob*)unit isLootable] ) && ![unit isPet] ) {
			
			// mob already in our list? in theory this should never happen (how could we kill a unit twice? lul)
			if ([_mobsToLoot containsObject: unit]) {
				log(LOG_LOOT, @"%@ was already in the loot list, removing first", unit);
				[_mobsToLoot removeObject: unit];
			}
			
			log(LOG_LOOT, @"Adding %@ to loot list.", unit);
			[_mobsToLoot addObject: (Mob*)unit];
		} else {
			log(LOG_LOOT, @"Mob %@ isn't lootable, ignoring", unit);
		}
	}
}

#pragma mark -
#pragma mark Party

-(BOOL)mountNowParty{

	if ( !followUnit ) return NO;
	if ( ![followUnit isValid] ) return NO;

	// some error checking
	if ( _mountAttempt > 8 ) {
		float timeUntilRetry = 5.0f - (-1.0f * [_mountLastAttempt timeIntervalSinceNow]);
		
		if ( timeUntilRetry > 0.0f ) {
			log(LOG_MOUNT, @"Will not mount for another %0.2f seconds", timeUntilRetry );
			return NO;
		} else {
			_mountAttempt = 0;
		}
	}
	
	_mountAttempt++;
	
	int theMountType = 1;	// ground
	if ([followUnit isFlyingMounted] ) theMountType = 2;		// air
	
	
	Spell *mount = [spellController mountSpell:theMountType andFast:YES];
	
	// record our last attempt
	[_mountLastAttempt release]; _mountLastAttempt = nil;
	_mountLastAttempt = [[NSDate date] retain];
	
	if ( mount != nil ) {
		
		// stop moving if we need to!
		if ([movementController isMoving]) {
			[movementController stopMovement];
			usleep(100000);
		}
		// Time to cast!
		int errID = [self performAction:[[mount ID] intValue]];
		if ( errID == ErrNone ){				
			log(LOG_MOUNT, @"Mounting started! No errors!");
			_mountAttempt = 0;
			usleep(1800000);
		} else {
			log(LOG_MOUNT, @"Mounting failed! Error: %d", errID);
		}				
		return YES;
	} else {			
		log(LOG_PARTY, @"No mounts found! PG will try to load them, you can do it manually on your spells tab 'Load All'");
		
		// should we load any mounts
		if ( [playerController mounts] > 0 && [spellController mountsLoaded] == 0 ) {
			log(LOG_MOUNT, @"Attempting to load mounts...");
			[spellController reloadPlayerSpells];				
		}
	}
	
	return NO;
}

// Records the current step of your follow target
-(void)followStepsRecord {

	if ( !followUnit ) return;

	// If the unit is out of sight
	if ( ![followUnit isValid]) return;
	
	Position *positionFollowUnit = [followUnit position];
	float distance = [[[playerController player] position] distanceToPosition: positionFollowUnit];

	if ( distance <=  theCombatProfile.yardsBehindTargetStop ) return;

	log(LOG_DEV, @"[Follow] Adding waypoint: %@", positionFollowUnit);
	// If we already have a list of steps
	if ([_followSteps count]) {
		Position *lastStepped = [_followSteps objectAtIndex: ([_followSteps count]-1)];
		if (lastStepped == positionFollowUnit) return;
		
		float distanceMoved = [lastStepped distanceToPosition: positionFollowUnit];
		
		// Should add all the step points we can... they get removed based on distance
		if (distanceMoved > 1.0f) [_followSteps addObject: positionFollowUnit];
//		if (lastStepped != positionFollowUnit) [_followSteps addObject: positionFollowUnit];
	} else {
	// No list yet so just add it
		[_followSteps addObject: positionFollowUnit];
	}
}

-(void)followStepsClear {
	if ([_followSteps count]) [_followSteps removeAllObjects];
}

// Find someone to follow
-(BOOL)findFollowUnit {
	// If it's a new target then we need to clear the steps
	[self followStepsClear];

	Player *followTarget = nil;
	float distance = 0.0;

	// Look for the actual follow unit
	if (theCombatProfile.followUnitGUID > 0x0) {
		followTarget = [playersController playerWithGUID:theCombatProfile.followUnitGUID];
		if ( followTarget ) {
			if ( [followTarget isValid] ) {
				distance = [[[playerController player] position] distanceToPosition: [followTarget position]];
				if (distance < INFINITY) {
					self.followUnit = followTarget;
					log(LOG_PARTY, @"[Follow] Unit found!");
					return YES;
				}
			}
		}
	}

	// Look for the assist unit
	if (theCombatProfile.assistUnit && theCombatProfile.assistUnitGUID > 0x0) {
		followTarget = [playersController playerWithGUID:theCombatProfile.assistUnitGUID];
		if (followTarget) {
			if ( [followTarget isValid] ) {
				distance = [[[playerController player] position] distanceToPosition: [followTarget position]];
				if (distance < INFINITY) {
					self.followUnit = followTarget;
					log(LOG_PARTY, @"[Follow] Unit not found, following the Assist Unit!");
					return YES;
				}
			}
		}
	}
		
	// Look for the tank
	if (theCombatProfile.tankUnit && theCombatProfile.tankUnitGUID > 0x0) {
		followTarget = [playersController playerWithGUID:theCombatProfile.tankUnitGUID];
		if (followTarget) {
			if ( [followTarget isValid] ) {
				distance = [[[playerController player] position] distanceToPosition: [followTarget position]];
				if (distance < INFINITY) {
					self.followUnit = followTarget;
					log(LOG_PARTY, @"[Follow] Unit not found, following the Tank!");
					return YES;
				}
			}
		}
	}

	log(LOG_DEV, @"[Follow] No target found to follow!");
	return NO;
}

-(BOOL)followMountCheck {
	
	if ( !theCombatProfile.mountEnabled ) return NO;
	
	if ( !followUnit) return NO;
	
	if ( ![followUnit isValid]) return NO;

	
	// Mount if needed
	if ( [followUnit isMounted] && ![[playerController player] isMounted] &&
		![[playerController player] isSwimming] && ![playerController isInCombat] ){
		if ( [self mountNowParty] ) {
			log(LOG_PARTY, @"Leader mounted so am I...");
			[self performSelector: _cmd withObject: nil afterDelay: 1.0f];
			return YES;
		}
	}
	
	// Get off the ground if leader is in the air
	if ( ![followUnit isOnGround] && [[playerController player] isFlyingMounted] ) [self jumpIfAirMountOnGround];
	
	// Dismount if we're not on an air mount we're supposed to be!
	if ( [followUnit isFlyingMounted] && ![[playerController player] isFlyingMounted] && [[playerController player] isMounted] ) {
		log(LOG_PARTY, @"[Follow] Looks like I'm supposed to be on an air mount, dismounting.");
		[movementController dismount];
		return YES;
	}
	
	Position *positionFollowUnit = [followUnit position];
	float distance = [[[playerController player] position] distanceToPosition: positionFollowUnit];
	
	// If we're on the ground and the leader isn't mounted then dismount
	if ( distance <= theCombatProfile.followDistanceToMove && ![followUnit isMounted] && 
			[[playerController player] isMounted] && [[playerController player] isOnGround] ) {
		log(LOG_PARTY, @"[Follow] Leader dismounted, so am I.");
		[movementController dismount];
		return YES;
	}
	
	// If we're technically in the air, but still close to the dismoutned leader, dismount
	if ( distance < 15.0f && ![followUnit isMounted] &&  [[playerController player] isMounted] && [followUnit isOnGround]) {
		log(LOG_PARTY, @"[Follow] Leader dismounted, so am I.");
		[movementController dismount];
		return YES;
	}
	return NO;
}

// Determines whether or not you should be on assist, also sets the assistUnit.
-(BOOL)isOnAssist {

	if ( !theCombatProfile.partyEnabled || !theCombatProfile.assistUnit || theCombatProfile.assistUnitGUID <= 0x0 ) return NO;

	// If we're in suspend mode and theres a route lets get to grindin
	if ( self.theRouteSet && [self partyFollowSuspended] ) return NO;

	// If we've already found an assist and it's valid just return true
	if ( assistUnit && [assistUnit isValid] ) return YES;
	
	
	// Let's see if we can set the assistUnit
	Player *assistPlayer = [playersController playerWithGUID: theCombatProfile.assistUnitGUID];
	if ( assistPlayer && [assistPlayer isValid] ) {
		self.assistUnit = assistPlayer;
		[playerController faceToward: [assistPlayer position]];
		log(LOG_PARTY, @"Found the player I'm assisting.");
		return YES;
	} else {
		log(LOG_PARTY, @"Assist player not found! GUID: 0x%qX", theCombatProfile.assistUnitGUID);
		self.assistUnit = nil;

		// Return no if we have a route we can do
		if ( self.theRouteSet ) return NO;
		
	}

	return YES;
}

// Determines whether or not we have a tank, also sets the tankUnit.
-(BOOL)isTankUnit {
	
	if ( !theCombatProfile.partyEnabled || !theCombatProfile.tankUnit || theCombatProfile.tankUnitGUID <= 0x0 ) return NO;
	
	// If we're in suspend mode and theres a route lets get to grindin
	if ( theRouteSet && [self partyFollowSuspended] ) return NO;
	
	// If we've already found an tank and it's valid just return true
	if ( tankUnit && [tankUnit isValid] ) return YES;
	
	// Let's see if we can set the tankUnit
	Player *tankPlayer = [playersController playerWithGUID: theCombatProfile.tankUnitGUID];
	if ( tankPlayer && [tankPlayer isValid] ) {
		self.tankUnit = tankPlayer;
		log(LOG_PARTY, @"Found the tank.");
		return YES;
	} else {
		log(LOG_PARTY, @"Tank not found! GUID: 0x%qX", theCombatProfile.tankUnitGUID);
		self.tankUnit = nil;
	}

	return NO;
}

- (void)jumpIfAirMountOnGround {
	// Is the player air mounted, and on the ground?  Me no likey - lets jump!
	UInt32 movementFlags = [playerController movementFlags];
	if ( (movementFlags & 0x1000000) == 0x1000000 && (movementFlags & 0x3000000) != 0x3000000 ){
		if ( _jumpAttempt == 0 && ![controller isWoWChatBoxOpen] ){
			usleep(200000);
			log(LOG_MOVEMENT, @"Player on ground while air mounted, jumping!");
			[movementController jump];
			usleep(10000);
		}
		if ( _jumpAttempt++ > 3 )	_jumpAttempt = 0;
	}
}

#pragma mark -
#pragma mark [Input] MovementController

- (void)reachedObject: (NSNotification*)notification {

	// Returning from follow mode
	if ( [movementController isFollowing] ) {
		log(LOG_DEV, @"Reached object called for Follow");
		movementController.isFollowing = NO;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return;
	}
	
	WoWObject *object = [notification object];

	log(LOG_DEV, @"Reached object called for %@", object);

	// if it's a player, or a non-dead NPC, we must be doing melee combat
	if ( [object isPlayer] || ([object isNPC] && ![(Unit*)object isDead]) )log(LOG_COMBAT, @"Reached melee range with %@", object);
	
	// Back to evaluation
	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
	
	return;
}

// should the notification be here?  or in movementcontroller?
- (void)finishedRoute: (Route*)route {
    if( ![self isBotting]) return;
    if ( !self.theRouteSet ) return;
	if ( route != [self.theRouteSet routeForKey: CorpseRunRoute] ) return;
	log(LOG_GHOST, @"Finished Corpse Run. Begin search for body...");
	[controller setCurrentStatus: @"Bot: Searching for body..."];
}

#pragma mark -
#pragma mark Evaluation Tasks
- (BOOL)evaluateForPVP {
	if ( !self.isPvPing ) return NO;
	
	log(LOG_EVALUATE, @"Evaluating for PvP");

	// Check for preparation buff
	if ( self.isPvPing && [self.pvpBehavior preparationDelay] && [auraController unit: [playerController player] hasAura: PreparationSpellID] ){		
		[controller setCurrentStatus: @"PvP: Waiting for preparation buff to fade..."];
		[movementController stopMovement];	
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
		return YES;
	}
	
	// wait for boat to settle!
	if ( self.isPvPing && _strandDelay ){
		[controller setCurrentStatus: @"PvP: Waiting for boat to arrive..."];
		[movementController stopMovement];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
		return YES;
	}
	
	// walk off boat
	if ( self.isPvPing && [playerController zone] == ZoneStrandOfTheAncients && [playerController isOnBoatInStrand] ){
		[controller setCurrentStatus: @"PvP: Walking off the boat..."];
		BOOL onLeftBoat = [playerController isOnLeftBoatInStrand];
		Position *pos = nil;
		
		if ( onLeftBoat ){
			log(LOG_PVP, @"Moving off of left boat!");
			pos = [Position positionWithX:6.23f Y:20.94f Z:4.97f];
		} else {
			log(LOG_PVP, @"Moving off of right boat!");
			pos = [Position positionWithX:5.88f Y:-25.1f Z:5.3f];
		}
		
		[movementController moveToPosition:pos];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.5f];
		return YES;
	}
	return NO;
}

-(BOOL)evaluateForGhost {
	
	if ( ![playerController isGhost]) return NO;
	
	if (![self isBotting]) return NO;
	
	log(LOG_EVALUATE, @"Evaluating for Ghost");

	if ( ![self evaluationInProgress] ) {
		log(LOG_GHOST, @"Player is dead.");
		self.evaluationInProgress = @"Ghost";
		[controller setCurrentStatus: @"Bot: Player is Dead"];
	}

	if( ![playerController corpsePosition] ) {
		log(LOG_DEV, @"Still not near the corpse.");
		if ( ![movementController isMoving] ) [movementController resumeMovement];
		return NO;
	}
	
	Position *playerPosition = [playerController position];
	Position *corpsePosition = [playerController corpsePosition];
	float distanceToCorpse = [playerPosition distanceToPosition: corpsePosition];
	
	// If we see the corpse and it's close enough, let's move to it
	if ( _ghostDance == 0 && distanceToCorpse > 6.0f && distanceToCorpse < 40.0f) {
		[movementController moveToPosition: corpsePosition];
		log(LOG_GHOST, @"Moving to the corpse now.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.3f];
		return YES;
	} else
	// If we're not close to the corpse let's keep moving
	if( _ghostDance == 0 && distanceToCorpse > 6.0 ) {
		log(LOG_DEV, @"Still not near the corpse.");
		if ( ![movementController isMoving] ) [movementController resumeMovement];
		return NO;
	}
	

	// we found our corpse
	[controller setCurrentStatus: @"Bot: Waiting to Resurrect"];
	[movementController stopMovement];

	if ( theCombatProfile.checkForCampers ) {
		log(LOG_GHOST, @"Checking for campers.");
		// Check for Campers
		float campingRange = 100.0f;
		BOOL nearbyCampers = [playersController playerWithinRangeOfUnit: campingRange Unit:[playerController player] includeFriendly:NO includeHostile:YES];
		if ( theCombatProfile.checkForCampers && nearbyCampers ) {
			log(LOG_GHOST, @"Looks like I'm being camped, going to hold of on resurrecting.");
			[self performSelector: _cmd withObject: nil afterDelay: 5.0f];
			return YES;
		}
		log(LOG_GHOST, @"No campers.");
	}


	if (_ghostDance <= 3) {
		NSMutableArray *mobs = [NSMutableArray array];
		[mobs addObjectsFromArray: [mobController mobsWithinDistance: 20.0f MobIDs:nil position:[[playerController player]position] aliveOnly:YES]];
		// Do a little dance to make sure we're clear of mobs
		if ([mobs count]) {
			log(LOG_GHOST, @"Mobs near the corpse, finding a safe spot.");
			[mobs sortUsingFunction: DistanceFromPositionCompare context: playerPosition];
			Unit *mob = nil;
			for ( mob in mobs ) {
				// This is very basic, but it's a good place to start =]
				log(LOG_DEV, @"Face and Reverse...");

				// Face the target
				[playerController faceToward: [mob position]];
				usleep(500000);
				[movementController moveBackwardStart];
				usleep(1600000);
				[movementController moveBackwardStop];
				_ghostDance++;
				[self performSelector: _cmd withObject: nil afterDelay: 0.1f];
				return YES;
			}
		}
	}
	
	// Ghost was dancin a lil too much
	if ( _ghostDance > 3 && distanceToCorpse > 26.0 ) {
		log(LOG_GHOST, @"Ghost dance didnt help, moving back to the corpse.");
		[movementController moveToPosition: corpsePosition];
		[self performSelector: _cmd withObject: nil afterDelay: 0.3f];
		return YES;
	}
	
	log(LOG_DEV, @"Clicking the Resurrect button....");

	// set our next-revive wait timer
	if (!_reviveAttempt) _reviveAttempt = 1;
		else _reviveAttempt = _reviveAttempt*2;

	[macroController useMacroOrSendCmd:@"Resurrect"];	 // get corpse
	if ( _reviveAttempt > 15 ) _reviveAttempt = 15;
	
	log(LOG_GHOST, @"Waiting %d seconds to resurrect.", _reviveAttempt);
	[self performSelector: _cmd withObject: nil afterDelay: _reviveAttempt];
	return YES;
}

- (BOOL)evaluateForParty {

	// Return no if this isn't turned on
	if ( !theCombatProfile.partyEnabled || !theCombatProfile.followUnit ) return NO;
	
	// If we've recieved a chat command to wait then we'll skip this
	if (self.partyFollowSuspended) return NO;

	// Skip this if we are already in evaluation
	if ( [self evaluationInProgress] ) return NO;

	// Skip this if we still have steps to follow
	if ( [_followSteps count] ) return NO;

	log(LOG_EVALUATE, @"Evaluating for Party");

	// Find someone to follow if we've lost our target and there are no more steps.
	if ( !self.followUnit ) if ( ![self findFollowUnit] ) return NO;

	// Validate the current unit
	if ( ![followUnit isValid]) {
		// Keep goin just a lil in case you need a zone in
//		[movementController moveForwardStart];
//		usleep(1500000);
//		[movementController moveForwardStop];
		self.evaluationInProgress = nil;
		self.followUnit = nil;
		_stepAttempts=0;
		// Help restart after zone in?
//		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 5.0f];
		return NO;
	}
	
	return NO;
}

- (BOOL)evaluateForFollow {

	// If this has not been set, or it has been unset
	if ( !self.followUnit ) return NO;
	
	// If we're doing something, lets record the steps of our follow target
	if ( [self evaluationInProgress] && ![[self evaluationInProgress] isEqualToString: @"Follow"] ) {
		// record their steps
		[self followStepsRecord];
		log(LOG_DEV, @"Skipping Follow because we're evaluating for something else.");
		return NO;
	}

	// If we're following, lets record the steps of our follow target
	if ( [movementController isFollowing] ) {
		// record their steps
		[self followStepsRecord];
		log(LOG_DEV, @"Skipping Follow because we're already moving.");
		return NO;
	}

	log(LOG_EVALUATE, @"Evaluating for Follow");

	// If we need to mount lets return
	if ( [self followMountCheck] ) {
		self.evaluationInProgress = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return YES;
	}
	
	Position *positionFollowUnit = nil;
	float distance = 0.0;
	
	// If we can still see our follow unit
	if ([followUnit isValid]) {
		
		positionFollowUnit = [followUnit position];
		distance = [[[playerController player] position] distanceToPosition: positionFollowUnit];
		
		// We're not out of range and not returning from follow
		if ( distance <=  theCombatProfile.followDistanceToMove && ![self evaluationInProgress] ) {
			log(LOG_DEV, @"Follow target not out of range.");
			self.evaluationInProgress = nil;			
			return NO;
		}
		
		// If we've been following and are close enough to stop
		if ( [self evaluationInProgress] && distance <=  theCombatProfile.yardsBehindTargetStart ) {
			log(LOG_DEV, @"Close enough to stop!");
			[controller setCurrentStatus: @"Bot: Enabled"];

			if ( [movementController isMoving] ) [movementController stopMovement];
			
			[playerController faceToward: [followUnit position]];
			self.evaluationInProgress = nil;

			[self followStepsClear];
			_stepAttempts=0;
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.3f];
			return YES;
		}
	}
	
	/*
	 * If we've made it this far then we need to follow
	 */
	
	// Record targets current step
	[self followStepsRecord];
	
	float waypointSpacing = [playerController speedMax] / 2.0f;
	
	Position *positionToMove = nil;
	float distanceToWaypoint = 0.0;
	
	NSEnumerator *enumerator = [_followSteps objectEnumerator];
	id thisWaypoint;
	Position *playerPosition = [[playerController player] position];
	
	// Use a loop in case we need to invalidate the 1st waypoint n go to the next
	while ((thisWaypoint = [enumerator nextObject])) {
		
		distanceToWaypoint = [playerPosition distanceToPosition: thisWaypoint];
		
		// If this point is less than 1 step lets remove it
		if (distanceToWaypoint <= waypointSpacing) {
			[_badWaypoints addObject: thisWaypoint];
			continue;
		}
		
		// Record the current position so we can compare it against the next point in the loop
		positionToMove = thisWaypoint;
		break;
	}
	
	// Toss out the bad waypoints that we found
	if ([_badWaypoints count]) {
		
		enumerator = [_badWaypoints objectEnumerator];
		
		// Loop through the bad ones and remove them from the steps
		while ((thisWaypoint = [enumerator nextObject])) {
			log(LOG_DEV, @"[Follow] Removing bad waypoint: %@", thisWaypoint);
			[_followSteps removeObject: thisWaypoint];
		}
		
		[_badWaypoints removeAllObjects];
		
	}
	
	// Increment the attempt counter
	if (_lastAttemptedStep == positionToMove) _stepAttempts++; else _stepAttempts=0;
	
	// If we've already tried this position once and it's close by, let's remove it
	if (_stepAttempts > 0 && distanceToWaypoint < (waypointSpacing*1.1f) ) {
		log(LOG_DEV, @"Made too many step attempts, removing position");
		[_followSteps removeObject: positionToMove];
	}
	
	// Check to see if we're getting close enough to do random stop distance
	if ( [followUnit isValid] && positionToMove) {
		float distancePositionToFollowUnit = [positionFollowUnit distanceToPosition: positionToMove];
		float distanceBotToFollowUnit = [positionFollowUnit distanceToPosition: [[playerController player] position]];
		
		if ( distancePositionToFollowUnit <= theCombatProfile.yardsBehindTargetStop && distanceBotToFollowUnit < (waypointSpacing+theCombatProfile.yardsBehindTargetStop)) {
			log(LOG_DEV, @"Close enough to set a random stopping position.");
			float start = theCombatProfile.yardsBehindTargetStart;
			float stop = theCombatProfile.yardsBehindTargetStop;
			float randomDistance = SSRandomFloatBetween( start, stop );
			positionToMove = [positionFollowUnit positionAtDistance:randomDistance withDestination: [[playerController player] position]];
			if ([_followSteps count]) [_followSteps removeAllObjects];
		}
	}
	
	if ( ![[self evaluationInProgress] isEqualToString: @"Follow"] ) {
		distance = [[[playerController player] position] distanceToPosition: positionFollowUnit];
		[controller setCurrentStatus: @"Bot: Following"];
		self.evaluationInProgress = @"Follow";
		log(LOG_PARTY, @"Follow Target is %0.2f away, following.", distance);
	}	
	
	// If we're out of waypoints, but the unit is in range
	if (!positionToMove) {
		if ( [followUnit isValid] ) {
			float distanceBotToFollowUnit = [positionFollowUnit distanceToPosition: [[playerController player] position]];
			
			if ( distanceBotToFollowUnit > theCombatProfile.yardsBehindTargetStart ) {
				float start = theCombatProfile.yardsBehindTargetStart;
				float stop = theCombatProfile.yardsBehindTargetStop;
				float randomDistance = SSRandomFloatBetween( start, stop );
				positionToMove = [positionFollowUnit positionAtDistance:randomDistance withDestination: [[playerController player] position]];
				[self followStepsClear];
				self.evaluationInProgress = @"Follow";
				log(LOG_DEV, @"Out of footsteps, but close enough to set a random stopping position.");
			} else {
				if ([[self evaluationInProgress] isEqualToString: @"Follow"]) [controller setCurrentStatus: @"Bot: Enabled"];
				log(LOG_DEV, @"Out of footsteps, but close to my follow unit.");
				[movementController stopMovement];
				[playerController faceToward: [followUnit position]];
				self.evaluationInProgress = nil;
				movementController.isFollowing = NO;
				[self followStepsClear];
				_stepAttempts=0;
				[self evaluateSituation];
				return YES;
			}
		} else {
			log(LOG_PARTY, @"Out of footsteps and I can't see my follow unit.");
			if ([[self evaluationInProgress] isEqualToString: @"Follow"]) [controller setCurrentStatus: @"Bot: Enabled"];
			[movementController stopMovement];
			[playerController faceToward: [followUnit position]];
			self.evaluationInProgress = nil;
			movementController.isFollowing = NO;
			_stepAttempts=0;
			[self followStepsClear];
			[self evaluateSituation];
			return NO;
		}
	}

	distanceToWaypoint = [[[playerController player] position] distanceToPosition: positionToMove];
/*
	// If our next recorded step is larger than normal (perhaps we just started and the unit is far off).
	if (distanceToWaypoint > waypointSpacing ) {
		// Let's pass a normal sized stop on to the movementController
//		positionToMove = [positionToMove positionAtDistance:waypointSpacing withDestination: [[playerController player] position]];
		positionToMove = [[[playerController player] position] positionAtDistance:waypointSpacing withDestination: positionToMove];

		distanceToWaypoint = [[[playerController player] position] distanceToPosition: positionToMove];
		log(LOG_EVALUATE, @"Next waypoint is far off, fabricating a closer one.");
	}
*/
	int stepsLeft = [_followSteps count];
	log(LOG_DEV, @"Target is %0.2f away, following. (%d steps left, %d attempts, wp distance: %0.2f, stride: %0.2f) ", distance, stepsLeft, _stepAttempts, distanceToWaypoint, waypointSpacing);

	_lastAttemptedStep = positionToMove;
	self.evaluationInProgress = @"Follow";
	movementController.isFollowing = YES;
	[movementController  moveToPosition:positionToMove];

	return YES;
}

- (BOOL)evaluateForCombatContinuation {

	if (self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted]) return NO;
	
    if ( ![combatController inCombat] && ![playerController isInCombat]) return NO;

	log(LOG_EVALUATE, @"Evaluating for Combat Continuation");

	// Let's try just usin the player controller to match n see if this gives any better results
//    if (![playerController isInCombat] && (!theCombatProfile.partyEnabled || [self partyFollowSuspended] ) ) {
		// If we're actually not in combat and not in a party lets reset the combat table as there is no combat 'contination'
//		[combatController resetAllCombat];
//		return NO;
//	}
	
	Unit *bestUnit = [combatController findUnitWithFriendly:_includeFriendly onlyHostilesInCombat:YES];

	if ( !bestUnit ) {
		if ( [combatController inCombat] ) [combatController resetAllCombat];
		return NO;
	}

	log(LOG_DEV, @"checking %@ for validity", bestUnit);

	if ( [self combatProcedureValidForUnit:bestUnit] ) {
		log(LOG_DEV, @"[Combat Continuation] Found %@ to act on!", bestUnit);
		[self actOnUnit:bestUnit];
		[movementController stopMovement];
		return YES;
	}

	return NO;
}

- (BOOL)evaluateForCombatStart {
	
	// Skip this if we are already in evaluation
	if ( [self evaluationInProgress] ) return NO;

	if ( ![combatController combatEnabled] && !theCombatProfile.healingEnabled ) {
//		self.preCombatUnit = nil;
		return NO;
	}
		
	// If we're supposed to ignore combat while flying lets return false
	if (self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted]) return NO;
	
	// If we're not a healer, not on assist and set to only attack when attacked then lets return false.
	if ( !theCombatProfile.healingEnabled && !theCombatProfile.assistUnit && theCombatProfile.onlyRespond) return NO;

	// If we're supposed to be following then follow!
	if ( ![self partyFollowSuspended] && theCombatProfile.partyEnabled && theCombatProfile.followUnit && [followUnit isValid] && [followUnit isMounted] ) return NO;
		
	log(LOG_EVALUATE, @"Evaluating for Combat Start");

	Position *playerPosition = [playerController position];

	// Look for a new target
	Unit *unitToActOn  = [combatController findUnitWithFriendly:_includeFriendly onlyHostilesInCombat:NO];
	if ( unitToActOn && [unitToActOn isValid] ) {
		float unitToActOnDist  = unitToActOn ? [[unitToActOn position] distanceToPosition: playerPosition] : INFINITY;
		if ( unitToActOnDist < INFINITY && [self combatProcedureValidForUnit:unitToActOn] ) {
			log(LOG_DEV, @"[Combat Start] Valid unit to act on: %@", unitToActOn);
			// hostile only
			if ( [playerController isHostileWithFaction: [unitToActOn factionTemplate]] ) {	
				// should we do pre-combat?
				if ( ![combatController inCombat] && !_didPreCombatProcedure ) {				
					_didPreCombatProcedure = YES;
					self.preCombatUnit = unitToActOn;
					log(LOG_COMBAT, @"%@ Pre-Combat procedure underway.", [combatController unitHealthBar:[playerController player]]);
					[self performProcedureWithState: [NSDictionary dictionaryWithObjectsAndKeys: 
													  PreCombatProcedure,		    @"Procedure",
													  [NSNumber numberWithInt: 0],	    @"CompletedRules",
													  unitToActOn,			   @"Target",  nil]];
					return YES;
				}
				if ( unitToActOn != self.preCombatUnit ) log(LOG_DEV, @"[Combat Start] Attacking unit other than pre-combat unit.");
				self.preCombatUnit = nil;
				log(LOG_DEV, @"%@ Found %@ trying to attack.", [combatController unitHealthBar: unitToActOn], unitToActOn);
//				[movementController turnTowardObject: unitToActOn];
			}
			[self actOnUnit: unitToActOn];
			return YES;
		}
	}
	
	// Check the party units (not sure if we'll even need this now)
	if ( theCombatProfile.partyEnabled && theCombatProfile.healingEnabled ) {
		NSArray *validUnits = [NSArray arrayWithArray:[combatController validUnitsWithFriendly:YES onlyHostilesInCombat:NO]];
		if ( [validUnits count] ) {
			for ( Unit *unit in validUnits ) {
				if ([playerController isHostileWithFaction: [unit factionTemplate]]) continue;
				if ([playerPosition distanceToPosition:[unit position]] > theCombatProfile.healingRange) continue;
				if ( ![self combatProcedureValidForUnit:unit] ) continue;
				log(LOG_PARTY, @"%@ helping %@", [combatController unitHealthBar: unitToActOn], unit);
				[self actOnUnit: unit];
				return YES;
			}
		}
	}
	return NO;
}


-(BOOL) evaluateForRegen {

	// Skip this if we are already in evaluation
	if ( [self evaluationInProgress] && ![[self evaluationInProgress] isEqualToString: @"Regen"]) return NO;

	// If we're mounted then let's not do anything that would cause us to dismount
	if ( [[playerController player] isMounted] ) return NO;
	
	log(LOG_EVALUATE, @"Evaluating for Regen");

	// Check to continue regen if the bot was started during regen	
	Unit *player = [playerController player];
	BOOL eatClear = NO, drinkClear = NO;
	
	// check health
	if ( [playerController health] == [playerController maxHealth] ) eatClear = YES;
	// no buff for eating anyways
	else if ( ![auraController unit: player hasBuffNamed: @"Food"] ) eatClear = YES;
	
	// check mana
	if ( [playerController mana] == [playerController maxMana] ) drinkClear = YES;
	// no buff for drinking anyways
	else if ( ![auraController unit: player hasBuffNamed: @"Drink"] ) drinkClear = YES;

	// we're not done eating/drinking
	if ( !eatClear || !drinkClear ) {
		log(LOG_EVALUATE, @"Looks like we weren't done drinking or eating.");		
		self.evaluationInProgress = @"Regen";
		[self performSelector: @selector(performProcedureWithState:) 
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
								RegenProcedure,		  @"Procedure",
								[NSNumber numberWithInt: 0],	  @"CompletedRules", nil] 
				   afterDelay: 0.25];
		 return YES;
	}

	// See if we need to perform this
	BOOL performRegen = NO;
	for(Rule* rule in [[self.theBehavior procedureForKey: RegenProcedure] rules]) {
		if( ([rule resultType] != ActionType_None) && ([rule actionID] > 0) && [self evaluateRule: rule withTarget: nil asTest: NO] ) {
			performRegen = YES;
			break;
		}
	}

	if (!performRegen) {
		self.evaluationInProgress = nil;
		return NO;
	} else {
		self.evaluationInProgress = @"Regen";
	}

	// check if all used abilities are instant
	BOOL needToPause = NO;
	for(Rule* rule in [[self.theBehavior procedureForKey: RegenProcedure] rules]) {
		if( ([rule resultType] == ActionType_Spell)) {
			Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: [rule actionID]]];
			if ([spell isInstant]) continue;
		}
		if([rule resultType] == ActionType_None) continue;
		needToPause = YES; 
		break;
	}
	
	// only pause if we are performing something non instant
	if (needToPause) [movementController stopMovement];

	[self performSelector: @selector(performProcedureWithState:) 
			   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
							RegenProcedure,		  @"Procedure",
							[NSNumber numberWithInt: 0],	  @"CompletedRules", nil] 
			   afterDelay: (needToPause ? 0.25 : 0.0)];

	if (needToPause) return YES;

	return NO;
}

- (BOOL)evaluateForLoot {

	if (!self.doLooting) return NO;

	// Enforce the loot scan idle
	int secondsPassed = _lootScanIdleTimer/10;
	if (secondsPassed > 20) return NO;

	// Skip this if we are already in evaluation
	if ( [self evaluationInProgress] && self.evaluationInProgress != @"Loot") return NO;

	// No looting if we're in procedure
	if ( [self procedureInProgress] ) return NO;
	
	// If we're mounted and in the air lets just skip loot scans
	if ( ![playerController isOnGround] && [[playerController player] isMounted]) return NO;
	
	// If we're supposed to be following then follow!
	if ( theCombatProfile.partyEnabled && theCombatProfile.followUnit && [[playerController player] isMounted]) return NO;
	
	// We don't loot in combat
	if ([[playerController player] isInCombat]) return NO;

	// If we're moving to the mob let's wait till we get there to do anything
    if ([movementController moveToObject]) return NO;
	
	log(LOG_EVALUATE, @"Evaluating for Loot");

    // get potential units and their distances
    Mob *mobToLoot	= [self mobToLoot];
	
    if ( !mobToLoot ) {

		// If we're outta mobs to loot and the loot timer has been incremented at least once
		if ( [self lootScan] ) {
			mobToLoot	= [self mobToLoot];
		} else {
			self.evaluationInProgress = nil;
			return NO;
		}
	}

	if ( ![mobToLoot isValid] ) {
		if ([_mobsToLoot count]) [_mobsToLoot removeAllObjects];
		self.evaluationInProgress = nil;
		return NO;
	}
	
	Unit *unitToCheck	= [self mobToLoot];
	// If it's a node then we'll leave it to the mining evaluation
	if ( [unitToCheck isKindOfClass: [Node class]] ) return NO;
	

	Position *playerPosition = [playerController position];
	float mobToLootDist	    = mobToLoot ? [[mobToLoot position] distanceToPosition: playerPosition] : INFINITY;
	
	Unit *unitToActOn  = [combatController findUnitWithFriendly:_includeFriendly onlyHostilesInCombat:YES];
	float unitToActOnDist  = unitToActOn ? [[unitToActOn position] distanceToPosition: playerPosition] : INFINITY;
    
    // if theres a unit that needs our attention that's closer than the lute.
    if ( mobToLootDist > unitToActOnDist && [playerController isHostileWithFaction: [unitToActOn factionTemplate]]) {		
		log(LOG_LOOT, @"Mob is too close to loot: %0.2f > %0.2f", mobToLootDist, unitToActOnDist);
		self.evaluationInProgress = nil;
		return NO;
	}

	// Close enough to loot it
	if ( mobToLootDist <= 5.0 ) {
		
		// Looting failed :/ I doubt this will ever actually happen, probably more an issue with nodes, but just in case!
		int attempts = [blacklistController attemptsForObject:mobToLoot];
		
		if ( self.lastAttemptedUnitToLoot == mobToLoot && attempts >= 3 ){
			log(LOG_LOOT, @"Unable to loot %@ after %d attempts, removing from loot list", self.lastAttemptedUnitToLoot, attempts);
			[_mobsToLoot removeObject: self.unitToLoot];
			self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
			return YES;
		}
		[controller setCurrentStatus: @"Bot: Looting"];		
		self.evaluationInProgress = @"Loot";
		[self performSelector: @selector(lootUnit:) withObject: mobToLoot afterDelay: 0.1f];
		return YES;
	}

	
	// Move to it	
	if ( self.evaluationInProgress != @"Loot") {
		log(LOG_DEV, @"Found mob to loot: %@ at dist %.2f", mobToLoot, mobToLootDist);
	} else {
		_movingTowardMobCount++;
	}
	self.evaluationInProgress = @"Loot";
			
	// have we exceeded the amount of attempts to move to the unit?
	// attempts... no longer seconds
	if ( _movingTowardMobCount > 4 ){
		log(LOG_LOOT, @"Unable to reach %@, removing from loot list", mobToLoot);
		[movementController resetMoveToObject];
		self.evaluationInProgress = nil;
		[_mobsToLoot removeObject:mobToLoot];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return YES;
	}
	
	if ( [movementController isMoving] ) [movementController stopMovement];
	[controller setCurrentStatus: @"Bot: Moving to Loot"];
	
	if ( ![movementController moveToObject: mobToLoot] ) 
		// In the off chance that we're unable to move to it
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
	
	return YES;
		
}

- (BOOL)evaluateForMiningAndHerbalism {
	
	if (!_doMining && !_doHerbalism && !_doNetherwingEgg) return NO;

	// If we're already mounted in party mode then
	if ( theCombatProfile.partyEnabled && [self followUnit] && [[playerController player] isMounted]) return NO;
	
	// Skip this if we are already in evaluation
	if ( [self evaluationInProgress] && ![[self evaluationInProgress] isEqualToString: @"MiningAndHerbalism"]) return NO;

	// If we're moving to the node let's wait till we get there to do anything
    if ([movementController moveToObject]) return NO;

	log(LOG_EVALUATE, @"Evaluating for Mining and Herbalism");
	
	Position *playerPosition = [playerController position];

	// check for mining and herbalism
	NSMutableArray *nodes = [NSMutableArray array];
	if(_doMining)			[nodes addObjectsFromArray: [nodeController nodesWithinDistance: self.gatherDistance ofType: MiningNode maxLevel: _miningLevel]];
	if(_doHerbalism)		[nodes addObjectsFromArray: [nodeController nodesWithinDistance: self.gatherDistance ofType: HerbalismNode maxLevel: _herbLevel]];
	if(_doNetherwingEgg)	[nodes addObjectsFromArray: [nodeController nodesWithinDistance: self.gatherDistance EntryID: 185915 position:[playerController position]]];
	
	[nodes sortUsingFunction: DistanceFromPositionCompare context: playerPosition];
	
	// If we've no node then skip this
	if ( ![nodes count] ) {
		[blacklistController clearAttempts];
		self.wasLootWindowOpen = NO;
		self.evaluationInProgress=nil;
		return NO;
	}
				
	// find a valid node to loot
	Node *thisNode = nil;
	Node *nodeToLoot = nil;
	float nodeDist = INFINITY;
		
	for(thisNode in nodes) {

		if ( ![thisNode validToLoot] ){
			log(LOG_NODE, @"%@ is not valid to loot, ignoring...", thisNode);
			continue;
		}
						
		NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[thisNode cachedGUID]];
		NSNumber *count = [_lootDismountCount objectForKey:guid];

		if ( count ) {
			
			// took .5 seconds or longer to fall!
			if ( [count intValue] > 4 ) {
				log(LOG_NODE, @"Failed to acquire node %@ after dismounting, ignoring...", thisNode);
				[blacklistController blacklistObject:thisNode withReason:Reason_NodeMadeMeFall];
				continue;
			}
		}
			
		if ( thisNode && [thisNode isValid] && ![blacklistController isBlacklisted:thisNode] ) {
			nodeDist = [playerPosition distanceToPosition: [thisNode position]];
			if ( nodeDist != INFINITY ) {
				nodeToLoot = thisNode;
				break;
			}
		}
		
	}

	// No valid nodes found
	if ( !nodeToLoot || ![nodeToLoot isValid] ) {
		self.evaluationInProgress=nil;
		return NO;
	}	
	
	
	// Only check this if we're not on the node
	if ( nodeDist > 20.0f ) {
		// If we're not supposed to loot this node due to proximity rules
		BOOL nearbyScaryUnits = [self scaryUnitsNearNode:nodeToLoot doMob:_nodeIgnoreMob doFriendy:_nodeIgnoreFriendly doHostile:_nodeIgnoreHostile];

		if ( nearbyScaryUnits ) {
			log(LOG_NODE, @"Skipping node due to proximity count");
			self.evaluationInProgress=nil;
			
			if (self.evaluationInProgress) [movementController stopMovement];
			
			[blacklistController blacklistObject:nodeToLoot];
			return NO;
		}
	}

	log(LOG_NODE, @"Found node to loot: %@ at dist %.2f", nodeToLoot, nodeDist);

	// Close enough to loot it
	if ( nodeDist <= DistanceUntilDismountByNode ) {
		
		int attempts = [blacklistController attemptsForObject:nodeToLoot];

		if ( self.lastAttemptedUnitToLoot == nodeToLoot && attempts >= 3 ) {
			log(LOG_NODE, @"Unable to loot %@, blacklisting.", self.lastAttemptedUnitToLoot);
			[blacklistController blacklistObject:nodeToLoot];
			self.evaluationInProgress=nil;
			return NO;
		}
		
		self.evaluationInProgress = @"MiningAndHerbalism";
		[controller setCurrentStatus: @"Bot: Working node"];
		[self lootUnit:nodeToLoot];
		return YES;
	}

	// if it's potentially unreachable or at a distance lets make sure we're mounted
	// We're putting this here so we can run this check prior to the patrol evaluation
	// This allows us to disregard the mounting if it's not in our behavior (low levels or what ever)
	if (nodeDist > 12.0f && ![[playerController player] isMounted ]) {
		// see if we would be performing anything in the patrol procedure
		BOOL performPatrolProc = NO;
		Rule *ruleToCheck;
		for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules]) {
			if( ([rule resultType] != ActionType_None) && ([rule actionID] > 0) && [self evaluateRule: rule withTarget: nil asTest: NO] ) {
				ruleToCheck = rule;
				performPatrolProc = YES;
				break;
			}
		}
			
		if (performPatrolProc) {
			// lets just unset evaluation and return so patrol triggers next
			self.evaluationInProgress=nil;
			return NO;
		}
	}

	
	// Move to it	
	if ( self.evaluationInProgress != @"MiningAndHerbalism") {
		log(LOG_DEV, @"Moving to node...");
		_movingTowardNodeCount = 0;
	} else {
		_movingTowardNodeCount++;
		self.evaluationInProgress = @"MiningAndHerbalism";
	}
	
	// have we exceeded the amount of attempts to move to the node?
	if ( _movingTowardNodeCount > 4 ){
		log(LOG_NODE, @"Unable to reach %@!, blacklisting.", nodeToLoot);
		[blacklistController blacklistObject:nodeToLoot];
		[movementController resetMoveToObject];
		self.evaluationInProgress = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return YES;
	}
	
//	if ( [movementController isMoving] ) [movementController stopMovement];
	[controller setCurrentStatus: @"Bot: Moving to node"];

	// Safe to move to the node!
	if ( ![movementController moveToObject: nodeToLoot] ) 
		// If for some reason we're un able to move to the node lets evaluate
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
	
	return YES;
}

- (BOOL)evaluateForFishing {
	
	// Skip this if we are already in evaluation
	if ( [self evaluationInProgress] && ![[self evaluationInProgress] isEqualToString: @"Fishing"]) return NO;

	if ( [movementController moveToObject] ) return NO;
	if ( !_doFishing ) return NO;

	// If we're supposed to be following then follow!
	if ( theCombatProfile.partyEnabled && [self followUnit] && [[playerController player] isMounted]) return NO;

	log(LOG_EVALUATE, @"Evaluating for Fishing.");

	log(LOG_FISHING, @"Fishing scan!");
	
	Position *playerPosition = [playerController position];
	
	// fishing only in schools! (probably have a route we're following)
	if ( _fishingOnlySchools ) {
		NSMutableArray *nodes = [NSMutableArray array];
		[nodes addObjectsFromArray:[nodeController nodesWithinDistance:_fishingGatherDistance ofType: FishingSchool maxLevel: 1]];
		[nodes sortUsingFunction: DistanceFromPositionCompare context: playerPosition];
		
		// are we close enough to start fishing?
		if ( [nodes count] ){			
			// lets find a node
			Node *nodeToFish = nil;
			float nodeDist = INFINITY;
			for (nodeToFish in nodes) {
				if ( [blacklistController isBlacklisted:nodeToFish] ){
					log(LOG_FISHING, @"Node %@ blacklisted, ignoring", nodeToFish);
					continue;
				}
				if ( nodeToFish && [nodeToFish isValid] ) {
					nodeDist = [playerPosition distanceToPosition: [nodeToFish position]];
					break;
				}
			}
			BOOL nearbyScaryUnits = [self scaryUnitsNearNode:nodeToFish doMob:_nodeIgnoreMob doFriendy:_nodeIgnoreFriendly doHostile:_nodeIgnoreHostile];

			// we have a valid node!
			if ( [nodeToFish isValid] && (nodeDist != INFINITY) && !nearbyScaryUnits ) {
				self.evaluationInProgress = @"Fishing";
				[movementController stopMovement];
				log(LOG_FISHING, @"Found closest school %@ at dist %.2f", nodeToFish, nodeDist);
				if (nodeDist <= NODE_DISTANCE_UNTIL_FISH) {
					[movementController turnTowardObject:nodeToFish];					
					log(LOG_FISHING, @"We are near %@, time to fish!", nodeToFish);
					if ( [[playerController player] isMounted] ) {
						log(LOG_FISHING, @"Dismounting...");
						[movementController dismount]; 
					}
					
					if ( ![fishController isFishing] ){
						[fishController fish: _fishingApplyLure
								  withRecast:_fishingRecast
									 withUse:_fishingUseContainers
									withLure:_fishingLureSpellID
								  withSchool:nodeToFish];
					}
					return YES;
				}
			}
		}
		
		self.evaluationInProgress = nil;
		
		log(LOG_FISHING, @"Didn't find a node, so we're doing nothing...");
		
	} else {
		// fish where we are
		log(LOG_FISHING, @"Just fishing from wherever we are!");
		[fishController fish: _fishingApplyLure
				  withRecast:NO
					 withUse:_fishingUseContainers
					withLure:_fishingLureSpellID
				  withSchool:nil];		
		return YES;
	}
	
	// if we get here, we shouldn't be fishing, stop if we are
	if ( [fishController isFishing] ) [fishController stopFishing];
	self.evaluationInProgress = nil;
	return NO;
}

- (BOOL)evaluateForPatrol {

	// If we're already evaluating something then let's skip this.
	if ( [self evaluationInProgress] ) return NO;

	// If we're already mounted then let's not do anything that would cause us to dismount
	if ( [[playerController player] isMounted] ) return NO;

	// If your leader is mounted then stop buffing others
	if ( followUnit && [followUnit isMounted]) return NO;

	if ( [playerController isCasting] )return NO;

	if ( [self isOnAssist] && [[self assistUnit] isInCombat]) return NO;

	if ( [self isTankUnit] && [[self tankUnit] isInCombat]) return NO;

	log(LOG_EVALUATE, @"Evaluating for Patrol");

	// see if we would be performing anything in the patrol procedure
	BOOL performPatrolProc = NO;
	Rule *ruleToCheck;
	for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules]) {
		if( ([rule resultType] != ActionType_None) && ([rule actionID] > 0) && [self evaluateRule: rule withTarget: nil asTest: NO] ) {
			ruleToCheck = rule;
			performPatrolProc = YES;
			break;
		}
	}

	// Look to see if there are friendlies to be checked in our patrol routine, buffing others?
	if ( !performPatrolProc && _includeFriendlyPatrol) {
		NSArray *units = [combatController validUnitsWithFriendly:_includeFriendlyPatrol onlyHostilesInCombat:NO];
		for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules]) {
			if ([rule target] != TargetFriend ) continue;
			log(LOG_RULE, @"[Patrol] Evaluating rule %@", rule);

			//Let go through the friendly targets
			Unit *target = nil;
			for ( target in units ) {
				if (![playerController isFriendlyWithFaction: [target factionTemplate]] ) continue;
				if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
					// do something
					log(LOG_RULE, @"[Patrol] Match for %@ with %@", rule, target);
					ruleToCheck = rule;
					performPatrolProc = YES;
					break;
				}
			}
		}
	}

	// Look for corpses - resurrection
	if ( !performPatrolProc && theCombatProfile.healingEnabled && _includeFriendlyPatrol) {
		NSMutableArray *allPotentialUnits = [NSMutableArray array];
		[allPotentialUnits addObjectsFromArray: [playersController allPlayers]];
		
		if ( [allPotentialUnits count] ){
			log(LOG_DEV, @"[CorpseScan] in evaluation...");
			float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
			for ( Unit *unit in allPotentialUnits ){
				log(LOG_DEV, @"[CorpseScan] looking for corpses: %@", unit);

				if ( ![unit isPlayer] || ![unit isDead] ) continue;
				if ( [[unit position] verticalDistanceToPosition: [playerController position]] > vertOffset ) continue;
				if ( [[playerController position] distanceToPosition:[unit position]] > theCombatProfile.healingRange ) continue;

				if ( [blacklistController isBlacklisted:unit] ) {
					log(LOG_DEV, @":[CorpseScan] Ignoring blacklisted unit: %@", unit);
					continue;
				}

				// player: make sure they're not a ghost
				NSArray *auras = [auraController aurasForUnit: unit idsOnly: YES];
				if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ) {
					continue;
				}

				log(LOG_DEV, @"Found a corpse in evaluation!");

				performPatrolProc = YES;
				break;
			}
		}
	}
	
	if (!performPatrolProc) return NO;

	// Perform the procedure.
	[controller setCurrentStatus: @"Bot: Patrolling Phase"];

	// check if all used abilities are instant
	BOOL needToPause = NO;
		if( ([ruleToCheck resultType] == ActionType_Spell)) {
			Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: [ruleToCheck actionID]]];
			if (![spell isInstant]) needToPause = YES;
		} else
		if ([ruleToCheck resultType] != ActionType_None) needToPause = YES; 
		
	// only pause if we are performing something non instant
	
	if (needToPause && [movementController isMoving]) [movementController stopMovement];
	log(LOG_DEV, @"Patrol now calling for performProcedurewithState");

	[self performSelector: @selector(performProcedureWithState:) 
			   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
							PatrollingProcedure,		  @"Procedure",
							[NSNumber numberWithInt: 0],	  @"CompletedRules", nil] 
				afterDelay: 0.1];

	return YES;
}

- (BOOL)evaluateSituation {
    if (![self isBotting])						return NO;
    if (![playerController playerIsValid:self])	return NO;

	if ( [self evaluationInProgress] ) {
		log(LOG_EVALUATE, @"Evaluating Situation with %@ in progress", [self evaluationInProgress]);
	} else {
		log(LOG_EVALUATE, @"Evaluating Situation");
	}
	
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];	


	// Order of operations is established here
	
	if ( [playerController isGhost] ) return [self evaluateForGhost];
	
	if ( [self evaluateForPVP] ) return YES;

	if ( [self evaluateForParty] ) return YES;

	if ( [self evaluateForFollow] ) return YES;

	if ( [self evaluateForCombatContinuation] ) return YES;
	
    /* *** if we get here, we aren't in combat *** */
	
	if ( [self evaluateForRegen] ) return YES;

	if ( [self evaluateForLoot] ) return YES;

	// Increment the loot scan idle timer if it's not already past it's cut off
	if (_lootScanIdleTimer <= (20*10)) _lootScanIdleTimer++;

	if ( [self evaluateForFishing] ) return YES;
	
	if ( [self evaluateForMiningAndHerbalism] ) return YES;
	
   	if ( [self evaluateForPatrol] ) return YES;

	if ( [self evaluateForCombatStart] ) return YES;

	/*
	 * Evaluation Checks Complete, lets see if we're supposed to do a route.
	 */
	
	// If we're just performing a check while we're in route we can return here
	if ( [ movementController isFollowing] ) {
		log(LOG_EVALUATE, @"Nothing to do so we'll not interrupt our Follow.");
		return NO;
	} else if ( [movementController isMoving] ) {
		log(LOG_EVALUATE, @"Nothing to do so we'll not interrupt our patrol.");
		return NO;
	} else {
		log(LOG_EVALUATE, @"Nothing to do, checking for a route.");
	}
	
	if ( ![self evaluationInProgress] && ![_mobsToLoot count] ) {
		
		// If we have a follow unit then skip your route
		if ( self.theRouteSet && ( ![self followUnit] || [self partyFollowSuspended] ) ) {

			// Update the status if we need to
			if ( ![[controller currentStatus] isEqualToString: @"Bot: Patrolling"] ) {
				[controller setCurrentStatus: @"Bot: Patrolling"];
				log(LOG_GENERAL, @"Going on Patrol...");
			}

			// resume movement if we're not moving!
			if ( ![movementController isPatrolling] || ![movementController isMoving] ) [movementController resumeMovement];

		} else {

			// Update the status if we need to
			if ( ![[controller currentStatus] isEqualToString: @"Bot: Enabled"] ) [controller setCurrentStatus: @"Bot: Enabled"];
	
			[self performSelector: _cmd withObject: nil afterDelay: 0.1];
		}
		
	} else {
		
		[self performSelector: _cmd withObject: nil afterDelay: 0.1];
		
	}
	
    return NO;
}

#pragma mark IBActions


- (IBAction)editCombatProfiles: (id)sender {
    [[CombatProfileEditor sharedEditor] showEditorOnWindow: [self.view window] 
										   forProfileNamed: [[NSUserDefaults standardUserDefaults] objectForKey: @"CombatProfile"]];
}

- (IBAction)updateStatus: (id)sender {
    CombatProfile *profile = [[combatProfilePopup selectedItem] representedObject];
	
    NSString *status = [NSString stringWithFormat: @"%@ (%@). ", 
						[[[behaviorPopup selectedItem] representedObject] name],    // behavior
						[[[routePopup selectedItem] representedObject] name]];	     // route
    
    NSString *bleh = nil;
    if(!profile || !profile.combatEnabled) {
		bleh = @"Combat disabled.";
    } else {
		if(profile.onlyRespond) {
			bleh = @"Only attacking back.";
		}
		else if ( profile.assistUnit ){
			
			bleh = [NSString stringWithFormat:@"Only assisting %@", @""];
		}
		else{
			NSString *levels = profile.attackAnyLevel ? @"any levels" : [NSString stringWithFormat: @"levels %d-%d", 
																		 profile.attackLevelMin,
																		 profile.attackLevelMax];
			bleh = [NSString stringWithFormat: @"Attacking %@ within %.1fy.", 
					levels,
					profile.engageRange];
		}
    }
    
    status = [status stringByAppendingString: bleh];
    
    
    if([miningCheckbox state])
		status = [status stringByAppendingFormat: @" Mining (%d).", [miningSkillText intValue]];
    if([herbalismCheckbox state])
		status = [status stringByAppendingFormat: @" Herbalism (%d).", [herbalismSkillText intValue]];
    if([skinningCheckbox state])
		status = [status stringByAppendingFormat: @" Skinning (%d).", [skinningSkillText intValue]];
    
    [statusText setStringValue: status];
}


- (IBAction)startBot: (id)sender {
	BOOL ignoreRoute = ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"UseRoute"] boolValue];
    BOOL usePvPBehavior = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"UsePvPBehavior"] boolValue];
	
    // grab route info
    if ( ignoreRoute ) {
		self.theRouteSet = nil;
		self.theRouteCollection = nil;
    } else {
		self.theRouteCollection = [[routePopup selectedItem] representedObject];
		self.theRouteSet = [_theRouteCollection startingRoute];
    }
	
    self.theBehavior = [[behaviorPopup selectedItem] representedObject];
    self.theCombatProfile = [[combatProfilePopup selectedItem] representedObject];
	
    self.doLooting = [lootCheckbox state];
    self.gatherDistance = [gatherDistText floatValue];

	// we using a PvP Behavior?
	if ( usePvPBehavior ){
		self.pvpBehavior = [[pvpBehaviorPopUp selectedItem] representedObject];
	}
	else{
		self.pvpBehavior = nil;
	}	
	
	if ( ([self isHotKeyInvalid] & HotKeyPrimary) == HotKeyPrimary ){
		log(LOG_STARTUP, @"Primary hotkey is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Invalid Hotkey", @"You must choose a valid primary hotkey, or the bot will be unable to use any spells or abilities.", @"Okay", NULL, NULL);
		return;
    }
	
	if ( self.doLooting && ([self isHotKeyInvalid] & HotKeyInteractMouseover) == HotKeyInteractMouseover ){
		log(LOG_STARTUP, @"Interact with MouseOver hotkey is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Invalid Looting Hotkey", @"You must choose a valid Interact with MouseOver hotkey, or the bot will be unable to loot bodies.", @"Okay", NULL, NULL);
		return;
	}
    
    // check that we have valid conditions
    if( ![controller isWoWOpen]) {
		log(LOG_STARTUP, @"WoW is not open. Bailing.");
		NSBeep();
		NSRunAlertPanel(@"WoW is not open", @"WoW is not open...", @"Okay", NULL, NULL);
		return;
    }
    
    if( ![playerController playerIsValid:self]) {
		log(LOG_STARTUP, @"The player is not valid. Bailing.");
		NSBeep();
		NSRunAlertPanel(@"Player not valid or cannot be detected", @"You must be logged into the game before you can start the bot.", @"Okay", NULL, NULL);
		return;
    }
	
	if ( !self.theRouteSet && self.theRouteCollection && !ignoreRoute ){
		NSBeep();
		log(LOG_STARTUP, @"You don't have a starting route selected!");
		NSRunAlertPanel(@"Starting route is not selected", @"You must select a starting route for your route set! Go to the route tab and select one,", @"Okay", NULL, NULL);
		return;
    }
    
    if( !self.theRouteSet && !ignoreRoute ) {
		NSBeep();
		log(LOG_STARTUP, @"The current route is not valid.");
		NSRunAlertPanel(@"Route is not valid", @"You must select a valid route before starting the bot.	 If you removed or renamed a route, please select an alternative. And make sure you have a starting route selected on the route tab!", @"Okay", NULL, NULL);
		return;
    }
    
    if( !self.theBehavior ) {
		log(LOG_STARTUP, @"The current behavior is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Behavior is not valid", @"You must select a valid behavior before starting the bot.  If you removed or renamed a behavior, please select an alternative.", @"Okay", NULL, NULL);
		return;
    }
	
    if( !self.theCombatProfile ) {
		log(LOG_STARTUP, @"The current combat profile is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Combat Profile is not valid", @"You must select a valid combat profile before starting the bot.  If you removed or renamed a profile, please select an alternative.", @"Okay", NULL, NULL);
		return;
    }
	
	if ( !self.theRouteCollection && !ignoreRoute ) {
		log(LOG_STARTUP, @"The current route set is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Route Set is not valid", @"You must select a valid route set before starting the bot.	 If you removed or renamed a profile, please select an alternative.", @"Okay", NULL, NULL);
		return;
    }
	
	// we need at least one macro!
	if ( [[macroController macros] count] == 0 ){
		log(LOG_STARTUP, @"You need at least one macro for Pocket Gnome to function.");
		NSBeep();
		NSRunAlertPanel(@"You need a macro!", @"You need at least one macro for Pocket Gnome to function correctly. It can be blank, simply create one in your game menu.", @"Okay", NULL, NULL);
		return;
	}

	// find our key bindings
	[bindingsController reloadBindings];
	BOOL bindingsError = NO;
	NSMutableString *error = [NSMutableString stringWithFormat:@"You need to bind your keys to something! The following aren't bound:\n"];
	if ( ![bindingsController bindingForKeyExists:BindingPrimaryHotkey] ){
		[error appendString:@"\tLower Left Action Bar 1 (Or Action Bar 1)\n"];
		bindingsError = YES;
	}
	else if ( ![bindingsController bindingForKeyExists:BindingPetAttack] && self.theBehavior.usePet ){
		[error appendString:@"\tPet Attack\n"];
		bindingsError = YES;
	}
	else if ( ![bindingsController bindingForKeyExists:BindingInteractMouseover] ){
		[error appendString:@"\tInteract With Mouseover\n"];
		bindingsError = YES;
	}
	else if ( ![bindingsController bindingForKeyExists:BindingTargetLast] ){
		[error appendString:@"\tTarget Last Target\n"];
		bindingsError = YES;
	}
/*
	else if ( ![bindingsController bindingForKeyExists:BindingStrafeRight] ){
		[error appendString:@"\tStrafe Right\n"];
		bindingsError = YES;
	}
	else if ( ![bindingsController bindingForKeyExists:BindingStrafeLeft] ){
		[error appendString:@"\tStrafe Left\n"];
		bindingsError = YES;
	}	
*/
	if ( bindingsError ){
		log(LOG_STARTUP, @"All keys aren't bound!");
		NSBeep();
		NSRunAlertPanel(@"You need to bind the correct keys in your Game Menu", error, @"Okay", NULL, NULL);
		return;
	}
	
	// behavior check - friendly
	if ( self.theCombatProfile.healingEnabled ){
		BOOL validFound = NO;
		Procedure *procedure = [self.theBehavior procedureForKey: CombatProcedure];
		int i;
		for ( i = 0; i < [procedure ruleCount]; i++ ) {
			Rule *rule = [procedure ruleAtIndex: i];
			
			if ( [rule target] == TargetFriend ){
				validFound = YES;
				break;
			}
		}
		
		if ( !validFound ){
			log(LOG_STARTUP, @"You have healing selected, but no rules heal friendlies!");
			NSBeep();
			NSRunAlertPanel(@"Behavior is not set up correctly", @"Your combat profile states you should be healing. But no targets are selected as friendly in your behavior! So how can I heal anyone?", @"Okay", NULL, NULL);
			return;
		}
	}
	
	// behavior check - hostile
	if ( self.theCombatProfile.combatEnabled ){
		BOOL validFound = NO;		
		Procedure *procedure = [self.theBehavior procedureForKey: CombatProcedure];
		int i;
		for ( i = 0; i < [procedure ruleCount]; i++ ) {
			Rule *rule = [procedure ruleAtIndex: i];			
			if ( [rule target] == TargetEnemy || [rule target] == TargetAdd ){
				validFound = YES;
				break;
			}
		}		
		if ( !validFound ){
			log(LOG_STARTUP, @"You have combat selected, but no rules attack enemies!");
			NSBeep();
			NSRunAlertPanel(@"Behavior is not set up correctly", @"Your combat profile states you should be attacking. But no targets are selected as enemies in your behavior! So how can I kill anyone?", @"Okay", NULL, NULL);
			return;
		}
	}
	
	// make sure the route will work!
	if ( self.theRouteSet ){
		[_routesChecked removeAllObjects];
		NSString *error = [self isRouteSetSound:self.theRouteSet];
		if ( error && [error length] > 0 ) {
			log(LOG_STARTUP, @"[Bot] Your route is not configured correctly!");
			NSBeep();
			NSRunAlertPanel(@"Route is not configured correctly", error, @"Okay", NULL, NULL);
			return;
		}
	}
	
	// make sure our spells are on our action bars!
	NSString *spellError = [spellController spellsReadyForBotting];
	if ( spellError && [spellError length] ){
		log(LOG_STARTUP, @"Your spells/macros/items need to be on your action bars!");
		NSBeep();
		NSRunAlertPanel(@"Your spells/macros/items need to be on your action bars!", spellError, @"Okay", NULL, NULL);
		return;
	}
	
	// pvp checks
	UInt32 zone = [playerController zone];
	if ( [playerController isInBG:zone] ){
		
		// verify we're able to actually do something (otherwise we make the assumption the user selected the correct route!)
		if ( self.pvpBehavior ){
			
			// do we have a BG for this?
			Battleground *bg = [self.pvpBehavior battlegroundForZone:zone];
			
			if ( !bg ){
				NSString *errorMsg = [NSString stringWithFormat:@"No battleground found for '%@', check your PvP Behavior!", [bg name]];
				log(LOG_STARTUP, errorMsg);
				NSBeep();
				NSRunAlertPanel(@"Unknown error in PvP Behavior", errorMsg, @"Okay", NULL, NULL);
				return;	
			}
			else if ( ![bg routeCollection] ){
				NSString *errorMsg = [NSString stringWithFormat:@"You must select a valid Route Set in your PvP Behavior for '%@'.", [bg name]];
				log(LOG_STARTUP, @"No valid route found for BG %d.", zone);
				NSBeep();
				NSRunAlertPanel(@"No route set found for this battleground", errorMsg, @"Okay", NULL, NULL);
				return;
			}
		}
	}
	
	if ( self.pvpBehavior && ![self.pvpBehavior canDoRandom] ){
		log(LOG_STARTUP, @"Currently PG will only do random BGs, you must enabled all battlegrounds + select a route for each");
		NSBeep();
		NSRunAlertPanel(@"Enable all battlegrounds", @"Currently PG will only do random BGs, you must enabled all battlegrounds + select a route for each", @"Okay", NULL, NULL);
		return;
		
	}
	
	// not a valid pvp behavior
	/*if ( self.pvpBehavior && ![self.pvpBehavior isValid] ){
		
		if ( [self.pvpBehavior random] ){
			log(LOG_STARTUP, @"You must have all battlegrounds enabled in your PvP behavior to do random!", zone);
			NSBeep();
			NSRunAlertPanel(@"Enable all battlegrounds", @"You must have all battlegrounds enabled in your PvP behavior to do random!", @"Okay", NULL, NULL);
			return;
		}
		else{
			log(LOG_STARTUP, @"You need at least 1 battleground enabled in your PvP behavior to do PvP!", zone);
			NSBeep();
			NSRunAlertPanel(@"Enable 1 battleground", @"You need at least 1 battleground enabled in your PvP behavior to do PvP!", @"Okay", NULL, NULL);
			return;
		}
	}*/
	
	// TO DO: verify starting routes for ALL PvP routes
	
	// not really sure how this could be possible hmmm
    if( [self isBotting]) [self stopBot: nil];
    
    if ( self.theCombatProfile && self.theBehavior ) {
		log(LOG_STARTUP, @"Starting...");
		[spellController reloadPlayerSpells];
		
		// also check that the route has any waypoints
		// and that the behavior has any procedures
		_doMining			= [miningCheckbox state];
		_doNetherwingEgg	= [netherwingEggCheckbox state];
		_miningLevel		= [miningSkillText intValue];
		_doHerbalism		= [herbalismCheckbox state];
		_herbLevel			= [herbalismSkillText intValue];
		_doSkinning			= [skinningCheckbox state];
		_skinLevel			= [skinningSkillText intValue];
		
		
// I can see where this needs things connected to work, but for the life of me I can't find where to edit it!?
// Using this work around until then... it would be awesome if you could give me a pointer as to where to edit the connector
//		_doNinjaSkin			= [ninjaSkinCheckbox state];
		
//		NSString* type = [NSString stringWithFormat:@"",];
//		if ([[NSUserDefaults standardUserDefaults] objectForKey: type])
		if (_doSkinning) _doNinjaSkin = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"DoNinjaSkin"] boolValue];
		else _doNinjaSkin = NO;
		
		// fishing
		_doFishing				= [fishingCheckbox state];
		_fishingGatherDistance	= [fishingGatherDistanceText floatValue];
		_fishingApplyLure		= [fishingApplyLureCheckbox state];
		_fishingOnlySchools		= [fishingOnlySchoolsCheckbox state];
		_fishingRecast			= [fishingRecastCheckbox state];
		_fishingUseContainers	= [fishingUseContainersCheckbox state];
		_fishingLureSpellID		= [fishingLurePopUpButton selectedTag];
		
		// node checking
		_nodeIgnoreFriendly				= [nodeIgnoreFriendlyCheckbox state];
		_nodeIgnoreHostile				= [nodeIgnoreHostileCheckbox state];
		_nodeIgnoreMob					= [nodeIgnoreMobCheckbox state];
		_nodeIgnoreFriendlyDistance		= [nodeIgnoreFriendlyDistanceText floatValue];
		_nodeIgnoreHostileDistance		= [nodeIgnoreHostileDistanceText floatValue];
		_nodeIgnoreMobDistance			= [nodeIgnoreMobDistanceText floatValue];
		
		_lootUseItems					= [lootUseItemsCheckbox state];
		_lootScanIdleTimer	= 0;
		
		self.mobToSkin = nil;
		self.unitToLoot = nil;	
		
		// Party resets
		[self followStepsClear];
		self.followUnit = nil;
		self.tankUnit = nil;
		
		// friendly shit
		_includeFriendly = [self includeFriendlyInCombat];
		_includeFriendlyPatrol = [self includeFriendlyInPatrol];
		
		// reset statistics
		[statisticsController resetQuestMobCount];
		
		// start our log out timer - only check every 5 seconds!
		_logOutTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0f target: self selector: @selector(logOutTimer:) userInfo: nil repeats: YES];
		
		int canSkinUpToLevel = 0;
		if(_skinLevel <= 100) canSkinUpToLevel = (_skinLevel/10)+10;
		else canSkinUpToLevel = (_skinLevel/5);
		if (_doSkinning) log(LOG_STARTUP, @"Starting bot with Sknning skill %d, allowing mobs up to level %d", _skinLevel, canSkinUpToLevel);
		if (_doNinjaSkin) log(LOG_STARTUP, @"Ninja Skin enabled.");		
		
		[startStopButton setTitle: @"Stop Bot"];
		_didPreCombatProcedure = NO;
		_reviveAttempt = 0;
		_ghostDance = 0;
		
		// Bot started, lets reset our whisper history!
		[chatLogController clearWhisperHistory];

		self.startDate = [[NSDate date] retain];

		// set our route
		if ( self.theRouteSet ) [movementController setPatrolRouteSet:self.theRouteSet];
	
		[controller setCurrentStatus: @"Bot: Enabled"];
		log(LOG_STARTUP, @" StartBot");
		self.isBotting = YES;
		
		// TO DO: allow botting before u join a BG!
		
		if ( [playerController isDead] ){
			
			[controller setCurrentStatus: @"Bot: Player is Dead"];
			
			if ( ![playerController isGhost] ){
				log(LOG_GENERAL, @"[Bot] Do we need to release?");
				[self rePop:[NSNumber numberWithInt:0]];
			}
		}
		
		// we have a PvP behavior!
		if ( self.pvpBehavior ){
			
			// TO DO - map these to bindings
			self.pvpPlayWarning = NO;// [pvpPlayWarningCheckbox state];
			self.pvpLeaveInactive = [self.pvpBehavior leaveIfInactive];
			
			// reset these in case they have them selected
			self.theRouteSet = nil;
			self.theRouteCollection = nil;
			
			log(LOG_GENERAL, @"[PvP] Starting with PvP");
			
			[self performSelector:@selector(pvpQueueOrStart) withObject:nil afterDelay:0.1f];
		}
		
		// normal, non-PvP
		else if ( self.theRouteSet ) {
			[movementController setPatrolRouteSet:self.theRouteSet];
			[self evaluateSituation];
		}
		
		// Running in a mode with no route selected
		else {
			[self evaluateSituation];
		}
    }
}

- (void)updateRunningTimer{
	int duration = (int) [[NSDate date] timeIntervalSinceDate: self.startDate];
	
	NSMutableString *runningFor = [NSMutableString stringWithFormat:@"Running for: "];
	
	if ( duration > 0 ){
		// Prob a better way for this heh
		int seconds = duration % 60;
		duration /= 60;
		int minutes = duration % 60;
		duration /= 60;
		int hours = duration % 24;
		duration /= 24;
		int days = duration;
		
		if (days > 0) [runningFor appendString:[NSString stringWithFormat:@"%d day%@", days, (days > 1) ? @"s " : @" "]];
		if (hours > 0) [runningFor appendString:[NSString stringWithFormat:@"%d hour%@", hours, (hours > 1) ? @"s " : @" "]];
		if (minutes > 0) [runningFor appendString:[NSString stringWithFormat:@"%d minute%@", minutes, (minutes > 1) ? @"s " : @" "]];
		if (seconds > 0) [runningFor appendString:[NSString stringWithFormat:@"%d second%@", seconds, (seconds > 1) ? @"s " : @""]];
		
		[runningTimer setStringValue: runningFor];
	}
}

- (IBAction)stopBot: (id)sender {
	
	// we are we stopping the bot if we aren't even botting? (partly doing this as I don't want the status to change if we logged out due to something)
	if ( !self.isBotting ){
		return;
	}
	
	if ( self.isPvPing )
		[self pvpStop];
	
	// TO DO: stop PvP stuff (i.e. if we're queued, unqueue)
	if ( self.pvpBehavior ){
		log (LOG_PVP, @" Botting stopped, we need to stop the queue if it's up");
	}
	
	// Then a user clicked!
	if ( sender != nil ){
		self.startDate = nil;
	}
	log(LOG_GENERAL, @"Bot Stopped: %@", sender);
    [self cancelCurrentProcedure];
	[movementController resetMovementState];
    [combatController resetAllCombat];
	[blacklistController clearAll];

	// Party resets
	[self followStepsClear];
	self.followUnit = nil;
	self.tankUnit = nil;
	_mountAttempt = 0;
	
    [_mobsToLoot removeAllObjects];
    self.isBotting = NO;
    self.preCombatUnit = nil;
    [controller setCurrentStatus: @"Bot: Stopped"];
    
    log(LOG_GENERAL, @"[Bot] Stopped.");
	
	// stop our log out timer
	[_logOutTimer invalidate];_logOutTimer=nil;
	
	// make sure we're not fishing
	[fishController stopFishing];
	
	// Reset the evaluation
	self.evaluationInProgress = nil;
    
    [startStopButton setTitle: @"Start Bot"];
}

// the idea of this function is that we want to stop the bot from doing anything, but we don't want to actually stop botting ;)
- (void)stopBotActions{
	
	// just in case
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateSituation) object: nil];
	
	[self cancelCurrentProcedure];
	[movementController resetMovementState];
	[movementController stopMovement];
    [combatController resetAllCombat];
	[blacklistController clearAll];
    [_mobsToLoot removeAllObjects];
    self.preCombatUnit = nil;
	
	// stop fishing
	if ( [fishController isFishing] ){
		[fishController stopFishing];
	}
	
	// invalidate PvP timer
	if ( !self.isPvPing ){
		[_pvpTimer invalidate]; _pvpTimer = nil;
	}
	
	self.pvpAntiAFKCounter = 0;
}

- (void)reEnableStart {
    [startStopButton setEnabled: YES];
}

- (IBAction)startStopBot: (id)sender {
    if ( self.isBotting ){
		[self stopBot: sender];
    } else {
		[self startBot: sender];
    }
}

NSMutableDictionary *_diffDict = nil;
- (IBAction)testHotkey: (id)sender {
	
	
	log(LOG_GENERAL, @"testing");
	
	return;
	
    //int value = 28734;
    //[[controller wowMemoryAccess] saveDataForAddress: ([offsetController offset:@"HOTBAR_BASE_STATIC"] + BAR6_OFFSET) Buffer: (Byte *)&value BufLength: sizeof(value)];
    //log(LOG_GENERAL, @"Set Mana Tap.");
    
    //[chatController pressHotkey: hotkey.code withModifier: hotkey.flags];
    
    
    if(!_diffDict) _diffDict = [[NSMutableDictionary dictionary] retain];
    
    BOOL firstRun = ([_diffDict count] == 0);
    UInt32 i, value;
    
    if(firstRun) {
		log(LOG_GENERAL, @"First run.");
		for(i=0x900000; i< 0xFFFFFF; i+=4) {
			if([[controller wowMemoryAccess] loadDataForObject: self atAddress: i Buffer: (Byte *)&value BufLength: sizeof(value)]) {
				if(value < 2)
					[_diffDict setObject: [NSNumber numberWithUnsignedInt: value] forKey: [NSNumber numberWithUnsignedInt: i]];
			}
		}
    } else {
		NSMutableArray *removeKeys = [NSMutableArray array];
		for(NSNumber *key in [_diffDict allKeys]) {
			if([[controller wowMemoryAccess] loadDataForObject: self atAddress: [key unsignedIntValue] Buffer: (Byte *)&value BufLength: sizeof(value)]) {
				if( value == [[_diffDict objectForKey: key] unsignedIntValue]) {
					[removeKeys addObject: key];
				} else {
					[_diffDict setObject: [NSNumber numberWithUnsignedInt: value] forKey: key];
				}
			}
		}
		[_diffDict removeObjectsForKeys: removeKeys];
    }
    
    log(LOG_GENERAL, @"%d values.", [_diffDict count]);
    if([_diffDict count] < 20) {
		log(LOG_GENERAL, @"%@", _diffDict);
    }
    
    return;
}


- (IBAction)hotkeyHelp: (id)sender {
	[NSApp beginSheet: hotkeyHelpPanel
	   modalForWindow: [self.view window]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
}

- (IBAction)closeHotkeyHelp: (id)sender {
    [NSApp endSheet: hotkeyHelpPanel returnCode: 1];
    [hotkeyHelpPanel orderOut: nil];
}

- (IBAction)lootHotkeyHelp: (id)sender {
	[NSApp beginSheet: lootHotkeyHelpPanel
	   modalForWindow: [self.view window]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
}

- (IBAction)closeLootHotkeyHelp: (id)sender {
    [NSApp endSheet: lootHotkeyHelpPanel returnCode: 1];
    [lootHotkeyHelpPanel orderOut: nil];
}

- (IBAction)gatheringLootingOptions: (id)sender{
	[NSApp beginSheet: gatheringLootingPanel
	   modalForWindow: [self.view window]
		modalDelegate: self
	   didEndSelector: @selector(gatheringLootingDidEnd: returnCode: contextInfo:)
		  contextInfo: nil];
}

- (IBAction)gatheringLootingSelectAction: (id)sender {
    [NSApp endSheet: gatheringLootingPanel returnCode: [sender tag]];
}

- (void)gatheringLootingDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [gatheringLootingPanel orderOut: nil];
}

// sometimes queueing for the BG fails, so lets just check every second to make sure we queued
- (void)queueForBGCheck{
	int status = [playerController battlegroundStatus];
	if ( status == BGWaiting ){
		// queue then check again!
		[macroController useMacroOrSendCmd:@"AcceptBattlefield"];
		[self performSelector:@selector(queueForBGCheck) withObject: nil afterDelay:1.0f];
		log(LOG_GENERAL, @"[PvP] Additional join BG check executed!");
	}
}


#pragma mark Notifications

- (void)eventBattlegroundStatusChange: (NSNotification*)notification{
	if ( ![self isPvPing] ) return;
	
	int status = [[notification object] intValue];
	
	// Lets join the BG!
	if ( status == BGWaiting ){
		//[macroController useMacroOrSendCmd:@"AcceptBattlefield"];
		float queueAfter = SSRandomFloatBetween(3.0f, 20.0f);
		[self performSelector:@selector(queueForBGCheck) withObject: nil afterDelay:queueAfter];
		log(LOG_GENERAL, @"[PvP] Joining the BG after %0.2f seconds", queueAfter);
	}
	else if ( status == BGNone ){
		// just stop movement
		[movementController resetMovementState];
		log(LOG_GENERAL, @"[PvP] Battleground is over?? Resetting movement state");
	}
}

- (void)eventZoneChanged: (NSNotification*)notification{
	if ( ![self isBotting] ) return;
	
	NSNumber *lastZone = [notification object];
	
	if ( [playerController isInBG:[lastZone intValue]] ){
		
		[movementController stopMovement];
		
		log(LOG_GENERAL, @"[PvP] Left BG, stopping bot!");
	}
	
	// this is done in pvpMonitor, no need for it here
	// pvping and we just switched to a BG - start!
	/*if ( self.isPvPing && self.pvpBehavior ){
		UInt32 zone = [playerController zone];
		if ( [playerController isInBG:zone] ){
			log(LOG_PVP, " zone changed fired, we're in a BG, starting...");
			[self pvpStart];
		}
	}*/

	log(LOG_GENERAL, @"[Bot] Zone change fired... to %@", lastZone);
}

// Want to respond to some commands? o.O
- (void)whisperReceived: (NSNotification*)notification{
	ChatLogEntry *entry = [notification object];
	
	//TO DO: Check to make sure you only respond to people around you that you are healing!
		
	if ( ( [[entry text] isEqualToString: @"Stay there"] || [[entry text] isEqualToString: @"Stay here"] ) && theCombatProfile.partyEnabled && theCombatProfile.followUnit ) {
		log(LOG_PARTY, @"Command recieved, stop following.");
		self.partyFollowSuspended = YES;
		self.evaluationInProgress = nil;
		if ( [self followUnit] ) [playerController targetGuid:[[self followUnit] GUID]];
		[chatController sendKeySequence: [NSString stringWithFormat: @"%c/salute%c", '\n', '\n']];
		self.followUnit = nil;		
	} else 
	if ( [[entry text] isEqualToString: @"Come on"] && theCombatProfile.partyEnabled && theCombatProfile.followUnit ) {
		log(LOG_PARTY, @"Command recieved, following again.");
		self.partyFollowSuspended = NO;
		[chatController sendKeySequence: [NSString stringWithFormat: @"%c/train%c", '\n', '\n']];
	}
	
}

#pragma mark AKA [Input] PlayerData

- (void)playerHasRevived: (NSNotification*)notification {
    if ( ![self isBotting] ) return;
    log(LOG_GENERAL, @"---- Player has revived!");
    [controller setCurrentStatus: @"Bot: Player has Revived"];
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
	if ( [movementController isMoving] ) [movementController stopMovement];
	[self followStepsClear];
	_ghostDance = 0;
	self.evaluationInProgress = nil;
	[self performSelector:@selector(evaluateSituation) withObject:nil afterDelay:0.5f];
}

- (void)playerHasDied: (NSNotification*)notification {    
    if( ![self isBotting]) return;
	if ( ![playerController playerIsValid:self] ) return;
	
    log(LOG_GHOST, @"---- Player has died.");
    [controller setCurrentStatus: @"Bot: Player has Died"];
    
    [self cancelCurrentProcedure];		// this wipes all bot state (except pvp)
    [combatController resetAllCombat];	       // this wipes all combat state
	
	if ([_followSteps count]) [_followSteps removeAllObjects];	// Wipe our follow footsteps so we don't try em when we res
	
	_shouldFollow = YES;
    
    // send notification to Growl
    if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
		[GrowlApplicationBridge notifyWithTitle: @"Player Has Died!"
									description: @"Sorry :("
							   notificationName: @"PlayerDied"
									   iconData: [[NSImage imageNamed: @"Ability_Warrior_Revenge"] TIFFRepresentation]
									   priority: 0
									   isSticky: NO
								   clickContext: nil];
    }
	
	// Try to res in a second! (give the addon time to release if they're using one!)
    [self performSelector: @selector(rePop:) withObject: [NSNumber numberWithInt:0] afterDelay: 3.0f];
	
	// Play an alarm after we die?
	if ( [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmOnDeath"] boolValue] ){
		[[NSSound soundNamed: @"alarm"] play];
		log(LOG_GHOST, @"Playing alarm, you have died!");
	}
}

- (void)moveAfterRepop{
	
	// don't move if we're PvPing or in a BG
	if ( self.isPvPing || [playerController isInBG:[playerController zone]] ){
		return;
	}

	if ( [playerController isDead] && [playerController isGhost] ){
		log(LOG_GHOST, @"We're dead and starting movement!");
		[movementController resumeMovement];
	}
}

- (void)rePop: (NSNumber *)count{
	if ( ![self isBotting]) return;
	if ( ![playerController playerIsValid:self] ) return;
	
	if ( theCombatProfile.disableRelease ) {
		log(LOG_GHOST, @"Ignoring release due to a combat setting");
		return;
	}
	
	log(LOG_GHOST, @"Trying to repop (%d:%d)", [playerController isGhost], [playerController isDead] );
	
	// Reset the loot scan idle timer
	[self resetLootScanIdleTimer];
	
	// We need to repop!
	if ( ![playerController isGhost] && [playerController isDead] ) {
		int try = [count intValue];
		// ONLY stop bot if we're not in PvP (we'll auto res in PvP!)
		if (++try > 25 && !self.isPvPing) {
			log(LOG_GHOST, @"Repop failed after 10 tries.  Stopping bot.");
			[self stopBot: nil];
			[controller setCurrentStatus: @"Bot: Failed to Release. Stopped."];
			return;
		}
		log(LOG_GHOST, @"Attempting to repop %d.", try);
		
		[macroController useMacroOrSendCmd:@"ReleaseCorpse"];
		[self performSelector: @selector(moveAfterRepop) withObject:nil afterDelay:0.5f];
		
		// Try again every few seconds
		[self performSelector: @selector(rePop:) withObject: [NSNumber numberWithInt:try] afterDelay: 5.0];
	}
}

- (void)playerIsInvalid: (NSNotification*)not {
    if ( ![self isBotting]) return;
	
	if ( self.isPvPing ){
		log(LOG_PVP, @" player is invalid, but we're not stopping as we're pvping!");
		return;
	}
	
	log(LOG_GENERAL, @"[Bot] Player is no longer valid, stopping bot.");
	[self stopBot: nil];
}

#pragma mark ShortcutRecorder Delegate

- (void)toggleGlobalHotKey:(SRRecorderControl*)sender
{
	if (StartStopBotGlobalHotkey != nil) {
		[[PTHotKeyCenter sharedCenter] unregisterHotKey: StartStopBotGlobalHotkey];
		[StartStopBotGlobalHotkey release];
		StartStopBotGlobalHotkey = nil;
	}
    
    KeyCombo keyCombo = [sender keyCombo];
    
    if((keyCombo.code >= 0) && (keyCombo.flags >= 0)) {
		StartStopBotGlobalHotkey = [[PTHotKey alloc] initWithIdentifier: @"StartStopBot"
															   keyCombo: [PTKeyCombo keyComboWithKeyCode: keyCombo.code
																							   modifiers: [sender cocoaToCarbonFlags: keyCombo.flags]]];
		
		[StartStopBotGlobalHotkey setTarget: startStopButton];
		[StartStopBotGlobalHotkey setAction: @selector(performClick:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey: StartStopBotGlobalHotkey];
    }
}

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo {
	
    if(recorder == startstopRecorder) {
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"StartstopCode"];
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"StartstopFlags"];
		[self toggleGlobalHotKey: startstopRecorder];
    }
	
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark PvP!

- (void)auraGain: (NSNotification*)notification {
	
    if ( self.isPvPing ) {
		UInt32 spellID = [[(Spell*)[[notification userInfo] objectForKey: @"Spell"] ID] unsignedIntValue];
		
		// if we are waiting to rez, pause the bot (incase it is not)
		if( spellID == WaitingToRezSpellID ) {
			[movementController stopMovement];
			
		}
		
		// Just got preparation?  Lets check to see if we're in strand + should be attacking/defending
		if ( spellID == PreparationSpellID ) {
			log(LOG_GENERAL, @"We have preparation, checking BG info!");
			
			// Do it in a bit, as we need to wait for our controller to update the object list!
			[self performSelector:@selector(pvpGetBGInfo) withObject:nil afterDelay:3.1f];
		}
    }
}

- (void)auraFade: (NSNotification*)notification {
	
	// Player is PvPing!
    if(self.isPvPing) {
		UInt32 spellID = [[(Spell*)[[notification userInfo] objectForKey: @"Spell"] ID] unsignedIntValue];
		
		if( spellID == PreparationSpellID ) {
			
			// Only checking for the delay!
			if ( [playerController isOnBoatInStrand] && [playerController zone] == ZoneStrandOfTheAncients ){
				// We want to pause, and not move until the boat stops!	 Delay 10 seconds?
				[movementController stopMovement];
				
				_strandDelay = YES;
				
				// reset the delay in 10 seconds?
				[self performSelector:@selector(pvpResetStrandDelay) withObject:nil afterDelay:10.0f];
				
				log(LOG_GENERAL, @"[PvP] We are on a boat in Strand! Starting a delay until the boat stops!");
			}
		}
    }
}

- (void)logOutWithMessage:(NSString*)message{
	
	log(LOG_GENERAL, @"[Bot] %@", message);
	[self logOut];
	
	// sleep a bit before we update our status
	usleep(500000);
	[self updateStatus: [NSString stringWithFormat:@"Bot: %@", message]];
}

#pragma mark Timers

- (void)logOutTimer: (NSTimer*)timer {

	BOOL logOutNow = NO;
	NSString *logMessage = nil;
	
	// check for full inventory
	if ( [logOutOnFullInventoryCheckbox state] && [itemController arePlayerBagsFull] ){
		logOutNow = YES;
		logMessage = @"Inventory full, closing game";
	}
	
	// check for timer
	if ( [logOutOnTimerExpireCheckbox state] && self.startDate ){
		float hours = [logOutAfterRunningTextField floatValue];
		NSDate *stopDate = [[NSDate alloc] initWithTimeInterval:hours * 60 * 60 sinceDate:self.startDate];
		
		// check to see which date is earlier
		if ( [stopDate earlierDate: [NSDate date] ] == stopDate ){
			logOutNow = YES;
			logMessage = [NSString stringWithFormat:@"Timer expired after %0.2f hours! Logging out!", hours];
		}
	}
	
	// check durability
	if ( [logOutOnBrokenItemsCheckbox state] ){
		float averageDurability = [itemController averageWearableDurability];
		float durabilityPercentage = [logOutAfterRunningTextField floatValue];
		
		if ( averageDurability > 0 && averageDurability < durabilityPercentage ){
			logOutNow = YES;
			logMessage = [NSString stringWithFormat:@"Item durability has reached %02.f, logging out!", averageDurability];
		}
	}
	
	// check honor
	if ( self.pvpBehavior && [self.pvpBehavior stopHonor] ){
		UInt32 currentHonor = [playerController honor];
		if ( currentHonor && currentHonor >= [self.pvpBehavior stopHonorTotal] ){
			logOutNow = YES;
			logMessage = [NSString stringWithFormat:@"Honor has reached %u, logging out!", currentHonor];
		}
	}
	
	// time to stop botting + log!
	if ( logOutNow ){
		[self logOutWithMessage:logMessage];
	}
}

// called every 30 seconds
- (void)afkTimer: (NSTimer*)timer {
	
	if (  ![playerController playerIsValid] ) return;
	
	// don't need this if we're botting since we're doing things!
	if ( self.isBotting && 
		
		// Addition to kick in AFK when in party mode on flying mounts
		( ![movementController movementType] == MovementType_CTM || ![antiAFKButton state] || [movementController isMoving] || self.evaluationInProgress) 
		) return;
	
	log(LOG_DEV, @"[AFK] Attempt: %d", _afkTimerCounter);
	
	
	if ( [antiAFKButton state] ){
		_afkTimerCounter++;
		
		// then we are at 4 minutes
		if ( _afkTimerCounter > 8 ){
			
			[movementController antiAFK];
			
			_afkTimerCounter = 0;
		}
	}
}

- (void)wgTimer: (NSTimer*)timer {
	
	// WG zone ID: 4197
	if ( [autoJoinWG state] && ![playerController isDead] && [playerController zone] == 4197 && [playerController playerIsValid] ){
		
		NSDate *currentTime = [NSDate date];
		
		// then we are w/in the first hour after we've done a WG!  Let's leave party!
		if ( _dateWGEnded && [currentTime timeIntervalSinceDate: _dateWGEnded] < 3600 ){
			// check to see if they are in a party - and leave!
			UInt32 offset = [offsetController offset:@"PARTY_LEADER_PTR"];
			UInt64 guid = 0;
			if ( [[controller wowMemoryAccess] loadDataForObject: self atAddress: offset Buffer: (Byte *)&guid BufLength: sizeof(guid)] && guid ){
				
				[macroController useMacroOrSendCmd:@"LeaveParty"];
				log(LOG_GENERAL, @"[Bot] Player is in party leaving!");				
			}
			
			log(LOG_GENERAL, @"[Bot] Leaving party anyways - there a leader? 0x%qX", guid);
			[macroController useMacroOrSendCmd:@"LeaveParty"];
		}
		
		// only autojoin if it's 2 hours+ after a WG end
		if ( _dateWGEnded && [currentTime timeIntervalSinceDate: _dateWGEnded] <= 7200 ){
			log(LOG_GENERAL, @"[Bot] Not autojoing WG since it's been %0.2f seconds", [currentTime timeIntervalSinceDate: _dateWGEnded]);
			return;
		}
		
		// should we auto accept quests too? o.O
		
		// click the button!
		[macroController useMacroOrSendCmd:@"ClickFirstButton"];
		log(LOG_GENERAL, @"[Bot] Autojoining WG!  Seconds since last WG: %0.2f", [currentTime timeIntervalSinceDate: _dateWGEnded]);
		
		// check how many marks they have (if it went up, we need to leave the group)!
		Item *item = [itemController itemForID:[NSNumber numberWithInt:43589]];
		if ( item && [item isValid] ){
			
			// it's never been set - /cry - lets set it!
			if ( _lastNumWGMarks == 0 ){
				_lastNumWGMarks = [item count];
				log(LOG_GENERAL, @"[Bot] Setting wintegrasp mark counter to %d", _lastNumWGMarks);
			}
			
			// the player has more!
			if ( _lastNumWGMarks != [item count] ){
				_lastNumWGMarks = [item count];
				
				log(LOG_GENERAL, @"[Bot] Wintergrasp over you now have %d marks! Leaving group!", _lastNumWGMarks);
				[macroController useMacroOrSendCmd:@"LeaveParty"];
				
				// update our time
				log(LOG_GENERAL, @"[Bot] It's been %0.2f:: opens seconds since we were last given marks!", [currentTime timeIntervalSinceDate: _dateWGEnded]);
				[_dateWGEnded release]; _dateWGEnded = nil;
				_dateWGEnded = [[NSDate date] retain];
			}
		}
	}
}

- (int)errorValue: (NSString*) errorMessage{
	if (  [errorMessage isEqualToString: INV_FULL] ){
		return ErrInventoryFull;
	}
	else if ( [errorMessage isEqualToString:TARGET_LOS] ){
		return ErrTargetNotInLOS;
	}
	else if ( [errorMessage isEqualToString:SPELL_NOT_READY] ){
		return ErrSpellNotReady;
	}
	else if ( [errorMessage isEqualToString:TARGET_FRNT] ){
		return ErrTargetNotInFrnt;
	}
	else if ( [errorMessage isEqualToString:CANT_MOVE] ){
		return ErrCantMove;
	}
	else if ( [errorMessage isEqualToString:WRNG_WAY] ){
		return ErrWrng_Way;
	}
	else if ( [errorMessage isEqualToString:ATTACK_STUNNED] ){
		return ErrAttack_Stunned;
	}
	else if ( [errorMessage isEqualToString:NOT_YET] ){
		return ErrSpell_Cooldown;
	}
	else if ( [errorMessage isEqualToString:SPELL_NOT_READY2] ){
		return ErrSpellNot_Ready;
	}
	else if ( [errorMessage isEqualToString:NOT_RDY2] ){
		return ErrSpellNot_Ready;
	}
	else if ( [errorMessage isEqualToString:TARGET_RNGE] ){
		return ErrTargetOutRange;
	}
	else if ( [errorMessage isEqualToString:TARGET_RNGE2] ){
		return ErrTargetOutRange;
	}
	else if ( [errorMessage isEqualToString:INVALID_TARGET] || [errorMessage isEqualToString:CANT_ATTACK_TARGET] ){
		return ErrInvalidTarget;
	}
	else if ( [errorMessage isEqualToString:CANT_ATTACK_MOUNTED] ){
		return ErrCantAttackMounted;
	}
	else if ( [errorMessage isEqualToString:YOU_ARE_MOUNTED] ){
		return ErrYouAreMounted;
	}
	else if ( [errorMessage isEqualToString:TARGET_DEAD] ){
		return ErrInvalidTarget;
	}
	else if ( [errorMessage isEqualToString:MORE_POWERFUL_SPELL_ACTIVE] ){
		return ErrMorePowerfullSpellActive;
	}
	
	return ErrNotFound;
}


- (void)interactWithMob:(UInt32)entryID {
	Mob *mobToInteract = [mobController closestMobForInteraction:entryID];
	
	if ([mobToInteract isValid]) {
		[self interactWithMouseoverGUID:[mobToInteract GUID]];
	}
}

- (void)interactWithNode:(UInt32)entryID {
	Node *nodeToInteract = [nodeController closestNodeForInteraction:entryID];
	
	if([nodeToInteract isValid]) {
		[self interactWithMouseoverGUID:[nodeToInteract GUID]];
	}
	else{
		log(LOG_GENERAL, @"[Bot] Node %d not found, unable to interact", entryID);
	}
}

// This will set the GUID of the mouseover + trigger interact with mouseover!
- (BOOL)interactWithMouseoverGUID: (UInt64) guid{
	if ( [[controller wowMemoryAccess] saveDataForAddress: ([offsetController offset:@"TARGET_TABLE_STATIC"] + TARGET_MOUSEOVER) Buffer: (Byte *)&guid BufLength: sizeof(guid)] ){
		
		// wow needs time to process the change
		usleep([controller refreshDelay]);
		
		return [bindingsController executeBindingForKey:BindingInteractMouseover];
	}
	
	return NO;
}

// Simply will log us out!
- (void)logOut{
	
	if ( [logOutUseHearthstoneCheckbox state] && (_zoneBeforeHearth == -1) ){
		
		// Can only use if it's not on CD!
		if ( ![spellController isSpellOnCooldown:HearthStoneSpellID] ){
			
			_zoneBeforeHearth = [playerController zone];
			// Use our hearth
			UInt32 actionID = (USE_ITEM_MASK + HearthstoneItemID);
			[self performAction:actionID];
			
			// Kill bot + log out
			[self performSelector:@selector(logOut) withObject: nil afterDelay:25.0f];
			
			return;
		}
	}
	
	// The zones *should* be different
	if ( [logOutUseHearthstoneCheckbox state] ){
		if ( _zoneBeforeHearth != [playerController zone] ){
			log(LOG_GENERAL, @"[Bot] Hearth successful from zone %d to %d", _zoneBeforeHearth, [playerController zone]);
		}
		else{
			log(LOG_GENERAL, @"[Bot] Sorry hearth failed for some reason (on CD?), still closing WoW!");
		}
	}
	
	// Reset our variable in case the player fires up wow again later
	_zoneBeforeHearth = -1;
	
	// Stop the bot
	[self pvpStop];
	[self stopBot: nil];
	usleep(1000000);
	
	// Kill the process
	[controller killWOW];
}

// check if units are nearby
- (BOOL)scaryUnitsNearNode: (WoWObject*)node doMob:(BOOL)doMobCheck doFriendy:(BOOL)doFriendlyCheck doHostile:(BOOL)doHostileCheck{
	if ( doMobCheck ){
		log(LOG_DEV, @"Scanning nearby mobs within %0.2f of %@", _nodeIgnoreMobDistance, [node position]);
		NSArray *mobs = [mobController mobsWithinDistance: _nodeIgnoreMobDistance MobIDs:nil position:[node position] aliveOnly:YES];
		if ( [mobs count] ){
			log(LOG_NODE, @"There %@ %d scary mob(s) near the node, ignoring %@", ([mobs count] == 1) ? @"is" : @"are", [mobs count], node);
			return YES;
		}
	}
	if ( doFriendlyCheck ){
		if ( [playersController playerWithinRangeOfUnit: _nodeIgnoreFriendlyDistance Unit:(Unit*)node includeFriendly:YES includeHostile:NO] ){
			log(LOG_NODE, @"Friendly player(s) near node, ignoring %@", node);
			return YES;
		}
	}
	if ( doHostileCheck ) {
		if ( [playersController playerWithinRangeOfUnit: _nodeIgnoreHostileDistance Unit:(Unit*)node includeFriendly:NO includeHostile:YES] ){
			log(LOG_NODE, @"Hostile player(s) near node, ignoring %@", node);
			return YES;
		}
	}
	
	return NO;
}

- (UInt8)isHotKeyInvalid{
	
	// We know it's not set if flags are 0 or code is -1 then it's not set!
	UInt8 flags = 0;
	
	// Check start/stop hotkey
	KeyCombo combo = [startstopRecorder keyCombo];
	if ( combo.code == -1 ){
		flags |= HotKeyStartStop;
	}
	
	return flags;	
}

- (char*)randomString: (int)maxLength{
	// generate a random string to write
	int i, len = SSRandomIntBetween(3,maxLength);
	char *string = (char*)malloc(len);
	char randomChar = 0;
    for (i = 0; i < len; i++) {
		while (YES) {
			randomChar = SSRandomIntBetween(0,128);
			if (((randomChar >= '0') && (randomChar <= '9')) || ((randomChar >= 'a') && (randomChar <= 'z'))) {
				string[i] = randomChar;
				break; // we found an alphanumeric character, move on
			}
		}
    }
	string[i] = '\0';
	
	return string;
}

#pragma mark Waypoint Action stuff

// set the new combat profile + select it in the dropdown!
- (void)changeCombatProfile:(CombatProfile*)profile{
	
	log(LOG_GENERAL, @"[Bot] Switching to combat profile %@", profile);
	self.theCombatProfile = profile;
	
	for ( NSMenuItem *item in [combatProfilePopup itemArray] ){
		if ( [[(CombatProfile*)[item representedObject] name] isEqualToString:[profile name]] ){
			[combatProfilePopup selectItem:item];
			break;
		}
	}
}

- (NSString*)isRouteSound: (Route*)route withName:(NSString*)name{
	NSMutableString *errorMessage = [NSMutableString string];
	// loop through!
	int wpNum = 1;
	for ( Waypoint *wp in [route waypoints] ){
		if ( wp.actions && [wp.actions count] ){
			for ( Action *action in wp.actions ){
				
				if ( [action type] == ActionType_SwitchRoute ){
					
					RouteSet *switchRoute = nil;
					NSString *UUID = [action value];
					for ( RouteSet *otherRoute in [waypointController routes] ){
						if ( [UUID isEqualToString:[otherRoute UUID]] ){
							switchRoute = otherRoute;
							break;
						}
					}
					
					// check this route for issues
					if ( switchRoute != nil ){
						[errorMessage appendString:[self isRouteSetSound:switchRoute]];
					}
					else{
						[errorMessage appendString:[NSString stringWithFormat:@"Error on route '%@'\r\n\tSwitch route not found on waypoint action %d\r\n", name, wpNum]];
					}
				}
				
				else if ( [action type] == ActionType_CombatProfile ){
					BOOL profileFound = NO;
					NSString *UUID = [action value];
					for ( CombatProfile *otherProfile in [combatProfileEditor combatProfiles] ){
						if ( [UUID isEqualToString:[otherProfile UUID]] ){
							profileFound = YES;
							break;
						}
					}
					if ( !profileFound ){
						[errorMessage appendString:[NSString stringWithFormat:@"Error on route '%@'\r\n\tCombat profile not found on waypoint action %d\r\n", name, wpNum]];
					}
				}
			}			
		}	
		wpNum++;
	}
	
	return errorMessage;
}

// this will loop through to make sure we actually have the correct routes + profiles!
- (NSString*)isRouteSetSound: (RouteSet*)route{
	
	// so we don't get stuck in an infinite loop
	if ( [_routesChecked containsObject:[route UUID]] ){
		return [NSString string];
	}
	[_routesChecked addObject:[route UUID]];
	
	NSMutableString *errorMessage = [NSMutableString string];
	
	// verify primary route
	Route *primaryRoute  = [route routeForKey: PrimaryRoute];
	[errorMessage appendString:[self isRouteSound:primaryRoute withName:[route name]]];
	
	// verify corpse route
	Route *corpseRunRoute = [route routeForKey: CorpseRunRoute];
	[errorMessage appendString:[self isRouteSound:corpseRunRoute withName:[route name]]];
	
	if ( !errorMessage || [errorMessage length] == 0 ){
		return [NSString string];
	}
	
	return errorMessage;
}

#pragma mark Testing Shit

- (IBAction)test: (id)sender{
	
	log(LOG_GENERAL, @"Current Game State: %d", [controller gameState]);
	
	float ping = [controller getPing];
	
	log(LOG_GENERAL, @"Ping: %f", ping);
	
	return;	
	
}


- (IBAction)test2: (id)sender{
	/*
	 Position *pos = [[Position alloc] initWithX: -4968.875 Y:-1208.304 Z:501.715];
	 Position *playerPosition = [playerController position];
	 
	 log(LOG_GENERAL, @"Distance: %0.2f", [pos distanceToPosition:playerPosition]);
	 
	 Position *newPos = [pos positionAtDistance:10.0f withDestination:playerPosition];
	 
	 log(LOG_GENERAL, @"New pos: %@", newPos);
	 
	 [movementController setClickToMove:newPos andType:ctmWalkTo andGUID:0x0];
	 */
}

- (int)CompareFactionHash: (int)hash1 withHash2:(int)hash2{	
	if ( hash1 == 0 || hash2 == 0 )
		return -1;
	
	UInt32 hashCheck1 = 0, hashCheck2 = 0;
	UInt32 check1 = 0, check2 = 0;
	int hashCompare = 0, hashIndex = 0, i = 0;
	//Byte *bHash1[0x40];
	//Byte *bHash2[0x40];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	//[memory loadDataForObject: self atAddress: hash1 Buffer: (Byte*)&bHash1 BufLength: sizeof(bHash1)];
	//[memory loadDataForObject: self atAddress: hash2 Buffer: (Byte*)&bHash2 BufLength: sizeof(bHash2)];
	
	// get the hash checks
	[memory loadDataForObject: self atAddress: hash1 + 0x4 Buffer: (Byte*)&hashCheck1 BufLength: sizeof(hashCheck1)];
	[memory loadDataForObject: self atAddress: hash2 + 0x4 Buffer: (Byte*)&hashCheck2 BufLength: sizeof(hashCheck2)];
	
	//bitwise compare of [bHash1+0x14] and [bHash2+0x0C]
	[memory loadDataForObject: self atAddress: hash1 + 0x14 Buffer: (Byte*)&check1 BufLength: sizeof(check1)];
	[memory loadDataForObject: self atAddress: hash2 + 0xC Buffer: (Byte*)&check2 BufLength: sizeof(check2)];
	if ( ( check1 & check2 ) != 0 )
		return 1;	// hostile
	
	hashIndex = 0x18;
	[memory loadDataForObject: self atAddress: hash1 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
	if ( hashCompare != 0 ){
		for ( i = 0; i < 4; i++ ){
			if ( hashCompare == hashCheck2 )
				return 1; // hostile
			
			hashIndex += 4;
			[memory loadDataForObject: self atAddress: hash1 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
			
			if ( hashCompare == 0 )
				break;
		}
	}
	
	//bitwise compare of [bHash1+0x10] and [bHash2+0x0C]
	[memory loadDataForObject: self atAddress: hash1 + 0x10 Buffer: (Byte*)&check1 BufLength: sizeof(check1)];
	[memory loadDataForObject: self atAddress: hash2 + 0xC Buffer: (Byte*)&check2 BufLength: sizeof(check2)];
	if ( ( check1 & check2 ) != 0 ){
		log(LOG_GENERAL, @"friendly");
		return 4;	// friendly
	}
	
	hashIndex = 0x28;
	[memory loadDataForObject: self atAddress: hash1 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
	if ( hashCompare != 0 ){
		for ( i = 0; i < 4; i++ ){
			if ( hashCompare == hashCheck2 ){
				log(LOG_GENERAL, @"friendly2");
				return 4;	// friendly
			}
			
			hashIndex += 4;
			[memory loadDataForObject: self atAddress: hash1 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
			
			if ( hashCompare == 0 )
				break;
		}
	}
	
	//bitwise compare of [bHash2+0x10] and [bHash1+0x0C]
	[memory loadDataForObject: self atAddress: hash2 + 0x10 Buffer: (Byte*)&check1 BufLength: sizeof(check1)];
	[memory loadDataForObject: self atAddress: hash1 + 0xC Buffer: (Byte*)&check2 BufLength: sizeof(check2)];
	if ( ( check1 & check2 ) != 0 ){
		log(LOG_GENERAL, @"friendly3");
		return 4;	// friendly
	}
	
	hashIndex = 0x28;
	[memory loadDataForObject: self atAddress: hash2 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
	if ( hashCompare != 0 ){
		for ( i = 0; i < 4; i++ ){
			if ( hashCompare == hashCheck1 ){
				log(LOG_GENERAL, @"friendly4");
				return 4;	// friendly
			}
			
			hashIndex += 4;
			[memory loadDataForObject: self atAddress: hash2 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
			
			if ( hashCompare == 0 )
				break;
		}
	}
	
	return 3;	//neutral
}

- (void)startClick{
	
	
	if ( [playerController isDead] ){
		log(LOG_GENERAL, @"Player died, stopping");
		return;
	}
	
	[macroController useMacro:@"AuctioneerClick"];
	
	[self performSelector:@selector(startClick) withObject:nil afterDelay:1.0f];	
}

- (IBAction)maltby: (id)sender{
	
	[self startClick];
}

#define ACCOUNT_NAME_SEP	@"SET accountName \""
#define ACCOUNT_LIST_SEP	@"SET accountList \""
/*
 
 SET accountName "myemail@hotmail.com"
 SET accountList "!ACCOUNT1|ACCOUNT2|"
 */
- (IBAction)login: (id)sender{
	//LOGIN_STATE		this will be "login", "charselect", or "charcreate"
	//	note: it will stay in it's last state even if we are logged in + running around!
	
	//LOGIN_SELECTED_CHAR - we want to write the position to memory, the chosen won't change on screen, but it will log into that char!
	//	values: 0-max
	
	//LOGIN_TOTAL_CHARACTERS - obviously the total number of characters on the selection screen
	
	NSString *account = @"MyBNETAccount12312";
	NSString *password = @"My1337Password";
	NSString *accountList = @"!Accoun23t1|Accoun1t2|";
	
	
	
	// ***** GET THE PATH TO OUR CONFIG FILE
	NSString *configFilePath = [controller wowPath];
	// will be the case if wow is closed (lets go with the default option?)
	if ( [configFilePath length] == 0 ){
		[configFilePath release]; configFilePath = nil;
		configFilePath = @"/Applications/World of Warcraft/WTF/Config.wtf";
	}
	// we have a dir
	else{
		configFilePath = [configFilePath stringByDeletingLastPathComponent];
		configFilePath = [configFilePath stringByAppendingPathComponent: @"WTF/Config.wtf"];	
	}
	
	
	// ***** GET OUR CONFIG FILE DATA + BACK IT UP!
	NSString *configData = [[NSString alloc] initWithContentsOfFile:configFilePath];
	NSMutableString *newConfigFile = [NSMutableString string];
	NSMutableString *configFileBackup = [NSString stringWithFormat:@"%@.bak", configFilePath];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ( ![fileManager fileExistsAtPath:configFilePath] || [configData length] == 0 ){
		log(LOG_GENERAL, @"[Bot] Unable to find config file at path '%@'. Aborting.", configFilePath);
		return;
	}
	// should we create a backup file?
	if ( ![fileManager fileExistsAtPath:configFileBackup] ){
		if ( ![configData writeToFile:configFileBackup atomically:YES encoding:NSUnicodeStringEncoding error:nil] ){
			log(LOG_GENERAL, @"[Bot] Unable to backup existing config file to '%@'. Aborting", configFileBackup);
			return;
		}
	}
	
	// if we get here we have a config file! And have backed it up!
	
	
	// Three conditions for information in this file:
	//	1. Account list and Account name are set
	//	2. Account list is set (when remember checkbox was once checked, but is no longer)
	//	3. Neither exist in config file
	if ( configData != nil ){
		
		NSScanner *scanner = [NSScanner scannerWithString: configData];
		
		BOOL accountNameFound = NO;
		BOOL accountListFound = NO;
		NSString *beforeAccountName = nil;
		NSString *beforeAccountList = nil;
		
        // get the account name?
		int scanSave = [scanner scanLocation];
		log(LOG_GENERAL, @"Location: %d", [scanner scanLocation]);
        if([scanner scanUpToString: ACCOUNT_NAME_SEP intoString: &beforeAccountName] && [scanner scanString: ACCOUNT_NAME_SEP intoString: nil]) {
            NSString *newName = nil;
            if ( [scanner scanUpToString: @"\"" intoString: &newName] && newName && [newName length] ) { 
				//log(LOG_GENERAL, @"Account name: %@", newName);
				accountNameFound = YES;
            }
        }
		
		// if the user doesn't have "remember" checked, the above search will fail, so lets reset to find the account list! (maybe?)
		if ( !accountNameFound ){
			[scanner setScanLocation: scanSave];
		}
		
		// get the account list
		scanSave = [scanner scanLocation];
		log(LOG_GENERAL, @"Location: %d %d", [scanner scanLocation], [beforeAccountName length]);
        if ( [scanner scanUpToString: ACCOUNT_LIST_SEP intoString: &beforeAccountList] && [scanner scanString: ACCOUNT_LIST_SEP intoString: nil] ) {
            NSString *newName = nil;
            if ( [scanner scanUpToString: @"\"" intoString: &newName] && newName && [newName length] ) {
				//log(LOG_GENERAL, @"Account list: %@", newName);
				accountListFound = YES;
            }
        }
		
		// reset the location, in case we have info after our login info + can add it back to the config file!
		if ( !accountListFound ){
			[scanner setScanLocation: scanSave];
		}
		log(LOG_GENERAL, @"Location: %d %d", [scanner scanLocation], [beforeAccountList length]);
		// save what we have left in the scanner! There could be config data after our account name!
		NSString *endOfConfigFileData = [[scanner string]substringFromIndex:[scanner scanLocation]];
		
		// condition 1: we have an existing account! we need to replace it (and potentially an account list to add)
		if ( accountNameFound ){
			// add our new account name
			[newConfigFile appendString:beforeAccountName];
			[newConfigFile appendString:ACCOUNT_NAME_SEP];
			[newConfigFile appendString:account];
			[newConfigFile appendString:@"\""];
			
			// did we also have an account list to replace?
			if ( [accountList length] ){
				[newConfigFile appendString:@"\n"];
				[newConfigFile appendString:ACCOUNT_LIST_SEP];
				[newConfigFile appendString:accountList];
				[newConfigFile appendString:@"\""];
			}
		}
		
		// condition 2: only the account list was found, add the account name + potentially replace the account list
		else if ( accountListFound ){
			[newConfigFile appendString:beforeAccountList];
			[newConfigFile appendString:ACCOUNT_NAME_SEP];
			[newConfigFile appendString:account];
			[newConfigFile appendString:@"\""];
			
			if ( [accountList length] ){
				[newConfigFile appendString:@"\n"];
				[newConfigFile appendString:ACCOUNT_LIST_SEP];
				[newConfigFile appendString:accountList];
				[newConfigFile appendString:@"\""];
			}
		}
		
		// condition 3: nothing was found
		else{
			[newConfigFile appendString:beforeAccountList];
			[newConfigFile appendString:ACCOUNT_NAME_SEP];
			[newConfigFile appendString:account];
			[newConfigFile appendString:@"\""];
			
			if ( [accountList length] ){
				[newConfigFile appendString:@"\n"];
				[newConfigFile appendString:ACCOUNT_LIST_SEP];
				[newConfigFile appendString:accountList];
				[newConfigFile appendString:@"\""];
			}
		}
		
		// only add data if we found an account name or list!
		if ( ( accountListFound || accountNameFound ) && [endOfConfigFileData length] ){
			[newConfigFile appendString:endOfConfigFileData];
		}
		
	}
	
	// write our new config file!
	[newConfigFile writeToFile:configFileBackup atomically:YES encoding:NSUnicodeStringEncoding error:nil];
	log(LOG_GENERAL, @"[Bot] New config file written to '%@'", configFilePath);
	
	// make sure wow is open
	if ( [controller isWoWOpen] ){
		
		[chatController sendKeySequence:account];
		usleep(50000);
		[chatController sendKeySequence:password];	   
		
	}
}

#pragma Testing/Development Info (Generally Reversing)

#pragma mark New PvP

- (void)pvpQueueOrStart{
	
	self.isPvPing = YES;
	
	// is the player already in a BG?
	UInt32 zone = [playerController zone];
	if ( [playerController isInBG:zone] ){
		
		if ( [self pvpSetEnvironmentForZone] ){
			[self pvpStart];
		}
		else{
			log(LOG_GENERAL, @"[PvP] should never be here really, but if so, we weren't able to set the PvP environment!");
		}
	}
	// player isn't in a BG, so we need to queue!
	else{
		[self pvpQueueBattleground];
	}
}

// this will set up the pvp environment based on the zone we're in (basically set the RouteSet)
- (BOOL)pvpSetEnvironmentForZone{
	
	UInt32 zone = [playerController zone];
	if ( [playerController isInBG:zone] ){
		
		Battleground *bg = [self.pvpBehavior battlegroundForZone:zone];
		// we have a BG
		if ( bg ){
			
			RouteCollection *rc = [bg routeCollection];
			if ( rc ){
				self.theRouteSet = [[rc startingRoute] retain];
				self.theRouteCollection = [rc retain];
				log(LOG_GENERAL,  @"[PvP] Setting PvP route set to %@", self.theRouteSet);
				return YES;
			}
		}
	}
	
	log(LOG_GENERAL, @"PvP No pvp route found!");
	
	return NO;	
}

- (void)finishQueue{
	[macroController useMacroOrSendCmd:@"JoinBattlefield"];
	usleep(100000);
	
	if ( [playerController battlegroundStatus] != BGQueued ){
		log(LOG_GENERAL,  @"[PvP] Error, we just queued for the BG, but we're not queued? hmmm");
	}
	
}

- (void)pvpQueueBattleground{
	
	// error checking (removed valid player and !isPvPing)
	UInt32 zone = [playerController zone];
	
	if ( [playerController isInBG:zone] ){
		log(LOG_GENERAL,  @"[PvP Not queueing for BG, already in a BG!");
		return;
	}
	if ( [playerController battlegroundStatus] == BGQueued ){
		log(LOG_GENERAL,  @"[PvP] Already queued, no need to try again!");
		return;
	}
	if ( !self.pvpBehavior ){
		log(LOG_GENERAL,  @"[PvP] No valid pvp behavior found, unable to queue!");
		return;
	}
	
	// check for deserter
    if ( [auraController unit: [playerController player] hasAura: DeserterSpellID] ) {
		[controller setCurrentStatus: @"PvP: Waiting for deserter to fade..."];
		
		// Will jump once every 1-3 minutes
		if ( self.pvpAntiAFKCounter++ >= 4 ){
			self.pvpAntiAFKCounter = 0;
			[movementController antiAFK];
		}
		
		// make sure pvpAntiAFK isn't running - it shouldn't be
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(pvpAntiAFK) object: nil];
		
		float nextQueueAttempt = SSRandomFloatBetween(15.0f, 45.0f);
		[self performSelector: @selector(pvpQueueBattleground) withObject: nil afterDelay:nextQueueAttempt];
		return;
    }
	
	log(LOG_GENERAL, @"[PvP] Queueing...");
	
	NSString *macroEnd = [macroController macroTextForKey:@"QueueForBattleground"];
	
	// doing a random? ezmode!
	if ( [self.pvpBehavior random] ){
		
		// execute the macro
		NSString *fullMacro = [NSString stringWithFormat:@"/run a,b={%d},{}; %@", 32, macroEnd];
		[macroController useMacroOrSendCmd:fullMacro];
		
		// actually join
		[self performSelector:@selector(finishQueue) withObject:nil afterDelay:1.0f];
	}
	// we have some checked!
	else{
		
		NSString *fullMacro = [NSString stringWithFormat:@"/run a,b={%@},{}; %@", [self.pvpBehavior formattedForJoinMacro], macroEnd];
		[macroController useMacroOrSendCmd:fullMacro];
		
		// actually join
		[self performSelector:@selector(finishQueue) withObject:nil afterDelay:1.0f];
	}
	
	self.pvpAntiAFKCounter = 0;
	[controller setCurrentStatus: @"PvP: Waiting to join Battleground."];
	[self pvpAntiAFK];
	
	// To account for sometimes the queue failing, lets try to join after minute or two just in case?
	/*float nextCheck = SSRandomFloatBetween(60.0f, 120.0f);
	 [self performSelector: @selector(pvpQueueBattleground) withObject: nil afterDelay:nextCheck];*/
	
	// try to queue again in case it failed!
	[self performSelector: @selector(pvpQueueRetry) withObject: nil afterDelay:5.0f];
	
	// start our monitor
	_pvpIsInBG = NO;
	if ( !_pvpTimer )
		_pvpTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f target: self selector: @selector(pvpMonitor:) userInfo: nil repeats: YES];
}

// try to requeue if we need to
- (void)pvpQueueRetry{
	if ( [playerController battlegroundStatus] != BGNone ){
		return;
	}
	
	log(LOG_GENERAL,  @" still not queued, trying again!");
	
	// cancel previous requests
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(pvpQueueBattleground) object: nil];
	[self pvpQueueBattleground];
}

// so simple
- (void)pvpStart{
	
	log(LOG_GENERAL,  @"[PvP] Starting...");
	
	// these conditions will be true:
	//	player is in a BG
	//	valid route collection
	//	valid route set
	//	valid behavior
	//	valid pvp behavior
	//	valid combat profile
	
	// reset movement state
	[movementController resetMovementState];
	
	// set the route set
	[movementController setPatrolRouteSet:self.theRouteSet];
	
	// start to evaluate!
	[self evaluateSituation];
	
	// Start our monitor!
	_pvpIsInBG = YES;
	if ( !_pvpTimer )
		_pvpTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f target: self selector: @selector(pvpMonitor:) userInfo: nil repeats: YES];
}

- (void)pvpStop {
	log(LOG_GENERAL,  @"[PvP] pvp stopped");
	
	self.isPvPing = NO;
	
	[self stopBotActions];
}


- (void)pvpResetStrandDelay{
	_strandDelay = NO;
	
	log(LOG_GENERAL, @"[PvP] Delay reset!");
	
	[controller setCurrentStatus: @"PvP: Delay reset, am I really waiting for eval?..."];
	
	log(LOG_GENERAL, @"[Eval] Reset strand");
	[self performSelector:@selector(evaluateSituation) withObject:nil afterDelay:10.0f];
}

- (void)pvpGetBGInfo{
	
	// Lets gets some info?
	if ( [playerController zone] == ZoneStrandOfTheAncients ){
		
		NSArray *antipersonnelCannons = [mobController mobsWithEntryID:StrandAntipersonnelCannon];
		
		if ( [antipersonnelCannons count] > 0 ){
			BOOL foundFriendly = NO, foundHostile = NO;
			for ( Mob *mob in antipersonnelCannons ){
				
				int faction = [mob factionTemplate];
				BOOL isHostile = [playerController isHostileWithFaction: faction];
				//log(LOG_GENERAL, @"[PvP] Faction %d (%d) of Mob %@", faction, isHostile, mob);
				
				if ( isHostile ){
					foundHostile = YES;
				}
				else if ( !isHostile ){
					foundFriendly = YES;
				}
			}
			
			if ( foundHostile && foundFriendly ){
				log(LOG_GENERAL, @"[PvP] New round for Strand! Found hostile and friendly! Were we attacking last round? %d", _attackingInStrand);
				_attackingInStrand = _attackingInStrand ? NO : YES;
			}
			else if ( foundHostile ){
				_attackingInStrand = YES;
				log(LOG_GENERAL, @"[PvP] We're attacking in strand!");
			}
			else if ( foundFriendly ){
				_attackingInStrand = NO;
				log(LOG_GENERAL, @"[PvP] We're defending in strand!");
			}
		}
		// If we don't see anything, then we're attacking!
		else{
			_attackingInStrand = YES;
			log(LOG_GENERAL, @"[PvP] We're attacking in strand!");
		}
		
		// Check to see if we're on the boat!
		if ( _attackingInStrand && [playerController isOnBoatInStrand]){
			_strandDelay = YES;
			log(LOG_GENERAL, @"[PvP] We're on a boat so lets delay our movement until it settles!");
		}
	}
}

// This little guy controls most of our PvP functions!
- (void)pvpMonitor: (NSTimer*)timer{
	if ( !self.isPvPing )							return;
	if ( ![playerController playerIsValid:self] )   return;
	
	BOOL isPlayerInBG = [playerController isInBG:[playerController zone]];
	Player *player = [playerController player];
	
	// Player just left the BG!
	if ( _pvpIsInBG && !isPlayerInBG ){
		_pvpIsInBG = NO;
		
		log(LOG_GENERAL,  @"[PvP] Player has left the battleground...");
		
		// technically we shouldn't have to do this, but just in case (it's done by the offset check)
		[self stopBotActions];
		
		// Only requeue if we're PvPing!
		if ( self.isPvPing ){
			
			// check for deserter
			BOOL hasDeserter = NO;
			if( [player isValid] && [auraController unit: player hasAura: DeserterSpellID] ) {
				hasDeserter = YES;
			}
			
			if ( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
				[GrowlApplicationBridge notifyWithTitle: [NSString stringWithFormat: @"Battleground Complete"]
											description: (hasDeserter ? @"Waiting for Deserter to fade." : @"Will re-queue in 10 seconds.")
									   notificationName: @"BattlegroundLeave"
											   iconData: (([controller reactMaskForFaction: [player factionTemplate]] & 0x2) ? [[NSImage imageNamed: @"BannerAlliance"] TIFFRepresentation] : [[NSImage imageNamed: @"BannerHorde"] TIFFRepresentation])
											   priority: 0
											   isSticky: NO
										   clickContext: nil];		   
			}
			
			if ( hasDeserter ) {
				log(LOG_GENERAL,  @"[PvP] Deserter! Waiting for deserter to go away :(");
				[controller setCurrentStatus: @"PvP: Waiting for Deserter to fade..."];
				[self performSelector: @selector(pvpQueueBattleground) withObject: nil afterDelay: 10.0];
				return;
			}
			
			// Requeue after 10 seconds (to account for some crappy computers)
			[controller setCurrentStatus: @"PvP: Re-queueing for BG in 10 seconds..."];
			[self performSelector: @selector(pvpQueueBattleground) withObject: nil afterDelay: 10.0f];
		}
	}
	
	// player just joined the BG!
	else if ( !_pvpIsInBG && isPlayerInBG ){
		_pvpIsInBG = YES;
		_waitingToLeaveBattleground = NO;
		
		// cancel anti-afk
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(pvpAntiAFK) object: nil];
		
		if ( self.isPvPing ){
			if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
				// [GrowlApplicationBridge setGrowlDelegate: @""];
				[GrowlApplicationBridge notifyWithTitle: [NSString stringWithFormat: @"Battleground Entered"]
											description: [NSString stringWithFormat: @"Starting bot in 5 seconds."]
									   notificationName: @"BattlegroundEnter"
											   iconData: (([controller reactMaskForFaction: [[playerController player] factionTemplate]] & 0x2) ? [[NSImage imageNamed: @"BannerAlliance"] TIFFRepresentation] : [[NSImage imageNamed: @"BannerHorde"] TIFFRepresentation])
											   priority: 0
											   isSticky: NO
										   clickContext: nil];		   
			}
			
			// Start bot after 5 seconds!
			log(LOG_GENERAL,  @" PvP environment valid. Starting bot in 5 seconds...");
			[controller setCurrentStatus: @"PvP: Starting Bot in 5 seconds..."];
			
			// in theory this shouldn't happen as there should be enough error check before we start the bot (although I guess someone could change the PvP behavior while it's running)
			if ( ![self pvpSetEnvironmentForZone] ){
				log(LOG_GENERAL, @"[PvP] No valid environment found for pvp! Leaving battleground.");
				[controller setCurrentStatus: @"PvP: No route found, leaving battleground"];
				
				[macroController useMacroOrSendCmd:@"LeaveBattlefield"];				
			}
			[self performSelector: @selector(pvpStart) withObject: nil afterDelay: 5.0f];
		}
	}
	
	// We can do some checks in here amirite?
	if ( _pvpIsInBG && isPlayerInBG ){
		
		if ( self.isPvPing ){
			
			// is the BG over?
			if ( !_waitingToLeaveBattleground ){
				UInt32 offset = [offsetController offset:@"Lua_GetBattlefieldWinner"], status = 0;
				[[controller wowMemoryAccess] loadDataForObject: self atAddress: offset Buffer: (Byte*)&status BufLength: sizeof(status)];
				log(LOG_GENERAL, @"[PvP] BG End Status: %d", status);
				if ( status != 0 ){
					log(LOG_GENERAL, @"[PvP] Battleground ending!");
					[self stopBotActions];
					
					if ( [self.pvpBehavior waitToLeave] && [self.pvpBehavior waitTime] >= 0.0f ){
						_waitingToLeaveBattleground = YES;
						[controller setCurrentStatus: [NSString stringWithFormat:@"PvP: Battleground over, waiting %0.2f seconds to leave", [self.pvpBehavior waitTime]]];
						[self performSelector: @selector(pvpBattlegroundOver) withObject: nil afterDelay: [self.pvpBehavior waitTime]];
					}
					
					return;
				}
			}
			
			// Play warning!
			if( self.pvpPlayWarning ) {
				if( [auraController unit: player hasAura: IdleSpellID] || [auraController unit: player hasAura: InactiveSpellID]) {
					[[NSSound soundNamed: @"alarm"] play];
					log(LOG_GENERAL,  @"[PvP] Idle/Inactive debuff detected!");
				}
			}
			
			// Leave BG?
			if( [auraController unit: player hasAura: InactiveSpellID] && self.pvpLeaveInactive ) {
				// leave the battleground
				log(LOG_GENERAL,  @"[PvP] Leaving battleground due to Inactive debuff.");
				
				[macroController useMacroOrSendCmd:@"LeaveBattlefield"];
			}
			
			// check for status change?  or wait for event to fire when BG is over?
		}
	}
}

- (void)pvpBattlegroundOver{
	log(LOG_GENERAL, @"[PvP] Leaving battleground!");
	
    self.pvpLeaveInactive = NO;
    self.pvpPlayWarning = NO;
    self.pvpAntiAFKCounter = 0;
	
	// now leave
	[macroController useMacroOrSendCmd:@"LeaveBattlefield"];	
}

// this will keep us from going afk
- (void)pvpAntiAFK {
	if ( !self.isBotting )							return;
	if ( ![playerController playerIsValid:self] )   return;
	
    if ( self.isPvPing ) {
		
		if ( [playerController isInBG:[playerController zone]] ){
			log(LOG_GENERAL,  @" player is in BG, cancelling anti-afk");
			return;
		}
		
		// in theory there shouldn't be others
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(pvpAntiAFK) object: nil];
		
		// Will move once every minute
		if ( self.pvpAntiAFKCounter++ >= 60 ) {
			self.pvpAntiAFKCounter = 0;
			[movementController antiAFK];
		}
		
		[self performSelector: @selector(pvpAntiAFK) withObject: nil afterDelay: 1.0f];
    }
}

- (IBAction)pvpTestWarning: (id)sender {
    [[NSSound soundNamed: @"alarm"] play];
}

#pragma Reversed Functions


- (int)lua_GetWorldState: (int)index{
	
	UInt32 offset = [offsetController offset:@"Lua_GetWorldStateUIInfo"];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	int32_t valid = 0x0;
	[memory loadDataForObject: self atAddress: offset + 0x8 Buffer: (Byte *)&valid BufLength: sizeof(valid)];
	
	if ( valid != -1 ){
		UInt32 v2 = 0x0, structAddress = 0x0;
		[memory loadDataForObject: self atAddress: offset Buffer: (Byte *)&v2 BufLength: sizeof(v2)];
		v2 += 12 * (index & valid);
		[memory loadDataForObject: self atAddress: v2 + (2*4) Buffer: (Byte *)&structAddress BufLength: sizeof(structAddress)];
		
		if ( ! (structAddress & 1) ){
			
			int32_t readIndex = 0x0;
			UInt32 offset = 0x0;	// potentially named wrong
			
			while ( structAddress ){
				
				// grab the next index from the world state struct
				[memory loadDataForObject: self atAddress: structAddress Buffer: (Byte *)&readIndex BufLength: sizeof(readIndex)];
				
				// found the correct index?
				if ( readIndex == index ){
					int32_t nextWintergraspTime = 0x0;
					[memory loadDataForObject: self atAddress: structAddress + (24) Buffer: (Byte *)&nextWintergraspTime BufLength: sizeof(nextWintergraspTime)];
					return nextWintergraspTime;
				}
				
				// try the next struct address
				[memory loadDataForObject: self atAddress: v2 Buffer: (Byte *)&offset BufLength: sizeof(offset)];			
				[memory loadDataForObject: self atAddress: offset+structAddress+4 Buffer: (Byte *)&structAddress BufLength: sizeof(structAddress)];
				
				// index not found
				if ( structAddress & 1 ){
					PGLog(@"[GetWorldState] Index %d not found", index);
					return 0;
				}
			}			
		}
	}
	
	return 0;	
}

- (double)lua_GetWintergraspWaitTime{
	
	if ( [self lua_GetWorldState:3801] > 0 )
	{
		int state = [self lua_GetWorldState:4354];
		MemoryAccess *memory = [controller wowMemoryAccess];
		
		int32_t v4 = 0x0;
		[memory loadDataForObject: self atAddress: [offsetController offset:@"Lua_GetWorldStateUIInfo"] + 0x10 Buffer: (Byte *)&v4 BufLength: sizeof(v4)];
		
		int seconds = state - (v4 + time(0));
		if ( seconds <= 0 )
			seconds = 0;
		
		return (double) seconds;
		
	}
	
	PGLog(@"[Wintergrasp] Unable to find time - is wintergrasp running?");
	
	return -1.0f;	
}

#pragma mark Login

- (void)login{
	
	/*
	 
	 Though process - verify
	 
	 
	 */

/*	
Commented out to avoid compile errors
	
	int gameState = [controller gameState];
	// yay!
	if ( gameState == GameState_LoggingIn ){
		
		MemoryAccess *memory = [controller wowMemoryAccess];
		if ( memory && [memory isValid] ){
			UInt32 offset = [offsetController offset:@"LoginState"];
			char state[21];
			state[20] = 0;
			if ( [memory loadDataForObject: self atAddress: offset Buffer: (Byte *)&state BufLength: sizeof(state)-1] ){
				
				NSString *stateAsString = [NSString stringWithUTF8String: state];
				if ( [stateAsString length] ){
					
					if ( [stateAsString isEqualToString:@"login"] ){
						log(LOG_GENERAL, @"[Login] We're at the login screen! Yay!");
						
						// here we want to check to see if we have already been logged in w/this account (if so, the username will still be there!)
						NSString *user = @"test";
						NSString *pass = @"pass";
						
						
					}	
				}
			}
		}
	}
	else{
		log(LOG_GENERAL, @"[Login] Player is already logged in? Current state: %d", gameState);
	}
*/	
}

@end
