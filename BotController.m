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
- (void)skinOrFinish;
- (BOOL)unitValidToHeal: (Unit*)unit;
- (void)lootNode: (WoWObject*) unit;

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

@synthesize castingUnit = _castingUnit;

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
	
	_pvpLastBattleground = -1;
	_theRouteCollection = nil;
	_pvpBehavior = nil;
	_procedureInProgress = nil;
	_lastProcedureExecuted = nil;
	_didPreCombatProcedure = NO;
	_lastSpellCastGameTime = 0;
	self.startDate = nil;
	_unitToLoot = nil;
	_mobToSkin = nil;
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
	_lootDismountCount = [[NSMutableDictionary dictionary] retain];
	_mountLastAttempt = nil;
	_castingUnit	= nil;
	
	_routesChecked = [[NSMutableArray array] retain];
	_mobsToLoot = [[NSMutableArray array] retain];
	
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
@synthesize mobToSkin = _mobToSkin;
@synthesize unitToLoot = _unitToLoot;
@synthesize lastAttemptedUnitToLoot = _lastAttemptedUnitToLoot;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize preCombatUnit;
@synthesize pvpPlayWarning = _pvpPlayWarning;
@synthesize pvpLeaveInactive = _pvpLeaveInactive;
@synthesize pvpAntiAFKCounter = _pvpAntiAFKCounter;

@synthesize startDate;
@synthesize doLooting	    = _doLooting;
@synthesize gatherDistance  = _gatherDist;

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
}

- (void)finishCurrentProcedure: (NSDictionary*)state {	
	log(LOG_DEV, @"Finishing Procedure: %@", [state objectForKey: @"Procedure"]);
    
    // make sure we're done casting before we end the procedure
    if( [playerController isCasting] ) {
		float timeLeft = [playerController castTimeRemaining];
		if( timeLeft <= 0 ) {
			[self performSelector: _cmd withObject: state afterDelay: 0.1];
		} else {
			log(LOG_DEV, @"Still casting (%.2f remains): Delaying procedure end.", timeLeft);
			[self performSelector: _cmd withObject: state afterDelay: timeLeft];
			return;
		}
		return;
    }
    
    [self cancelCurrentProcedure];
    
    // when we finish PreCombat, re-evaluate the situation
    if([[state objectForKey: @"Procedure"] isEqualToString: PreCombatProcedure]) {
		log(LOG_DEV, @"[Eval] After PreCombat");
		[self evaluateSituation];
		return;
    }

	// when we finish PostCombat, go back to evaluation
    if ([[state objectForKey: @"Procedure"] isEqualToString: PostCombatProcedure]) {
		log(LOG_DEV, @"[Eval] After PostCombat");
		[self evaluateSituation];
		return;
	}

    if ( [[state objectForKey: @"Procedure"] isEqualToString: RegenProcedure] ) {
		if ( [[state objectForKey: @"ActionsPerformed"] intValue] > 0 ) {
			log(LOG_REGEN, @"Starting regen!");
			[self performSelector: @selector(monitorRegen:) withObject: [[NSDate date] retain] afterDelay: 1.0];
		} else {
			// or if we didn't regen, go back to evaluate
			log(LOG_DEV, @"No regen, back to evaluate");
			[self evaluateSituation];
		}
	}

    // if we did the Patrolling procdure, go back to evaluate
    if([[state objectForKey: @"Procedure"] isEqualToString: PatrollingProcedure]) [self evaluateSituation];
	
	if([[state objectForKey: @"Procedure"] isEqualToString: CombatProcedure]) {
		log(LOG_DEV, @"Combat completed, moving to PostCombat (in combat? %d)", [playerController isInCombat]);
		[self performSelector: @selector(performProcedureWithState:) 
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys: PostCombatProcedure,		  @"Procedure", [NSNumber numberWithInt: 0],	  @"CompletedRules", nil]
				   afterDelay: (0.1)];
	}
}

