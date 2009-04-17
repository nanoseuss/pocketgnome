//
//  Unit.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/26/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WoWObject.h"

enum eUnitBaseFields {
    BaseField_XLocation                 = 0x790,  // 3.0.9: 0x7C4
    BaseField_YLocation                 = 0x794,  // 3.0.9: 0x7C8
    BaseField_ZLocation                 = 0x798,  // 3.0.9: 0x7CC
    BaseField_Facing_Horizontal         = 0x79C,  // 3.0.9: 0x7D0  // [0, 2pi]
    BaseField_Facing_Vertical           = 0x7A0,  // 3.0.9: 0x7D0  // [-pi/2, pi/2]
    
    BaseField_MovementFlags             = 0x7C0,  // 3.0.9: 0x7F0
    // 0x80000001 - move forward
    // 0x80000002 - move backward
    // 0x80000004 - strafe left
    // 0x80000008 - strafe right
    
    // 0x80000010 - turn left
    // 0x80000020 - turn left
    
    // 0x80001000 - jumping
    
    // 0x80200000 - swimming
    
    // 0x81000000 - air mounted, on the ground
    // 0x83000400 - air mounted, in the air
    // 0x83400400 - air mounted, going up (spacebar)
    // 0x83800400 - air mounted, going down (sit key)
    // among others...
    
    BaseField_RunSpeed_Current          = 0x808,	// 3.0.9: 0x838
    BaseField_RunSpeed_Walk             = 0x80C,	// (you sure this is runspeed walk? - i noticed it was 2.5, yet current speed when walking was 7.0) 3.0.9: 0x83C
    BaseField_RunSpeed_Max              = 0x810,	// 3.0.9: 0x840
    BaseField_RunSpeed_Back             = 0x814,	// 3.0.9: 0x844
    BaseField_AirSpeed_Max              = 0x820,	// 3.0.9: 0x850
    

    BaseField_Spell_ToCast              = 0xA48,	// 3.0.9: 0xA28
    BaseField_Spell_Casting             = 0xA4C,	// 3.0.9: 0xA2C
    BaseField_Spell_TargetGUID_Low      = 0xA50,	// 3.0.9: 0xA30  (not sure how to verify if 3.1.0 offset is correct)
    BaseField_Spell_TargetGUID_High     = 0xA54,	// 3.0.9: 0xA34  (not sure how to verify if 3.1.0 offset is correct)
    BaseField_Spell_TimeStart           = 0xA58,	// 3.0.9: 0xA38
    BaseField_Spell_TimeEnd             = 0xA5C,	// 3.0.9: 0xA3C
    
    BaseField_Spell_Channeling          = 0xA60,	// 3.0.9: 0xA40
    BaseField_Spell_ChannelTimeStart    = 0xA64,	// 3.0.9: 0xA44
    BaseField_Spell_ChannelTimeEnd      = 0xA68,	// 3.0.9: 0xA48
    
    BaseField_UnitIsSelected            = 0xA50,	// 3.0.9:		( not sure what this is )
    
    BaseField_Player_CurrentTime        = 0xA94,	// 3.0.9: 0xA70
    
    // BaseField_CurrentStance          = 0xB40, // this seems to have dissapeared in 3.0.8
    
    BaseField_Auras_ValidCount          = 0xDA0,	// 3.0.9: 0xC40  (this number doesn't seem to actually have the number of auras - it doesn't change if you get new ones... confused why it's used?)
    BaseField_Auras_Start               = 0xDA4,	// 3.0.9: 0xC44
    
    // I'm not entirely sure what the story is behind these pointers
    // but it seems that once the player hits > 16 buffs/debuffs (17 or more)
    // the Aura fields in the player struct is abandoned and moves elsewhere
    BaseField_Auras_OverflowPtr1        = 0xE28,    // 3.0.9: 0xDD0 // 3.0.8-9: i could not verify overflow 2, 3, 4
    // BaseField_Auras_OverflowPtr2        = 0xEA4, // but since they aren't actually used, I don't think it matters.
    // BaseField_Auras_OverflowPtr3        = 0xF3C,
    // BaseField_Auras_OverflowPtr4        = 0xF94,
};

enum eUnitFields {
	UnitField_Charm                     = 0x18,
	UnitField_Summon                    = 0x20,
	UnitField_Critter                   = 0x28,
	UnitField_CharmedBy                 = 0x30,
	UnitField_SummonedBy                = 0x38,
	UnitField_CreatedBy                 = 0x40,
	UnitField_Target                    = 0x48,
	//UnitField_Persuaded                 = 0x48,
	UnitField_Channel_Object            = 0x50,
    
