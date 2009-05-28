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

#import "BetterSegmentedControl.h"
#import "Behavior.h"
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

#import "ScanGridView.h"
#import "TransparentWindow.h"

#import <Growl/GrowlApplicationBridge.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

#define USE_ITEM_MASK       0x80000000
#define USE_MACRO_MASK      0x40000000

#define DeserterSpellID         26013
#define HonorlessTargetSpellID  2479 
#define HonorlessTarget2SpellID 46705
#define IdleSpellID             43680
#define InactiveSpellID         43681
#define PreparationSpellID      44521
#define WaitingToRezSpellID     2584

@interface BotController ()

@property (readwrite, retain) RouteSet *theRoute;
@property (readwrite, retain) Behavior *theBehavior;
@property (readwrite, retain) CombatProfile *theCombatProfile;
    
@property (readwrite, retain) NSDate *stopDate;
@property (readwrite, retain) Mob *mobToSkin;
@property (readwrite, retain) Unit *preCombatUnit;

// pvp
@property (readwrite, retain) Mob *pvpBattlemaster;
@property (readwrite, assign) int pvpEntryID;
@property (readwrite, assign) BOOL isPvPing;
@property (readwrite, assign) BOOL pvpInBG;
@property (readwrite, assign) BOOL pvpAutoQueue;
@property (readwrite, assign) BOOL pvpAutoJoin;
@property (readwrite, assign) BOOL pvpPlayWarning;
@property (readwrite, assign) BOOL pvpLeaveInactive;
@property (readwrite, assign) BOOL pvpAutoRelease;
@property (readwrite, assign) int pvpCheckCount;

@property (readwrite, assign) BOOL doLooting;
@property (readwrite, assign) float gatherDistance;

@end

@interface BotController (Internal)

- (void)timeUp: (id)sender;

- (void)preRegen;
- (void)evaluateRegen: (NSDictionary*)regenDict;

- (BOOL)isUnitValidToAttack: (Unit*)unit fromPosition: (Position*)position ignoreDistance: (BOOL)ignoreDistance;

- (BOOL)evaluateRule: (Rule*)rule withTarget: (Unit*)target asTest: (BOOL)test;
- (void)performProcedureWithState: (NSDictionary*)state;
- (void)playerHasDied: (NSNotification*)noti;

// pvp
- (void)pvpStop;
- (void)pvpStart;

@end


@implementation BotController

+ (void)initialize {
    
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool: NO],      @"IgnoreRoute",
                                   [NSNumber numberWithBool: YES],      @"AttackAnyLevel",
                                   [NSNumber numberWithFloat: 50.0],    @"GatheringDistance",
                                   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoJoin",
                                   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoQueue",
                                   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoRelease",
                                   [NSNumber numberWithInt: NSOnState], @"PvPPlayWarningSound",
                                   [NSNumber numberWithInt: NSOnState], @"PvPLeaveWhenInactive",
                                   nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasDied:) name: PlayerHasDiedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasRevived:) name: PlayerHasRevivedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsValid:) 
                                                     name: PlayerIsValidNotification 
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsInvalid:) 
                                                     name: PlayerIsInvalidNotification 
                                                   object: nil];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(auraGain:) 
                                                     name: BuffGainNotification 
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(auraFade:) 
                                                     name: BuffFadeNotification 
                                                   object: nil];


        
        _procedureInProgress = nil;
        _didPreCombatProcedure = NO;
        
        _mobsToLoot = [[NSMutableArray array] retain];
        
        // wipe pvp options
        self.isPvPing = NO;
        self.pvpAutoRelease = NO;
        self.pvpAutoQueue = NO;
        self.pvpAutoJoin = NO;
        self.pvpBattlemaster = nil;
        self.pvpEntryID = 0;
        self.pvpInBG = NO;
        self.pvpLeaveInactive = NO;
        self.pvpPlayWarning = NO;
		
        [NSBundle loadNibNamed: @"Bot" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = [self.view frame].size;
    
    [shortcutRecorder setCanCaptureGlobalHotKeys: YES];
    [startstopRecorder setCanCaptureGlobalHotKeys: YES];
    [petAttackRecorder setCanCaptureGlobalHotKeys: YES];
    [interactWithRecorder setCanCaptureGlobalHotKeys: YES];
    
    KeyCombo combo1 = { NSShiftKeyMask, kSRKeysF13 };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"HotkeyCode"])
        combo1.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"HotkeyCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"HotkeyFlags"])
        combo1.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"HotkeyFlags"] intValue];

    KeyCombo combo2 = { NSCommandKeyMask, kSRKeysEscape };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopCode"])
        combo2.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopFlags"])
        combo2.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopFlags"] intValue];
    
    KeyCombo combo3 = { NSShiftKeyMask, kVK_ANSI_T };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"PetAttackCode"])
        combo3.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"PetAttackCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"PetAttackFlags"])
        combo3.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"PetAttackFlags"] intValue];
        
    KeyCombo combo4 = { 0, -1 };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"InteractWithTargetCode"])
        combo4.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"InteractWithTargetCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"InteractWithTargetFlags"])
        combo4.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"InteractWithTargetFlags"] intValue];
    
    [shortcutRecorder setDelegate: nil];
    [startstopRecorder setDelegate: self];
    [petAttackRecorder setDelegate: nil];
    [interactWithRecorder setDelegate: nil];

    [shortcutRecorder setKeyCombo: combo1];
    [startstopRecorder setKeyCombo: combo2];
    [petAttackRecorder setKeyCombo: combo3];
    [interactWithRecorder setKeyCombo: combo4];
    
    [shortcutRecorder setDelegate: self];
    [petAttackRecorder setDelegate: self];
    [interactWithRecorder setDelegate: self];
    
    // set up overlay window
    [overlayWindow setLevel: NSFloatingWindowLevel];
    if([overlayWindow respondsToSelector: @selector(setCollectionBehavior:)]) {
        [overlayWindow setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];
    }
    
    [self updateStatus: nil];
}

@synthesize theRoute;
@synthesize theBehavior;
@synthesize theCombatProfile;

@synthesize view;
@synthesize isBotting = _isBotting;
@synthesize procedureInProgress = _procedureInProgress;
@synthesize mobToSkin = _mobToSkin;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize preCombatUnit;
@synthesize pvpBattlemaster;
@synthesize pvpEntryID;
@synthesize pvpInBG = _pvpInBG;
@synthesize isPvPing = _isPvPing;
@synthesize pvpAutoQueue = _pvpAutoQueue;
@synthesize pvpAutoJoin = _pvpAutoJoin;
@synthesize pvpPlayWarning = _pvpPlayWarning;
@synthesize pvpLeaveInactive = _pvpLeaveInactive;
@synthesize pvpAutoRelease = _pvpAutoRelease;
@synthesize pvpCheckCount = _pvpCheckCount;

@synthesize stopDate;
@synthesize doLooting       = _doLooting;
@synthesize gatherDistance  = _gatherDist;

- (NSString*)sectionTitle {
    return @"Start/Stop Bot";
}

- (CombatProfileEditor*)combatProfileEditor {
    return [CombatProfileEditor sharedEditor];
}

#pragma mark -