- (void)performProcedureWithState: (NSDictionary*)state {
	log(LOG_DEV, @"performProcedureWithState called");

	// player dead?
	if ( [playerController isDead] ) {
		log(LOG_PROCEDURE, @"Player is dead! Aborting!");
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
			if( [[self procedureInProgress] isEqualToString: PreCombatProcedure])	[controller setCurrentStatus: @"Bot: Pre-Combat Phase"];
			else if( [[self procedureInProgress] isEqualToString: PostCombatProcedure]) [controller setCurrentStatus: @"Bot: Post-Combat Phase"];
			else if( [[self procedureInProgress] isEqualToString: RegenProcedure]) [controller setCurrentStatus: @"Bot: Regen Phase"];
			else if( [[self procedureInProgress] isEqualToString: PatrollingProcedure]) [controller setCurrentStatus: @"Bot: Patrolling Phase"];
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
	if (![movementController isMoving] && [combatController castingUnit] == target) {
		if (![self performProcedureMobCheck:target]) {
			[self finishCurrentProcedure: state];
			return;
		}
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
		// decision "tree"
		// if in combat, attack nearby
		// if not in combat, check for an add
		// if not in combat, should we loot?
		// if not in combat, should we find another?
		// evaluate...
		
		// kind of a hack right now, but it *should* work
		//	I'm running into a problem where PG will not loot after death, but instead move onto a hostile NOT in combat
		//	So lets add a check here, this isn't how I want it to operate, but it will work for now
		BOOL doCombatProcedure = YES;
		
		// check to see if we should choose looting over attacking
		if ( self.doLooting && [_mobsToLoot count] && ![playerController isInCombat]) {
			NSArray *inCombatUnits = [combatController validUnitsWithFriendly:_includeFriendly onlyHostilesInCombat:YES];
			
			// we can break out of this procedure early!
			if ( [inCombatUnits count] == 0 && !theCombatProfile.partyEnabled) {
				doCombatProcedure = NO;
				log(LOG_DEV, @"Skipping combat to loot.");
			} else if (theCombatProfile.partyEnabled) {
				// keep running the combat routine if we're in a group and the tank or assist is in combat
				Player *assistPlayer = [playersController playerWithGUID:theCombatProfile.assistUnitGUID];
				Player *tankPlayer = [playersController playerWithGUID:theCombatProfile.tankUnitGUID];
				BOOL StayInCombat = NO;
				if ([inCombatUnits count] != 0) StayInCombat = YES;
				else if ([assistPlayer isInCombat]) StayInCombat = YES;
				else if ([tankPlayer isInCombat]) StayInCombat = YES;
				if (!StayInCombat) {
					doCombatProcedure = NO;
					log(LOG_DEV, @"Skipping combat to loot.");
				}
			}
		}
		
		if ( doCombatProcedure ) {
			NSArray *units = [combatController validUnitsWithFriendly:_includeFriendly onlyHostilesInCombat:NO];
			NSArray *adds = [combatController allAdds];
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
				else if ( [rule target] == TargetAdd ){
					
					// only check for an add if we don't have one already!
					if ( [combatController addUnit] == nil ){
						for ( target in adds ){
							if ( [self evaluateRule: rule withTarget: target asTest: NO] ){
								// do something
								log(LOG_RULE, @"Match for %@ with add %@", rule, target);
								matchFound = YES;
								break;
							}
						}
					}
				}
				
				// pet
				else if ( [rule target] == TargetPet ){
					target = [playerController pet];
					
					if ( [self evaluateRule: rule withTarget: target asTest: NO] ){
						// do something
						log(LOG_RULE, @"Pet match for %@", rule);
						matchFound = YES;
						break;
					}
				}

				// If we don't have a target by this point we should try our combat target
//				else if ( [rule target] == TargetEnemy &&
				else if ( [combatController castingUnit] &&
						[[combatController castingUnit] isValid] && 
						![[combatController castingUnit] isDead] &&
						[self evaluateRule: rule withTarget: [combatController castingUnit] asTest: NO]
					) {
					target = [combatController castingUnit];
					matchFound = YES;
					break;
				}

				// loop through all units
				else{
					 
					//Unit *notInCombatUnit = nil;
					for ( target in units ){
						
						// special rule if we're NOT pvping
						if ( !self.isPvPing ){
							// if we're in combat, and the unit is not, ignore!
							if ( [playerController isInCombat] && ![target isInCombat] ) {
								log(LOG_DEV, @"Ignoring %@ since we're in combat and the target isn't!", target);
								continue;
							}
						}
						
						if ( [self evaluateRule: rule withTarget: target asTest: NO] ){
							// do something
							log(LOG_RULE, @"Match for %@ with unit %@", rule, target);
							log(LOG_DEV, @"  Player in combat: %d	Unit in combat: %d", [playerController isInCombat], [target isInCombat]);
							matchFound = YES;
							break;
						}
					}
				}

				if ( matchFound ) break;
			}
		}
	}
	// old-school for non-combat (just goes in order)
	else {
		
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
	
		if ( [rule target] != TargetNone ) {
			log(LOG_PROCEDURE, @"%@ %@ doing %@", [combatController unitHealthBar:target], target, rule );
		} else {
			log(LOG_PROCEDURE, @"%@ %@ doing %@", [combatController unitHealthBar:target], target, rule );
//			log(LOG_PROCEDURE, @"Doing %@", rule );
		}
			
		// target if needed!
		if ( [[self procedureInProgress] isEqualToString: CombatProcedure] && [rule target] != TargetNone) 
			[combatController stayWithUnit:target withType:[rule target]];
		
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
					
					// target yourself
					if ( [rule target] == TargetSelf ) {
						log(LOG_DEV, @"Targeting self");
						[playerController setPrimaryTarget: [playerController player]];
					} else 
					if ( [rule target] != TargetNone ){
						_castingUnit = target;
						[playerController setPrimaryTarget: target];
					}
					
					// Let the target change set in (generally this shouldn't be needed, but I've noticed sometimes the target doesn't switch)
					usleep([controller refreshDelay]);
										
					// do it!
					int actionResult = [self performAction:actionID];
					log(LOG_DEV, @"Action %u taken with result: %d", actionID, actionResult);
					
					// error of some kind :/
					if ( actionResult != ErrNone ){
						log(LOG_PROCEDURE, @"Attempted to do %u on %@ %d %d times", actionID, target, attempts, completed);
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
		
		// if we found a match, try again until we can't anymore!
		[self performSelector: _cmd
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
								[state objectForKey: @"Procedure"],				@"Procedure",
								[NSNumber numberWithInt: completed],		@"CompletedRules",
								[NSNumber numberWithInt: attempts+1],			@"RuleAttempts",			// but increment attempts
								rulesTried,										@"RulesTried",				// track how many times we've tried each rule
								[NSNumber numberWithInt:actionsPerformed],		@"ActionsPerformed",
								target,											@"Target", nil]
				   afterDelay: 0.1f]; 
		log(LOG_DEV, @"Rule executed, trying for more rules!");

		// If we resurected them lets give them a moment to repop before we assess them again
		if (wasResurrected && [playerController isFriendlyWithFaction: [target factionTemplate]] && [target isValid]) {

			log(LOG_DEV, @"Adding resurrection CD to %@", target);

			[blacklistController blacklistObject:target withReason:Reason_RecentlyResurrected];
			
		}
		// The idea is that this will improve decision making for healers and keep the bot from looking stupid
		if (wasFriend &&
			[target isValid] &&
			target != [playersController playerWithGUID:theCombatProfile.assistUnitGUID] &&
			target != [playersController playerWithGUID:theCombatProfile.tankUnitGUID] &&
			[playerController isFriendlyWithFaction: [target factionTemplate]]
			) {
			log(LOG_DEV, @"Adding friend GCD to %@", target);

			// If they were a friendly then lets put them on the friend GCD so we don't double heal or buff.
			[blacklistController blacklistObject:target withReason:Reason_RecentlyHelpedFriend];

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
	if (!target || target == nil) return YES;

	// Dismount if mounted, if we've gotten this far it should be safe to do so
	if ( [[playerController player] isMounted] ) [movementController dismount];
	
	// only do this for hostiles
	if (![playerController isHostileWithFaction: [target factionTemplate]]) return YES;
	
	// Doube check so we don't wast casts
	if ( [target isDead] ) return NO;

	if ( !self.theBehavior.meleeCombat && [movementController isMoving]) {
		log(LOG_PROCEDURE, @"Stopping movement to cast on %@.", target);
		[movementController stopMovement];
	}
	
	if ([movementController checkUnitOutOfRange:target]) return YES;

	// They're running and they're nothing we can do so lets bail
	log(LOG_PROCEDURE, @"Disengaging!");
	[combatController resetAllCombat];
	return NO;
}

#pragma mark -
#pragma mark Loot Helpers

- (Mob*)mobToLoot {
	// if our loot list is empty scan for missed mobs
	if ( ![_mobsToLoot count] ) [self lootScan];
    if ( ![_mobsToLoot count] ) return nil;
	
	Mob *mobToLoot = nil;
	// sort the loot list by distance
	[_mobsToLoot sortUsingFunction: DistanceFromPositionCompare context: [playerController position]];
	
	// find a valid mob to loot
	for ( mobToLoot in _mobsToLoot ) {
		if ( mobToLoot && [mobToLoot isValid] ) {
			if ( ![blacklistController isBlacklisted:mobToLoot] ) return mobToLoot;
			else log(LOG_LOOT, @"Found unit to loot but it's blacklisted! %@", mobToLoot);
		}
	}
	return nil;
}

- (void)lootScan {
	if ( !self.doLooting ) return;
	log(LOG_DEV, @"Scanning for missed mobs to loot.");
	NSArray *mobs = [mobController mobsWithinDistance: self.gatherDistance MobIDs:nil position:[playerController position] aliveOnly:NO];
	for (Mob *mob in mobs) {
		
		if (_doSkinning && _doNinjaSkin && [mob isSkinnable] && ![_mobsToLoot containsObject: mob]) {
			log(LOG_LOOT, @"[NinjaSkin] Adding %@ to skinning list.", mob);
			[_mobsToLoot addObject: mob];
		}
		
		if ([mob isLootable] && [mob isDead] && ![_mobsToLoot containsObject: mob] && ![blacklistController isBlacklisted:mob]) {
			log(LOG_LOOT, @"[LootScan] Adding %@ to loot list.", mob);
			[_mobsToLoot addObject: mob];
		}
	}
}

- (void)lootUnit: (WoWObject*) unit{

	// are we still in the air?  shit we can't loot yet!
	if ( ![playerController isOnGround] ) {
		
		// once the macro failed, so dismount if we need to
		if ( [[playerController player] isMounted] ) [movementController dismount];
		
		NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[unit cachedGUID]];
		NSNumber *count = [_lootDismountCount objectForKey:guid];
		if ( !count ) count = [NSNumber numberWithInt:1]; else count = [NSNumber numberWithInt:[count intValue] + 1];
		[_lootDismountCount setObject:count forKey:guid];
		
		log(LOG_LOOT, @"Player is still in the air, waiting to loot. Attempt %@", count);
		
		[self performSelector:@selector(lootUnit:) withObject:unit afterDelay:0.1f];
		return;
	}
	
	// playr moving, wait to loot
	if ( [movementController isMoving] ){
		log(LOG_DEV, @"Still moving, waiting to loot");
		[self performSelector:@selector(lootUnit:) withObject:unit afterDelay:0.1f];
		return;
	}
	
	BOOL isNode = [unit isKindOfClass: [Node class]];
	
	// looting?
    if ( self.doLooting || isNode ) {
		Position *playerPosition = [playerController position];
		float distanceToUnit = [playerController isOnGround] ? [playerPosition distanceToPosition2D: [unit position]] : [playerPosition distanceToPosition: [unit position]];
		[movementController turnTowardObject: unit];
		[controller setCurrentStatus: @"Bot: Looting"];
		
		self.lastAttemptedUnitToLoot = unit;
		
		if ( [unit isValid] && ( distanceToUnit <= 5.0 ) ) { //	 && (unitIsMob ? [(Mob*)unit isLootable] : YES)
			if ( [[playerController player] isMounted] ) [movementController dismount];
			log(LOG_LOOT, @"Looting : %@", unit);
			self.lootStartTime = [NSDate date];
			self.unitToLoot = unit;
			self.mobToSkin = (Mob*)unit;
			[blacklistController incrementAttemptForObject:unit];

			// Lets do this instead of the loot hotkey!
			[self interactWithMouseoverGUID: [unit GUID]];
			
			// normal lute delay
			float delayTime = 0.5;
			
			// If we do skinning and it may become skinnable
			if (_doSkinning && [self.mobToSkin isKindOfClass: [Mob class]] && [self.mobToSkin isNPC]) 
				delayTime = 1.5;				// if it's missing mobs that it should have skinned then increase this

			if (isNode) delayTime = 1.5; // if it's trying on nodes it just hit increase this

			[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: delayTime];
		} else {
			log(LOG_LOOT, @"Unit not within 5 yards (%d) or is invalid (%d), unable to loot - removing %@ from list", distanceToUnit <= 5.0, ![unit isValid], unit );
			// remove from list
			if ( ![self.unitToLoot isKindOfClass: [Node class]] ) [_mobsToLoot removeObject: self.unitToLoot];
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		}
	}
}

// Sometimes there isn't an item to loot!  So we'll use this to fire off the notification
- (void)verifyLootSuccess {
	
	// Check if the player is casting still (herbalism/mining/skinning)
	if ( [playerController isCasting] ){
		[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: 1.0f];
		return;
	}

	log(LOG_DEV, @"Verifying loot succes...");
	
	// Is the loot window stuck being open?
	if ( [lootController isLootWindowOpen] && _lootMacroAttempt < 3 ) {
		log(LOG_LOOT, @"Loot window open? ZOMG lets close it!");
		_lootMacroAttempt++;
		[lootController acceptLoot];
		[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: 1.0f];
		return;
	} else if ( _lootMacroAttempt >= 3 ){
		log(LOG_LOOT, @"Attempted to loot %d times, moving on...", _lootMacroAttempt);
	}
	
	// fire off notification (sometimes needed if the mob only had $$, or the loot failed)
	if ( self.unitToLoot) {
		log(LOG_DEV, @"Firing off loot success");
		// is it a mob?
		if ( [self.mobToSkin isKindOfClass: [Mob class]] && [self.mobToSkin isNPC] ) log(LOG_DEV, @"Is mob still lootable? %d", [(Mob*)self.unitToLoot isLootable] );
		[[NSNotificationCenter defaultCenter] postNotificationName: AllItemsLootedNotification object: [NSNumber numberWithInt:0]];	
	} else {
		log(LOG_DEV, @"verifyLootSuccess was called, but there was no mob luted.");
		// Return to evaluate since our luting was bugged r we attempted to relute
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
	}
}

// This is called when all items have actually been looted (the loot window will NOT be open at this point)
- (void)itemsLooted: (NSNotification*)notification {
	if ( !self.isBotting ) return;
	
	// If this event fired, we don't need to verifyLootSuccess! We ONLY need verifyLootSuccess when a body has nothing to loot!
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(verifyLootSuccess) object: nil];
	
	// This lets us know that the LAST loot was just from us looting a corpse (vs. via skinning or herbalism)
	if ( self.unitToLoot ){
		NSDate *currentTime = [NSDate date];
		
		int attempts = [blacklistController attemptsForObject:self.unitToLoot];
		
		// Unit was looted, remove from list!
		if ( [self.unitToLoot isKindOfClass: [Node class]] ){
			//[nodeController finishedNode: (Node*)self.unitToLoot];
			self.mobToSkin = nil;
			log(LOG_DEV, @"Node looted in %0.2f seconds after %d attempt%@", [currentTime timeIntervalSinceDate: self.lootStartTime], attempts, attempts == 1 ? @"" : @"s");
		}else{
			[_mobsToLoot removeObject: self.unitToLoot];
			log(LOG_DEV, @"Mob looted in %0.2f seconds after %d attempt%@. %d mobs to loot remain", [currentTime timeIntervalSinceDate: self.lootStartTime], attempts, attempts == 1 ? @"" : @"s", [_mobsToLoot count]);
		}
		
		// clear the attempts since it was successful
		[blacklistController clearAttemptsForObject:self.unitToLoot];
		
		// Not 100% sure why we need this, but it seems important?
		//[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(reachedUnit:) object: self.unitToLoot];
	}
	// Here from skinning!
	else if ( self.mobToSkin ){
		NSDate *currentTime = [NSDate date];
		log(LOG_LOOT, @"Skinning completed in %0.2f seconds", [currentTime timeIntervalSinceDate: self.skinStartTime]);		
		self.mobToSkin = nil;
	}
	
	// Lets skin the mob, or we're done!
	[self skinOrFinish];
	
	// No longer need this unit!
	self.unitToLoot = nil;
}

// called when ONE item is looted
- (void)itemLooted: (NSNotification*)notification {
	
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

- (void)skinOrFinish{	

	BOOL canSkin = NO;
	BOOL unitIsMob = ([self.mobToSkin isKindOfClass: [Mob class]] && [self.mobToSkin isNPC]);
	
	// Should we be skinning?
	if ( ( _doSkinning || _doHerbalism ) && self.mobToSkin && unitIsMob ) {
		// Up to skinning 100, you can find out the highest level mob you can skin by: ((Skinning skill)/10)+10.
		// From skinning level 100 and up the formula is simply: (Skinning skill)/5.
		int canSkinUpToLevel = 0;
		if (_skinLevel <= 100) canSkinUpToLevel = (_skinLevel/10)+10; else canSkinUpToLevel = (_skinLevel/5);
		
		if ( _doSkinning ) {
			if ( canSkinUpToLevel >= [self.mobToSkin level] ) {
				_skinAttempt = 0;
				[self skinMob:self.mobToSkin];
				canSkin = YES;
			} else {
				log(LOG_LOOT, @"The mob is above your max %@ level (%d).", ((_doSkinning) ? @"skinning" : @"herbalism"), canSkinUpToLevel);
			}
		}
	}
	
	// We're done looting+skinning!
	if ( !canSkin ) {
		NSDate *currentTime = [NSDate date];
		log(LOG_LOOT, @"All looting completed in %0.2f seconds", [currentTime timeIntervalSinceDate: self.lootStartTime]);
		
		// Reset our attempt variables!
		_lootMacroAttempt = 0;
		self.lastAttemptedUnitToLoot = nil;
		
		log(LOG_DEV, @"Evaluate After skinned");
		float delayTime = 0.1;

		// If you are trying to skin a disappeared corse you may need to increase the delay here
		if (_doSkinning) delayTime = 0.4;

		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: delayTime];
	}

	if ( ![playerController isCasting] ) [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
}

// It actually takes 1.2 - 2.0 seconds for [mob isSkinnable] to change to the correct status, this makes me very sad as a human, seconds wasted!
- (void)skinMob: (Mob*)mob {
    float distanceToUnit = [[playerController position] distanceToPosition2D: [mob position]];
	
	// We tried for 2.0 seconds, lets bail
	if ( _skinAttempt++ > 20 ) {
		log(LOG_LOOT, @"[Skinning] Mob is not valid (%d), not skinnable (%d) or is too far away (%d)", ![mob isValid], ![mob isSkinnable], distanceToUnit > 5.0f );
		self.mobToSkin = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return;
	}
	
	// Set to null so our loot notifier realizes we shouldn't try to skin again :P
	self.mobToSkin = nil;
	self.skinStartTime = [NSDate date];
	
	// Not able to skin :/
	if( ![mob isValid] || ![mob isSkinnable] || distanceToUnit > 5.0f ) {
// if its not skinnable lets go back to evaluation instead of skinning it again lol
//		[self performSelector: @selector(skinMob:) withObject:mob afterDelay:0.1f];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
		return;
    }
	
	[controller setCurrentStatus: @"Bot: Skinning"];
	
	log(LOG_LOOT, @"Skinning!");
	
	// Lets interact w/the mob!
	[self interactWithMouseoverGUID: [mob GUID]];
	
	// In the off chance that no items are actually looted
	[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: 0.5f];
	
}

#pragma mark -
#pragma mark [Input] CombatController

- (void)unitEnteredCombat: (NSNotification*)notification {
	if (![self isBotting]) return;
	
	Unit *unit = [notification object];
	
	log(LOG_COMBAT, @"%@ %@ entered combat!", [combatController unitHealthBar:unit], unit);
	
	// start a combat procedure if we're not in one!
	if ( ![self.procedureInProgress isEqualToString: CombatProcedure] ) {
		
		// If we're supposed to ignore combat while flying
		if (self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted]) {
			log(LOG_DEV, @"Ignoring combat with %@ since we're set to ignore combat while flying.", unit);
			return;
		}
		
		// make sure we're not flying mounted and in the air
		if ( self.theCombatProfile.ignoreFlying && ![playerController isOnGround] ){
			log(LOG_DEV, @"Ignoring combat with %@ since we're in the air!", unit);
			return;
		}
		
		log(LOG_COMBAT, @"Looks like an ambush, taking action!");

		[self cancelCurrentProcedure];

		[self actOnUnit:unit];
	} else {
		// If it's a player attacking us and we're on a mob then lets attack the player!
		if ( ( [[combatController castingUnit] isKindOfClass: [Mob class]] || [[combatController castingUnit] isPet] ) &&
			[combatController combatEnabled] &&
			!theCombatProfile.healingEnabled &&
			[unit isPlayer]) {

			log(LOG_COMBAT, @"%@ %@ has jumped me, Targeting Player!", [combatController unitHealthBar:unit], unit);
			[self cancelCurrentProcedure];
			
			[self actOnUnit:unit];
			
		} else {
			log(LOG_DEV, @"Already in combat procedure! Not acting on unit");
		}
	}
}