    UnitField_Bytes0                    = 0x58,
    
	UnitField_Health                    = 0x5C,
	UnitField_Power1                    = 0x60, // Mana
	UnitField_Power2                    = 0x64, // Rage
	UnitField_Power3                    = 0x68, // Focus
	UnitField_Power4                    = 0x6C, // Energy
	UnitField_Power5                    = 0x70, // Happiness
	UnitField_Power6                    = 0x74, // unknown
	UnitField_Power7                    = 0x78, // Runic Power
	UnitField_MaxHealth                 = 0x7C,
	UnitField_MaxPower1                 = 0x80,
	UnitField_MaxPower2                 = 0x84,
	UnitField_MaxPower3                 = 0x88,
	UnitField_MaxPower4                 = 0x8C,
	UnitField_MaxPower5                 = 0x90,
	UnitField_MaxPower6                 = 0x94,
	UnitField_MaxPower7                 = 0x98,

    UnitField_PowerRegen_FlatMod        = 0x9C,
    // 0xA0 - 0xB4 are not known
    UnitField_PowerRegen_Interrupted_FlatMod = 0xB8,


	UnitField_Level                     = 0xD4,
	UnitField_FactionTemplate           = 0xD8,
    // UNIT_VIRTUAL_ITEM_SLOT_ID
    
    UnitField_StatusFlags               = 0xE8,
    UnitField_StatusFlags2              = 0xEC,
    
    UnitField_MainhandSpeed             = 0xF4, // these speeds are in milliseconds, eg 2000 = 2.0sec
    UnitField_OffhandSpeed              = 0xF8,
    UnitField_RangedSpeed               = 0xFC,

    UnitField_BoundingRadius            = 0x100,
    UnitField_CombatReach               = 0x104,

    UnitField_DisplayID                 = 0x108,
    UnitField_NativeDisplayID           = 0x10C,
    UnitField_MountDisplayID            = 0x110,

	UnitField_Bytes_1                   = 0x124,    // sit, lie, kneel and so on (stealth = 0x20000)
    
    UnitField_PetNumber                 = 0x128,    // not the same as entry ID
	UnitField_PetNameTimestamp          = 0x12C,
	UnitField_PetExperience             = 0x130,
	UnitField_PetNextLevelExp           = 0x134,

	UnitField_DynamicFlags              = 0x138,    // tracking, tapped
	UnitField_ChannelSpell              = 0x13C,
	UnitField_ModCastSpeed              = 0x140,
	UnitField_UnitCreatedBySpell        = 0x144,
	UnitField_NPCFlags                  = 0x148,    // repairer, auctioneer, etc
	UnitField_NPCEmoteState             = 0x14C,
    
    // 5x stats
    // 5x +states
    // 5x -stats
    // 7x resistances
    // 7x resistances mod positive
    // 7x resistances mod negative
    
	UnitField_BaseMana                  = 0x1E0,
	UnitField_BaseHealth                = 0x1E4,
    UnitField_Bytes_2                   = 0x1E8,    // 0x1001 for most mobs. 0x2801 for totems?

    UnitField_AttackPower               = 0x1EC,
    UnitField_AttackPower_Mod           = 0x1F0,
    UnitField_AttackPower_Mult          = 0x1F4,
    UnitField_Ranged_AttackPower        = 0x1F8,
    UnitField_Ranged_AttackPower_Mod    = 0x1FC,
    UnitField_Ranged_AttackPower_Mult   = 0x200,
    UnitField_Ranged_MinDamage          = 0x204,
    UnitField_Ranged_MaxDamage          = 0x208,
    UnitField_PowerCost_Mod             = 0x20C,
    // 7 total fields ^^
    UnitField_PowerCost_Mult            = 0x228,
    // 7 total fields ^^
    
    UnitField_MaxHealth_Modifier        = 0x244,
    UnitField_HoverHeight               = 0x248,
    // padding

    UnitField_TotalUnitFields           = 0x59,
    
};

