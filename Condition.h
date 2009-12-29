//
//  Condition.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum Variety {
    VarietyNone             = 0,
    VarietyHealth           = 1,
    VarietyStatus           = 2,
    VarietyAura             = 3,
    VarietyDistance         = 4,
    VarietyInventory        = 5,
    VarietyComboPoints      = 6,
    VarietyAuraStack        = 7,
    VarietyTotem            = 8,
    VarietyTempEnchant      = 9,
    VarietyTargetType       = 10,
    VarietyTargetClass      = 11,
    VarietyCombatCount      = 12,
    VarietyProximityCount   = 13,
	VarietySpellCooldown	= 14,
	VarietyLastSpellCast	= 15,
} ConditionVariety;

typedef enum UnitComponents {
    UnitNone = 0,
    UnitPlayer = 1,
    UnitTarget = 2,
    UnitPlayerPet = 3,
	UnitFriend = 4,
	UnitAdd = 5,
} ConditionUnit;

typedef enum QualityComponents {
    QualityNone = 0,

    QualityHealth = 1,
    QualityPower = 2,
    QualityBuff = 3,
    QualityDebuff = 4,
    QualityDistance = 5,
    QualityInventory = 6,

    QualityComboPoints = 7,
    QualityMana = 8,
    QualityRage = 9,
    QualityEnergy = 10,
    QualityHappiness = 11,
    QualityFocus = 12,
    QualityRunicPower = 20,

    QualityBuffType = 13,
    QualityDebuffType = 14,

    QualityTotem = 15,
    
    QualityMainhand = 16,
    QualityOffhand = 17,
    
    QualityNPC          = 18,
    QualityPlayer       = 19,
    // QualityRunicPower = 20
} ConditionQuality;

typedef enum ComparatorComponents {
    CompareNone = 0,
    CompareMore = 1,
    CompareEqual = 2,
    CompareLess = 3,
    CompareIs = 4,
    CompareIsNot = 5,
    CompareExists = 6,
    CompareDoesNotExist = 7,
    CompareAtLeast = 8,
} ConditionComparator;

typedef enum StateComponents {
    StateNone = 0,
    StateAlive = 1,
    StateCombat = 2,
    StateCasting = 3,
    
    StateMagic = 4,
    StateCurse = 5,
    StateDisease = 6,
    StatePoison = 7,

    StateMounted = 8,
    StateIndoors = 9,
    
} ConditionState;

typedef enum TypeComponents {
    TypeNone = 0,
    TypeValue = 1,
    TypePercent = 2,
    TypeString = 3,
} ConditionType;

@interface Condition : NSObject <NSCoding, NSCopying> {
    ConditionVariety    _variety;
    ConditionUnit       _unit;
    ConditionQuality    _quality;
    ConditionComparator _comparator;
    ConditionState      _state;
    ConditionType       _type;
    
    id                  _value;
    BOOL                _enabled;
}

- (id)initWithVariety: (int)variety unit: (int)unit quality: (int)quality comparator: (int)comparator state: (int)state type: (int)type value: (id)value;
+ (id)conditionWithVariety: (int)variety
                      unit: (int)unit 
                   quality: (int)quality 
                comparator: (int)comparator 
                     state: (int)state
                      type: (int)type 
                     value: (id)value;

@property ConditionVariety variety;
@property ConditionUnit unit;
@property ConditionQuality quality;
@property ConditionComparator comparator;
@property ConditionState state;
@property ConditionType type;
@property (readwrite, retain) id value;
@property BOOL enabled;

@end