int DistanceFromPositionCompare(id <UnitPosition> unit1, id <UnitPosition> unit2, void *context) {
    
    //PlayerDataController *playerData = (PlayerDataController*)context; [playerData position];
    Position *position = (Position*)context; 

    float d1 = [position distanceToPosition: [unit1 position]];
    float d2 = [position distanceToPosition: [unit2 position]];
    if (d1 < d2)
        return NSOrderedAscending;
    else if (d1 > d2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}


#pragma mark -

- (void)testRule: (Rule*)rule {
    Unit *unit = [mobController playerTarget];
    if(!unit) unit = [playersController playerTarget];

    PGLog(@"Testing rule with target: %@", unit);
    BOOL result = [self evaluateRule: rule withTarget: unit asTest: YES];
    NSRunAlertPanel(TRUE_FALSE(result), [NSString stringWithFormat: @"%@", rule], @"Okay", NULL, NULL);
}

- (BOOL)evaluateRule: (Rule*)rule withTarget: (Unit*)target asTest: (BOOL)test {
    //PGLog(@"Checking rule %@.", rule);
    //BOOL eval = [rule isMatchAll] ? YES : NO;

    int numMatched = 0, needToMatch = 0;
    if([rule isMatchAll]) {
        for(Condition *condition in [rule conditions]) {
            if( [condition enabled]) needToMatch++;
        }
    }
    
    if(needToMatch == 0) needToMatch = 1;
    
    Player *thePlayer = [playerController player];
    
    //PGLog(@"    Need to match: %d", needToMatch);
    
    for(Condition *condition in [rule conditions]) {
        //PGLog(@"Checking condition: %@", condition);
        
        if(![condition enabled]) continue;  // skip disabled conditions
        
        BOOL conditionEval = NO;
        if([condition unit] == UnitNone) goto loopEnd;
        if([condition unit] == UnitTarget && !target) goto loopEnd;
        
        switch([condition variety]) {
            case VarietyNone:;
                PGLog(@"Error: %@ in %@ is of an unknown type.", condition, rule);
                break;
            case VarietyHealth:;
                /* ******************************** */
                /* Health / Power Condition         */
                /* ******************************** */
                int qualityValue = 0;
                if( [condition unit] == UnitPlayer ) {
                    //PGLog(@"Checking player... type %d", [condition type]);
                    if( ![playerController playerIsValid] || ![thePlayer isValid]) goto loopEnd;
                    if( [condition quality] == QualityHealth ) {
                        qualityValue = ([condition type] == TypeValue) ? [thePlayer currentHealth] : [thePlayer percentHealth];
                    } else if ([condition quality] == QualityPower ) {
                        qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPower] : [thePlayer percentPower];
                    } else if ([condition quality] == QualityMana ) {
                        qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Mana] : [thePlayer percentPowerOfType: UnitPower_Mana];
                    } else if ([condition quality] == QualityRage ) {
                        qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Rage] : [thePlayer percentPowerOfType: UnitPower_Rage];
                    } else if ([condition quality] == QualityEnergy ) {
                        qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Energy] : [thePlayer percentPowerOfType: UnitPower_Energy];
                    } else if ([condition quality] == QualityHappiness ) {
                        qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Happiness] : [thePlayer percentPowerOfType: UnitPower_Happiness];
                    } else if ([condition quality] == QualityFocus ) {
                        qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_Focus] : [thePlayer percentPowerOfType: UnitPower_Focus];
                    } else if ([condition quality] == QualityRunicPower ) {
                        qualityValue = ([condition type] == TypeValue) ? [thePlayer currentPowerOfType: UnitPower_RunicPower] : [thePlayer percentPowerOfType: UnitPower_RunicPower];
                    } else goto loopEnd;
                } else {
                    // get unit as either target or player's pet
                    Unit *aUnit = ([condition unit] == UnitTarget) ? target : [playerController pet];
                    if( ![aUnit isValid]) goto loopEnd;
                    if( [condition quality] == QualityHealth ) {
                        qualityValue = ([condition type] == TypeValue) ? [aUnit currentHealth] : [aUnit percentHealth];
                    } else if ([condition quality] == QualityPower ) {
                        qualityValue = ([condition type] == TypeValue) ? [aUnit currentPower] : [aUnit percentPower];
                    } else if ([condition quality] == QualityMana ) {
                        qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Mana] : [aUnit percentPowerOfType: UnitPower_Mana];
                    } else if ([condition quality] == QualityRage ) {
                        qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Rage] : [aUnit percentPowerOfType: UnitPower_Rage];
                    } else if ([condition quality] == QualityEnergy ) {
                        qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Energy] : [aUnit percentPowerOfType: UnitPower_Energy];
                    } else if ([condition quality] == QualityHappiness ) {
                        qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Happiness] : [aUnit percentPowerOfType: UnitPower_Happiness];
                    } else if ([condition quality] == QualityFocus ) {
                        qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_Focus] : [aUnit percentPowerOfType: UnitPower_Focus];
                    } else if ([condition quality] == QualityRunicPower ) {
                        qualityValue = ([condition type] == TypeValue) ? [aUnit currentPowerOfType: UnitPower_RunicPower] : [aUnit percentPowerOfType: UnitPower_RunicPower];
                    } else goto loopEnd;
                }
                
                // now we have the value of the quality
                if( [condition comparator] == CompareMore) {
                    conditionEval = ( qualityValue > [[condition value] unsignedIntValue] ) ? YES : NO;
                    //PGLog(@"  %d > %@ is %d", qualityValue, [condition value], conditionEval);
                } else if([condition comparator] == CompareEqual) {
                    conditionEval = ( qualityValue == [[condition value] unsignedIntValue] ) ? YES : NO;
                    //PGLog(@"  %d = %@ is %d", qualityValue, [condition value], conditionEval);
                } else if([condition comparator] == CompareLess) {
                    conditionEval = ( qualityValue < [[condition value] unsignedIntValue] ) ? YES : NO;
                    //PGLog(@"  %d > %@ is %d", qualityValue, [condition value], conditionEval);
                } else goto loopEnd;
                
                break;
                
                /* ******************************** */
                /* Status Condition                 */
                /* ******************************** */
            case VarietyStatus:; 
                //PGLog(@"-- Checking status condition --");
                
                // check alive status
                if( [condition state] == StateAlive ) {
                    if( [condition unit] == UnitPlayer)
                        conditionEval = ( [condition comparator] == CompareIs ) ? ![playerController isDead] : ![playerController isDead];
                    else if( [condition unit] == UnitTarget)
                        conditionEval = ( [condition comparator] == CompareIs ) ? ![target isDead] : [target isDead];
                    else if( [condition unit] == UnitPlayerPet) {
                        if(playerController.pet == nil) {
                            conditionEval = ([condition comparator] == CompareIs) ? NO : YES;
                        } else
                            conditionEval = ( [condition comparator] == CompareIs ) ? ![playerController.pet isDead] : [playerController.pet isDead];
                    } else goto loopEnd;
                    //PGLog(@"  Alive? %d", conditionEval);
                }
                
                // check combat status
                if( [condition state] == StateCombat ) {
                    if( [condition unit] == UnitPlayer)
                        conditionEval = ( [condition comparator] == CompareIs ) ? [combatController inCombat] : ![combatController inCombat];
                    else if( [condition unit] == UnitTarget)
                        conditionEval = ( [condition comparator] == CompareIs ) ? [target isInCombat] : ![target isInCombat];
                    else if( [condition unit] == UnitPlayerPet)
                        conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isInCombat] : ![playerController.pet isInCombat];
                    else goto loopEnd;
                    //PGLog(@"  Combat? %d", conditionEval);
                }
                
                // check casting status
                if( [condition state] == StateCasting ) {
                    if( [condition unit] == UnitPlayer)
                        conditionEval = ( [condition comparator] == CompareIs ) ? [playerController isCasting] : ![playerController isCasting];
                    else if( [condition unit] == UnitTarget)
                        conditionEval = ( [condition comparator] == CompareIs ) ? [target isCasting] : ![target isCasting];
                    else if( [condition unit] == UnitPlayerPet)
                        conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isCasting] : ![playerController.pet isCasting];
                    goto loopEnd;
                    //PGLog(@"  Casting? %d", conditionEval);
                }
                
                // IS THE UNIT MOUNTED?
                if( [condition state] == StateMounted ) {
                    if(test) PGLog(@"Doing State IsMounted condition...");
                    Unit *aUnit = nil;
                    if( [condition unit] == UnitPlayer)         aUnit = thePlayer;
                    else if( [condition unit] == UnitTarget)    aUnit = target;
                    else if( [condition unit] == UnitPlayerPet) aUnit = playerController.pet;
                    if(test) PGLog(@" --> Testing unit %@", aUnit);
                    
                    if([aUnit isValid]) {
                        conditionEval = ( [condition comparator] == CompareIs ) ? [aUnit isMounted] : ![aUnit isMounted];
                        if(test) PGLog(@" --> Unit is mounted? %@", YES_NO(conditionEval));
                    } else {
                        if(test) PGLog(@" --> Unit is invalid.");
                    }
                }
                
                // IS THE PLAYER INDOORS?
                if( [condition state] == StateIndoors ) {
                    if(test) PGLog(@"Doing State 'Indoors' condition...");
                    conditionEval = ( [condition comparator] == CompareIs ) ? [playerController isIndoors] : [playerController isOutdoors];
                    if(test) {
                        if([condition comparator] == CompareIs) {
                            if(conditionEval)   PGLog(@" --> (%@) Unit is indoors.", TRUE_FALSE(conditionEval));
                            else                PGLog(@" --> (%@) Unit is not indoors.", TRUE_FALSE(conditionEval));
                        } else {
                            if(conditionEval)   PGLog(@" --> (%@) Unit is not indoors.", TRUE_FALSE(conditionEval));
                            else                PGLog(@" --> (%@) Unit is indoors.", TRUE_FALSE(conditionEval));
                        }
                    }
                }
                
                break;
                
                /* ******************************** */
                /* Aura Condition                   */
                /* ******************************** */
            case VarietyAura:;
                //PGLog(@"-- Checking aura condition --");
                
                unsigned spellID = 0;
                NSString *dispelType = nil;
                BOOL doDispelCheck = ([condition quality] == QualityBuffType) || ([condition quality] == QualityDebuffType);
                
                // sanity checks
                if(!doDispelCheck) {
                    if( [condition type] == TypeValue)
                        spellID = [[condition value] unsignedIntValue];
                    
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
                        if([condition state] == StateMagic)     dispelType = DispelTypeMagic;
                        if([condition state] == StateCurse)     dispelType = DispelTypeCurse;
                        if([condition state] == StatePoison)    dispelType = DispelTypePoison;
                        if([condition state] == StateDisease)   dispelType = DispelTypeDisease;
                    }
                }
                
                //PGLog(@"  Searching for spell '%@'", [condition value]);
                
                Unit *aUnit = nil;
                if( [condition unit] == UnitPlayer ) {
                    if( ![playerController playerIsValid]) goto loopEnd;
                    aUnit = thePlayer;
                } else {
                    aUnit = ([condition unit] == UnitTarget) ? target : [playerController pet];
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
                
                
                /* ******************************** */
                /* Aura Stack Condition             */
                /* ******************************** */
            case VarietyAuraStack:;
                
                spellID = 0;
                dispelType = nil;
                
                if(test) PGLog(@"Doing Aura Stack condition...");
                
                // sanity checks
                if(([condition type] != TypeValue) && ([condition type] != TypeString)) {
                    if(test) PGLog(@" --> Invalid condition type.");
                    goto loopEnd;
                }
                if( [condition type] == TypeValue) {
                    spellID = [[condition value] unsignedIntValue];
                    if(spellID == 0) { // invalid spell ID
                        if(test) PGLog(@" --> Invalid spell number");
                        goto loopEnd;
                    } else {
                        if(test) PGLog(@" --> Scanning for aura %u", spellID);
                    }
                }
                if( [condition type] == TypeString) {
                    if( ![[condition value] isKindOfClass: [NSString class]] || ![[condition value] length] ) {
                        if(test) PGLog(@" --> Invalid or blank Spell name.");
                        goto loopEnd;
                    } else {
                        if(test) PGLog(@" --> Scanning for aura \"%@\"", [condition value]);
                    }
                }
                
                aUnit = nil;
                if( [condition unit] == UnitPlayer ) {
                    if( ![playerController playerIsValid]) goto loopEnd;
                    aUnit = thePlayer;
                } else {
                    aUnit = ([condition unit] == UnitTarget) ? target : [playerController pet];
                }
                
                if( [aUnit isValid]) {
                    //PGLog(@"Testing unit %@ for %d", aUnit, spellID);
                    int stackCount = 0;
                    if( [condition quality] == QualityBuff ) {
                        if([condition type] == TypeValue)   stackCount = [auraController unit: aUnit hasBuff: spellID];
                        if([condition type] == TypeString)  stackCount = [auraController unit: aUnit hasBuffNamed: [condition value]];
                    } else if([condition quality] == QualityDebuff) {
                        if([condition type] == TypeValue)   stackCount = [auraController unit: aUnit hasDebuff: spellID];
                        if([condition type] == TypeString)  stackCount = [auraController unit: aUnit hasDebuffNamed: [condition value]];
                    }
                    
                    if([condition comparator] == CompareMore) {
                        conditionEval = (stackCount > [condition state]);
                    }
                    if([condition comparator] == CompareEqual) {
                        conditionEval = (stackCount == [condition state]);
                    }
                    if([condition comparator] == CompareLess) {
                        conditionEval = (stackCount < [condition state]);
                    }
                    if(test) PGLog(@" --> Found %d stacks for result %@", stackCount, (conditionEval ? @"TRUE" : @"FALSE"));
                    // conditionEval = ([condition comparator] == CompareMore) ? (stackCount > [condition state]) : (([condition comparator] == CompareEqual) ? (stackCount == [condition state]) : (stackCount < [condition state]));
                } else goto loopEnd;
                
                break;
                
                
                /* ******************************** */
                /* Distance Condition               */
                /* ******************************** */
            case VarietyDistance:;
                
                if( [condition unit] == UnitTarget && [condition quality] == QualityDistance && target) {
                    float distanceToTarget = [[(PlayerDataController*)playerController position] distanceToPosition: [target position]];
                    // PGLog(@"-- Checking distance condition --");
                    
                    if( [condition comparator] == CompareMore) {
                        conditionEval = ( distanceToTarget > [[condition value] floatValue] ) ? YES : NO;
                        //PGLog(@"  %f > %@ is %d", distanceToTarget, [condition value], conditionEval);
                    } else if([condition comparator] == CompareEqual) {
                        conditionEval = ( distanceToTarget == [[condition value] floatValue] ) ? YES : NO;
                        //PGLog(@"  %f = %@ is %d", distanceToTarget, [condition value], conditionEval);
                    } else if([condition comparator] == CompareLess) {
                        conditionEval = ( distanceToTarget < [[condition value] floatValue] ) ? YES : NO;
                        //PGLog(@"  %f < %@ is %d", distanceToTarget, [condition value], conditionEval);
                    } else goto loopEnd;
                }
                
                break;
                
                
                /* ******************************** */
                /* Inventory Condition              */
                /* ******************************** */
            case VarietyInventory:;
                if( [condition unit] == UnitPlayer && [condition quality] == QualityInventory) {
                    //PGLog(@"-- Checking inventory condition --");
                    Item *item = ([condition type] == TypeValue) ? [itemController itemForID: [condition value]] : [itemController itemForName: [condition value]];
                    
                    int totalCount = [itemController collectiveCountForItem: item];
                    if( [condition comparator] == CompareMore) {
                        conditionEval = (totalCount > [condition state]) ? YES : NO;
                    }
                    
                    if( [condition comparator] == CompareEqual) {
                        conditionEval = (totalCount == [condition state]) ? YES : NO;
                    }
                    
                    if( [condition comparator] == CompareLess) {
                        conditionEval = (totalCount < [condition state]) ? YES : NO;
                    }
                }
                break;
                
                /* ******************************** */
                /* Combo Points Condition           */
                /* ******************************** */
            case VarietyComboPoints:;
                
                if(test) PGLog(@"Doing Combo Points condition...");
                
                UInt32 class = [thePlayer unitClass];
                if( (class != UnitClass_Rogue) && (class != UnitClass_Druid) ) {
                    if(test) PGLog(@" --> You are not a rogue or druid, noob.");
                    goto loopEnd;
                }
                
                if( ([condition unit] == UnitPlayer) && ([condition quality] == QualityComboPoints) && target) {
                    
                    // either we have no CP target, or our CP target matched our current target
                    UInt64 cpUID = [playerController comboPointUID];
                    if( (cpUID == 0) || ([target GUID] == cpUID)) {
                        int comboPoints = [playerController comboPoints];
                        if(test) PGLog(@" --> Found %d combo points.", comboPoints);
                        
                        if( [condition comparator] == CompareMore) {
                            conditionEval = ( comboPoints > [[condition value] intValue] ) ? YES : NO;
                            if(test) PGLog(@" --> %d > %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
                        } else if([condition comparator] == CompareEqual) {
                            conditionEval = ( comboPoints == [[condition value] intValue] ) ? YES : NO;
                            if(test) PGLog(@" --> %d = %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
                        } else if([condition comparator] == CompareLess) {
                            conditionEval = ( comboPoints < [[condition value] intValue] ) ? YES : NO;
                            if(test) PGLog(@" --> %d < %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
                        } else goto loopEnd;
                    }
                }
                
                break;
                
                /* ******************************** */
                /* Totem Condition                  */
                /* ******************************** */
            case VarietyTotem:;
                
                if(test) PGLog(@"Doing Totem condition...");
                
                if( ![condition value] || ![[condition value] length] || ![[condition value] isKindOfClass: [NSString class]] ) {
                    if(test) PGLog(@" --> Invalid totem name.");
                    goto loopEnd;
                }
                if( ([condition unit] != UnitPlayer) || ([condition quality] != QualityTotem)) {
                    if(test) PGLog(@" --> Invalid condition parameters.");
                    goto loopEnd;
                }
                if( [thePlayer unitClass] != UnitClass_Shaman ) {
                    if(test) PGLog(@" --> You are not a shaman, noob.");
                    goto loopEnd;
                }
                
                // we need to rescan the mob list before we check for active totems
                // [mobController enumerateAllMobs];
                
                BOOL foundTotem = NO;
                for(Mob* mob in [mobController allMobs]) {
                    if( [mob isTotem] && ([mob createdBy] == [playerController GUID]) ) {
                        NSRange range = [[mob name] rangeOfString: [condition value]
                                                          options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
                        if(range.location != NSNotFound) {
                            foundTotem = YES;
                            if(test) PGLog(@" --> Found totem %@ matching \"%@\".", mob, [condition value]);
                            break;
                        }
                    }
                }
                
                if(!foundTotem && test) {
                    PGLog(@" --> No totem found with name \"%@\"", [condition value]);
                }
                
                conditionEval = ([condition comparator] == CompareExists) ? foundTotem : !foundTotem;
                
                break;
                
                
                /* ******************************** */
                /* Temp. Enchant Condition          */
                /* ******************************** */
            case VarietyTempEnchant:;
                
                if(test) PGLog(@"Doing Temp Enchant condition...");
                
                Item *item = [itemController itemForGUID: [thePlayer itemGUIDinSlot: ([condition quality] == QualityMainhand) ? SLOT_MAIN_HAND : SLOT_OFF_HAND]];
                if(test) PGLog(@" --> Got item %@.", item);
                BOOL hadEnchant = [item hasTempEnchantment];
                conditionEval = ([condition comparator] == CompareExists) ? hadEnchant : !hadEnchant;
                if(test) PGLog(@" --> Had enchant? %@. Result is %@.", YES_NO(hadEnchant), TRUE_FALSE(conditionEval));
				
                break;
                
                
                /* ******************************** */
                /* Target Type Condition          */
                /* ******************************** */
            case VarietyTargetType:;
                
                if(test) PGLog(@"Doing Target Type condition...");
                
                if([condition quality] == QualityNPC) {
                    conditionEval = [target isNPC];
                    if(test) PGLog(@" --> Is NPC? %@", YES_NO(conditionEval));
                }
                if([condition quality] == QualityPlayer) {
                    conditionEval = [target isPlayer];
                    if(test) PGLog(@" --> Is Player? %@", YES_NO(conditionEval));
                }
                break;
                
                /* ******************************** */
                /* Target Class Condition           */
                /* ******************************** */
            case VarietyTargetClass:;
                
                if(test) PGLog(@"Doing Target Class condition...");
                
                if([condition quality] == QualityNPC) {
                    conditionEval = ([target creatureType] == [condition state]);
                    if(test) PGLog(@" --> Unit Creature Type %d == %d? %@", [condition state], [target creatureType], YES_NO(conditionEval));
                }
                if([condition quality] == QualityPlayer) {
                    conditionEval = ([target unitClass] == [condition state]);
                    if(test) PGLog(@" --> Unit Class %d == %d? %@", [condition state], [target unitClass], YES_NO(conditionEval));
                }
                break;
                
                
                /* ******************************** */
                /* Combat Count Condition           */
                /* ******************************** */
            case VarietyCombatCount:;
                
                if(test) PGLog(@"Doing Combat Count condition...");
                
                int combatUnits = [[combatController combatUnits] count];
                if(test) PGLog(@" --> Found %d units in combat.", combatUnits);
                
                if( [condition comparator] == CompareMore) {
                    conditionEval = ( combatUnits > [condition state] ) ? YES : NO;
                    if(test) PGLog(@" --> %d > %d is %@.", combatUnits, [condition state], TRUE_FALSE(conditionEval));
                } else if([condition comparator] == CompareEqual) {
                    conditionEval = ( combatUnits == [condition state] ) ? YES : NO;
                    if(test) PGLog(@" --> %d = %d is %@.", combatUnits, [condition state], TRUE_FALSE(conditionEval));
                } else if([condition comparator] == CompareLess) {
                    conditionEval = ( combatUnits < [condition state] ) ? YES : NO;
                    if(test) PGLog(@" --> %d < %d is %@.", combatUnits, [condition state], TRUE_FALSE(conditionEval));
                } else goto loopEnd;
                break;
                
                
                /* ******************************** */
                /* Proximity Count Condition        */
                /* ******************************** */
            case VarietyProximityCount:;
                if(test) PGLog(@"Doing Proximity Count condition...");

                float distance = [[condition value] floatValue];
                
                Position *playerPosition = [thePlayer position];
                Position *basePosition = ([condition unit] == UnitTarget) ? [target position] : playerPosition;
                
                // get list of all possible targets
                NSMutableArray *allTargets = [NSMutableArray array], *validTargets = [NSMutableArray array];
                if(test || self.theCombatProfile.attackNeutralNPCs || self.theCombatProfile.attackHostileNPCs) {
                    [allTargets addObjectsFromArray: [mobController allMobs]];
                }
                if(test || self.theCombatProfile.attackPlayers) {
                    [allTargets addObjectsFromArray: [playersController allPlayers]];
                }
                if(test) PGLog(@" --> Found %d total units.", [allTargets count]);
                
                // extract valid targets from all targets
                for(Unit *unit in allTargets) {
                    if( test || [self isUnitValidToAttack: unit fromPosition: playerPosition ignoreDistance: YES]) {
                        [validTargets addObject: unit];
                    }
                }
                
                if(test) {
                    PGLog(@" --> Test mode checks all units; normal mode will validate units against your combat profile.");
                    if([condition unit] == UnitPlayer) PGLog(@" --> Checking %.2fy around player...", distance);
                    if([condition unit] == UnitTarget) PGLog(@" --> Checking %.2fy around target...", distance); 
                }
                
                // count the units in range
                int inRangeCount = 0;
                for(Unit *unit in validTargets) {
                    float range = [basePosition distanceToPosition: [unit position]];
                    if(range <= distance) {
                        PGLog(@" ----> In Range (%.2fy): %@", range, unit);
                        inRangeCount++;
                    }
                }
                
                // compare with specified number of units
                if( [condition comparator] == CompareMore) {
                    conditionEval = ( inRangeCount > [condition state] ) ? YES : NO;
                    if(test) PGLog(@" --> %d > %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
                } else if([condition comparator] == CompareEqual) {
                    conditionEval = ( inRangeCount == [condition state] ) ? YES : NO;
                    if(test) PGLog(@" --> %d = %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
                } else if([condition comparator] == CompareLess) {
                    conditionEval = ( inRangeCount < [condition state] ) ? YES : NO;
                    if(test) PGLog(@" --> %d < %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
                } else goto loopEnd;
                
                break;
            default:;
                break;
        }
        
    loopEnd:
        if(conditionEval)   {
            numMatched++;
            //if(test) NSRunAlertPanel(@"Condition True", [NSString stringWithFormat: @"%@ is true.", condition], @"Okay", NULL, NULL);
        } else {
            //if(test) NSRunAlertPanel(@"Condition False", [NSString stringWithFormat: @"%@ is false.", condition], @"Okay", NULL, NULL);
        }
        
        // shortcut bail if we can
        if([rule isMatchAll]) {
            if(!conditionEval) return NO;
        } else {
            if(conditionEval) return YES;
        }
    }
    
    // match all requires as many Yes and there are conditions
    //if([rule isMatchAll] && (numMatched >= needToMatch ))
    //    return YES;
    //if(![rule isMatchAll] && (numMatched > 0))
    //    return YES;
    //PGLog(@"    Matched %d of %d", numMatched, needToMatch);

    if(numMatched >= needToMatch)
        return YES;
    return NO;
}

#define RULE_EVAL_DELAY_SHORT   0.25f
#define RULE_EVAL_DELAY_NORMAL  0.5f
#define RULE_EVAL_DELAY_LONG    0.5f

- (void)cancelCurrentProcedure {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [self setProcedureInProgress: nil];
}

- (void)finishCurrentProcedure: (NSDictionary*)state {
    
    // make sure we're done casting before we end the procedure
    if( [playerController isCasting] ) {
        float timeLeft = [playerController castTimeRemaining];
        if( timeLeft <= 0 ) {
            [self performSelector: _cmd withObject: state afterDelay: 0.1];
        } else {
            // PGLog(@"[Bot] Still casting (%.2f remains): Delaying procedure end.", timeLeft);
            [self performSelector: _cmd withObject: state afterDelay: timeLeft];
            return;
        }
        return;
    }
    
    //if( ![[state objectForKey: @"Procedure"] isEqualToString: CombatProcedure])
    // PGLog(@"--- All done with procedure: %@.", [state objectForKey: @"Procedure"]);
    [self cancelCurrentProcedure];
    
    // when we finish PreCombat, re-evaluate the situation
    if([[state objectForKey: @"Procedure"] isEqualToString: PreCombatProcedure]) {
        [self evaluateSituation];
        return;
    }
    
    // when we finish PostCombat, run regen
    if([[state objectForKey: @"Procedure"] isEqualToString: PostCombatProcedure]) {
        float regenDelay = 0.0f;
        if( [[state objectForKey: @"ActionsPerformed"] intValue] > 0 ) {
            regenDelay = 1.5f;
        }
        [self performSelector: @selector(performProcedureWithState:) 
                   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                RegenProcedure,                   @"Procedure",
                                [NSNumber numberWithInt: 0],      @"CompletedRules", nil] 
                   afterDelay: regenDelay];
        return;
    }
    
    // if we did any regen, wait 30 seconds before re-evaluating the situation
    if([[state objectForKey: @"Procedure"] isEqualToString: RegenProcedure]) {
        if( [[state objectForKey: @"ActionsPerformed"] intValue] > 0 ) {
            [self performSelector: @selector(preRegen) withObject: nil afterDelay: 2.0];
        } else {
            // or if we didn't regen, go back to evaluate
            [self evaluateSituation];
        }
    }
    
    // if we did the Patrolling procdure, go back to evaluate
    if([[state objectForKey: @"Procedure"] isEqualToString: PatrollingProcedure]) {
        [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25];
        //[self evaluateSituation];
    }
}

- (void)performProcedureWithState: (NSDictionary*)state {
    
    // if there's another procedure running, we gotta stop it
    if( self.procedureInProgress && ![self.procedureInProgress isEqualToString: [state objectForKey: @"Procedure"]]) {
        [self cancelCurrentProcedure];
        // PGLog(@"Cancelling a previous procedure to begin %@.", [state objectForKey: @"Procedure"]);
    }
    
    if(![self procedureInProgress]) {
        [self setProcedureInProgress: [state objectForKey: @"Procedure"]];
        //PGLog(@"Setting current procedure: %@", self.procedureInProgress);
        
        if ( [[self procedureInProgress] isEqualToString: CombatProcedure]) {
            int count = [[combatController attackQueue] count];
            if(count == 1)  [controller setCurrentStatus: [NSString stringWithFormat: @"Bot: Player in Combat (%d unit)", count]];
            else            [controller setCurrentStatus: [NSString stringWithFormat: @"Bot: Player in Combat (%d units)", count]];
        } else {
            if( [[self procedureInProgress] isEqualToString: PreCombatProcedure])
                [controller setCurrentStatus: @"Bot: Pre-Combat Phase"];
            else if( [[self procedureInProgress] isEqualToString: PostCombatProcedure])
                [controller setCurrentStatus: @"Bot: Post-Combat Phase"];
            else if( [[self procedureInProgress] isEqualToString: RegenProcedure])
                [controller setCurrentStatus: @"Bot: Regen Phase"];
        }
    }
    
    Procedure *procedure = [self.theBehavior procedureForKey: [state objectForKey: @"Procedure"]];
    Unit *target = [state objectForKey: @"Target"];
    int completed = [[state objectForKey: @"CompletedRules"] intValue];
    int attempts = [[state objectForKey: @"RuleAttempts"] intValue];
    int actions = [[state objectForKey: @"ActionsPerformed"] intValue];
    
    // send your pet to attack
    if( [self.theBehavior usePet] && [playerController pet]) {
        if( [[self procedureInProgress] isEqualToString: PreCombatProcedure] || [[self procedureInProgress] isEqualToString: CombatProcedure] ) {
            if(![controller isWoWChatBoxOpen] && (_currentPetAttackHotkey >= 0)) {
                [chatController pressHotkey: _currentPetAttackHotkey withModifier: _currentPetAttackHotkeyModifier];
            }
        }
    }
    
    // have we completed all the rules?
    int ruleCount = [procedure ruleCount];
    if( !procedure || (completed >= ruleCount) ) {
        [self finishCurrentProcedure: state];
        return;
    }
    
    // delay our next rule until we can cast
    if( [playerController isCasting] ) {
        
        // try to be smart about how long we wait
        float delayTime = [playerController castTimeRemaining]/2.0f;
        if(delayTime < RULE_EVAL_DELAY_SHORT) delayTime = RULE_EVAL_DELAY_SHORT;
        // PGLog(@"  Player casting. Waiting %.2f to perform next rule.", delayTime);
        
        [self performSelector: _cmd
                   withObject: state 
                   afterDelay: delayTime];
        return;
    }
    
    // have we exceeded our maximum attempts on this rule?
    if(attempts > 3) {
        PGLog(@"  Exceeded maximum (3) attempts on action %d. Skipping.", [[procedure ruleAtIndex: completed] actionID]);
        [self performSelector: _cmd
                   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                [state objectForKey: @"Procedure"],             @"Procedure",
                                [NSNumber numberWithInt: completed+1],          @"CompletedRules",
                                target,                                         @"Target",  nil] 
                   afterDelay: RULE_EVAL_DELAY_SHORT];
        return;
    }

    int i;
    for(i = completed; i< ruleCount; i++) {
        Rule *rule = [procedure ruleAtIndex: i];
        if( [self evaluateRule: rule withTarget: target asTest: NO] ) {
            
            if( [rule resultType] > 0) {
                int32_t oldActionID = 0, actionID = [rule actionID];
                if(actionID > 0) {
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
                            canPerformAction = [spellController canCastSpellWithID: [NSNumber numberWithUnsignedInt: actionID]];
                            break;
                        default:
                            break;
                    }
                    
                    // if we can cast the spell, do so
                    if(canPerformAction) {
                        
                        // special rule for Hunter's Mark in pre-combat
                        if(([[self procedureInProgress] isEqualToString: PreCombatProcedure]) && 
                           ([rule resultType] == ActionType_Spell) &&
                           ([[[spellController spellForID: [NSNumber numberWithUnsignedInt: actionID]] name] isEqualToString: @"Hunter's Mark"]))
                        {
                            // target the unit if we are casting Hunter's mark in pre-combat
                            if([target isNPC])  [mobController selectMob: (Mob*)target];
                            else                [playerController setPrimaryTarget: [target GUID]];
                        }
                        
                        // replace the first entry on the hotbar
                        [[controller wowMemoryAccess] loadDataForObject: self atAddress: (HOTBAR_BASE_STATIC + BAR6_OFFSET) Buffer: (Byte *)&oldActionID BufLength: sizeof(oldActionID)];
                        [[controller wowMemoryAccess] saveDataForAddress: (HOTBAR_BASE_STATIC + BAR6_OFFSET) Buffer: (Byte *)&actionID BufLength: sizeof(actionID)];
                        
                        // wow needs time to process the spell change
                        usleep([controller refreshDelay]*2);
                        
                        // then post keydown if the chat box is not open
                        if(![controller isWoWChatBoxOpen] || (_currentHotkey == kVK_F13)) {
                            [chatController pressHotkey: _currentHotkey withModifier: _currentHotkeyModifier];
                        }

                        // wow needs time to process the spell change before we change it back
                        usleep([controller refreshDelay]);
                        
                        // then save our old action back
                        [[controller wowMemoryAccess] saveDataForAddress: (HOTBAR_BASE_STATIC+BAR6_OFFSET) Buffer: (Byte *)&oldActionID BufLength: sizeof(oldActionID)];
						
						// Lets just check to see if there was an error
						/*
						usleep([controller refreshDelay]);
						
						if ( [spellController lastAttemptedActionID] == actionID ){
							PGLog(@"Spell didn't cast - reason: %@", [playerController lastErrorMessage]);
						}*/
                        
                    }
                    
                    // time for the next rule?
                    // for now we have to ignore items, since they cast spells that are different from their own ID
                    if( ([rule resultType] == ActionType_Item) || ([rule resultType] == ActionType_Macro) || ([spellController lastAttemptedActionID] == 0) || !canPerformAction ) {
                        
                        if([rule resultType] == ActionType_Spell) {
                            Spell *spell = [spellController spellForID: [NSNumber numberWithInt: actionID]];
                            if(canPerformAction) {
                                
                                // tell the spell controller so it can track cooldowns
                                [spellController didCastSpell: spell];
                                
                                // special rule for Vanish
                                if(([[self procedureInProgress] isEqualToString: CombatProcedure]) && 
                                   ([rule resultType] == ActionType_Spell) &&
                                   ([[[spellController spellForID: [NSNumber numberWithUnsignedInt: actionID]] name] isEqualToString: @"Vanish"]))
                                {
                                    PGLog(@"VANISH! Attemping to exit combat (cross your fingers).");
                                    [combatController cancelAllCombat];
                                    return; // bail out of here
                                }
                                
                                // PGLog(@"  %@ cast after %d attempts.", spell, attempts);

                            } else {
                                // PGLog(@"  %@ skipped for cooldown.", spell );
                            }
                        } else {
                            // PGLog(@"  Using %@.", [itemController itemForID: [NSNumber numberWithInt: [rule actionID]]]);
                        }
                        
                        NSDictionary *newState = [NSDictionary dictionaryWithObjectsAndKeys: 
                                                  [state objectForKey: @"Procedure"],     @"Procedure",
                                                  [NSNumber numberWithInt: i+1],          @"CompletedRules",    // increment
                                                  [NSNumber numberWithInt: actions+1],    @"ActionsPerformed",  // increment
                                                  target,                                 @"Target",  nil];
                        
                        // shortcut end to skip the rule eval delay
                        if( i+1 >= ruleCount) { [self finishCurrentProcedure: newState]; return; }
                        
                        // the last spell registered
                        [self performSelector: _cmd
                                   withObject: newState
                                   afterDelay: RULE_EVAL_DELAY_NORMAL];
                    } else {
                        // the last spell didn't register; try it again soon, but up the attempt count
                        //PGLog(@"  The spell didn't.");
                        [self performSelector: _cmd
                                   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                [state objectForKey: @"Procedure"],     @"Procedure",
                                                [NSNumber numberWithInt: i],            @"CompletedRules",      // dont increment completed
                                                [NSNumber numberWithInt: attempts+1],   @"RuleAttempts",        // but increment attempts
                                                target,                                 @"Target", nil]
                                   afterDelay: RULE_EVAL_DELAY_LONG];
                    }
                    
                    return;
                }
            }
        } else {
            ;//PGLog(@"Rule %@ is FALSE.", rule);
        }
    }
    
    // we're done
    [self finishCurrentProcedure: state];
}

#pragma mark -
#pragma mark Loot Helpers

void PostMouseEvent(CGEventType type, CGMouseButton button, CGPoint location, ProcessSerialNumber psn)
{
    CGEventRef event = CGEventCreateMouseEvent(NULL, type, location, button);
    if(event) {
        CGEventSetType(event, type);
        CGEventPostToPSN(&psn, event);
        CFRelease(event);
    }
}

- (CGPoint)scanForObjectOnScreen: (WoWObject*)unit {
    if(![controller isWoWFront]) return CGPointZero;
    
    GUID unitID = [unit GUID];
    
    PGLog(@"Scanning for 0x%XULL on the screen...", unitID);
    
    // get the window size/location
    CGRect windowRect = [controller wowWindowRect];
        
    CGPoint foundPt = CGPointZero, firstPt = CGPointZero;
    float foundX = 0, foundY = 0, numFound = 0;
    
    // okay, so the middle didn't work. lets try a small square around the center
    int i, j;
    int minX = (windowRect.size.width*0.375f), maxX = windowRect.size.width - minX;
    int minY = (windowRect.size.height*0.375f), maxY = windowRect.size.height - minY;
    int incX = (maxX - minX)/16, incY = (maxY - minY)/16;
    
    /*
    // set up overlay window
    NSPoint screenPt = NSZeroPoint; 
    screenPt.x += windowRect.origin.x;
    screenPt.y += ([[NSScreen mainScreen] frame].size.height - (windowRect.origin.y + windowRect.size.height));
    
    // create new window bounds
    NSRect newRect = NSMakeRect(minX+windowRect.origin.x, [[NSScreen mainScreen] frame].size.height - (maxY+windowRect.origin.y), maxX-minX, maxY-minY);
    [overlayWindow setFrame: newRect display: YES];
    [overlayWindow makeKeyAndOrderFront: nil];
    
    [scanGrid setXIncrement: 16.0f];
    [scanGrid setYIncrement: 16.0f];
    [scanGrid display];*/
    
    //NSDate *date = [NSDate date];
    
    // scan the window for the mob
    for(j=minY; j<maxY; j=j+incY) {
        for(i=minX; i<maxX; i=i+incX) {
            CGPoint aPoint = CGPointMake(windowRect.origin.x + i, windowRect.origin.y + j);
            CGPostMouseEvent(aPoint, FALSE, 2, FALSE, FALSE);
            usleep(7500); // 7500
            if( [playerController mouseoverID] == unitID ) {
                //PGLog(@"[1/4 Scan]: Found loot point (%.2f, %.2f) after %.2f sec; incX = %d, incY = %d", windowRect.origin.x + i, windowRect.origin.y + j, [date timeIntervalSinceNow]*-1.0f, incX, incY);
                //return CGPointMake(windowRect.origin.x + i, windowRect.origin.y + j);
                
                foundX += (windowRect.origin.x + i);
                foundY += (windowRect.origin.y + j);
                numFound++;

                if(numFound == 1) {
                    firstPt = aPoint;
                }
                
                // break early if we've found 10 points
                if(numFound >= 5.0f) {
                    j = maxY;
                    break;
                }
            }
            //[scanGrid setScanPoint: CGPointMake(aPoint.x, [[NSScreen mainScreen] frame].size.height - aPoint.y)];
            //[scanGrid display];
            //usleep(100000);
        }
    }
    
    // PGLog(@"[1/4 Scan]: Failed after %.2f sec; incX = %d, incY = %d", [date timeIntervalSinceNow]*-1.0f, incX, incY);
    //[overlayWindow orderOut: nil];
    if(numFound > 0) {
        foundPt.x = foundX / numFound;
        foundPt.y = foundY / numFound;
        // PGLog(@"[1/4 Scan]: Found avg loot point (%.2f, %.2f) with %.0f samples; incX = %d, incY = %d", foundPt.x, foundPt.y, numFound, incX, incY);
        
        // verify that this average point actually works
        CGPostMouseEvent(foundPt, FALSE, 2, FALSE, FALSE);
        usleep(10000);
        if( [playerController mouseoverID] == unitID ) {
            //PGLog(@"[1/4 Scan] Using average point.");
            return foundPt;
        } else {
            //PGLog(@"[1/4 Scan] Using first point.");
            return firstPt;
        }
    }
    
    // okay that didn't work, well try a bigger square
    minX = (windowRect.size.width/5.0f), maxX = windowRect.size.width - minX;
    minY = (windowRect.size.height/5.0f), maxY = windowRect.size.height - minY;
    foundX = foundY = numFound = 0;
    foundPt = firstPt = CGPointZero;
    
    // scan the window for the mob
    for(j=minY; j<maxY; j=j+24) {
        for(i=minX; i<maxX; i=i+24) {
            CGPostMouseEvent(CGPointMake(windowRect.origin.x + i, windowRect.origin.y + j), FALSE, 2, FALSE, FALSE);
            usleep(7500); // 7500
            if( [playerController mouseoverID] == unitID ) {
                //PGLog(@"FOUND MOB AT: (%d, %d) after %.2f sec", i, j, [start timeIntervalSinceNow]*-1.0);
                //return CGPointMake(windowRect.origin.x + i, windowRect.origin.y + j);
                
                foundX += (windowRect.origin.x + i);
                foundY += (windowRect.origin.y + j);
                numFound++;

                if(numFound == 1) {
                    firstPt = CGPointMake(windowRect.origin.x + i, windowRect.origin.y + j);
                }
                
                // break early if we've found 10 points
                if(numFound >= 5.0f) {
                    j = maxY;
                    break;
                }
                //return CGPointMake(windowRect.origin.x + i, windowRect.origin.y + j);
            }
        }
    }
    
    if(numFound > 0) {
        foundPt.x = foundX / numFound;
        foundPt.y = foundY / numFound;
        // PGLog(@"[3/5 Scan]: Found avg loot point (%.2f, %.2f) with %.0f samples", foundPt.x, foundPt.y, numFound);
        
        // verify that this average point actually works
        CGPostMouseEvent(foundPt, FALSE, 2, FALSE, FALSE);
        usleep(10000);
        if( [playerController mouseoverID] == unitID ) {
            //PGLog(@"[3/5 Scan] Using average point.");
            return foundPt;
        } else {
            //PGLog(@"[3/5 Scan] Using first point.");
            return firstPt;
        }
    }
    
    return CGPointZero;
}

- (void)finishLoot: (Mob*)mob {
    _lootAttempt = 0;
    [_mobsToLoot removeObject: mob];
    [movementController finishMovingToObject: mob];
    PGLog(@"[Loot] Removed %@ from loot list. %d remain.", mob, [_mobsToLoot count]);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(reachedUnit:) object: mob];
}