- (void)playerEnteringCombat: (NSNotification*)notification {
	if (![self isBotting]) return;
	[controller setCurrentStatus: @"Bot: Player in Combat"];
	log(LOG_COMBAT, @"Entering combat");
	[self evaluateSituation];
}

- (void)playerLeavingCombat: (NSNotification*)notification {
	if(![self isBotting]) return;
	_didPreCombatProcedure = NO;
	
	if ( [playerController isDead] ) return;

	// if we're already looting lets not interfere
	if ( [[controller currentStatus] isEqualToString: @"Bot: Looting"] || [[controller currentStatus] isEqualToString: @"Bot: Skinning"]) {
		log(LOG_DEV, @"Skipping post combat since we're already looting.");
		return;
	}
	// start post-combat after specified delay
	
	// This is an odd situation that can occur (still in CombatProcedure when we leave combat)
	//	But basically it comes from killing something, then while we're casting on another we leave combat
	//	To prevent weird shit, lets not move to PostCombat if we're in combat!
	log(LOG_COMBAT, @"Left combat! Current procedure: %@  Last executed: %@", self.procedureInProgress, _lastProcedureExecuted);
	
	//if(self.theRouteSet) [movementController stopMovement];
	[movementController resetMoveToObject];
	
	log(LOG_DEV, @"[Bot] should we evaluate after resetting the unit?");
	[self evaluateSituation];
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

- (BOOL)combatProcedureValidForUnit: (Unit*)unit{	
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
			log(LOG_DEV, @"Skipping combat to loot.");
		} else 
			if (theCombatProfile.partyEnabled) {
				// keep running the combat routine if we're in a group and the tank or assist is in combat
				Player *assistPlayer = [playersController playerWithGUID:theCombatProfile.assistUnitGUID];
				Player *tankPlayer = [playersController playerWithGUID:theCombatProfile.tankUnitGUID];
				BOOL StayInCombat = NO;
				if ([inCombatUnits count] != 0) StayInCombat = YES;
				else if ([assistPlayer isInCombat]) StayInCombat = YES;
				else if ([tankPlayer isInCombat]) StayInCombat = YES;
				if (!StayInCombat) {
					doCombatProcedure = NO;
					log(LOG_DEV, @"Skipping combat to loot.");
				}
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
		log(LOG_BLACKLIST, @"Ambushed by a blacklisted unit??  Ignoring %@ at %0.2f away", distance, unit);
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
				log(LOG_COMBAT, @"Still %0.2f away, moving to %@", distance, unit);
				[movementController moveToObject:unit];		//andNotify:YES
			}
			// we're in range
			else{
				log(LOG_COMBAT, @"In range, attacking!");
				readyToAttack = YES;
				//[movementController stopMovement];
			}
		} else {
			UInt32 movementFlags = [playerController movementFlags];
			if ( movementFlags & MovementFlag_Forward || movementFlags & MovementFlag_Backward ){
				log(LOG_COMBAT, @"Don't need to be in melee, stopping movement");
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
	//	else {
	//		log(LOG_COMBAT, @"We are already performing %@ so actOnUnit should not have been called!?", [self procedureInProgress]);
	//	}
	return;
}

/*
// this is called when any unit enters combat
- (void)addingUnit: (Unit*)unit {
    if (![self isBotting]) return;
    
    //if( ![[self procedureInProgress] isEqualToString: CombatProcedure] && [unit isValid] ) {
    //	  log(LOG_GENERAL, @"[Bot] Add! Stopping current procedure to attack.", unit);
    //	  [self cancelCurrentProcedure];
    //}
    
    float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
    if (self.isPvPing && ([[playerController position] verticalDistanceToPosition: [unit position]] > vertOffset)) {
		log(LOG_COMBAT, @"Added mob is beyond vertical offset limit; ignoring.");
		return;
    }
	
	// Don't attack if the player is mounted and in the air!
	if ( ![playerController isOnGround] && [[playerController player] isMounted] ) return;
	log(LOG_COMBAT, @"Adding %@", unit);
	
    if ( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
		NSString *unitName = ([unit name]) ? [unit name] : nil;
		// [GrowlApplicationBridge setGrowlDelegate: @""];
		[GrowlApplicationBridge notifyWithTitle: [NSString stringWithFormat: @"%@ Entering Combat", [unit isPlayer] ? @"Player" : @"Mob"]
									description: ( unitName ? [NSString stringWithFormat: @"[%d] %@ at %d%%", [unit level], unitName, [unit percentHealth]] : ([unit isPlayer]) ? [NSString stringWithFormat: @"[%d] %@ %@, %d%%", [unit level], [Unit stringForRace: [unit race]], [Unit stringForClass: [unit unitClass]], [unit percentHealth]] : [NSString stringWithFormat: @"[%d] %@, %d%%", [unit level], [Unit stringForClass: [unit unitClass]], [unit percentHealth]])
							   notificationName: @"AddingUnit"
									   iconData: [[unit iconForClass: [unit unitClass]] TIFFRepresentation]
									   priority: 0
									   isSticky: NO
								   clickContext: nil];		   
	}
    
    //[combatController disposeOfUnit: unit];
	return;
}*/

- (void)unitDied: (NSNotification*)notification{
	Unit *unit = [notification object];
	
	log(LOG_DEV, @"Unit %@ killed %@", unit, [unit class]);
	
	// unit dead, reset!
	[movementController resetMoveToObject];
	
	if ( [unit isNPC] ) log(LOG_DEV, @"NPC Died, flags: %d %d", [(Mob*)unit isTappedByMe], [(Mob*)unit isLootable] );
	
	if ( self.doLooting && [unit isNPC] ) {
		// make sure this mob is even lootable
		// sometimes the mob isn't marked as 'lootable' yet because it hasn't fully died (death animation or whatever)
		usleep(500000);
		
		if ( [(Mob*)unit isTappedByMe] || [(Mob*)unit isLootable] ) {
			
			// mob already in our list? in theory this should never happen (how could we kill a unit twice? lul)
			if ([_mobsToLoot containsObject: unit]) {
				log(LOG_LOOT, @"%@ was already in the loot list, removing first", unit);
				[_mobsToLoot removeObject: unit];
			}
			
			log(LOG_DEV, @"Adding %@ to loot list.", unit);
			[_mobsToLoot addObject: (Mob*)unit];
		} else{
			log(LOG_DEV, @"Mob %@ isn't lootable, ignoring", unit);
		}
	}
}

#pragma mark -
#pragma mark [Input] MovementController

- (void)reachedObject: (NSNotification*)notification{
	
	WoWObject *object = [notification object];
	
	// reached a node!
	if ( [object isKindOfClass: [Node class]] ){
		// dismount if we need to
		if ( [[playerController player] isMounted] ) [movementController dismount];
		[self lootUnit:object];
	} else if ( [object isNPC] && [(Unit*)object isDead] ){
		[self lootUnit:object];
	} else {
		// if it's a player, or a non-dead NPC, we must be doing melee combat
		if ( [object isPlayer] || ([object isNPC] && ![(Unit*)object isDead]) ){
			log(LOG_COMBAT, @"Reached melee range with %@", object);
			return;
		}
	}
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
	if ( eatClear && drinkClear ){
		log(LOG_REGEN, @"Finished after %0.2f seconds", timeSinceStart);
		[self evaluateSituation];
		return;
	} else 
		// should we be done?
		if ( timeSinceStart > 30.0f ) {
			log(LOG_REGEN, @"Ran for 30, done, regen too long!?");
			[self evaluateSituation];
			return;
		}
	[self performSelector: _cmd withObject: start afterDelay: 1.0f];
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

	log(LOG_EVALUATE, @"Evaluating for Ghost");

	Position *playerPosition = [playerController position];
	if( [playerController corpsePosition] && [playerPosition distanceToPosition: [playerController corpsePosition]] < 26.0 ) {
		// we found our corpse
		[controller setCurrentStatus: @"Bot: Waiting to Resurrect"];
		[movementController stopMovement];
		
		// set our next-revive wait timer
		if (!_reviveAttempt) _reviveAttempt = 1;
		else _reviveAttempt = _reviveAttempt*2;
		[macroController useMacroOrSendCmd:@"Resurrect"];	 // get corpse
		if ( _reviveAttempt > 15 ) _reviveAttempt = 15;
		log(LOG_GHOST, @"Waiting %d seconds to resurrect.", _reviveAttempt);
		[self performSelector: _cmd withObject: nil afterDelay: _reviveAttempt];
		return YES;
	}
	if ( ![movementController isMoving] ) [movementController resumeMovement];		
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

- (BOOL)evaluateForPartyFollow {
	if ( !theCombatProfile.partyEnabled || 
		!theCombatProfile.followUnit || 
		!theCombatProfile.followUnitGUID > 0x0 ) return NO;

	if ( [[controller currentStatus] isEqualToString: @"Bot: Looting"] || [[controller currentStatus] isEqualToString: @"Bot: Skinning"]) {
		log(LOG_PARTY, @"Skipping party follow since we're looting.");
		return NO;
	}
	
	if ([playerController isCasting]) return NO;
	
	log(LOG_EVALUATE, @"Evaluating for Party Follow");

	Player *followTarget = [playersController playerWithGUID:theCombatProfile.followUnitGUID];
	
	if ( (!followTarget || ![followTarget isValid]) && ![[controller currentStatus] isEqualToString: @"Bot: Following"] && !_lastGoodFollowPosition) {
		if (![[controller currentStatus] isEqualToString: @"Bot: Cannot Follow!"]) {
			[controller setCurrentStatus: @"Bot: Cannot Follow!"];
			log(LOG_PARTY, @"[Follow] No target found to follow!");
		}
		return NO;
	}
	
	// mount
	if ( theCombatProfile.mountEnabled && 
		[followTarget isMounted] && 
		![[playerController player] isMounted] 
		&& ![[playerController player] isSwimming] && ![playerController isInCombat] ){
		if ( [self mountNowParty] ) {
			log(LOG_MOUNT, @"Mounting...");
			[self performSelector: _cmd withObject: nil afterDelay: 2.0f];
			return NO;
		}
	}
	
	if ( ![followTarget isOnGround] && [[playerController player] isFlyingMounted] ) [self jumpIfAirMountOnGround];

	// Make sure we're on an air mount if we're supposed to be!
	if ( [followTarget isFlyingMounted] && ![[playerController player] isFlyingMounted] ) {
		log(LOG_PARTY, @"[Follow] Looks like I'm supposed to be on an air mount, dismounting.");
		[movementController dismount];
		return NO;
	}

	// Moving Now...
	float range = [[[playerController player] position] distanceToPosition: [followTarget position]];
	
	if (range == INFINITY && _lastGoodFollowPosition) {
		// Target has gone out of range so lets just go to the last know good position
		[controller setCurrentStatus: @"Bot: Cannot Follow!"];
		log(LOG_PARTY, @"[Follow] Lost target, proceeding to last known position!");

		[movementController moveToPosition:_lastGoodFollowPosition];

		// Check our position again shortly!
		[self performSelector: _cmd withObject: nil afterDelay: 0.1f];
		
		return YES;
		
	} else if (range == INFINITY) {
			log(LOG_PARTY, @"[Follow] Lost target, but there is no last known position!?");
	}
	
	// If we're on the ground and the leader isn't mounted then dismount
	if ( range <= theCombatProfile.followDistanceToMove && 
			![followTarget isMounted] && 
			[[playerController player] isMounted] && 
			[[playerController player] isOnGround] 
		) {
		log(LOG_PARTY, @"[Follow] Leader dismounted, so am I.");
		[movementController dismount];
	}
	
	// If we're technically in the air, but still close to the dismoutned leader, dismount
	if ( range < 15.0f && ![followTarget isMounted] &&  [[playerController player] isMounted] ) {
		log(LOG_PARTY, @"[Follow] Leader dismounted, so am I.");
		[movementController dismount];
	}
	
	if ( range <= theCombatProfile.followDistanceToMove ) {
		_lastGoodFollowPosition = nil;
		return NO;
	}

	if (![[controller currentStatus] isEqualToString: @"Bot: Following"]) {
		[controller setCurrentStatus: @"Bot: Following"];
		log(LOG_PARTY, @"[Follow] Not within %0.2f yards of target, %0.2f away, following.", theCombatProfile.followDistanceToMove, range);
	}
	
	// not moving directly to the unit's position! Within a range from it
	float start = theCombatProfile.yardsBehindTargetStart;
	float stop = theCombatProfile.yardsBehindTargetStop;
	float randomDistance = SSRandomFloatBetween( start, stop );
	
	Position *positionToMove = [[followTarget position] positionAtDistance:randomDistance withDestination:[playerController position]];

	_lastGoodFollowPosition = positionToMove;

	[movementController moveToPosition:positionToMove];

	// Check our position again shortly!
	[self performSelector: _cmd withObject: nil afterDelay: 0.1f];

	return YES;
}

- (BOOL)evaluateForCombatContinuation {

    if ( ![combatController inCombat] && ![playerController isInCombat]) return NO;

	log(LOG_EVALUATE, @"Evaluating for Combat Continuation");

	// Let's try just usin the player controller to match n see if this gives any better results
    if (![playerController isInCombat] && !theCombatProfile.partyEnabled) {
		// If we're actually not in combat and not in a party lets reset the combat table as there is no combat 'contination'
		[combatController resetAllCombat];
		return NO;
	}
	
	Unit *bestUnit = [combatController findUnitWithFriendly:_includeFriendly onlyHostilesInCombat:YES];
	if ( !bestUnit ) return NO;
	
	log(LOG_DEV, @"checking %@ for validity", bestUnit);
	if ([self combatProcedureValidForUnit:bestUnit] ) {
		log(LOG_DEV, @"[Combat Continuation] Found %@ to act on!", bestUnit);
		[self actOnUnit:bestUnit];
		[movementController stopMovement];
		return YES;
	}
	return NO;
}

- (BOOL)evaluateForCombatStart {
	
	// Don't look for new combat if we're fishin
	if ( [fishController isFishing] && !theCombatProfile.partyEnabled) return NO;

	if ( ![combatController combatEnabled] && !theCombatProfile.healingEnabled ) {
		self.preCombatUnit = nil;
		return NO;
	}
	
	// If we're supposed to ignore combat while flying lets return false
	if (self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted]) return NO;
	
	// If we're mounted and in the air don't look for a target
	if ( [[playerController player] isFlyingMounted] && ![[playerController player] isOnGround]) return NO;

	// If we're not a healer, not on assist and set to only attack when attacked then lets return false.
	if ( !theCombatProfile.healingEnabled && !theCombatProfile.assistUnit && theCombatProfile.onlyRespond) return NO;

	// If we're supposed to be following then follow!
	if ( theCombatProfile.followUnit && [[playersController playerWithGUID:theCombatProfile.followUnitGUID] isMounted]) return NO;
	
	log(LOG_EVALUATE, @"Evaluating for Combat Start");

	Position *playerPosition = [playerController position];
	
	// check for party mode assist
	if ( theCombatProfile.partyEnabled && theCombatProfile.assistUnit && theCombatProfile.assistUnitGUID > 0x0) {
		Player *assistPlayer = [playersController playerWithGUID:theCombatProfile.assistUnitGUID];
		if ( assistPlayer && [assistPlayer isValid] ) {
			UInt64 targetGUID = [assistPlayer targetID];
			if ( targetGUID > 0x0 ) {
				Mob *mob = [mobController mobWithGUID:targetGUID];
				if ( mob ) {
					if ( [assistPlayer isInCombat] ) {
						[movementController turnTowardObject: mob];
						log(LOG_PARTY, @" [Combat Start] assisting with %@", mob);
						[self actOnUnit: mob];
						return YES;
					}
				}
			}
		}
	} else
	if ( theCombatProfile.partyEnabled && theCombatProfile.assistUnit) {
		// IF assist is broke let's stop here.
		return NO;
	}
		
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
				log(LOG_COMBAT, @"[Combat Start] Found %@ and attacking.", unitToActOn);
				[movementController turnTowardObject: unitToActOn];
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
				log(LOG_PARTY, @" [Combat Start] helping %@", unit);
				[self actOnUnit: unit];
				return YES;
			}
		}
	}
	return NO;
}