/*
// Value masks for UNIT_FIELD_FLAGS (UnitField_StatusFlags)
enum UnitFlags
{
    UNIT_FLAG_UNKNOWN7       = 0x00000001,
    UNIT_FLAG_NON_ATTACKABLE = 0x00000002,                  // not attackable
    UNIT_FLAG_DISABLE_MOVE   = 0x00000004,
    UNIT_FLAG_UNKNOWN1       = 0x00000008,                  // for all units, make unit attackable even it's friendly in some cases...
    UNIT_FLAG_RENAME         = 0x00000010,
    UNIT_FLAG_RESTING        = 0x00000020,
    UNIT_FLAG_UNKNOWN9       = 0x00000040,
    UNIT_FLAG_UNKNOWN10      = 0x00000080,
    UNIT_FLAG_UNKNOWN2       = 0x00000100,                  // 2.0.8
    UNIT_FLAG_UNKNOWN11      = 0x00000200,
    UNIT_FLAG_UNKNOWN12      = 0x00000400,                  // loot animation
    UNIT_FLAG_PET_IN_COMBAT  = 0x00000800,                  // in combat?, 2.0.8
    UNIT_FLAG_PVP            = 0x00001000,                  // ok
    UNIT_FLAG_SILENCED       = 0x00002000,                  // silenced, 2.1.1
    UNIT_FLAG_UNKNOWN4       = 0x00004000,                  // 2.0.8
    UNIT_FLAG_UNKNOWN13      = 0x00008000,
    UNIT_FLAG_UNKNOWN14      = 0x00010000,
    UNIT_FLAG_PACIFIED       = 0x00020000,
    UNIT_FLAG_DISABLE_ROTATE = 0x00040000,                  // stunned, 2.1.1
    UNIT_FLAG_IN_COMBAT      = 0x00080000,
    UNIT_FLAG_UNKNOWN15      = 0x00100000,                  // mounted? 2.1.3, probably used with 0x4 flag
    UNIT_FLAG_DISARMED       = 0x00200000,                  // disable melee spells casting..., "Required melee weapon" added to melee spells tooltip.
    UNIT_FLAG_CONFUSED       = 0x00400000,
    UNIT_FLAG_FLEEING        = 0x00800000,
    UNIT_FLAG_UNKNOWN5       = 0x01000000,                  // used in spell Eyes of the Beast for pet...
    UNIT_FLAG_NOT_SELECTABLE = 0x02000000,                  // ok
    UNIT_FLAG_SKINNABLE      = 0x04000000,
    UNIT_FLAG_MOUNT          = 0x08000000,                  // the client seems to handle it perfectly
    UNIT_FLAG_UNKNOWN17      = 0x10000000,
    UNIT_FLAG_UNKNOWN6       = 0x20000000,                  // used in Feing Death spell
    UNIT_FLAG_SHEATHE        = 0x40000000
};
*/
   // polymorph sets bits 22 and 29
    
    // bit 1  - not attackable
    // bit 4  - evading
    // bit 10 - looting
    // bit 11 - combat (for mob)
    // but 18 - stunned
    // bit 19 - combat (for player)
    // bit 23 - running away
    // bit 25 - invisible/not selectable
    // bit 26 - skinnable
    // bit 29 - feign death
    
typedef enum {
    UnitStatus_Unknown0         = 0,
    UnitStatus_NotAttackable    = 1,
    UnitStatus_Disablemove      = 2,
    UnitStatus_Unknown3,
    UnitStatus_Evading          = 4,
    UnitStatus_Resting          = 5,
    UnitStatus_Elite            = 6,
    UnitStatus_Unknown7,
    UnitStatus_Unknown8,
    UnitStatus_Unknown9,                // most NPCs in IF have this
    UnitStatus_Looting          = 10,   // loot animation
    UnitStatus_NPC_Combat       = 11,   // not really sure
    UnitStatus_PVP              = 12,
    UnitStatus_Silenced         = 13,
    UnitStatus_Unknown14,
    UnitStatus_Unknown15,               // guards in IF all have this
    UnitStatus_Unknown16,
    UnitStatus_Pacified         = 17,
    UnitStatus_Stunned          = 18,
    UnitStatus_InCombat         = 19,
    UnitStatus_Unknown20,
    UnitStatus_Disarmed         = 21,
    UnitStatus_Confused         = 22, // used in polymorph
    UnitStatus_Fleeing          = 23,
    UnitStatus_MindControl      = 24, // used in eyes of the beast...
    UnitStatus_NotSelectable    = 25,
    UnitStatus_Skinnable        = 26,
    UnitStatus_Mounted          = 27,
    UnitStatus_Unknown28        = 28,
    UnitStatus_FeignDeath       = 29,
    UnitStatus_Sheathe          = 30,
} UnitStatusBits;


typedef enum {
    UnitPower_Mana          = 0,
    UnitPower_Rage          = 1,
    UnitPower_Focus         = 2,
    UnitPower_Energy        = 3,
    UnitPower_Happiness     = 4,
    UnitPower_RunicPower    = 6,
    UnitPower_Max           = 7,
} UnitPower;