- (void)finishSkin {
    self.mobToSkin = nil;
    _mobToSkinPoint = CGPointZero;
    _lootAttempt = 0;
}

- (void)verifyLoot: (Mob*)mob {
    // up our loot attempt counter
    _lootAttempt++;
    
    // check to see if the mob was successfully looted
    if( ![mob isLootable] ) {
        PGLog(@"[Loot] Loot success for %@", mob);
        [self finishLoot: mob];
        
        // should we skin it?
        if(self.mobToSkin) {
            PGLog(@"[Loot] Skinning %@", mob);
            [self performSelector: @selector(skinMob:) withObject: self.mobToSkin afterDelay: 1];
            return;
        }
    } else {
        if(_lootAttempt > 2) {
            PGLog(@"[Loot] Ignoring %@ after 3 failed loot attempts.", mob);
            [self finishLoot: mob];
        }
    }
    
    // the mob was not successfully looted.
    [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1];
}

- (void)skinMob: (Mob*)mob {
    float distanceToUnit = [[playerController position] distanceToPosition2D: [mob position]];
    if( ![mob isValid] || ![mob isSkinnable] || (distanceToUnit > 5.0f) || (_mobToSkinPoint.x <= 0) || (_mobToSkinPoint.y <= 0)) {
        // reset skin variables and bail
        PGLog(@"[Loot] Mob is not skinnable or has already been skinned.");
        [self finishSkin];
        [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1];
        return;
    } else {
        // check our loot attempt count
        if(_lootAttempt > 2) {
            PGLog(@"[Loot] Exceeded 3 attempts at skinning; ignoring this mob.");
            [self finishSkin];
            [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1];
            return;
        }
    }
    
    // get wow process number
    ProcessSerialNumber oldProcess = { kNoProcess, kNoProcess };
    ProcessSerialNumber wowProcess = [controller getWoWProcessSerialNumber];
    GetFrontProcess(&oldProcess);
    
    // figure out which workspace WoW is in
    int thisSpace, wowSpace;
    int delay = 10000, timeWaited = 0;
    BOOL wasWoWHidden = [controller isWoWHidden];
    if(wasWoWHidden) ShowHideProcess( &wowProcess, YES);
    CGSConnection cgsConnection = _CGSDefaultConnection();
    CGSGetWorkspace(cgsConnection, &thisSpace);
    while(!IsProcessVisible(&wowProcess) && (timeWaited < 500000)) {
        usleep(delay);
        timeWaited += delay;
    }
    CGSGetWindowWorkspace(cgsConnection, [controller getWOWWindowID], &wowSpace);
    
    BOOL weMadeWoWFront = NO;
    
    // move wow to the front if necessary
    if(![controller isWoWFront]) {
        // move to WoW's workspace
        if(thisSpace != wowSpace) {
            CGSSetWorkspace(cgsConnection, wowSpace);
            usleep(100000);
        }
        
        // and set it as front process
        SetFrontProcess(&wowProcess);
        usleep(100000);
        
        weMadeWoWFront = YES;
    }
    
    // verify our loot point
    CGPoint clickPt = CGPointZero;
    CGPostMouseEvent(_mobToSkinPoint, FALSE, 2, FALSE, FALSE);
    usleep(10000);
    if( [playerController mouseoverID] == [mob GUID] ) {
        // our loot point is correct
        clickPt = _mobToSkinPoint;
        //PGLog(@"Skin point is correct: (%.2f, %.2f).", clickPt.x, clickPt.y);
    } else {
        // we've got to search for the point again
        if([mob isValid]) {
            clickPt = _mobToSkinPoint = [self scanForObjectOnScreen: mob];
            //PGLog(@"Skin point NOT correct. Scanning for new point: (%.2f, %.2f)", clickPt.x, clickPt.y);
        }
    }
    
    // right click on the loot point to skin
    BOOL weSkinned = NO;
    if(clickPt.x && clickPt.y && [controller isWoWFront]) {
        // move the mouse into position and click
        weSkinned = YES;
        CGInhibitLocalEvents(YES);
        CGPostMouseEvent(clickPt, FALSE, 2, FALSE, FALSE);
        PostMouseEvent(kCGEventMouseMoved, kCGMouseButtonLeft, clickPt, wowProcess);
        usleep(100000);	// wait
        PostMouseEvent(kCGEventRightMouseDown, kCGMouseButtonRight, clickPt, wowProcess);
        usleep(30000);
        PostMouseEvent(kCGEventRightMouseUp, kCGMouseButtonRight, clickPt, wowProcess);
        usleep(100000);	// wait
        CGInhibitLocalEvents(NO);
    }
    
    // bring our prevous app to the front
    
    if(wasWoWHidden) ShowHideProcess( &wowProcess, NO);
    if(weMadeWoWFront) {
        // bring our prevous app to the front
        if(thisSpace != wowSpace) {
            CGSSetWorkspace(cgsConnection, thisSpace);
            usleep(100000);
        }
        SetFrontProcess(&oldProcess);
        usleep(100000);
    }
    
    _lootAttempt++;
    if(weSkinned) {
        PGLog(@"[Loot] Attempt %d: skinning again in 3.0 seconds.", _lootAttempt);
        [self performSelector: @selector(skinMob:) withObject: self.mobToSkin afterDelay: 3.0f];
        return;
    } else {
        // skin is complete or some parameter is invalid. we're done.
        [self finishSkin];
        [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.5f];
        return;
    }
}