-(BOOL) evaluateForRegen {
	
	// If we're mounted then let's not do anything that would cause us to dismount
	if ( [[playerController player] isMounted] ) return NO;

	// Don't try if we're fishin
	if ( [fishController isFishing] ) return NO;

	log(LOG_EVALUATE, @"Evaluating for Regen");

	// Check to continue regen if the bot was started durring regen
	
	if ( [auraController unit: [playerController player] hasBuffNamed: @"Food"] || [auraController unit: [playerController player] hasBuffNamed: @"Drink"] ){
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
	
	if (!performRegen) return NO;
	
	if ( [playerController isInCombat] ) {
		log(LOG_REGEN, @"Still in combat, waiting for regen!");
		return YES;
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

	// Don't try if we're fishin
	if ( [fishController isFishing] ) return NO;	// pretty sure this will be a good thing.. make sure it doesn't prevent fishing looting!

	if (!self.doLooting) return NO;

	// If we're mounted and in the air lets just skip loot scans
	if ( ![playerController isOnGround] && [[playerController player] isMounted]) return NO;
	
	// If we're supposed to be following then follow!
	if ( theCombatProfile.followUnit && [[playersController playerWithGUID:theCombatProfile.followUnitGUID] isMounted]) return NO;

	log(LOG_EVALUATE, @"Evaluating for Loot");

    // get potential units and their distances
    Mob *mobToLoot	= [self mobToLoot];
    if ( !mobToLoot ) return NO;
	
	Position *playerPosition = [playerController position];
    Unit *unitToActOn  = [combatController findUnitWithFriendly:_includeFriendly onlyHostilesInCombat:NO];
    
    float mobToLootDist	    = mobToLoot ? [[mobToLoot position] distanceToPosition: playerPosition] : INFINITY;
    float unitToActOnDist  = unitToActOn ? [[unitToActOn position] distanceToPosition: playerPosition] : INFINITY;
    
    // if theres a unit that needs our attention that's closer than the lute.
    if ( mobToLootDist > unitToActOnDist ) {
		log(LOG_LOOT, @"Mob is too close to loot: %0.2f > %0.2f", mobToLootDist, unitToActOnDist);
		return NO;
	}

	// if the mob is close, just loot it!
	if ( mobToLootDist <= 5.0 ) {
		[self performSelector: @selector(lootUnit:) withObject: mobToLoot afterDelay: 0.1f];
		return YES;
	} else
		// do we need to start moving to it?
		if ( mobToLoot != [movementController moveToObject] ) {
			if ( [mobToLoot isValid] && (mobToLootDist < INFINITY) ) {
				int attempts = [blacklistController attemptsForObject:mobToLoot];				
				// Looting failed :/ I doubt this will ever actually happen, probably more an issue with nodes, but just in case!
				if ( self.lastAttemptedUnitToLoot == mobToLoot && attempts >= 3 ){
					log(LOG_LOOT, @"Unable to loot %@ after %d attempts, removing from loot list", self.lastAttemptedUnitToLoot, attempts);
					[_mobsToLoot removeObject: self.unitToLoot];
				} else {
					_movingTowardMobCount = 0;
					log(LOG_DEV, @"Found mob to loot: %@ at dist %.2f", mobToLoot, mobToLootDist);
					[movementController moveToObject: mobToLoot];		// andNotify: YES
				}
				return YES;
			} else {
				log(LOG_LOOT, @"Mob found, but either isn't valid (%d), is too far away (%d)", [mobToLoot isValid], (mobToLootDist < INFINITY) );
				return NO;
			}
		} else {
			_movingTowardMobCount++;
			// gives us 6 seconds to move to the unit
			if ( _movingTowardMobCount <= 60 ){
				log(LOG_LOOT, @"We're already moving toward %@ (%@) %d", mobToLoot, [movementController moveToObject], _movingTowardMobCount);
				[movementController resumeMovement];
			} else {
				log(LOG_LOOT, @"Unable to reach %@, removing from loot list", mobToLoot);
				[movementController resetMoveToObject];
				[_mobsToLoot removeObject:mobToLoot];
			}
			return YES;
		}
	return NO;
}

- (BOOL)evaluateForMiningAndHerbalism {
	if (!_doMining && !_doHerbalism && !_doNetherwingEgg) return NO;

	// Don't try if we're fishin
	if ( [fishController isFishing] ) return NO;

	log(LOG_EVALUATE, @"Evaluating for Mining and Herbalism");

	Position *playerPosition = [playerController position];
    if ([movementController moveToObject]) return NO;
	
	// check for mining and herbalism
	NSMutableArray *nodes = [NSMutableArray array];
	if(_doMining)			[nodes addObjectsFromArray: [nodeController nodesWithinDistance: self.gatherDistance ofType: MiningNode maxLevel: _miningLevel]];
	if(_doHerbalism)		[nodes addObjectsFromArray: [nodeController nodesWithinDistance: self.gatherDistance ofType: HerbalismNode maxLevel: _herbLevel]];
	if(_doNetherwingEgg)	[nodes addObjectsFromArray: [nodeController nodesWithinDistance: self.gatherDistance EntryID: 185915 position:[playerController position]]];
	
	[nodes sortUsingFunction: DistanceFromPositionCompare context: playerPosition];
	
	if ([nodes count]) {
		// find a valid node to loot
		Node *nodeToLoot = nil;
		float nodeDist = INFINITY;
		
		for(nodeToLoot in nodes) {

			if ( ![nodeToLoot validToLoot] ){
				log(LOG_NODE, @"%@ is not valid to loot, ignoring...", nodeToLoot );
				continue;
			}
						
			NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[nodeToLoot cachedGUID]];
			NSNumber *count = [_lootDismountCount objectForKey:guid];
			if ( count ){
				// took .5 seconds or longer to fall!
				if ( [count intValue] > 4 ) {
					log(LOG_NODE, @"Failed to acquire node %@ after dismounting, ignoring...", nodeToLoot);
					[blacklistController blacklistObject:nodeToLoot withReason:Reason_NodeMadeMeFall];
				}
			}
			
			if ( nodeToLoot && [nodeToLoot isValid] && ![blacklistController isBlacklisted:nodeToLoot] ) {
				nodeDist = [playerPosition distanceToPosition: [nodeToLoot position]];
				break;
			}
		}
		
		// We have a valid node!
		if ([nodeToLoot isValid] && (nodeDist != INFINITY) ) {
			BOOL nearbyScaryUnits = [self scaryUnitsNearNode:nodeToLoot doMob:_nodeIgnoreMob doFriendy:_nodeIgnoreFriendly doHostile:_nodeIgnoreHostile];
			if ( !nearbyScaryUnits ) {
				[controller setCurrentStatus: @"Bot: Moving to node"];
				[movementController stopMovement];
				log(LOG_NODE, @"Found closest node to loot: %@ at dist %.2f", nodeToLoot, nodeDist);
				int attempts = [blacklistController attemptsForObject:nodeToLoot];
				if ( nodeDist <= DistanceUntilDismountByNode ){
					if ( self.lastAttemptedUnitToLoot == nodeToLoot && attempts >= 3 ){
						log(LOG_NODE, @"Unable to loot %@, should we add this to a blacklist?", self.lastAttemptedUnitToLoot);
						[self lootUnit:nodeToLoot];
						[blacklistController blacklistObject:nodeToLoot];
					} else {
						// log(LOG_NODE, @"Used to call reachedUnit for node here");
						[self lootUnit:nodeToLoot];
						return YES;
					}
				}
				/*
				// Should we be mounted before we move to the node?
				else if ( [self mountNow] ) {
					log(LOG_MOUNT, @"[Stay Mounted] Mounting...");
					[self performSelector: _cmd withObject: nil afterDelay: 2.0f];	
					return YES;
				} */else {
					// Safe to move to the node!
					[movementController moveToObject: nodeToLoot];		//andNotify: YES
				}
				return YES;
			}
		}
	}
	return NO;
}

- (BOOL)evaluateForFishing {
	if ( [movementController moveToObject] ) return NO;
	if ( !_doFishing ) return NO;

	// If we're supposed to be following then follow!
	if ( theCombatProfile.followUnit && [[playersController playerWithGUID:theCombatProfile.followUnitGUID] isMounted]) return NO;

	log(LOG_EVALUATE, @"Evaluating for Fishing.");
	
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
	
	return NO;
}

- (BOOL)evaluateForPatrol {
	if( ![self isBotting]) return NO;
	if( [playerController isDead]) return NO;
	
	// If we're already mounted then let's not do anything that would cause us to dismount
	if ( [[playerController player] isMounted] ) return NO;

	if ( [playerController isCasting] )return NO;

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

	// Look for corpses - resurection
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
			   afterDelay: (needToPause ? 0.7 : 0.1)];	// Havin a problem with mounts not completing so I'm increasing this

//	if (needToPause) return YES;

	return YES;
}