typedef enum {
    UnitGender_Male         = 0,
    UnitGender_Female       = 1,
    UnitGender_Unknown      = 2,
} UnitGender;

// UnitClass must be replicated in TargetClassCondition
typedef enum {
    UnitClass_Unknown       = 0,
    UnitClass_Warrior       = 1,
    UnitClass_Paladin       = 2,
    UnitClass_Hunter        = 3,
    UnitClass_Rogue         = 4,
    UnitClass_Priest        = 5,
    UnitClass_DeathKnight   = 6,
    UnitClass_Shaman        = 7,
    UnitClass_Mage          = 8,
    UnitClass_Warlock       = 9,
    UnitClass_Druid         = 11,
} UnitClass;

typedef enum {
    UnitRace_Human          = 1,
    UnitRace_Orc,
    UnitRace_Dwarf,
    UnitRace_NightElf,
    UnitRace_Undead,
    UnitRace_Tauren,
    UnitRace_Gnome,
    UnitRace_Troll,
    UnitRace_Goblin,
    UnitRace_BloodElf,
    UnitRace_Draenei,
    UnitRace_FelOrc,
    UnitRace_Naga,
    UnitRace_Broken,
    UnitRace_Skeleton       = 15,
} UnitRace;

// CreatureType must be replicated in TargetClassCondition
typedef enum CreatureType
{
    CreatureType_Unknown          = 0,
    CreatureType_Beast            = 1,  // CREATURE_TYPE_BEAST
    CreatureType_Dragon           = 2,
    CreatureType_Demon            = 3,
    CreatureType_Elemental        = 4,
    CreatureType_Giant            = 5,
    CreatureType_Undead           = 6,
    CreatureType_Humanoid         = 7,
    CreatureType_Critter          = 8,
    CreatureType_Mechanical       = 9,
    CreatureType_NotSpecified     = 10,
    CreatureType_Totem            = 11,
    CreatureType_Non_Combat_Pet   = 12,
    CreatureType_Gas_Cloud        = 13,
    
    CreatureType_Max,
} CreatureType;

@interface Unit : WoWObject <UnitPosition> {

}

+ (id)unitWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

// global
- (Position*)position;
- (float)directionFacing;

- (GUID)petGUID;

- (GUID)charm;
- (GUID)summon;
- (GUID)targetID;
- (GUID)createdBy;
- (GUID)charmedBy;
- (GUID)summonedBy;

// info
- (UInt32)level;
- (UInt32)maxPower;
- (UInt32)maxHealth;
- (UInt32)currentPower;
- (UInt32)percentPower;
- (UInt32)currentHealth;
- (UInt32)percentHealth;
- (UInt32)factionTemplate;

- (UInt32)currentStance; // only works for the current player

- (UInt32)maxPowerOfType: (UnitPower)powerType;
- (UInt32)currentPowerOfType: (UnitPower)powerType;
- (UInt32)percentPowerOfType: (UnitPower)powerType;

// unit type
- (UnitRace)race;
- (UnitGender)gender;
- (UnitClass)unitClass;
- (UnitPower)powerType;

- (CreatureType)creatureType;

// unit type translation
+ (NSString*)stringForClass: (UnitClass)unitClass;
+ (NSString*)stringForRace: (UnitRace)unitRace;
+ (NSString*)stringForGender: (UnitGender) underGender;
- (NSImage*)iconForClass: (UnitClass)unitClass;
- (NSImage*)iconForRace: (UnitRace)unitRace gender: (UnitGender)unitGender;

// status
- (BOOL)isPet;
- (BOOL)hasPet;
- (BOOL)isTotem;
- (BOOL)isElite;
- (BOOL)isCasting;
- (BOOL)isMounted;

- (UInt32)stateFlags;
- (BOOL)isPVP;
- (BOOL)isDead;
- (BOOL)isFleeing;
- (BOOL)isEvading;
- (BOOL)isInCombat;
- (BOOL)isSkinnable;
- (BOOL)isFeignDeath;
- (BOOL)isSelectable;
- (BOOL)isAttackable;

- (UInt32)dynamicFlags;
- (UInt32)npcFlags;
- (BOOL)isLootable;         // always NO
- (BOOL)isTappedByOther;    // always NO

- (void)trackUnit;
- (void)untrackUnit;

- (UInt32)petNumber;
- (UInt32)petNameTimestamp;

- (UInt32)createdBySpell;

- (UInt32)unitBytes1;
- (UInt32)unitBytes2;

- (BOOL)isSitting;

@end