#pragma mark -
#pragma mark [Input] CombatController

// This method is pure notification.  It's up to EvaluateSituaion or an incomming AddingUnit to initiate any attacking.
- (void)playerEnteringCombat {
    // if we're not even botting, bail
    if(![self isBotting]) return;
    
    [controller setCurrentStatus: @"Bot: Player in Combat"];
    
    [self evaluateSituation];
}

- (void)playerLeavingCombat {
    // if we're not even botting, bail
    if(![self isBotting]) return;

    _didPreCombatProcedure = NO;
    if(![playerController isDead]) {
        
        if( ![[combatController attackQueue] count] ) {
            // we're probably still in the middle of a combat procedure
            if(self.procedureInProgress)        // so let's cancel it
                [self cancelCurrentProcedure];
            
            //while( [playerController isInCombat] ) {
            //    [self performSelector: _cmd withObject: nil afterDelay: 0.1];
            //    return;
            //}
            
            // PGLog(@"PostCombatProcedure");
            
            if(self.theRoute) [movementController pauseMovement];
            [movementController moveToObject: nil andNotify: NO];
            
            BOOL vanished = [auraController unit: [playerController player] hasBuffNamed: @"Vanish"];
            
            // start post-combat after specified delay
            [self performSelector: @selector(performProcedureWithState:) 
                       withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                    PostCombatProcedure,              @"Procedure",
                                    [NSNumber numberWithInt: 0],      @"CompletedRules", nil] 
                       afterDelay: (vanished ? 5.0 : 0.1)];
            return;
        } else {
            [self evaluateSituation];
        }
    }
}


- (void)attackUnit: (Unit*)unit {
    if(![self isBotting]) return;
    
    if( ![[self procedureInProgress] isEqualToString: CombatProcedure] ) {
        // PGLog(@"Starting combat procedure (current: %@).", [self procedureInProgress]);
        // stop and attack
        [self cancelCurrentProcedure];
        
        // check to see if we are supposed to be in melee range
        if( self.theBehavior.meleeCombat) {
        
            // see if we are moving to this unit already
            if( ![[movementController moveToObject] isEqualToObject: unit]) {
                float distance = [[playerController position] distanceToPosition2D: [unit position]];
                
                if( distance > 5.0f) {
                    // if we are more than 5 yards away, move to this unit
                    PGLog(@"[Bot] Melee range required; moving to %@ at %.2f", unit, distance);
                    [movementController moveToObject: unit andNotify: YES];
                } else  {
                    // if we are in melee range, stop
                    [movementController pauseMovement];
                }
            } else {
                //PGLog(@"Already moving to %@", unit);
                // if we are already moving to the unit, make sure we keep going
                [movementController resumeMovement];
            }
        } else {
            // if we don't need to be in melee, pause
            [movementController pauseMovement];
        }
        
        // start the combat procedure
        [self performProcedureWithState: [NSDictionary dictionaryWithObjectsAndKeys: 
                                          CombatProcedure,                  @"Procedure",
                                          [NSNumber numberWithInt: 0],      @"CompletedRules",
                                          unit,                             @"Target", nil]];
    } else {
        // we are currently executing the combat routine;
        // do nothing
    }
}