- (BOOL)evaluateSituation {
    if (![self isBotting])						return NO;
    if (![playerController playerIsValid:self])	return NO;
	
	log(LOG_EVALUATE, @"Evaluating Situation");
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];	
	
    // Order of Operations
    // 1) If we are dead, check to see if we can resurrect.
	// 2) Should we follow a player
    // 3) If we are moving to melee range, return.
    // 4) If we are in combat but not already attacking, scan for mobs to attack.
    // ---- Not in Combat after here ----
    // 5) Check for bodies to loot, loot if necessary.
    // 6) Scan for valid target in range, attack if found.
    // 7) Check for nodes to harvest, harvest if necessary.
    // 8) Resume movement if needed, nothing else to do.
	
	if ( [playerController isGhost] ) return [self evaluateForGhost];
	
	if ( [self evaluateForPVP] ) return YES;

	if ( [self evaluateForCombatContinuation] ) return YES;
	
    /* *** if we get here, we aren't in combat *** */
	
	if ( [self evaluateForRegen] ) return YES;

	if ( [self evaluateForPartyFollow] ) return YES;

	if ( [self evaluateForLoot] ) return YES;


   	if ( [self evaluateForPatrol] ) return YES;

	if ( [self evaluateForCombatStart] ) return YES;
	
	if ( [self evaluateForMiningAndHerbalism] ) return YES;
	
	if ( [self evaluateForFishing] ) return YES;

	// Should we be mounted?
		if ( ![movementController moveToObject] && [self mountNow] ) {
			log(LOG_MOUNT, @"Mounting...");
			[self performSelector: _cmd withObject: nil afterDelay: 2.0f];
			return YES;
		}
	
    // if there's nothing to do, make sure we keep moving if we aren't
    if ( self.theRouteSet ) {
		
		// resume movement if we're not moving!
		if ( /*![movementController isMoving] &&*/ ![movementController isPatrolling] ){
			[movementController resumeMovement];
		}
		
		[controller setCurrentStatus: @"Bot: Patrolling"];
    } else {
		if (![[controller currentStatus] isEqualToString: @"Bot: Cannot Follow!"] && 
			![[controller currentStatus] isEqualToString: @"Bot: Following"]) {
			[controller setCurrentStatus: @"Bot: Enabled"];
		}
		[self performSelector: _cmd withObject: nil afterDelay: 0.1];
    }
	
    return NO;
}

-(BOOL)mountNow{
	
	/*
	// some error checking
	if ( _mountAttempt > 8 ) {
		float timeUntilRetry = 15.0f - (-1.0f * [_mountLastAttempt timeIntervalSinceNow]);
		
		if ( timeUntilRetry > 0.0f ) {
			log(LOG_MOUNT, @"Will not mount for another %0.2f seconds", timeUntilRetry );
			return NO;
		} else {
			_mountAttempt = 0;
		}
	}

	if ( [mountCheckbox state] && ([miningCheckbox state] || [herbalismCheckbox state] || [fishingCheckbox state]) && ![[playerController player] isSwimming] && ![[playerController player] isMounted] && ![playerController isInCombat] ){		
		_mountAttempt++;
		log(LOG_MOUNT, @"Mounting attempt %d! Movement flags: 0x%X", _mountAttempt, [playerController movementFlags]);
		
		// record our last attempt
		[_mountLastAttempt release]; _mountLastAttempt = nil;
		_mountLastAttempt = [[NSDate date] retain];
		
		// actually mount
		Spell *mount = [spellController mountSpell:[mountType selectedTag] andFast:YES];
		if ( mount ) {
			// stop moving if we need to!
			[movementController stopMovement];
			usleep(100000);
			
			// Time to cast!
			int errID = [self performAction:[[mount ID] intValue]];
			if ( errID == ErrNone ){				
				log(LOG_MOUNT, @"Mounting started! No errors!");
				_mountAttempt = 0;
				usleep(500000);
			} else {
				log(LOG_MOUNT, @"Mounting failed! Error: %d", errID);
			}
			return YES;
		} else {
			log(LOG_MOUNT, @"No mounts found! PG will try to load them, you can do it manually on your spells tab 'Load All'");
			
			// should we load any mounts
			if ( [playerController mounts] > 0 && [spellController mountsLoaded] == 0 ) {
				log(LOG_MOUNT, @"Attempting to load mounts...");
				[spellController reloadPlayerSpells];				
			}
		}
	}*/
	
	return NO;
}