// this is called when any unit enters combat
- (void)addingUnit: (Unit*)unit {
    if(![self isBotting]) return;
    
    //if( ![[self procedureInProgress] isEqualToString: CombatProcedure] && [unit isValid] ) {
    //    PGLog(@"[Bot] Add! Stopping current procedure to attack.", unit);
    //    [self cancelCurrentProcedure];
    //}
    
    float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
    if(self.isPvPing && ([[playerController position] verticalDistanceToPosition: [unit position]] > vertOffset)) {
        PGLog(@"[PvP] Adding mob is beyond vertical offset limit; ignoring.");
        return;
    }
    
    PGLog(@"Add! %@", unit);
    
    if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
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
    
    [combatController disposeOfUnit: unit];
}

- (void)finishUnit: (Unit*)unit wasInAttackQueue: (BOOL)wasInQueue {
    
    // we only need to loot this if it's a mob and if was one we were directed to attack
    if( [unit isNPC] ) {
        if(wasInQueue) {
            if([movementController moveToObject] == unit) {
                // PGLog(@"finishUnit says stop moving to this unit.");
                [movementController finishMovingToObject: unit];
            }
            
            if([unit isDead]) {
                // send growl notification
                if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
                    //int exp = [(Mob*)unit experience];
                    // [GrowlApplicationBridge setGrowlDelegate: @""];
                    [GrowlApplicationBridge notifyWithTitle: @"Unit Killed"
                                                description: [NSString stringWithFormat: @"%@, level %d.", [unit name], [unit level]]
                     // ((exp > 0) ? [NSString stringWithFormat: @"%d experience gained.", exp] : @"No experience gained.")
                                           notificationName: @"KilledUnit"
                                                   iconData: [[NSImage imageNamed: @"Spell_Holy_MindVision"] TIFFRepresentation]
                                                   priority: 0
                                                   isSticky: NO
                                               clickContext: nil];             
                }
                
                if(self.doLooting) {
                    // make sure this mob is even lootable
                    // sometimes the mob isn't marked as 'lootable' yet because it hasn't fully died (death animation or whatever)
                    if( ![_mobsToLoot containsObject: unit] && ([(Mob*)unit isTappedByMe] || [(Mob*)unit isLootable])) {
                        [_mobsToLoot addObject: (Mob*)unit];
                        PGLog(@"[Loot]: Adding %@ to loot list.", unit);
                    }
                }
            }
            
            // if we're in the middle of a combat procedure, end it
            if([[self procedureInProgress] isEqualToString: CombatProcedure])
                [self cancelCurrentProcedure];
        }
        return;
    }
    
    if( [unit isPlayer] ) {
        [self evaluateSituation];
    }
    
    // if we are not in combat, then an attack attempt went bust
    // --> this is disabled because the OOC notification is now being used to trigger the next action
    //if(![[combatController attackQueue] count]) {
    //    [self evaluateSituation];
    //}
}

#pragma mark -
#pragma mark [Input] MovementController

- (void)reachedUnit: (WoWObject*)unit {
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: unit];
    [movementController pauseMovement];

    // if it's a player, or a non-dead NPC, we must be doing melee combat
    if( [unit isPlayer] || ([unit isNPC] && ![(Unit*)unit isDead])) {
        PGLog(@"[Bot] Reached melee range with %@", unit);
        return;
    }
    
    BOOL isNode = [unit isKindOfClass: [Node class]];
    
    KeyCombo lootCombo = [interactWithRecorder keyCombo];
    int lootTargetHotkey = lootCombo.code;
    int lootTargetHotkeyModifier = lootCombo.flags;
    BOOL useLootHotkey = (lootTargetHotkey >= 0);
    
    if(self.doLooting || isNode) {
        Position *playerPosition = [playerController position];
        float distanceToUnit = [playerPosition distanceToPosition2D: [unit position]];
        [movementController turnToward: [unit position]];
        
        // get wow process number
        ProcessSerialNumber oldProcess = { kNoProcess, kNoProcess };
        ProcessSerialNumber wowProcess = [controller getWoWProcessSerialNumber];
        GetFrontProcess(&oldProcess);
        
        // figure out which workspace WoW is in
        int thisSpace, wowSpace;
        int delay = 10000, timeWaited = 0;
        BOOL wasWoWHidden = [controller isWoWHidden];
        if(wasWoWHidden) ShowHideProcess( &wowProcess, YES);
        CGSConnection cgsConnection = _CGSDefaultConnection();
        CGSGetWorkspace(cgsConnection, &thisSpace);
        while(!IsProcessVisible(&wowProcess) && (timeWaited < 500000)) {
            usleep(delay);
            timeWaited += delay;
        }
        CGSGetWindowWorkspace(cgsConnection, [controller getWOWWindowID], &wowSpace);
        
        // get ahold of the current mouse position
        CGPoint clickPt = CGPointZero, previousPt = CGPointMake([NSEvent mouseLocation].x, [[NSScreen mainScreen] frame].size.height - [NSEvent mouseLocation].y);
        
        BOOL weLooted = NO, weMadeWoWFront = NO, unitIsMob = ([unit isKindOfClass: [Mob class]] && [unit isNPC]);
        
        if([unit isValid] && (distanceToUnit <= 5.0)) { //  && (unitIsMob ? [(Mob*)unit isLootable] : YES)
            // PGLog(@"[Loot] Reached unit: %@. Attempting to loot.", unit);
            if(unitIsMob) {
                [mobController selectMob: (Mob*)unit];
            } else {
                [playerController setPrimaryTarget: [unit GUID]];
            }
            
            if(![controller isWoWFront] && !useLootHotkey) {
                // move to WoW's workspace
                if(thisSpace != wowSpace) {
                    CGSSetWorkspace(cgsConnection, wowSpace);
                    usleep(100000);
                }
                
                // and set it as front process
                SetFrontProcess(&wowProcess);
                usleep(100000);
                
                weMadeWoWFront = YES;
            }
            
            // find the point to click on if we aren't using the loot hotkey
            NSDate *date = [NSDate date];
            if(!useLootHotkey) {
                clickPt = [self scanForObjectOnScreen: unit];
            }
            
            // for mobs, ensure the point is valid
            if(clickPt.x && clickPt.y && unitIsMob) {
                CGPostMouseEvent(clickPt, FALSE, 2, FALSE, FALSE);
                usleep(10000);
                if( [playerController mouseoverID] != [unit GUID] ) {
                    // PGLog(@"[Loot] Click point { %.2f, %.2f } is invalid. Rescanning.", clickPt.x, clickPt.y);
                    clickPt = [self scanForObjectOnScreen: unit];
                }
            }
            
            // if we're using the hotkey, this will fail since we never set clickPt
            if(clickPt.x && clickPt.y && [controller isWoWFront]) {
                PGLog(@"[Loot] Located %@ at { %.2f, %.2f } after %.2f seconds.  Looting.", unit, clickPt.x, clickPt.y, [date timeIntervalSinceNow]*-1.0);
                weLooted = YES;
                
                CGInhibitLocalEvents(YES);
                
                // move the mouse into position
                CGPostMouseEvent(clickPt, FALSE, 2, FALSE, FALSE);   // move
                
                // post our right click
                PostMouseEvent(kCGEventMouseMoved, kCGMouseButtonLeft, clickPt, wowProcess);
                usleep(100000);	// wait
                PostMouseEvent(kCGEventRightMouseDown, kCGMouseButtonRight, clickPt, wowProcess);
                usleep(30000);
                PostMouseEvent(kCGEventRightMouseUp, kCGMouseButtonRight, clickPt, wowProcess);
                usleep(200000);
                
                PostMouseEvent(kCGEventMouseMoved, kCGMouseButtonLeft, previousPt, wowProcess);
                
                CGInhibitLocalEvents(NO);
            } else {
                if(useLootHotkey) {
                    weLooted = YES;
                    [chatController pressHotkey: lootTargetHotkey withModifier: lootTargetHotkeyModifier];
                } else {
                    PGLog(@"[Loot] Unable to locate %@ on the screen or wow is not frontmost.", unit);
                }
            }
            
        } else {
            // the unit was not within 5 yards
        }
        
        if(wasWoWHidden) ShowHideProcess( &wowProcess, NO);
        if(weMadeWoWFront) {
            // bring our prevous app to the front
            if(thisSpace != wowSpace) {
                CGSSetWorkspace(cgsConnection, thisSpace);
                usleep(100000);
            }
            SetFrontProcess(&oldProcess);
            usleep(100000);
        }
        
        // if it was a node, we're done now regardless of if we looted or not
        // we have to do this since nodes remain in memory after being looted
        // so either we got it or we can't find it on the screen -- done either way
        if(isNode) {
            [nodeController finishedNode: (Node*)unit];
            [movementController finishMovingToObject: unit];
        }
        
        // deal with mobs
        if(unitIsMob) {
            if(weLooted) {
                
                // Up to skinning 100, you can find out the highest level mob you can skin by: ((Skinning skill)/10)+10.
                // From skinning level 100 and up the formula is simply: (Skinning skill)/5.
                
                int canSkinUpToLevel = 0;
                if(_skinLevel <= 100) {
                    canSkinUpToLevel = (_skinLevel/10)+10;
                } else {
                    canSkinUpToLevel = (_skinLevel/5);
                }
                
                self.mobToSkin = nil;
                if(_doSkinning) {
                    if((canSkinUpToLevel >= [(Mob*)unit level])) {
                        _mobToSkinPoint = clickPt;
                        self.mobToSkin = (Mob*)unit;
                    } else {
                        PGLog(@"[Loot] %@ is above your max skinning level (%d).", unit, canSkinUpToLevel);
                    }
                } else if(_doHerbalism) {
                    if((canSkinUpToLevel >= [(Mob*)unit level])) {
                        _mobToSkinPoint = clickPt;
                        self.mobToSkin = (Mob*)unit;
                    }
                }
                
                // PGLog(@"Will verify loot in %.2f seconds.", 2.0f);
                [self performSelector: @selector(verifyLoot:) withObject: (Mob*)unit afterDelay: 2.0f];
                return;
            } else {
                [self finishLoot: (Mob*)unit];
            }
        }
    }

    // if we get here, there's nothing left to be done
    float moreDelay = (isNode ? 5.0f : 0.5f) + [playerController castTimeRemaining] + ([playerController isLooting] ? 5.0f : 0.0f);
    [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: moreDelay];
}

- (void)finishedRoute: (Route*)route {
    if( ![self isBotting]) return;
    
    if(self.theRoute) {
        if(route == [self.theRoute routeForKey: CorpseRunRoute]) {
            PGLog(@"Finished Corpse Run. Begin search for body...");
            [controller setCurrentStatus: @"Bot: Searching for body..."];
            [movementController setPatrolRoute: [self.theRoute routeForKey: PrimaryRoute]];
            [movementController beginPatrol: 1 andAttack: NO];
        } else {
            //PGLog(@"Finished something else...");
        }
	}
}

- (BOOL)shouldProceedFromWaypoint: (Waypoint*)waypoint {
    if( ![self isBotting]) return YES;
    if( [playerController isDead]) return YES;
    
    // see if we would be performing anything in the patrol procedure
    BOOL performPatrolProc = NO;
    for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules]) {
        if( ([rule resultType] != ActionType_None) && ([rule actionID] > 0) && [self evaluateRule: rule withTarget: nil asTest: NO] ) {
            performPatrolProc = YES;
            break;
        }
    }
    
    // check if all used abilities are instant
    BOOL needToPause = NO;
    for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules]) {

        if( ([rule resultType] == ActionType_Spell)) {
            Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: [rule actionID]]];
            if([spell isInstant]) {
                continue;
            }
        }
        
        if([rule resultType] == ActionType_None) continue;
        
        needToPause = YES; 
        break;
    }
    
    // if we are, pause movement and perform it.
    if(performPatrolProc) {
        //if(needToPause)  PGLog(@"[Bot] Pausing to perform Patrol Procedure.");
        //if(!needToPause) PGLog(@"[Bot] NOT pausing to perform Patrol Procedure.");
        
        // only pause if we are performing something non instant
        if(needToPause) [movementController pauseMovement];

        [self performSelector: @selector(performProcedureWithState:) 
                   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                PatrollingProcedure,              @"Procedure",
                                [NSNumber numberWithInt: 0],      @"CompletedRules", nil] 
                   afterDelay: (needToPause ? 0.25 : 0.0)];
        
        if(needToPause)  return NO;
    }
    return YES;
}

#pragma mark -

- (void)preRegen {
    BOOL drink = NO, eat = NO;
    Unit *player = [playerController player];
    if([auraController unit: player hasBuffNamed: @"Drink"]) {
        drink = YES;
        PGLog(@"[Regen] Player started drinking.");
    }
    if([auraController unit: player hasBuffNamed: @"Food"]) {
        eat = YES;
        PGLog(@"[Regen] Player started eating.");
    }
    NSDictionary *regenDict = [NSDictionary dictionaryWithObjectsAndKeys: 
                               [NSDate date],                       @"RegenStart",
                               [NSNumber numberWithBool: eat],      @"WatchHealth",
                               [NSNumber numberWithBool: drink],    @"WatchMana",
                               nil];
    
    [self evaluateRegen: regenDict];
}