-(BOOL)mountNowParty{
	// some error checking
	if ( _mountAttempt > 8 ) {
		float timeUntilRetry = 15.0f - (-1.0f * [_mountLastAttempt timeIntervalSinceNow]);
		
		if ( timeUntilRetry > 0.0f ) {
			log(LOG_MOUNT, @"Will not mount for another %0.2f seconds", timeUntilRetry );
			return NO;
		} else {
			_mountAttempt = 0;
		}
	}
	
	_mountAttempt++;

	Player *followTarget = [playersController playerWithGUID:theCombatProfile.followUnitGUID];
	int theMountType = 1;	// ground
	if ( [followTarget isFlyingMounted] ) theMountType = 2;		// air
	Spell *mount = [spellController mountSpell:theMountType andFast:YES];

	if ( mount != nil ) {
		// stop moving if we need to!
		[movementController stopMovement];
		usleep(100000);
		// Time to cast!
		int errID = [self performAction:[[mount ID] intValue]];
		if ( errID == ErrNone ){				
			log(LOG_MOUNT, @"Mounting started! No errors!");
			_mountAttempt = 0;
			usleep(1500000);
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
	
	// make sure mounting will even work
	/*if ( [mountCheckbox state] && ![[playerController player] isMounted] && ![playerController isInCombat] ){
		if ( ![spellController mountSpell:[mountType selectedTag] andFast:YES] ){
			log(LOG_STARTUP, @"Mounting will fail!");
			NSBeep();
			NSRunAlertPanel(@"No valid mount spells found on your action bars!", @"You must have a valid mount spell on ANY action bar in order for 'stay mounted' to function! You may also want to click 'Load All' on the spells tab if you don't see any spells listed under 'Mounts'", @"Okay", NULL, NULL);
			return;
		}
	}*/
	
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
	
	// not a valid pvp behavior
	if ( self.pvpBehavior && ![self.pvpBehavior isValid] ){
		
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
	}
	
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
		_doNinjaSkin			= [ninjaSkinCheckbox state];

		_skinLevel			= [skinningSkillText intValue];
		
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
		
		
		[startStopButton setTitle: @"Stop Bot"];
		_didPreCombatProcedure = NO;
		_reviveAttempt = 0;
		
		// Bot started, lets reset our whisper history!
		[chatLogController clearWhisperHistory];

		self.startDate = [[NSDate date] retain];

		// set our route
		if ( self.theRouteSet ) [movementController setPatrolRouteSet:self.theRouteSet];

		// player is dead but not a ghost - we need to res!
// lets just allow evaluation to handle this as bot start may require other tasks prior to movment
//		if ( [playerController isDead] && ![playerController isGhost] ) [self rePop:[NSNumber numberWithInt:0]];
//			else [movementController resumeMovement];
	
		[controller setCurrentStatus: @"Bot: Enabled"];
		log(LOG_STARTUP, @" StartBot");
		self.isBotting = YES;
		
		// we have a PvP behavior!
		if ( self.pvpBehavior ){
			
			// TO DO - map these to bindings
			self.pvpPlayWarning = NO;// [pvpPlayWarningCheckbox state];
			self.pvpLeaveInactive = [self.pvpBehavior leaveIfInactive];
			
			// reset these in case they have them selected
			self.theRouteSet = nil;
			self.theRouteCollection = nil;
			
			log ( LOG_STARTUP, @" Starting with PvP");
			
			// what was the last BG we joined?  -1 will default it to choosing the first
			_pvpLastBattleground = -1;
			
			[self performSelector:@selector(pvpQueueOrStart) withObject:nil afterDelay:0.1f];
		}
		
		// normal, non-PvP
		else if ( self.theRouteSet ){
			[movementController setPatrolRouteSet:self.theRouteSet];
			
			// player is dead but not a ghost - we need to res!
			if ( [playerController isDead] && ![playerController isGhost] ){
				[self rePop:[NSNumber numberWithInt:0]];
			}
			else{
				[movementController resumeMovement];
			}
			
			[self evaluateSituation];
		}

		// Running in a mode with no route selected
		else {
			[self evaluateSituation];
		}
		log(LOG_DEV, @" StartBot");

		if ( [playerController isDead])	[controller setCurrentStatus: @"Bot: Player is Dead"];
			else [controller setCurrentStatus: @"Bot: Enabled"];
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
	
    [_mobsToLoot removeAllObjects];
    self.isBotting = NO;
    self.preCombatUnit = nil;
    [controller setCurrentStatus: @"Bot: Stopped"];
    
    log(LOG_GENERAL, @"[Bot] Stopped.");
	
	// stop our log out timer
	[_logOutTimer invalidate];_logOutTimer=nil;
	
	// make sure we're not fishing
	[fishController stopFishing];
    
    [startStopButton setTitle: @"Start Bot"];
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
	
	if ( [[entry text] isEqualToString: @"stay"] ){
		log(LOG_GENERAL, @"[Heal] Stop following");
		_shouldFollow = NO;
	}
	else if ( [[entry text] isEqualToString: @"heel"] ){
		log(LOG_GENERAL, @"[Heal] Start following again!");
		_shouldFollow = YES;
	}
}

#pragma mark AKA [Input] PlayerData

- (void)playerHasRevived: (NSNotification*)notification {
    if ( ![self isBotting] ) return;
    log(LOG_GENERAL, @"---- Player has revived!");
    [controller setCurrentStatus: @"Bot: Player has Revived"];
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
	[self evaluateSituation];
}

- (void)playerHasDied: (NSNotification*)notification {    
    if( ![self isBotting]) return;
	if ( ![playerController playerIsValid:self] ) return;
	
    log(LOG_GHOST, @"---- Player has died.");
    [controller setCurrentStatus: @"Bot: Player has Died"];
    
    [self cancelCurrentProcedure];		// this wipes all bot state (except pvp)
    [combatController resetAllCombat];	       // this wipes all combat state
	
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
		log(LOG_GENERAL, @"[Bot] We're a ghost, starting movement!");
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
	
	// time to stop botting + log!
	if ( logOutNow ){
		[self logOutWithMessage:logMessage];
	}
}

// called every 30 seconds
- (void)afkTimer: (NSTimer*)timer {
	
	// don't need this if we're botting since we're doing things!
	if ( self.isBotting || ![playerController playerIsValid] )
		return;
	
	//log(LOG_GENERAL, @"[AFK] Attempt: %d", _afkTimerCounter);
	
	
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
		log(LOG_GENERAL, @"[Bot] Spell %d didn't cast(%d): %@", actionID, lastErrorMessage, [playerController lastErrorMessage] );
		
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
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorOutOfRange object: nil];
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
		log(LOG_GENERAL, @"[Bot] Scanning nearby mobs within %0.2f of %@", _nodeIgnoreMobDistance, [node position]);
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

/*
 using System.Runtime.InteropServices;
 
 namespace Onyx.WoW
 {
 public class WoWFaction
 {
 private readonly FactionTemplateDbcRecord _template;
 private FactionDbcRecord _record;
 
 public WoWFaction(int id) : this(id, true)
 {
 }
 
 internal WoWFaction(int id, bool isTemplate)
 {
 Id = id;
 if (IsValid)
 {
 if (isTemplate)
 {
 _template = OnyxWoW.Db[ClientDb.FactionTemplate].GetRow(id).GetStruct<FactionTemplateDbcRecord>();
 _record = OnyxWoW.Db[ClientDb.Faction].GetRow(_template.FactionId).GetStruct<FactionDbcRecord>();
 }
 else
 {
 _record = OnyxWoW.Db[ClientDb.Faction].GetRow(id).GetStruct<FactionDbcRecord>();
 }
 }
 }
 
 public int Id { get; private set; }
 public string Name { get { return _record.Name; } }
 public string Description { get { return _record.Description; } }
 public WoWFaction ParentFaction { get { return new WoWFaction(_record.ParentFaction, false); } }
 public bool IsValid { get { return Id != 0; } }
 
 public WoWUnitRelation RelationTo(WoWFaction other)
 {
 return CompareFactions(this, other);
 }
 
 public static WoWUnitRelation CompareFactions(WoWFaction factionA, WoWFaction factionB)
 {
 FactionTemplateDbcRecord atmpl = factionA._template;
 FactionTemplateDbcRecord btmpl = factionB._template;
 
 if ((btmpl.FightSupport & atmpl.HostileMask) != 0)
 {
 return (WoWUnitRelation) 1;
 }
 
 for (int i = 0; i < 4; i++)
 {
 if (atmpl.EnemyFactions[i] == btmpl.Id)
 {
 return (WoWUnitRelation) 1;
 }
 if (atmpl.EnemyFactions[i] == 0)
 {
 break;
 }
 }
 
 if ((btmpl.FightSupport & atmpl.FriendlyMask) != 0)
 {
 return (WoWUnitRelation) 4;
 }
 
 for (int i = 0; i < 4; i++)
 {
 if (atmpl.FriendlyFactions[i] == btmpl.Id)
 {
 return (WoWUnitRelation) 4;
 }
 if (atmpl.FriendlyFactions[i] == 0)
 {
 break;
 }
 }
 
 if ((atmpl.FightSupport & btmpl.FriendlyMask) != 0)
 {
 return (WoWUnitRelation) 4;
 }
 
 for (int i = 0; i < 4; i++)
 {
 if (btmpl.FriendlyFactions[i] == atmpl.Id)
 {
 return (WoWUnitRelation) 4;
 }
 if (btmpl.FriendlyFactions[i] == 0)
 {
 break;
 }
 }
 
 return (WoWUnitRelation) (~(byte) ((uint) atmpl.FactionFlags >> 12) & 2 | 1);
 }
 
 public override string ToString()
 {
 if (!IsValid)
 {
 return "N/A";
 }
 return Name + ", Parent: " + ParentFaction;
 }
 
 #region Nested type: FactionDbcRecord
 
 [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
 private struct FactionDbcRecord
 {
 public int Id;
 private int _unk0;
 public int Allied;
 public int AtWar;
 private int _unk1;
 private int _unk2;
 private int _unk3;
 private int _unk4;
 private int _unk5;
 private int _unk6;
 public int Reputation;
 public int Mod1;
 public int Mod2;
 public int Mod3;
 private int _unk7;
 private int _unk8;
 private int _unk9;
 private int _unk10;
 public int ParentFaction;
 
 // 4 unknowns added recently. Cba to figure out what they're for
 // since I have no use for them!
 private int _unk11;
 private int _unk12;
 private int _unk13;
 private int _unk14;
 
 [MarshalAs(UnmanagedType.LPStr)]
 public string Name;
 
 [MarshalAs(UnmanagedType.LPStr)]
 public string Description;
 }
 
 #endregion
 
 #region Nested type: FactionTemplateDbcRecord
 
 [StructLayout(LayoutKind.Sequential)]
 private struct FactionTemplateDbcRecord
 {
 public int Id;
 public int FactionId;
 public int FactionFlags;
 public int FightSupport;
 public int FriendlyMask;
 public int HostileMask;
 
 [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)]
 public int[] EnemyFactions;
 
 [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)]
 public int[] FriendlyFactions;
 }
 
 #endregion
 }
 }
 */ 

typedef struct WoWClientDb {
    UInt32    _vtable;		// 0x0
    UInt32  isLoaded;		// 0x4
    UInt32  numRows;		// 0x8				// 49379
    UInt32  maxIndex;		// 0xC				// 74445
    UInt32  minIndex;		// 0x10				// 1
	UInt32	stringTablePtr; // 0x14
	UInt32 _vtable2;		// 0x18
	// array of row pointers after this...
	UInt32 firstRow;		// 0x1C
	UInt32 row2;			// 0x20
	UInt32 row3;			// 0x24
	UInt32 row4;			// 0x28
	
} WoWClientDb;

- (IBAction)test: (id)sender{
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	// hooked the spell function which was passed: 0xD87980 0xA8D268 0x194
	UInt32 spellPtr = 0xD87980;//;
	
	WoWClientDb db;
	[memory loadDataForObject: self atAddress: spellPtr Buffer:(Byte*)&db BufLength: sizeof(db)];
	
	if ( db.stringTablePtr ){
		int index;
		for ( index = 0; index < db.numRows; index++ ){
			
			UInt32 rowPtr = db.row2 + ( 4 * ( index - db.minIndex ) );
			UInt32 addressOfSpellStruct = 0x0;
			[memory loadDataForObject: self atAddress: rowPtr Buffer:(Byte*)&addressOfSpellStruct BufLength: sizeof(addressOfSpellStruct)];
			
			if ( addressOfSpellStruct ){
				
				UInt32 spellID = 0x0;
				[memory loadDataForObject: self atAddress: addressOfSpellStruct Buffer:(Byte*)&spellID BufLength: sizeof(spellID)];
				
				// valid spell ID
				if ( spellID <= db.maxIndex ){
					log(LOG_GENERAL, @"[%d:0x%X]  %d", index, addressOfSpellStruct, spellID);
				}
			}
		}
		
		
		
		
		
		/*
		 
		 UInt32 addr = 0x18A060 + 0x9C;		// offset ptr
		 // offset + 0x8  (0xA4)
		 UInt32 lowest = 0x220D970C;
		 int i = 0;
		 for ( i = 0; i < 100; i++ ){
		 
		 UInt32 ptr = 0, offset = 0;
		 [memory loadDataForObject: self atAddress: addr Buffer:(Byte*)&ptr BufLength: sizeof(ptr)];
		 [memory loadDataForObject: self atAddress: addr + 0x8 Buffer:(Byte*)&offset BufLength: sizeof(offset)];
		 
		 log(LOG_GENERAL, @"[%d:0x%X] 0x%X:0x%X", i, addr, offset, ptr);
		 
		 UInt32 tmp = 0;
		 [memory loadDataForObject: self atAddress: ptr Buffer:(Byte*)&tmp BufLength: sizeof(tmp)];
		 if ( tmp < lowest && tmp > 0x0 ){
		 //log(LOG_GENERAL, @" found 0x%X at %d", tmp, i);
		 lowest = tmp;
		 }
		 
		 addr += 0xA4;
		 }
		 
		 log(LOG_GENERAL, @"Lowest: 0x%X", lowest);*/
		
		
		
		
		/*
		 int index;
		 for ( index = 0; index < 40; index++ ){
		 UInt32 addressOfString = db.row2 + ( 4 * ( index - db.maxIndex ) );
		 
		 log(LOG_GENERAL, @"[Read] 0x%X", addressOfString);
		 
		 if ( addressOfString ){
		 UInt32 nextAddr = 0x0;
		 [memory loadDataForObject: self atAddress: addressOfString Buffer:(Byte*)&nextAddr BufLength: sizeof(nextAddr)];
		 
		 if ( nextAddr ){
		 
		 log(LOG_GENERAL, @" Finding string at base 0x%X", nextAddr);
		 
		 NSString *str = [memory stringForAddress:nextAddr + 0x70 withSize:50];
		 
		 log(LOG_GENERAL, @"String %@ at 0x%X", str, nextAddr);
		 }
		 }
		 }*/
		/*
		 
		 
		 int index;
		 for ( index = 0; index < 10; index ++ ){
		 
		 if ( index >= db.minIndex && index <= db.maxIndex ){
		 
		 UInt32 address = db.rows + ((index - db.minIndex) * 4);
		 
		 log(LOG_GENERAL, @"Reading 0x%X", address);
		 }
		 }*/
	}
	
	
	/*public Row GetRow(int index)
	 {
	 if (index >= MinIndex && index <= MaxIndex)
	 {
	 //g_CreatureFamilyDB.Rows[result - g_CreatureFamilyDB.minIndex];
	 return new Row(Memory.Read<IntPtr>((IntPtr) (_nativeDb.Rows.ToInt64() + ((index - MinIndex) * 4))));
	 }
	 return new Row(IntPtr.Zero);
	 }*/
	
	
	
	
	
	
	//[bindingsController executeBindingForKey:BindingPrimaryHotkey];
	
	//MULTIACTIONBAR1BUTTON1
	//INTERACTMOUSEOVER
	
	//[bindingsController doIt];
	
	return;
	
	// ugh why won't the below work!	
	//MemoryAccess *memory = [controller wowMemoryAccess];
	UInt32 factionPointer = 0, totalFactions = 0, startIndex = 0;
	[memory loadDataForObject: self atAddress: 0xD787C0 + 0x10 Buffer: (Byte*)&startIndex BufLength: sizeof(startIndex)];
	[memory loadDataForObject: self atAddress: 0xD787C0 + 0xC Buffer: (Byte*)&totalFactions BufLength: sizeof(totalFactions)];
	[memory loadDataForObject: self atAddress: 0xD787C0 + 0x20 Buffer: (Byte*)&factionPointer BufLength: sizeof(factionPointer)];
	
	
	UInt32 hash1, hash2;
	int faction1 = [[playerController player] factionTemplate];
	int faction2 = 3;
	
	
	GUID guid = [playerController targetID];
	
	Unit *unit = [mobController mobWithGUID:guid];
	if ( !unit ){
		// player?
		unit = [playersController playerWithGUID:guid];
	}
	
	if ( unit ){
		log(LOG_GENERAL, @"We have a unit %@ with faction %d", unit, [unit factionTemplate]);
		faction2 = [unit factionTemplate];
	}
	
	if ( faction1 >= startIndex && faction1 < totalFactions && faction2 >= startIndex && faction2 < totalFactions ){
		hash1 = (factionPointer + ((faction1 - startIndex)*4));
		hash2 = (factionPointer + ((faction2 - startIndex)*4));
		
		log(LOG_GENERAL, @"Hashes: 0x%X  0x%X", hash1, hash2);
		
		log(LOG_GENERAL, @"Result of compare: %d", [self CompareFactionHash:hash1 withHash2:hash2]);
	}
	
	
	/*
	 //[playerController isOnRightBoatInStrand];
	 
	 MemoryAccess *memory = [controller wowMemoryAccess];
	 int v0=0,i=0,tmp=0,ptr=0;
	 [memory loadDataForObject: self atAddress: 0x10E760C Buffer: (Byte*)&ptr BufLength: sizeof(ptr)];
	 [memory loadDataForObject: self atAddress: ptr + 180 Buffer: (Byte*)&v0 BufLength: sizeof(v0)];
	 
	 if ( v0 & 1 || !v0 )
	 v0 = 0;
	 
	 int type = 0;
	 for ( i = 0; !(v0 & 1); ){
	 [memory loadDataForObject: self atAddress: ptr + 172 Buffer: (Byte*)&tmp BufLength: sizeof(tmp)];
	 [memory loadDataForObject: self atAddress: tmp + v0 + 4 Buffer: (Byte*)&v0 BufLength: sizeof(v0)];
	 [memory loadDataForObject: self atAddress: v0 + 0x10 Buffer: (Byte*)&type BufLength: sizeof(type)];
	 log(LOG_GENERAL, @"[Test] Address: 0x%X %d", v0, type);
	 if ( !v0 )
	 break;
	 ++i;
	 }
	 
	 log(LOG_GENERAL, @"[Test] Total : %d", i);
	 
	 int v2=0, v3=0;
	 [memory loadDataForObject: self atAddress: ptr + 12 Buffer: (Byte*)&v2 BufLength: sizeof(v2)];
	 if ( v2 & 1 || !v2 )
	 v2 = 0;
	 v3 = 0;*/
	
	/*
	 int v0; // eax@1
	 int i; // edi@3
	 int v2; // eax@6
	 int v3; // esi@8
	 int v4; // eax@12
	 int v5; // eax@16
	 int v6; // ebx@18
	 
	 v0 = *(_DWORD *)(dword_10E760C + 180);
	 if ( v0 & 1 || !v0 )
	 v0 = 0;
	 for ( i = 0; !(v0 & 1); v0 = *(_DWORD *)(*(_DWORD *)(dword_10E760C + 172) + v0 + 4) )
	 {
	 if ( !v0 )
	 break;
	 ++i;
	 }
	 v2 = *(_DWORD *)(dword_10E760C + 12);
	 if ( v2 & 1 || !v2 )
	 v2 = 0;
	 v3 = 0;
	 LABEL_9:
	 if ( !(v2 & 1) )
	 {
	 while ( v2 )
	 {
	 ++v3;
	 if ( v2 )
	 v4 = *(_DWORD *)(dword_10E760C + 4) + v2;
	 else
	 v4 = dword_10E760C + 8;
	 v2 = *(_DWORD *)(v4 + 4);
	 if ( v2 & 1 )
	 {
	 v2 = 0;
	 }
	 else
	 {
	 if ( v2 )
	 goto LABEL_9;
	 v2 = 0;
	 }
	 if ( v2 & 1 )
	 break;
	 }
	 }
	 v5 = *(_DWORD *)(dword_10E760C + 56);
	 if ( v5 & 1 || !v5 )
	 v5 = 0;
	 v6 = 0;
	 LABEL_19:
	 if ( !(v5 & 1) )
	 {
	 while ( v5 )
	 {
	 ++v6;
	 v5 = *(_DWORD *)(*(_DWORD *)(dword_10E760C + 48) + v5 + 4);
	 if ( v5 & 1 )
	 {
	 v5 = 0;
	 }
	 else
	 {
	 if ( v5 )
	 goto LABEL_19;
	 v5 = 0;
	 }
	 if ( v5 & 1 )
	 break;
	 }
	 }
	 sub_1214D0("Object manager list status:", 7);
	 sub_122110("	Active objects:		     %u objects (%u visible)", 7, v3);
	 sub_122110("	Objects waiting to be freed: %u objects", 7, v6, i);
	 return 1;
	 */	
	
	
	
	
	
	
	
	
	
	
	/*
	 Position *pos = [[Position alloc] initWithX: -4968.875 Y:-1208.304 Z:501.715];
	 Position *playerPosition = [playerController position];
	 
	 // this is where we want to face!
	 float direction = [playerPosition angleTo:pos];
	 
	 log(LOG_GENERAL, @"Angle to target: %0.2f", direction);
	 [playerController setDirectionFacing:direction];
	 */
	//0-2pi. North is 0, west is pi/2, south is pi, east is 3pi/2.
	/*
	 int quadrant = 0;
	 
	 if ( 0.0f < direction && direction <= M_PI/2.0f ){
	 quadrant = 1;
	 }
	 else if ( M_PI/2.0f < direction && direction <= M_PI ){
	 quadrant = 2;
	 }
	 else if ( M_PI < direction && direction <= (3*M_PI)/2.0f ){
	 quadrant = 3;
	 }
	 else if ( (3.0f*M_PI)/2.0f < direction && direction <= 2*M_PI ){
	 quadrant = 4;
	 }*/
	
	/*
	 
	 float x, y;
	 float closeness = 10.0f;
	 
	 // negative x
	 if ( [pos xPosition] < 0.0f ){
	 x = -1.0f * (cosf(direction) * closeness);
	 }
	 // positive x
	 else{
	 x = (cosf(direction) * closeness);
	 }
	 
	 // negative y
	 if ( [pos yPosition] < 0.0f ){
	 y = -1.0f * (sinf(direction) * closeness);
	 }
	 // positive y
	 else{
	 y = (sinf(direction) * closeness);
	 }
	 
	 Position *newPos = [[Position alloc] initWithX:([pos xPosition] + x) Y:([pos yPosition] + y) Z:[pos zPosition]];
	 log(LOG_GENERAL, @"Change in position: {%0.2f, %0.2f}", x, y);
	 
	 [movementController setClickToMove:newPos andType:ctmWalkTo andGUID:0x0];
	 */
	
	//[controller traverseNameList];
	/*
	 
	 log(LOG_GENERAL, @"After  write:'%@'", [playerController lastErrorMessage]);
	 NSString *lastErrorMessageAltered = [playerController lastErrorMessage];*/
	//free(string);
	
	
	//(BOOL)saveDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;
	
	/*
	 
	 Position *playerPosition = [playerController position];
	 Position *destination = [Position positionWithX:5486.823f Y:297.879f Z:147.4111];
	 Position *pos = [destination positionAtDistance:15.0f withDestination:playerPosition];
	 
	 log(LOG_GENERAL, @"10 yards from %@ is %@", destination, pos);
	 //[movementController turnToward:pos];
	 
	 [movementController moveNearPosition:pos andCloseness:0.0f];
	 
	 
	 
	 */
	
	
	
	/*if ( self.theCombatProfile == nil )
	 self.theCombatProfile = [[combatProfilePopup selectedItem] representedObject];
	 
	 
	 log(LOG_GENERAL, @"Attack range: %0.2f", self.theCombatProfile.attackRange);
	 log(LOG_GENERAL, @"[Bot] Current best target: %@", [combatController findBestUnitToAttack]);*/
	
	
	
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

#define SimonAuraBlueEntryID	185872
#define SimonAuraYellowEntryID	185875
#define SimonAuraRedEntryID		185874
#define SimonAuraGreenEntryID	185873
//#define SimonRelicDischarger	185894
#define SimonApexisRelic		185890

#define BlueCluster				185828
#define GreenCluster			185830
#define RedCluster				185831
#define YellowCluster			185829

- (IBAction)doTheRelicEmanation: (id)sender{
	
	
	// interact with discharger
	// wait 1.2 seconds
	// send macro or command to click!
	
	// MUST rescan after each time, the object change!!
	
	/*Node *green = [nodeController closestNode:SimonAuraGreenEntryID];
	 Node *red = [nodeController closestNode:SimonAuraRedEntryID];
	 Node *blue = [nodeController closestNode:SimonAuraBlueEntryID];
	 Node *yellow = [nodeController closestNode:SimonAuraYellowEntryID];
	 
	 if ( green == nil ){
	 [self performSelector:@selector(doTheRelicEmanation:) withObject:nil afterDelay:0.1f];
	 return;
	 }
	 
	 log(LOG_GENERAL, @"Green: %@", green);
	 log(LOG_GENERAL, @"Red: %@", red);
	 log(LOG_GENERAL, @"Blue: %@", blue);
	 log(LOG_GENERAL, @"Yellow: %@", yellow);
	 
	 //NSArray *objects = [NSArray arrayWithObjects:green, red, blue, yellow, nil];
	 
	 //[memoryViewController monitorObjects:objects];
	 
	 
	 green = [nodeController closestNode:BlueCluster];
	 red = [nodeController closestNode:GreenCluster];
	 blue = [nodeController closestNode:RedCluster];
	 yellow = [nodeController closestNode:YellowCluster];
	 
	 
	 [self monitorObject: green];
	 [self monitorObject: red];
	 [self monitorObject: blue];
	 [self monitorObject: yellow];*/
	
	/*[memoryViewController monitorObject:green];
	 [memoryViewController monitorObject:red];
	 [memoryViewController monitorObject:blue];
	 [memoryViewController monitorObject:yellow];*/
	//[self performSelector:@selector(doTheRelicEmanation:) withObject:nil afterDelay:0.1];
}

- (void)monitorObject: (WoWObject*)obj{
	
	
	UInt32 addr1 = [obj baseAddress] + 0x1F8;
	UInt32 addr2 = [obj baseAddress] + 0x230;
	UInt32 addr3 = [obj baseAddress] + 0x250;
	UInt32 addr4 = [obj baseAddress] + 0x260;
	
	MemoryAccess *memory = [controller wowMemoryAccess];
    if(memory) {
		UInt16 value1 = 0, value2 = 0, value3 = 0, value4 = 0;
		[memory loadDataForObject: self atAddress: addr1 Buffer: (Byte *)&value1 BufLength: sizeof(value1)];
		[memory loadDataForObject: self atAddress: addr2 Buffer: (Byte *)&value2 BufLength: sizeof(value2)];
		[memory loadDataForObject: self atAddress: addr3 Buffer: (Byte *)&value3 BufLength: sizeof(value3)];
		[memory loadDataForObject: self atAddress: addr4 Buffer: (Byte *)&value4 BufLength: sizeof(value4)];
		
		log(LOG_GENERAL, @"%d %d %d %d %@", value1, value2, value3, value4, obj);
	}
	
	
	if ( [obj isValid] ){
		[self performSelector:@selector(monitorObject:) withObject:obj afterDelay:0.1f];
	}
	else{
		log(LOG_GENERAL, @"%@ is no longer valid...", obj);
	}
	
}

#pragma mark New PvP

- (void)pvpQueueOrStart{

	// once the error messages are moved to startBot, remove the below comment
	//self.isPvPing = YES;
	
	// are we supposed to do random? can we?
	if ( [self.pvpBehavior random] && ![self.pvpBehavior canDoRandom] ){
		log(LOG_STARTUP, @"Unabled to queue for a random BG, your PvP Behavior doesn't have all BGs enabled!");
		NSBeep();
		NSRunAlertPanel(@"Unable to do random BGs", @"Unable to do random BGs, your behavior doesn't have all BGs enabled with a RouteSet!", @"Okay", NULL, NULL);
		return;
	}

	// is the player already in a BG?
	UInt32 zone = [playerController zone];
	if ( [playerController isInBG:zone] ){
		
		if ( [self pvpSetEnvironmentForZone] ){
			self.isPvPing = YES;
			[self pvpStart];
		}
		else{
			log(LOG_PVP, @" should never be here really, but if so, we weren't able to set the PvP environment!");
		}
	}
	// player isn't in a BG, so we need to queue!
	else{
		self.isPvPing = YES;
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
				log(LOG_PVP, @" setting PvP route set to %@", self.theRouteSet);
				return YES;
			}
		}
	}
	
	log(LOG_PVP, @" no pvp route found!");
	
	return NO;	
}

- (void)pvpQueueBattleground{
	
	// error checking (removed valid player and !isPvPing)
	UInt32 zone = [playerController zone];
	
	if ( [playerController isInBG:zone] ){
		log(LOG_PVP, @" not queueing for BG, already in a BG!");
		return;
	}
	if ( [playerController battlegroundStatus] == BGQueued ){
		log(LOG_PVP, @" already queued, no need to try again!");
		return;
	}
	if ( !self.pvpBehavior ){
		log(LOG_PVP, @" no valid pvp behavior found, unable to queue!");
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
	
	// open PvP screen
	[chatController sendKeySequence:[NSString stringWithFormat: @"%c", 'h']];
	usleep(100000);
	
	// move to the BG Tab
	[macroController useMacroOrSendCmd:@"BGMoveToBGTab"];
	usleep(100000);
	
	// here we need to determine which to select
	if ( [self.pvpBehavior random] ){
	
		// scroll up to be safe
		[macroController useMacroOrSendCmd:@"BGScrollUp"];
		usleep(100000);
		
		// click the first one (random)
		[macroController useMacroOrSendCmd:@"BGClickType1"];
		usleep(100000);
	}
	// choosing an actual BG
	else{
		log(LOG_PVP, @" choosing a BG to join, cycling through all available in the pvp behavior");
		
		Battleground *bg = nil;
		
		// grab the first BG
		if ( _pvpLastBattleground == -1 ){
			bg = [self.pvpBehavior battlegroundForIndex:0];
			_pvpLastBattleground = 0;
			log(LOG_PVP, @"selecting first bg: %@", bg);
		}
		
		else{
			bg = [self.pvpBehavior battlegroundForIndex:++_pvpLastBattleground];
			log(LOG_PVP, @"selecting next bg: %@", bg);
			
			// we've gone too far! grab the first!
			if ( bg == nil ){
				bg = [self.pvpBehavior battlegroundForIndex:0];
				_pvpLastBattleground = 0;
				log(LOG_PVP, @"selecting first bg: %@", bg);
			}
		}
		
		// we have a BG we want to queue for!
		if ( bg ){
			
			// scroll up to be safe
			[macroController useMacroOrSendCmd:@"BGScrollUp"];
			usleep(100000);
			
			if ( [bg zone] == ZoneArathiBasin ){
				[macroController useMacroOrSendCmd:@"BGClickType4"];
			}
			else if ( [bg zone] == ZoneAlteracValley ){
				[macroController useMacroOrSendCmd:@"BGClickType2"];
			}
			else if ( [bg zone] == ZoneEyeOfTheStorm ){
				[macroController useMacroOrSendCmd:@"BGClickType5"];
			}
			else if ( [bg zone] == ZoneIsleOfConquest ){
				[macroController useMacroOrSendCmd:@"BGScrollDown"];
				usleep(100000);
				[macroController useMacroOrSendCmd:@"BGClickType5"];
			}
			else if ( [bg zone] == ZoneStrandOfTheAncients ){
				[macroController useMacroOrSendCmd:@"BGScrollDown"];
				usleep(100000);
				[macroController useMacroOrSendCmd:@"BGClickType4"];
			}
			else if ( [bg zone] == ZoneWarsongGulch ){
				[macroController useMacroOrSendCmd:@"BGClickType3"];
			}
			
			usleep(100000);
		}
	}
	
	// join queue
	[macroController useMacroOrSendCmd:@"BGClickJoin"];
	usleep(100000);
	
	// close PvP screen
	[chatController sendKeySequence:[NSString stringWithFormat: @"%c", 'h']];
	usleep(100000);
	
	// did it not work? try again in 10 seconds? (not being used for now)
	if ( [playerController battlegroundStatus] != BGQueued ){
		log(LOG_PVP, @" error, we just queued for the BG, but we're not queued? hmmm");
	}
	
	self.pvpAntiAFKCounter = 0;
	[controller setCurrentStatus: @"PvP: Waiting to join Battleground."];
	[self pvpAntiAFK];
	
	// To account for sometimes the queue failing, lets try to join after minute or two just in case?
	/*float nextCheck = SSRandomFloatBetween(60.0f, 120.0f);
	[self performSelector: @selector(pvpQueueBattleground) withObject: nil afterDelay:nextCheck];*/
	
	// try to queue again in case it failed!
	[self performSelector: @selector(pvpQueueRetry) withObject: nil afterDelay:1.0f];
	
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
	
	log(LOG_PVP, @" still not queued, trying again!");
	
	// cancel previous requests
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(pvpQueueBattleground) object: nil];
	[self pvpQueueBattleground];
}

// so simple
- (void)pvpStart{
	
	log(LOG_PVP, @" pvp starting...");
	
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
	
	// time to move
	[movementController resumeMovement];


	// Start our monitor!
	_pvpIsInBG = YES;
	if ( !_pvpTimer )
		_pvpTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f target: self selector: @selector(pvpMonitor:) userInfo: nil repeats: YES];
}