- (void)evaluateRegen: (NSDictionary*)regenDict {
    NSDate *start = [regenDict objectForKey: @"RegenStart"];
    BOOL health   = [[regenDict objectForKey: @"WatchHealth"] boolValue];
    BOOL mana     = [[regenDict objectForKey: @"WatchMana"] boolValue];
    
    if(!health && !mana) {
        float sinceStart = [[NSDate date] timeIntervalSinceDate: start];
        [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: (28.0f - sinceStart)]; // since we spend 2 seconds in pre-regen
        return;
    }

    Unit *player = [playerController player];
    
    // check health
    if( health && ([playerController health] == [playerController maxHealth]))
        health = NO;
    if( health && (![auraController unit: player hasBuffNamed: @"Food"]))
        health = NO;
    
    if( mana && ([playerController mana] == [playerController maxMana]))
        mana = NO;
    if( mana && (![auraController unit: player hasBuffNamed: @"Drink"]))
        mana = NO;
    
    if(!health && !mana) {
        // we're done here
        PGLog(@"[Regen] Finished early after %.2f seconds!", [[NSDate date] timeIntervalSinceDate: start]);
        if([playerController isSitting] && ![controller isWoWChatBoxOpen]) {
            [chatController jump];
        }
        [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
        return;
    }
    
    // check to see if we've already spent 30 seconds (2 in pre-regen)
    if([[NSDate date] timeIntervalSinceDate: start] >= 28.0f) {
        [self evaluateSituation];
        return;
    }
    
    [self performSelector: _cmd withObject: regenDict afterDelay: 2.0f];
}

- (Mob*)mobToLoot {
    if([_mobsToLoot count]) {
    
        Mob *mobToLoot = nil;
        
        // sort the loot list by distance
        [_mobsToLoot sortUsingFunction: DistanceFromPositionCompare context: [playerController position]];
        
        // find a valid mob to loot
        for(mobToLoot in _mobsToLoot) {
            if(mobToLoot && [mobToLoot isValid] && [mobToLoot isLootable]) {
                return mobToLoot;
            }
        }
    }
    
    return nil;
}

- (BOOL)isUnitValidToAttack: (Unit*)unit fromPosition: (Position*)position ignoreDistance: (BOOL)ignoreDistance {
    
    float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
    
    // unit fits the combat profile
    // unit is within the vertical offset
    // unit is not blacklisted
    if(   ([self.theCombatProfile unitFitsProfile: unit ignoreDistance: ignoreDistance])
       && ([[unit position] verticalDistanceToPosition: position] <= vertOffset)  
       && (![combatController isUnitBlacklisted: unit])) {
        return YES;
    }
    return NO;
}

- (Unit*)unitToAttack {
    // scan for valid, in-range targets to attack
    
    // determine level range
    //int min, range, level = [playerController level];
    //if(_minLevel == 100)    min = 1;
    //else                    min = level - _minLevel;
    //if(min < 1) min = 1;
    //range = (level + _maxLevel) - min;  // set max level
    
    if(!self.theCombatProfile.combatEnabled)
        return nil;
    
    // get list of all targets
    NSMutableArray *targetsWithinRange = [NSMutableArray array];
    
    if(self.theCombatProfile.attackNeutralNPCs || self.theCombatProfile.attackHostileNPCs) {
        [targetsWithinRange addObjectsFromArray: [mobController allMobs]];
    }
    if(self.theCombatProfile.attackPlayers) {
        [targetsWithinRange addObjectsFromArray: [playersController allPlayers]];
    }
    
    // sort by range
    Position *playerPosition = [playerController position];
    [targetsWithinRange sortUsingFunction: DistanceFromPositionCompare context: playerPosition];



    /*
         // ...check for NPCs if specified
    if(self.theCombatProfile.attackNeutralNPCs || self.theCombatProfile.attackHostileNPCs) {
        [targetsWithinRange addObjectsFromArray: [mobController mobsWithinDistance: [self.theCombatProfile attackRange]
                                                                        levelRange: NSMakeRange(self.theCombatProfile.attackLevelMin, self.theCombatProfile.attackLevelMax - self.theCombatProfile.attackLevelMin)
                                                                      includeElite: !(self.theCombatProfile.ignoreElite)
                                                                   includeFriendly: NO
                                                                    includeNeutral: self.theCombatProfile.attackNeutralNPCs
                                                                    includeHostile: self.theCombatProfile.attackHostileNPCs]];
    }
    
    // ...check for players if specified
    if(self.theCombatProfile.attackPlayers) {
        [targetsWithinRange addObjectsFromArray: [playersController playersWithinDistance: [self.theCombatProfile attackRange] 
                                                                               levelRange: NSMakeRange(self.theCombatProfile.attackLevelMin, self.theCombatProfile.attackLevelMax - self.theCombatProfile.attackLevelMin)
                                                                          includeFriendly: NO
                                                                           includeNeutral: NO
                                                                           includeHostile: self.theCombatProfile.attackPlayers]];
    }*/
    
    
    // if we have mobs in range
    if([targetsWithinRange count] || [self.preCombatUnit isValid]) {
        // if there are mobs, pause moving and kill them
        Unit *unit = self.preCombatUnit;
        for(unit in targetsWithinRange) {   // find a valid mob
            if( [self isUnitValidToAttack: unit fromPosition: playerPosition ignoreDistance: NO]) {
                break;
            }
        }
        return unit;
    }
    
    return nil;
}

- (BOOL)evaluateSituation {
    if(![self isBotting])                   return NO;
    if(![playerController playerIsValid])   return NO;
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];
    
    if( [self.stopDate timeIntervalSinceNow] < 0) {
        PGLog(@"[Bot] Timer expired! Please register.");
        [self timeUp: nil];
        return NO;
    }
    
    Position *playerPosition = [playerController position];
    float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
    
    // Order of Operations
    // 1) If we are dead, check to see if we can resurrect.
    // 2) If we are moving to melee range, return.
    // 3) If we are in combat but not already attacking, scan for mobs to attack.
    // ---- Not in Combat after here ----
    // 4) Check for bodies to loot, loot if necessary.
    // 5) Scan for valid target in range, attack if found.
    // 6) Check for nodes to harvest, harvest if necessary.
    // 7) Resume movement if needed, nothing else to do.
    
    
    // if the player is a Ghost...
    if( [playerController isGhost]) {
		
        if( [playerController corpsePosition] && [playerPosition distanceToPosition: [playerController corpsePosition]] < 26.0 ) {
            // we found our corpse
            [controller setCurrentStatus: @"Bot: Waiting to Resurrect"];
            [movementController pauseMovement];
            
            // set our next-revive wait timer
            if(!_reviveAttempt) _reviveAttempt = 1;
            else _reviveAttempt = _reviveAttempt*2;
            
            // send the script command
            [chatController enter];             // open/close chat box
            usleep(100000);
            [chatController retrieveCorpse];    // get corpse
            
            PGLog(@"Waiting %d seconds to resurrect.", _reviveAttempt);
            [self performSelector: _cmd withObject: nil afterDelay: _reviveAttempt];
            return YES;
        }
        return NO;
    }
    
    // check to see if we are moving to attack a unit and bail if we are
    if( combatController.attackUnit && (combatController.attackUnit == [movementController moveToObject])) {
        // PGLog(@"attackUnit == moveToObject");
        return NO;
    }
    
    // first, check if we are in combat already (we agrod something by accident, whatever)
    if( [combatController combatEnabled] && [combatController inCombat] ) {
    
        if(![[combatController combatUnits] count]) {
            // PGLog(@"We are in combat, but show no mobs.");
            [mobController doCombatScan];
        }
        
        // attack first valid mob we find
        // this could definitely serve to be more intelligent
        NSMutableArray *combatUnits = [NSMutableArray arrayWithArray: [combatController combatUnits]];
        [combatUnits sortUsingFunction: DistanceFromPositionCompare context: playerPosition]; 
        for(Unit *unit in combatUnits) {
            if(unit && [unit isValid] && ![unit isDead] && ([[unit position] verticalDistanceToPosition: playerPosition] <= vertOffset)) {
                // PGLog(@"Found existing combat, attacking: %@", unit);
                [movementController pauseMovement];
                [combatController disposeOfUnit: unit];
                return YES;
            }
        }
        // PGLog(@"Still no mobs detected after combat scan.");
    }
    
    /* *** if we get here, we aren't in combat *** */
	
	// Lets check to see if we have some broken weapons
	if(_doCheckForBrokenWeapons){
		//PGLog(@"Checking for broken weapons...");
		
		Player *player = [playerController player];
		Item *itemMainHand = [itemController itemForGUID: [player itemGUIDinSlot: SLOT_MAIN_HAND]];
		Item *itemOffHand = [itemController itemForGUID: [player itemGUIDinSlot: SLOT_OFF_HAND]];
		
		int durabilityMainHand = itemMainHand ? [[itemMainHand durability] intValue] : 1;
		int durabilityOffHand = itemOffHand ? [[itemOffHand durability] intValue] : 1;
		
		// If one of our weapons is broken, we should log out :-(  /cry
		if ( durabilityMainHand == 0 || durabilityOffHand == 0 ){
			
			// Lets just kill the process, we could send "/logout" but then we will have to wait 20 seconds, and things like combat could take place etc...
			PGLog(@"[Bot] Logging out due to broken weapons: Main Hand Durability(%d), Off Hand Durability(%d)", durabilityMainHand, durabilityOffHand);
			
			// Stop the bot
			[self stopBot: nil];
			
			// Kill the process
			[controller killWOW];
			
			return NO;
		}
	}
    
    // first, check if we are in combat
    // this is to compensate for MovementController calling evaluate while moving to a mob
    //if( [[self procedureInProgress] isEqualToString: CombatProcedure] && [movementController moveToObject] ) {
    //    PGLog(@"CombatProcedure && moveToObject");
    //    return NO;
    //}
    
    // get potential units and their distances
    Mob *mobToLoot      = [self mobToLoot];
    Unit *unitToAttack  = [self unitToAttack];
    
    float mobToLootDist     = mobToLoot ? [[mobToLoot position] distanceToPosition: playerPosition] : INFINITY;
    float unitToAttackDist  = unitToAttack ? [[unitToAttack position] distanceToPosition: playerPosition] : INFINITY;
    
    // if the mob to loot is closer to us, loot it first
    if(mobToLoot && (mobToLootDist < unitToAttackDist)) {
        if(mobToLoot != [movementController moveToObject]) {
            // either move toward it or loot it now
            if([mobToLoot isValid] && (mobToLootDist < INFINITY)) {
                [controller setCurrentStatus: @"Bot: Looting Mobs"];
                PGLog(@"Found mob to loot: %@ at dist %.2f", mobToLoot, mobToLootDist);
                if(mobToLootDist <= 5.0)    [self performSelector: @selector(reachedUnit:) withObject: mobToLoot afterDelay: 0.5f];
                else                        [movementController moveToObject: mobToLoot andNotify: YES];
                return YES;
            }
        }
    }
    
    // otherwise, attack the unit
    if([unitToAttack isValid] && (unitToAttackDist < INFINITY)) {
        if([combatController combatEnabled]) {
            
            [movementController pauseMovement];
            
            // if we're not in combat, and haven't done the pre-combat already, do it.
            if( ![combatController inCombat] && !_didPreCombatProcedure ) {
                
                // do the pre-combat routine
                _didPreCombatProcedure = YES;
                self.preCombatUnit = unitToAttack;
                
                
                [self performProcedureWithState: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                  PreCombatProcedure,               @"Procedure",
                                                  [NSNumber numberWithInt: 0],      @"CompletedRules",
                                                  unitToAttack,                     @"Target",  nil]];
                return YES;
            }
            
            if(unitToAttack != self.preCombatUnit) {
                // PGLog(@"[Bot] Attacking unit other than pre-combat unit.");
            }
            self.preCombatUnit = nil;
            
            // turn and attack
            PGLog(@"Found %@ and attacking.", unitToAttack);
            [movementController turnToward: [unitToAttack position]];
            [combatController disposeOfUnit: unitToAttack];
            return YES;
        } else {
            self.preCombatUnit = nil;
        }
    }
    
    // check for mining and herbalism
    if(![movementController moveToObject]) {
        NSMutableArray *nodes = [NSMutableArray array];
        if(_doMining)       [nodes addObjectsFromArray: [nodeController nodesWithinDistance: self.gatherDistance ofType: MiningNode maxLevel: _miningLevel]];
        if(_doHerbalism)    [nodes addObjectsFromArray: [nodeController nodesWithinDistance: self.gatherDistance ofType: HerbalismNode maxLevel: _herbLevel]];
        
        [nodes sortUsingFunction: DistanceFromPositionCompare context: playerPosition];
        
        if([nodes count]) {
            // find a valid node to loot
            Node *nodeToLoot = nil;
            float nodeDist = INFINITY;
            
            for(nodeToLoot in nodes) {
                if(nodeToLoot && [nodeToLoot isValid]) {
                    nodeDist = [playerPosition distanceToPosition: [nodeToLoot position]];
                    break;
                }
            }
            
            if([nodeToLoot isValid] && (nodeDist != INFINITY)) {
                [movementController pauseMovement];
                // PGLog(@"Found closest node to loot: %@ at dist %.2f", nodeToLoot, closestNode);
                if(nodeDist <= 5.0)     [self reachedUnit: nodeToLoot];
                else                    [movementController moveToObject: nodeToLoot andNotify: YES];
                return YES;
            }
        }
    }
    
    // if there's nothing to do, make sure we keep moving if we aren't
    if(self.theRoute) {
        if([movementController isPatrolling] && ([movementController patrolRoute] == [self.theRoute routeForKey: PrimaryRoute])) {
            [movementController resumeMovementToNearestWaypoint];
        } else {
            [movementController setPatrolRoute: [self.theRoute routeForKey: PrimaryRoute]];
            [movementController beginPatrol: 0 andAttack: self.theCombatProfile.combatEnabled];
        }
        [controller setCurrentStatus: @"Bot: Patrolling"];
    } else {
        [controller setCurrentStatus: @"Bot: Enabled"];
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
                        [[[routePopup selectedItem] representedObject] name]];       // route
    
    NSString *bleh = nil;
    if(!profile || !profile.combatEnabled) {
        bleh = @"Combat disabled.";
    } else {
        if(profile.onlyRespond) {
            bleh = @"Only attacking back.";
        } else {
            NSString *levels = profile.attackAnyLevel ? @"any levels" : [NSString stringWithFormat: @"levels %d-%d", 
                                                                         profile.attackLevelMin,
                                                                         profile.attackLevelMax];
            bleh = [NSString stringWithFormat: @"Attacking %@ within %.1fy.", 
                    levels,
                    profile.attackRange];
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
    _currentHotkey = -1;
    _currentPetAttackHotkey = -1;
    
     BOOL ignoreRoute = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"IgnoreRoute"] boolValue];
    
    // gather appropriate information to start the bot
    if(ignoreRoute) {
        self.theRoute = nil;
    } else {
        self.theRoute = [[routePopup selectedItem] representedObject];
    }
    self.theBehavior = [[behaviorPopup selectedItem] representedObject];
    self.theCombatProfile = [[combatProfilePopup selectedItem] representedObject];
    
    // get hotkey settings
    KeyCombo hotkey = [shortcutRecorder keyCombo];
    _currentHotkeyModifier = hotkey.flags;
    _currentHotkey = hotkey.code;
    hotkey = [petAttackRecorder keyCombo];
    _currentPetAttackHotkeyModifier = hotkey.flags;
    _currentPetAttackHotkey = hotkey.code;
    
    self.doLooting = [lootCheckbox state];
    self.gatherDistance = [gatherDistText floatValue];
    
    if( _currentHotkey < 0 ) {
        PGLog(@"Hotkey is not valid.");
        NSBeep();
        NSRunAlertPanel(@"Invalid Hotkey", @"You must choose a valid hotkey, or the bot will be unable to use any spells or abilities.", @"Okay", NULL, NULL);
        return;
    }
    
    // check that we have valid conditions
    if( ![controller isWoWOpen]) {
        PGLog(@"WoW is not open. Bailing.");
        NSBeep();
        NSRunAlertPanel(@"WoW is not open", @"WoW is not open...", @"Okay", NULL, NULL);
        return;
    }
    
    if( ![playerController playerIsValid]) {
        PGLog(@"[Bot] The player is not valid. Bailing.");
        NSBeep();
        NSRunAlertPanel(@"Player not valid or cannot be detected", @"You must be logged into the game before you can start the bot.", @"Okay", NULL, NULL);
        return;
    }
    
    if( !self.theRoute && !ignoreRoute ) {
        NSBeep();
        PGLog(@"[Bot] The current route is not valid.");
        NSRunAlertPanel(@"Route is not valid", @"You must select a valid route before starting the bot.  If you removed or renamed a route, please select an alternative.", @"Okay", NULL, NULL);
        
        return;
    }
    
    if( ![[self.theRoute routeForKey: PrimaryRoute] waypointCount] && !ignoreRoute ) {
        PGLog(@"[Bot] The primary route has no waypoints.");
        NSBeep();
        NSRunAlertPanel(@"Route has no Waypoints", @"This route has no waypoints, and thus cannot be used.", @"Okay", NULL, NULL);
        return;
    }
    
    if( !self.theBehavior ) {
        PGLog(@"[Bot] The current behavior is not valid.");
        NSBeep();
        NSRunAlertPanel(@"Behavior is not valid", @"You must select a valid behavior before starting the bot.  If you removed or renamed a behavior, please select an alternative.", @"Okay", NULL, NULL);
        return;
    }

    if( !self.theCombatProfile ) {
        PGLog(@"[Bot] The current combat profile is not valid.");
        NSBeep();
        NSRunAlertPanel(@"Combat Profile is not valid", @"You must select a valid combat profile before starting the bot.  If you removed or renamed a profile, please select an alternative.", @"Okay", NULL, NULL);
        return;
    }

    
    if( [self isBotting])
        [self stopBot: nil];
    
    if(self.theCombatProfile && self.theBehavior && (_currentHotkey >= 0)) {
        PGLog(@"[Bot] Starting.");
        [spellController reloadPlayerSpells];
        
        // also check that the route has any waypoints
        // and that the behavior has any procedures
        _doMining = [miningCheckbox state];
        _miningLevel = [miningSkillText intValue];
        _doHerbalism = [herbalismCheckbox state];
        _herbLevel = [herbalismSkillText intValue];
        _doSkinning = [skinningCheckbox state];
        _skinLevel = [skinningSkillText intValue];
		_doCheckForBrokenWeapons = [brokenWeaponsCheckbox intValue];
        
        int canSkinUpToLevel = 0;
        if(_skinLevel <= 100) {
            canSkinUpToLevel = (_skinLevel/10)+10;
        } else {
            canSkinUpToLevel = (_skinLevel/5);
        }
        // PGLog(@"Starting bot with Sknning skill %d, allowing mobs up to level %d", _skinLevel, canSkinUpToLevel);
        
        self.isBotting = YES;
        [startStopButton setTitle: @"Stop Bot"];
        _didPreCombatProcedure = NO;
        _reviveAttempt = 0;
        
        // stopDate is not currently implemented
        self.stopDate = [NSDate distantFuture];
        
        if( [playerController isGhost] && self.theRoute) {
            Position *playerPosition = [playerController position];
            Route *primaryRoute  = [self.theRoute routeForKey: PrimaryRoute];
            Route *corpseRunRoute = [self.theRoute routeForKey: CorpseRunRoute];
            
            PGLog(@"[Bot] Started the bot, but we're a ghost!");
            
            float primaryDist = primaryRoute ? [[[primaryRoute waypointClosestToPosition: playerPosition] position] distanceToPosition: playerPosition] : INFINITY;
            float corpseDist = corpseRunRoute ? [[[corpseRunRoute waypointClosestToPosition: playerPosition] position] distanceToPosition: playerPosition] : INFINITY;
            
            if(primaryDist < corpseDist)
                [movementController setPatrolRoute: primaryRoute];
            else
                [movementController setPatrolRoute: corpseRunRoute];
            
            [movementController beginPatrol: 1 andAttack: NO];
            return;
        }
        
        if( [playerController isDead]) {
            PGLog(@"[Bot] Started the bot, but we're dead! Will try to release.");
            [self playerHasDied: nil];
            return;
        }
        
        [controller setCurrentStatus: @"Bot: Enabled"];
        [combatController setCombatEnabled: self.theCombatProfile.combatEnabled];
        // [movementController setPatrolRoute: [self.theRoute routeForKey: PrimaryRoute]];
        
        // if we're in combat when we start, have the mobController update
        if([combatController inCombat]) {
            Position *playerPosition = [playerController position];
            float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];

            for(Unit *unit in [combatController combatUnits]) {
                if(unit && [unit isValid] && ![unit isDead] && ([[unit position] verticalDistanceToPosition: playerPosition] <= vertOffset)) {
                    [combatController disposeOfUnit: unit];
                }
            }
        }

        [self evaluateSituation];
    }
    
}

- (IBAction)stopBot: (id)sender {
    [self cancelCurrentProcedure];
    [movementController setPatrolRoute: nil];
    [combatController cancelAllCombat];

    [_mobsToLoot removeAllObjects];
    self.isBotting = NO;
    self.preCombatUnit = nil;
    [controller setCurrentStatus: @"Bot: Stopped"];
    self.stopDate = [NSDate date];
    
    PGLog(@"[Bot] Stopped.");
    
    if(self.isPvPing && self.pvpEntryID) {
        PGLog(@"[Bot] Bot stopped but PvP is ongoing...");
        //[self performSelector: @selector(pvpCheck) withObject: nil afterDelay: 5.0];
    }
    
    [startStopButton setTitle: @"Start Bot"];
}

- (void)reEnableStart {
    [startStopButton setEnabled: YES];
    [pvpStartStopButton setEnabled: YES];
}

- (void)timeUp: (id)sender {
    if(self.isPvPing) [self pvpStop];
    [self stopBot: nil];
    [self performSelector: @selector(reEnableStart) withObject: nil afterDelay: 60];
    [startStopButton setEnabled: NO];
    [pvpStartStopButton setEnabled: NO];
    
    // show alert
    NSAlert *alert = [[[NSAlert alloc] init] autorelease]; 
    [alert addButtonWithTitle: @"Okay"];
    [alert setMessageText: @"Thanks for trying Pocket Gnome!"]; 
    [alert setInformativeText: @"Botting is restricted to 10 minute intervals in the unregistered version of Pocket Gnome.  Please register to unlock the full version.  You must now wait one minute before botting again."];
    [alert setAlertStyle: NSInformationalAlertStyle]; 
    [alert beginSheetModalForWindow: [self.view window] modalDelegate: self didEndSelector: nil contextInfo: nil]; 
}

- (IBAction)startStopBot: (id)sender {
    if(self.isBotting) {
        [self stopBot: sender];
    } else {
        [self startBot: sender];
    }
}

NSMutableDictionary *_diffDict = nil;
- (IBAction)testHotkey: (id)sender {
    //int value = 28734;
    //[[controller wowMemoryAccess] saveDataForAddress: (HOTBAR_BASE_STATIC + BAR6_OFFSET) Buffer: (Byte *)&value BufLength: sizeof(value)];
    //PGLog(@"Set Mana Tap.");
    
    KeyCombo hotkey = [shortcutRecorder keyCombo];
    [chatController pressHotkey: hotkey.code withModifier: hotkey.flags];
    
    
    if(!_diffDict) _diffDict = [[NSMutableDictionary dictionary] retain];
    
    BOOL firstRun = ([_diffDict count] == 0);
    UInt32 i, value;
    
    if(firstRun) {
        PGLog(@"First run.");
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
    
    PGLog(@"%d values.", [_diffDict count]);
    if([_diffDict count] < 20) {
        PGLog(@"%@", _diffDict);
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

#pragma mark Notifications
//
//- (void)playerNeverEnteredCombat {
//    if(![self isBotting]) return;
//    PGLog(@"playerNeverEnteredCombat");
//    
//    // cancel any outstanding procedure
//    if(self.procedureInProgress)
//        [self cancelCurrentProcedure];
//    
//    [self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1];
//}
#pragma mark AKA [Input] PlayerData

- (void)playerHasRevived: (NSNotification*)notification {
    if( ![self isBotting]) return;
    PGLog(@"---- Player has revived!");
    [controller setCurrentStatus: @"Bot: Player has Revived"];
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    _reviveAttempt = 0;
    
    // rescan for mobs
    // [mobController enumerateAllMobs];
    
    // reset our route and then pause again
    if(self.theRoute) {
        [movementController setPatrolRoute: [self.theRoute routeForKey: PrimaryRoute]];
        [movementController beginPatrol: 0 andAttack: self.theCombatProfile.combatEnabled];
        [movementController pauseMovement];
    }
    
    // perform post combat
    [self performSelector: @selector(performProcedureWithState:) 
               withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                            PostCombatProcedure,              @"Procedure",
                            [NSNumber numberWithInt: 0],      @"CompletedRules", nil] 
               afterDelay: 1.0];
}

- (void)playerHasDied: (NSNotification*)notification {
    
    if( ![self isBotting]) return;
    PGLog(@"---- Player has died.");
    [controller setCurrentStatus: @"Bot: Player has Died"];
    
    [self cancelCurrentProcedure];              // this wipes all bot state (except pvp)
    [movementController setPatrolRoute: nil];   // this wipes all movement state
    [combatController cancelAllCombat];         // this wipes all combat state
    
    // send notification to Growl
    if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
        // [GrowlApplicationBridge setGrowlDelegate: @""];
        [GrowlApplicationBridge notifyWithTitle: @"Player Has Died!"
                                    description: @"Sorry :("
                               notificationName: @"PlayerDied"
                                       iconData: [[NSImage imageNamed: @"Ability_Warrior_Revenge"] TIFFRepresentation]
                                       priority: 0
                                       isSticky: NO
                                   clickContext: nil];
    }

    // release
    int repopTry = 0;
    
    if(!self.isPvPing || !self.pvpAutoRelease) {
        while( ![playerController isGhost]) {
            if(repopTry > 10) {
                PGLog(@"[Bot] Repop failed after 10 tries.  Ending bot.");
                [self stopBot: nil];
                [controller setCurrentStatus: @"Bot: Failed to Release. Stopped."];
                return;
            }
            PGLog(@"[Bot] Attempting to repop %d.", ++repopTry);
            
            [chatController enter];         // open/close chat box
            usleep(100000);
            [chatController releaseBody];   // release
            usleep(1000000);
        }
    } else {
        PGLog(@"[PvP] Relying on an addon to release us.");
    }
    
    // run back if we have a route
    if(!self.isPvPing) {
        if([self.theRoute routeForKey: CorpseRunRoute]) {
            PGLog(@"[Bot] Starting Corpse Run...");
            [controller setCurrentStatus: @"Bot: Running back from graveyard..."];
            [movementController setPatrolRoute: [self.theRoute routeForKey: CorpseRunRoute]];
            [movementController beginPatrolAndStopAtLastPoint];
        }
    } else {
        PGLog(@"[PvP] Ignoring Corpse Run route because we are PvPing.");
    }
}

- (void)playerIsValid: (NSNotification*)not { 

}

- (void)playerIsInvalid: (NSNotification*)not {
    if( [self isBotting]) {
        PGLog(@"[Bot] Player is no longer valid, stopping bot.");
        [self stopBot: nil];
    }
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
    if(recorder == shortcutRecorder) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"HotkeyCode"];
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"HotkeyFlags"];
    }
    
    if(recorder == startstopRecorder) {
       [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"StartstopCode"];
       [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"StartstopFlags"];
       [self toggleGlobalHotKey: startstopRecorder];
    }
    
    if(recorder == petAttackRecorder) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"PetAttackCode"];
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"PetAttackFlags"];
    }
    
    if(recorder == interactWithRecorder) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"InteractWithTargetCode"];
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"InteractWithTargetFlags"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark PvP!

- (void)auraGain: (NSNotification*)notification {
    
    if(self.isPvPing) {
        UInt32 spellID = [[(Spell*)[[notification userInfo] objectForKey: @"Spell"] ID] unsignedIntValue];
        // honorless target
        if( (spellID == HonorlessTargetSpellID) || (spellID == HonorlessTarget2SpellID) || (spellID == [[[spellController spellForName: @"Honorless Target"] ID] unsignedIntValue]) ) {
            
            // cancel the PvP checks
            [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(pvpCheck) object: nil];
            
            if(self.pvpInBG) {
                // we're done with the battleground
                PGLog(@"[PvP] Honorless Target. PvP must be done.");
                self.pvpInBG = NO;
                [self stopBot: nil];
                
                Player *player = [playerController player];
                
                // check for deserter
                BOOL hasDeserter = NO;
                if( [player isValid] && [auraController unit: player hasAura: DeserterSpellID] ) {
                    hasDeserter = YES;
                }

                if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
                    // [GrowlApplicationBridge setGrowlDelegate: @""];
                    [GrowlApplicationBridge notifyWithTitle: [NSString stringWithFormat: @"Battleground Complete"]
                                                description: (hasDeserter ? @"Waiting for Deserter to fade." : @"Will re-queue when Honorless Target fades.")
                                           notificationName: @"BattlegroundLeave"
                                                   iconData: (([controller reactMaskForFaction: [player factionTemplate]] & 0x2) ? [[NSImage imageNamed: @"BannerAlliance"] TIFFRepresentation] : [[NSImage imageNamed: @"BannerHorde"] TIFFRepresentation])
                                                   priority: 0
                                                   isSticky: NO
                                               clickContext: nil];             
                }
                
                if(hasDeserter) {
                    PGLog(@"[PvP] Deserter! Waiting for deserter to go away :(");
                    [controller setCurrentStatus: @"PvP: Waiting for Deserter to fade."];
                    [self performSelector: @selector(pvpCheck) withObject: nil afterDelay: 10.0];
                    return;
                }
                
                if(self.pvpEntryID) {
                    [controller setCurrentStatus: @"PvP: Waiting for Honorless Target to fade."];
                    PGLog(@"[PvP] Waiting for Honorless to fade before re-queueing..."); // Will search for battlemaster in 1 second.");
                    [self performSelector: @selector(pvpFindBattlemaster:) withObject: [NSNumber numberWithBool: YES] afterDelay: 1.0];
                    return;
                }
            } else {
                // we just entered the battleground
                self.pvpInBG = YES;
                
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
                
                PGLog(@"[PvP] PvP environment valid. Starting bot in 5 seconds.");
                [controller setCurrentStatus: @"PvP: Starting Bot in 5 seconds..."];
                [self performSelector: @selector(startBot:) withObject: nil afterDelay: 5.0f];
            }
        }
        
        if( spellID == WaitingToRezSpellID) {
            // if we are waiting to rez, pause the bot (incase it is not)
            [movementController pauseMovement];
        }
        
        // play alarm if we get Idle or Inactive
        if( (spellID == IdleSpellID) && self.pvpPlayWarning) {     // honorless target
            PGLog(@"[PvP] Idle debuff detected!");
            
            [[NSSound soundNamed: @"alarm"] play];
            [self performSelector: @selector(pvpInactiveCheck) withObject: nil afterDelay: 10.0];
        }
        
        if( (spellID == InactiveSpellID) && self.pvpLeaveInactive ) {
            // leave the battleground
            PGLog(@"[PvP] Leaving battleground due to Inactive debuff.");
            [chatController sendKeySequence: [NSString stringWithFormat: @"/script LeaveBattlefield();%c", '\n']];
        }
    }
}