- (void)pvpStop {
	
	log(LOG_PVP, @" pvp stopped");

	// reset a few things (don't want to do stop bot here)
	[movementController stopMovement];
    [self cancelCurrentProcedure];
	[movementController resetMovementState];
    [combatController resetAllCombat];
	[blacklistController clearAll];
    self.isBotting = NO;
    self.preCombatUnit = nil;
	[fishController stopFishing];

    self.pvpLeaveInactive = NO;
    self.pvpPlayWarning = NO;
    self.pvpAntiAFKCounter = 0;
	
	[_pvpTimer invalidate]; _pvpTimer = nil;
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
		
		log(LOG_PVP, @" player has left the battleground...");
		
		// Stop the bot! (this could be triggered by our marks check, but of course someone could have maxed marks)
		if ( self.isBotting ){
			[self pvpStop];
		}
		
		// Only requeue if we're PvPing!
		if ( self.isPvPing ){
			
			// check for deserter
			BOOL hasDeserter = NO;
			if( [player isValid] && [auraController unit: player hasAura: DeserterSpellID] ) {
				hasDeserter = YES;
			}
			
			if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
				// [GrowlApplicationBridge setGrowlDelegate: @""];
				[GrowlApplicationBridge notifyWithTitle: [NSString stringWithFormat: @"Battleground Complete"]
											description: (hasDeserter ? @"Waiting for Deserter to fade." : @"Will re-queue in 15 seconds.")
									   notificationName: @"BattlegroundLeave"
											   iconData: (([controller reactMaskForFaction: [player factionTemplate]] & 0x2) ? [[NSImage imageNamed: @"BannerAlliance"] TIFFRepresentation] : [[NSImage imageNamed: @"BannerHorde"] TIFFRepresentation])
											   priority: 0
											   isSticky: NO
										   clickContext: nil];		   
			}
			
			if ( hasDeserter ) {
				log(LOG_PVP, @"[PvP] Deserter! Waiting for deserter to go away :(");
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
			log(LOG_PVP, @" PvP environment valid. Starting bot in 5 seconds...");
			[controller setCurrentStatus: @"PvP: Starting Bot in 5 seconds..."];
			
			// in theory this shouldn't happen as there should be enough error check before we start the bot (although I guess someone could change the PvP behavior while it's running)
			if ( ![self pvpSetEnvironmentForZone] ){
				log(LOG_PVP, @" no valid environment found for pvp! Nooo! Starting will fail :(");
				[controller setCurrentStatus: @"PvP: Unable to start PvP, check log files"];
			}
			[self performSelector: @selector(pvpStart) withObject: nil afterDelay: 5.0f];
		}
	}
	
	// We can do some checks in here amirite?
	if ( _pvpIsInBG && isPlayerInBG ){
		
		if ( self.isPvPing ){
			
			// Play warning!
			if( self.pvpPlayWarning ) {
				if( [auraController unit: player hasAura: IdleSpellID] || [auraController unit: player hasAura: InactiveSpellID]) {
					[[NSSound soundNamed: @"alarm"] play];
					log(LOG_PVP, @"[PvP] Idle/Inactive debuff detected!");
				}
			}
			
			// Leave BG?
			if( [auraController unit: player hasAura: InactiveSpellID] && self.pvpLeaveInactive ) {
				// leave the battleground
				log(LOG_PVP, @"[PvP] Leaving battleground due to Inactive debuff.");
				
				[macroController useMacroOrSendCmd:@"LeaveBattlefield"];
			}
		}
		
		// Check to see if we have been awarded a mark!	 If so the BG has closed!
		/*if ( _pvpMarks > 0 && [itemController pvpMarks] > _pvpMarks ){
		 
		 // Lets stop botting!
		 if ( self.isBotting ){
		 [self stopBot: nil];
		 
		 log(LOG_GENERAL, @"[PvP] BG has ended, botting stopped. %d > %d", [itemController pvpMarks], _pvpMarks );
		 [controller setCurrentStatus: @"PvP: BG has ended, botting stopped."];
		 }
		 }*/
	}
}

// this will keep us from going afk
- (void)pvpAntiAFK {
	if ( !self.isBotting )							return;
	if ( ![playerController playerIsValid:self] )   return;
	
    if ( self.isPvPing ) {
		
		if ( [playerController isInBG:[playerController zone]] ){
			log(LOG_PVP, " player is in BG, cancelling anti-afk");
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

@end