- (void)auraFade: (NSNotification*)notification {
    if(self.isPvPing) {
        
        UInt32 spellID = [[(Spell*)[[notification userInfo] objectForKey: @"Spell"] ID] unsignedIntValue];
        
        if( (spellID == DeserterSpellID) ) {     // deserter
            PGLog(@"[PvP] Deserter has faded...");
            if(self.pvpEntryID) {
                PGLog(@"[PvP] Searching for battlemaster...");
                [self performSelector: @selector(pvpFindBattlemaster:) withObject: [NSNumber numberWithBool: YES] afterDelay: 1.0];
            }
        }
    }
}

- (void)pvpInactiveCheck {
    if(self.isPvPing && self.pvpPlayWarning) {
        Player *player = [playerController player];
        if( [auraController unit: player hasAura: IdleSpellID] || [auraController unit: player hasAura: InactiveSpellID]) {
            [[NSSound soundNamed: @"alarm"] play];
            PGLog(@"[PvP] We still have a bad debuff...");
            [self performSelector: _cmd withObject: nil afterDelay: 10.0];
        }
    }
}

- (void)pvpQueueBattleground {
    if([self.pvpBattlemaster isValid]) {
        self.pvpInBG = NO;
        
        
        [controller setCurrentStatus: @"PvP: Queueing..."];
        
        // target the battlemaster
        [mobController selectMob: self.pvpBattlemaster];
        usleep(100000);
        
        PGLog(@"[PvP] Searching for \"%@\" (%d) on the screen.", [self.pvpBattlemaster name], self.pvpEntryID);
        // get wow process number
        ProcessSerialNumber oldProcess = { kNoProcess, kNoProcess };
        ProcessSerialNumber wowProcess = [controller getWoWProcessSerialNumber];
        GetFrontProcess(&oldProcess);
        
        // figure out which workspace WoW is in
        int thisSpace, wowSpace;
        int delay = 10000, timeWaited = 0;
        BOOL wasWoWHidden = [controller isWoWHidden];
        if(wasWoWHidden) ShowHideProcess( &wowProcess, YES);
        CGSConnection cgsConnection = _CGSDefaultConnection();
        CGSGetWorkspace(cgsConnection, &thisSpace);
        while(!IsProcessVisible(&wowProcess) && (timeWaited < 500000)) {
            usleep(delay);
            timeWaited += delay;
        }
        CGSGetWindowWorkspace(cgsConnection, [controller getWOWWindowID], &wowSpace);
        
        BOOL weMadeWoWFront = NO;
        
        // move wow to the front if necessary
        if(![controller isWoWFront]) {
            // move to WoW's workspace
            if(thisSpace != wowSpace) {
                CGSSetWorkspace(cgsConnection, wowSpace);
                usleep(100000);
            }
            
            // and set it as front process
            SetFrontProcess(&wowProcess);
            usleep(500000);
            
            weMadeWoWFront = YES;
        }
        // --- end stupid bring to front routine
        
        // find the bitch
        BOOL weClicked = NO;
        CGPoint point = [self scanForObjectOnScreen: self.pvpBattlemaster];
        if(point.x && point.y && [controller isWoWFront]) {
            
            CGPostMouseEvent(point, FALSE, 2, FALSE, FALSE);
            usleep(25000);
            if( [playerController mouseoverID] == [self.pvpBattlemaster GUID] ) {
                
                //PGLog(@"Found battlemaster at %@", NSStringFromPoint(NSPointFromCGPoint(point)));
                // move the mouse and click
                CGInhibitLocalEvents(YES);
                
                // post our right click
                weClicked = YES;
                PostMouseEvent(kCGEventMouseMoved, kCGMouseButtonLeft, point, wowProcess);
                usleep(100000);	// wait
                PostMouseEvent(kCGEventRightMouseDown, kCGMouseButtonRight, point, wowProcess);
                usleep(30000);
                PostMouseEvent(kCGEventRightMouseUp, kCGMouseButtonRight, point, wowProcess);
                
                CGInhibitLocalEvents(NO);
                usleep(250000);	// wait 0.25
            }
            
        }
        
        // hide wow if it was hidden, bring any other app back to the front
        if(wasWoWHidden) ShowHideProcess( &wowProcess, NO);
        if(weMadeWoWFront) {
            // bring our prevous app to the front
            if(thisSpace != wowSpace) {
                CGSSetWorkspace(cgsConnection, thisSpace);
                usleep(100000);
            }
            SetFrontProcess(&oldProcess);
            usleep(100000);
        }
        
        
        if(!weClicked) {
            PGLog(@"[PvP] Could not locate the battlemaster on the screen. Trying again in 5 seconds.");
            [self performSelector: @selector(pvpQueueBattleground) withObject: nil afterDelay: 5.0];
            return;
        }
        
        if( [playerController interactGUID] == [self.pvpBattlemaster GUID]) {
            PGLog(@"[PvP] Opened Battlemaster window.");
            if(!self.pvpAutoQueue) {
                usleep(2000000);
                [chatController sendKeySequence: [NSString stringWithFormat: @"/script JoinBattlefield(0);%c", '\n']];
                PGLog(@"[PvP] JoinBattlefield() sent.");
            } else {
                PGLog(@"[PvP] Relying on addon to Auto-Queue.");
            }
            if(![controller isWoWChatBoxOpen]) [chatController jump];  // jump to clear AFK
            PGLog(@"[PvP] Will check for PvP entry every 10 seconds.");
            self.pvpCheckCount = 0;
            
            [controller setCurrentStatus: @"PvP: Waiting to join Battleground."];
            [self performSelector: @selector(pvpCheck) withObject: nil afterDelay: 10.0];
        } else {
            PGLog(@"[PvP] Not interacting with Battlemaster. Trying again...");
            [self performSelector: @selector(pvpQueueBattleground) withObject: nil afterDelay: 5.0];
            return;
        }
        
    } else {
        PGLog(@"[PvP] Can't queue battleground with invalid battlemaster.");
    }
}

- (void)pvpFindBattlemaster: (NSNumber*)keepTrying {
    Mob *battleMaster = nil;
    
    if( [auraController unit: [playerController player] hasAura: HonorlessTargetSpellID] && [keepTrying boolValue] ) {
        [self performSelector: _cmd withObject: keepTrying afterDelay: 1.0];
        return;
    }

    [controller setCurrentStatus: @"PvP: Searching for Battlemaster..."];
    
    // find the battlemaster
    if(self.pvpEntryID) {
        // we have a saved battlemaster entry ID
        PGLog(@"[PvP] Searching for Battlemaster %d", self.pvpEntryID);
        battleMaster = [mobController mobWithEntryID: self.pvpEntryID];
    } else {
        // we don't have a saved battlemaster entry ID
        PGLog(@"[PvP] Searching for Battlemaster from player target.");
        battleMaster = [mobController playerTarget];
        //PGLog(@"[PvP] Found %@ as player target.", battleMaster);
    }
    
    // validate this battlemaster
    if(battleMaster && [battleMaster isValid] && [battleMaster isBattlemaster]) {
        self.pvpBattlemaster = battleMaster;
        self.pvpEntryID = [battleMaster entryID];
    } else {
        self.pvpBattlemaster = nil;
        if(self.pvpEntryID) PGLog(@"[PvP] Could not find battlemaster %d!", self.pvpEntryID);
        else                PGLog(@"[PvP] Could not find battlemaster!");
    }
    
    if([self.pvpBattlemaster isValid] && ([self.pvpBattlemaster entryID] == self.pvpEntryID)) {
        // battlemaster is valid
        PGLog(@"[PvP] Battlemaster \"%@\" (%d) is valid.", [self.pvpBattlemaster name], self.pvpEntryID);
        
        // if we are already PvPing, requeue!
        if(self.isPvPing) {
            [self pvpQueueBattleground];
        } else {
            return; // nothing else to do here
        }
    } else {
        if([keepTrying boolValue]) {
            [self performSelector: _cmd withObject: keepTrying afterDelay: 1.0];
        }
    }
}

- (void)pvpCheck {
    if(self.isPvPing) {
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(pvpCheck) object: nil];
        
        self.pvpCheckCount++;
        if(self.pvpCheckCount >= 6) {
            self.pvpCheckCount = 0;
            if(![controller isWoWChatBoxOpen]) [chatController jump];
        }
    
        // if the battlemaster is invalid, we are probably inside a BG
        if(![self.pvpBattlemaster isValid] || (self.pvpEntryID != [self.pvpBattlemaster entryID])) {
            // if we weren't previously in a BG, we are now...
            // PGLog(@"[PvP] Battlemaster has become invalid.");
            self.pvpBattlemaster = nil;
            
            // check for deserter
            if( ![auraController unit: [playerController player] hasAura: DeserterSpellID] ) {
                return;
            }
        } else {
            if(!self.pvpAutoJoin) {
                [chatController sendKeySequence: [NSString stringWithFormat: @"/script AcceptBattlefieldPort(1,1);%c", '\n']];
            } else {
                // PGLog(@"[PvP] Relying on addon to Auto-Join.");
            }
        }
        
        [self performSelector: @selector(pvpCheck) withObject: nil afterDelay: 10.0];
    }
}

- (NSString*)pvpButtonTitle {
    if(self.isPvPing)   return @"Stop PvP";
    else                return @"Start PvP";
}

- (void)pvpStop {
    [self stopBot: nil];
    
    self.pvpBattlemaster = nil;
    self.pvpEntryID = 0;
    
    self.isPvPing = NO;
    self.pvpAutoRelease = NO;
    self.pvpAutoQueue = NO;
    self.pvpAutoJoin = NO;
    self.pvpInBG = NO;
    self.pvpLeaveInactive = NO;
    self.pvpPlayWarning = NO;
    self.pvpCheckCount = 0;
    PGLog(@"[PvP] Stopped.");
    
    [self willChangeValueForKey: @"pvpButtonTitle"];
    [self didChangeValueForKey: @"pvpButtonTitle"];
}

- (void)pvpStart {
    Player *player = [playerController player];
    if(![player isValid]) return;
    
    // check for deserter
    if( [auraController unit: player hasAura: DeserterSpellID] ) {
        NSBeep();

        NSAlert *alert = [[[NSAlert alloc] init] autorelease]; 
        [alert addButtonWithTitle: @"Oh, Right"];
        [alert setMessageText: @"Deserter!"]; 
        [alert setInformativeText: @"You cannot start PvP while you have the Deserter debuff.  Try again when it is gone."];
        [alert setAlertStyle: NSCriticalAlertStyle]; 
        [alert beginSheetModalForWindow: [self.view window] modalDelegate: self didEndSelector: nil contextInfo: nil]; 

        return;
    }

    if( [auraController unit: player hasAura: HonorlessTargetSpellID] || [auraController unit: player hasAura: HonorlessTarget2SpellID] ) {
        NSBeep();

        NSAlert *alert = [[[NSAlert alloc] init] autorelease]; 
        [alert addButtonWithTitle: @"Okay"];
        [alert setMessageText: @"Honorless Target"]; 
        [alert setInformativeText: @"Please wait for Honorless Target to fade before starting PvP."];
        [alert setAlertStyle: NSWarningAlertStyle]; 
        [alert beginSheetModalForWindow: [self.view window] modalDelegate: self didEndSelector: nil contextInfo: nil]; 

        return;
    }
    
    if(!self.pvpBattlemaster || !self.pvpEntryID) {
        // PGLog(@"[PvP] Presenting PvP dialog...");
        
        if(([controller reactMaskForFaction: [player factionTemplate]] & 0x2)) {
            [pvpBannerImage setImage: [NSImage imageNamed: @"BannerAlliance"]];
        } else {
            [pvpBannerImage setImage: [NSImage imageNamed: @"BannerHorde"]];
        }
        
        [self performSelector: @selector(pvpValidateBattlemaster:) withObject: nil];
        
        [NSApp beginSheet: pvpBMSelectPanel
           modalForWindow: [self.view window]
            modalDelegate: self
           didEndSelector: @selector(pvpSheetDidEnd: returnCode: contextInfo:)
              contextInfo: nil];
        return;
    }
    
    self.pvpCheckCount = 0;
    self.pvpAutoJoin = [pvpAutoJoinCheckbox state];
    self.pvpAutoQueue = [pvpAutoQueueCheckbox state];
    self.pvpAutoRelease = [pvpAutoReleaseCheckbox state];
    self.pvpPlayWarning = [pvpPlayWarningCheckbox state];
    self.pvpLeaveInactive = [pvpLeaveInactiveCheckbox state];
    
    // off we go...?
    self.isPvPing = YES;
    PGLog(@"[PvP] Starting...");
    
    if([self.pvpBattlemaster isValid]) {
        PGLog(@"[PvP] Battlemaster set. Queueing...");
        [self pvpQueueBattleground];
    } else {
        PGLog(@"[PvP] No valid Battlemaster was chosen.");
        [self pvpStop];
    }
    
    [self willChangeValueForKey: @"pvpButtonTitle"];
    [self didChangeValueForKey: @"pvpButtonTitle"];
}

- (IBAction)pvpStartStop: (id)sender {
    if(self.isPvPing) {
        [self pvpStop];
    } else {
        [self pvpStart];
    }
}

- (IBAction)pvpValidateBattlemaster: (id)sender {
    // reset current battlemaster
    self.pvpBattlemaster = nil;
    self.pvpEntryID = 0;
    
    // find new one
    [self performSelector: @selector(pvpFindBattlemaster:) withObject: [NSNumber numberWithBool: NO]];
    
    if(!self.pvpBattlemaster) NSBeep();
}

- (void)pvpSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [pvpBMSelectPanel orderOut: nil];

    if(returnCode == NSCancelButton) {
        self.pvpBattlemaster = nil;
        self.pvpEntryID = 0;
        return;
    }
    
    if(returnCode == NSOKButton) {
        [self pvpStart];
    }
}

- (IBAction)pvpBMSelectAction: (id)sender {
    [NSApp endSheet: pvpBMSelectPanel returnCode: [sender tag]];
}

- (IBAction)pvpTestWarning: (id)sender {
    [[NSSound soundNamed: @"alarm"] play];
}


@end

