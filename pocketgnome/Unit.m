//
//  Unit.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/26/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Unit.h"
#import "Offsets.h"

#import "SpellController.h"

/*
/// Non Player Character flags
enum NPCFlags
{
    UNIT_NPC_FLAG_NONE              = 0x00000000,
    UNIT_NPC_FLAG_GOSSIP            = 0x00000001,
    UNIT_NPC_FLAG_QUESTGIVER        = 0x00000002,
    UNIT_NPC_FLAG_VENDOR            = 0x00000004,
    UNIT_NPC_FLAG_TAXIVENDOR        = 0x00000008,
    UNIT_NPC_FLAG_TRAINER           = 0x00000010,
    UNIT_NPC_FLAG_SPIRITHEALER      = 0x00000020,
    UNIT_NPC_FLAG_SPIRITGUIDE       = 0x00000040,           // Spirit Guide
    UNIT_NPC_FLAG_INNKEEPER         = 0x00000080,
    UNIT_NPC_FLAG_BANKER            = 0x00000100,
    UNIT_NPC_FLAG_PETITIONER        = 0x00000200,           // 0x600 = guild petitions, 0x200 = arena team petitions
    UNIT_NPC_FLAG_TABARDDESIGNER    = 0x00000400,
    UNIT_NPC_FLAG_BATTLEFIELDPERSON = 0x00000800,
    UNIT_NPC_FLAG_AUCTIONEER        = 0x00001000,
    UNIT_NPC_FLAG_STABLE            = 0x00002000,
    UNIT_NPC_FLAG_ARMORER           = 0x00004000,
    UNIT_NPC_FLAG_GUARD             = 0x00010000,           // custom flag
};
*/

@interface Unit (Internal)
- (UInt32)infoFlags;
@end

@implementation Unit

+ (id)unitWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    return [[[Unit alloc] initWithAddress: address inMemory: memory] autorelease];
}

#pragma mark Object Global Accessors

// 1 read
- (Position*)position {
    float pos[3] = {-1.0f, -1.0f, -1.0f };
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_XLocation) Buffer: (Byte *)&pos BufLength: sizeof(float)*3])
        return [Position positionWithX: pos[0] Y: pos[1] Z: pos[2]];
    return nil;
}

- (float)directionFacing {
    float floatValue = -1.0;
    [_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_Facing_Horizontal) Buffer: (Byte*)&floatValue BufLength: sizeof(floatValue)];
    return floatValue;
}


- (GUID)petGUID {
    UInt64 value = 0;
    
    // check for summon
    if( (value = [self summon]) ) {
        return value;
    }
    
    // check for charm
    if( (value = [self charm]) ) {
        return value;
    }
    return 0;
}


- (BOOL)hasPet {
    if( [self petGUID] > 0 ) {
        return YES;
    }
    return NO;
}

- (BOOL)isPet {
    if((GUID_HIPART([self GUID]) == HIGHGUID_PET) || [self isTotem])
        return YES;
        
    if( [self createdBy] || [self summonedBy] || [self charmedBy])
        return YES;
    
    return NO;
}

- (BOOL)isTotem {
    return NO;
}

- (BOOL)isCasting {
    UInt32 cast = 0, channel = 0;
    if([self isNPC]) {
        [_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_Spell_ToCast) Buffer: (Byte *)&cast BufLength: sizeof(cast)];
        [_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_Spell_Channeling) Buffer: (Byte *)&channel BufLength: sizeof(channel)];
    } else if([self isPlayer]) {
        [_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_Spell_Casting) Buffer: (Byte *)&cast BufLength: sizeof(cast)];
        [_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_Spell_Channeling) Buffer: (Byte *)&channel BufLength: sizeof(channel)];
    }
    
    if( cast > 0 || channel > 0)
        return YES;
    
    return NO;
}


- (BOOL)isMounted {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_MountDisplayID) Buffer: (Byte*)&value BufLength: sizeof(value)] && (value > 0) && (value != 0xDDDDDDDD)) {
        return YES;
    }
    return NO;
}

- (BOOL)isElite {
    return NO;
}

#pragma mark Object Field Accessors

- (UInt64)charm {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_Charm) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt64)summon {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_Summon) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 1 read
- (UInt64)targetID {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_Target) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt64)createdBy {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_CreatedBy) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt64)summonedBy {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_SummonedBy) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

- (UInt64)charmedBy {
    UInt64 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_CharmedBy) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 3 reads (2 in powerType, 1)
- (UInt32)maxPower {
    return [self maxPowerOfType: [self powerType]];
}

// 3 reads
- (UInt32)currentPower {
    return [self currentPowerOfType: [self powerType]];
}

// 4 reads: 2 in powerType, 2 in percentPowerOfType
- (UInt32)percentPower {
    return [self percentPowerOfType: [self powerType]];
}


// 1
- (UInt32)maxHealth {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_MaxHealth) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 1 read
- (UInt32)currentHealth {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_Health) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 2 reads
- (UInt32)percentHealth {
    UInt32 maxHealth = [self maxHealth];
    if(maxHealth == 0) return 0;
    return (UInt32)((((1.0)*[self currentHealth])/maxHealth) * 100);
}

// 1 read
- (UInt32)level {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_Level) Buffer: (Byte *)&value BufLength: sizeof(value)])
        return value;
    return 0;
}

// 1 read
- (UInt32)factionTemplate {
    UInt32 value = 0;
    [_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_FactionTemplate) Buffer: (Byte *)&value BufLength: sizeof(value)];
    return value;
}

// only works for the current player
// 0xFFFFFFF when invalid
- (UInt32)currentStance {
    // this field seems to have been removed in 3.0.8
    return 0;

    /*
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + BaseField_CurrentStance) Buffer: (Byte *)&value BufLength: sizeof(value)])
        if(value && (value != 0xFFFFFFFF))
            return value;
    return 0;*/
}

#pragma mark -

// 1 read
- (UInt32)maxPowerOfType: (UnitPower)powerType {
    if(powerType < 0 || powerType > UnitPower_Max) return 0;
    
    UInt32 value;
    if([_memory loadDataForObject: self atAddress: (([self infoAddress] + UnitField_MaxPower1) + (sizeof(value) * powerType)) Buffer: (Byte *)&value BufLength: sizeof(value)])
    { 
        if((powerType == UnitPower_Rage) || (powerType == UnitPower_RunicPower))
            return value/10;
        else
            return value;
    }
    return 0;
}

// 1 read
- (UInt32)currentPowerOfType: (UnitPower)powerType {
    if(powerType < 0 || powerType > UnitPower_Max) return 0;
    UInt32 value;
    if([_memory loadDataForObject: self atAddress: (([self infoAddress] + UnitField_Power1) + (sizeof(value) * powerType)) Buffer: (Byte *)&value BufLength: sizeof(value)])
    {
        if((powerType == UnitPower_Rage) || (powerType == UnitPower_RunicPower))
            return lrintf(floorf(value/10.0f));
        else
            return value;
    }
    return 0;
}

// 1 in maxP, 1 in currP
- (UInt32)percentPowerOfType: (UnitPower)powerType {

    UInt32 maxPower = [self maxPowerOfType: powerType];
    if(maxPower == 0) return 0;
    return (UInt32)((((1.0)*[self currentPowerOfType: powerType])/maxPower) * 100);
}

#pragma mark Unit Info

// 2 read
- (UInt32)infoFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_Bytes0) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return CFSwapInt32HostToLittle(value);
    }
    return 0;
}

- (UnitRace)race {
    return ([self infoFlags] >> 0 & 0xFF);
}

- (UnitClass)unitClass {
    return (([self infoFlags] >> 8) & 0xFF);
}

- (UnitGender)gender {
    return (([self infoFlags] >> 16) & 0xFF);
}

- (UnitPower)powerType {
    return (([self infoFlags] >> 24) & 0xFF);
}

- (CreatureType)creatureType {
    if([self isPlayer]) {
        return CreatureType_Humanoid;
    }
    return CreatureType_Unknown;
}

#pragma mark Unit Info Translations

+ (NSString*)stringForClass: (UnitClass)unitClass {
    NSString *stringClass = nil;
    
    switch(unitClass) {
        case UnitClass_Warrior:
            stringClass = @"Warrior";
            break;
        case UnitClass_Paladin:
            stringClass = @"Paladin";
            break;
        case UnitClass_Hunter:
            stringClass = @"Hunter";
            break;
        case UnitClass_Rogue:
            stringClass = @"Rogue";
            break;
        case UnitClass_Priest:
            stringClass = @"Priest";
            break;
        case UnitClass_Shaman:
            stringClass = @"Shaman";
            break;
        case UnitClass_Mage:
            stringClass = @"Mage";
            break;
        case UnitClass_Warlock:
            stringClass = @"Warlock";
            break;
        case UnitClass_Druid:
            stringClass = @"Druid";
            break;
        case UnitClass_DeathKnight:
            stringClass = @"Death Knight";
            break;
        default:
            stringClass = @"Unknown";
            break;
    }
    return stringClass;
}

+ (NSString*)stringForRace: (UnitRace)unitRace {
    NSString *string = nil;
    
    switch(unitRace) {
        case UnitRace_Human:
            string = @"Human";
            break;
        case UnitRace_Orc:
            string = @"Orc";
            break;
        case UnitRace_Dwarf:
            string = @"Dwarf";
            break;
        case UnitRace_NightElf:
            string = @"Night Elf";
            break;
        case UnitRace_Undead:
            string = @"Undead";
            break;
        case UnitRace_Tauren:
            string = @"Tauren";
            break;
        case UnitRace_Gnome:
            string = @"Gnome";
            break;
        case UnitRace_Troll:
            string = @"Troll";
            break;
        case UnitRace_Goblin:
            string = @"Goblin";
            break;
        case UnitRace_BloodElf:
            string = @"Blood Elf";
            break;
        case UnitRace_Draenei:
            string = @"Draenei";
            break;
        case UnitRace_FelOrc:
            string = @"Fel Orc";
            break;
        case UnitRace_Naga:
            string = @"Naga";
            break;
        case UnitRace_Broken:
            string = @"Broken";
            break;
        case UnitRace_Skeleton:
            string = @"Skeleton";
            break;
        default:
            string = @"Unknown";
            break;
    }
    return string;
}

+ (NSString*)stringForGender: (UnitGender) underGender {
    NSString *string = nil;
    
    switch(underGender) {
        case UnitGender_Male:
            string = @"Male";
            break;
        case UnitGender_Female:
            string = @"Female";
            break;
        default:
            string = @"Unknown";
            break;
    }
    return string;
}

- (NSImage*)iconForClass: (UnitClass)unitClass {
    return [NSImage imageNamed: [[NSString stringWithFormat: @"%@_Small", [Unit stringForClass: unitClass]] stringByReplacingOccurrencesOfString: @" " withString: @""]];
    
    NSImage *icon = nil;
    switch(unitClass) {
        case UnitClass_Warrior:
            icon = [NSImage imageNamed: @"Warrior"];
            break;
        case UnitClass_Paladin:
            icon = [NSImage imageNamed: @"Paladin"];
            break;
        case UnitClass_Hunter:
            icon = [NSImage imageNamed: @"Hunter"];
            break;
        case UnitClass_Rogue:
            icon = [NSImage imageNamed: @"Rogue"];
            break;
        case UnitClass_Priest:
            icon = [NSImage imageNamed: @"Priest"];
            break;
        case UnitClass_Shaman:
            icon = [NSImage imageNamed: @"Shaman"];
            break;
        case UnitClass_Mage:
            icon = [NSImage imageNamed: @"Mage"];
            break;
        case UnitClass_Warlock:
            icon = [NSImage imageNamed: @"Warlock"];
            break;
        case UnitClass_Druid:
            icon = [NSImage imageNamed: @"Druid"];
            break;
        case UnitClass_DeathKnight:
            icon = [NSImage imageNamed: @"Death Knight"];
            break;
        default:
            icon = [NSImage imageNamed: @"UnknownSmall"];
            break;
    }
    return icon;
}

- (NSImage*)iconForRace: (UnitRace)unitRace gender: (UnitGender)unitGender {
    return [NSImage imageNamed: 
            [[NSString stringWithFormat: @"%@-%@_Small", 
              [Unit stringForRace: unitRace], 
              [Unit stringForGender: unitGender]] 
             stringByReplacingOccurrencesOfString: @" " withString: @""]];
}


#pragma mark State Functions

// 2 read
- (UInt32)stateFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_StatusFlags) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}


- (BOOL)isPVP {
    if( ([self stateFlags] & (1 << UnitStatus_PVP)) == (1 << UnitStatus_PVP))   // 0x1000
        return YES;
    return NO;
}

// 2 reads
- (BOOL)isDead {
    if([self currentHealth] == 0) {
        if([self isFeignDeath]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)isFleeing {
    if( ([self stateFlags] & (1 << UnitStatus_Fleeing)) == (1 << UnitStatus_Fleeing))
        return YES;
    return NO;
}

- (BOOL)isEvading {
    if( ([self stateFlags] & (1 << UnitStatus_Evading)) == (1 << UnitStatus_Evading)) 
        return YES;
    return NO;
}

- (BOOL)isInCombat {
    if( ([self stateFlags] & (1 << UnitStatus_InCombat)) == (1 << UnitStatus_InCombat))   // 0x80000
        return YES;
    return NO;
}

- (BOOL)isSkinnable {
    return NO;
}

- (BOOL)isFeignDeath {
    if ( ([self stateFlags] & (1 << UnitStatus_FeignDeath)) == (1 << UnitStatus_FeignDeath))  // 0x20000000
        return YES;
    return NO;
}

- (BOOL)isSelectable {
    if ( ([self stateFlags] & (1 << UnitStatus_NotSelectable)) == (1 << UnitStatus_NotSelectable))
        return NO;
    return YES;
}

- (BOOL)isAttackable {
    if ( ([self stateFlags] & (1 << UnitStatus_NotAttackable)) == (1 << UnitStatus_NotAttackable))
        return NO;
    return YES;
}


- (UInt32)dynamicFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_DynamicFlags) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}

- (UInt32)npcFlags {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_NPCFlags) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}

- (BOOL)isLootable {
    return NO;
}

- (BOOL)isTappedByOther {
    return NO;
}

- (void)trackUnit {
    UInt32 value = [self dynamicFlags] | 0x2;
    [_memory saveDataForAddress: ([self infoAddress] + UnitField_DynamicFlags) Buffer: (Byte *)&value BufLength: sizeof(value)];
}
- (void)untrackUnit {
    UInt32 value = [self dynamicFlags] & ~0x2;
    [_memory saveDataForAddress: ([self infoAddress] + UnitField_DynamicFlags) Buffer: (Byte *)&value BufLength: sizeof(value)];
}

- (UInt32)petNumber {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_PetNumber) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return value;
    }
    return 0;
}

- (UInt32)petNameTimestamp {
    UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_PetNameTimestamp) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
        return value;
    }
    return 0;
}

- (UInt32)createdBySpell {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_UnitCreatedBySpell) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return value;
    }
    return 0;
}

- (UInt32)unitBytes1 {
    // sit == 4, 5, 6
    // lie down = 0x7
    // kneel = 0x8
    // no shadow = 9

    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_Bytes_1) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return CFSwapInt32HostToLittle(value);  // not tested if CFSwapInt32HostToLittle is necessary, since unitBytes1 is not yet used anywhere
    }
    return 0;
}


- (BOOL)isSitting {
    return ([self unitBytes1] & 0x1);
}

- (UInt32)unitBytes2 {
    UInt32 value = 0;
    if([self isValid] && [_memory loadDataForObject: self atAddress: ([self infoAddress] + UnitField_Bytes_2) Buffer: (Byte *)&value BufLength: sizeof(value)] && (value != 0xDDDDDDDD)) {
        return CFSwapInt32HostToLittle(value);
    }
    return 0;
}
/*
// high byte (3 from 0..3) of UNIT_FIELD_BYTES_2
enum ShapeshiftForm
{
    FORM_NONE               = 0x00,
    FORM_CAT                = 0x01,
    FORM_TREE               = 0x02,
    FORM_TRAVEL             = 0x03,
    FORM_AQUA               = 0x04,
    FORM_BEAR               = 0x05,
    FORM_AMBIENT            = 0x06,
    FORM_GHOUL              = 0x07,
    FORM_DIREBEAR           = 0x08,
    FORM_CREATUREBEAR       = 0x0E,
    FORM_CREATURECAT        = 0x0F,
    FORM_GHOSTWOLF          = 0x10,
    FORM_BATTLESTANCE       = 0x11,
    FORM_DEFENSIVESTANCE    = 0x12,
    FORM_BERSERKERSTANCE    = 0x13,
    FORM_TEST               = 0x14,
    FORM_ZOMBIE             = 0x15,
    FORM_FLIGHT_EPIC        = 0x1B,
    FORM_SHADOW             = 0x1C,
    FORM_FLIGHT             = 0x1D,
    FORM_STEALTH            = 0x1E,
    FORM_MOONKIN            = 0x1F,
    FORM_SPIRITOFREDEMPTION = 0x20
};


// byte (2 from 0..3) of UNIT_FIELD_BYTES_2
enum UnitRename
{
    UNIT_RENAME_NOT_ALLOWED = 0x02,
    UNIT_RENAME_ALLOWED     = 0x03
};

// byte (1 from 0..3) of UNIT_FIELD_BYTES_2
enum UnitBytes2_Flags
{
    UNIT_BYTE2_FLAG_UNK0  = 0x01,
    UNIT_BYTE2_FLAG_UNK1  = 0x02,
    UNIT_BYTE2_FLAG_UNK2  = 0x04,
    UNIT_BYTE2_FLAG_UNK3  = 0x08,
    UNIT_BYTE2_FLAG_AURAS = 0x10,                           // show possitive auras as positive, and allow its dispel
    UNIT_BYTE2_FLAG_UNK5  = 0x20,
    UNIT_BYTE2_FLAG_UNK6  = 0x40,
    UNIT_BYTE2_FLAG_UNK7  = 0x80
};

// low byte ( 0 from 0..3 ) of UNIT_FIELD_BYTES_2
enum SheathState
{
    SHEATH_STATE_UNARMED  = 0,                              // non prepared weapon
    SHEATH_STATE_MELEE    = 1,                              // prepared melee weapon
    SHEATH_STATE_RANGED   = 2                               // prepared ranged weapon
};
*/

#pragma mark -

- (NSString*)descriptionForOffset: (UInt32)offset {
    NSString *desc = nil;
    
    if(offset < ([self infoAddress] - [self baseAddress])) {
        switch(offset) {
        
            case BaseField_RunSpeed_Current:
                desc = @"Current Speed (float)";
                break;
            case BaseField_RunSpeed_Max:
                desc = @"Max Ground Speed (float)";
                break;
            case BaseField_AirSpeed_Max:
                desc = @"Max Air Speed (float)";
                break;
                
            case BaseField_XLocation:
                desc = @"X Location (float)";
                break;
            case BaseField_YLocation:
                desc = @"Y Location (float)";
                break;
            case BaseField_ZLocation:
                desc = @"Z Location (float)";
                break;
                
            case BaseField_Facing_Horizontal:
                desc = @"Direction Facing - Horizontal (float, [0, 2pi])";
                break;
            case BaseField_Facing_Vertical:
                desc = @"Direction Facing - Vertical (float, [-pi/2, pi/2])";
                break;
                
            case BaseField_MovementFlags:
                desc = @"Movement Flags";
                break;
                
            case BaseField_Spell_ToCast:
                desc = @"Spell ID to cast";
                break;
            case BaseField_Spell_Casting:
                desc = @"Spell ID of casting spell";
                break;
            case BaseField_Spell_TimeStart:
                desc = @"Time of cast start";
                break;
            case BaseField_Spell_TimeEnd:
                desc = @"Time of cast end";
                break;
                
            case BaseField_Spell_Channeling:
                desc = @"Spell ID channeling";
                break;
            case BaseField_Spell_ChannelTimeStart:
                desc = @"Time of channel start";
                break;
            case BaseField_Spell_ChannelTimeEnd:
                desc = @"Time of channel end";
                break;
				
            case BaseField_Auras_Start:
                desc = @"Start of Auras";
                break;
            case BaseField_Auras_Start_IDs:
                desc = @"Start of Aura IDs";
                break;
            case BaseField_Auras_ValidCount:
                desc = @"Auras Valid Count";
                break;
				
            case BaseField_Player_CurrentTime:
                if([self isPlayer]) {
                    desc = @"Current Time";
                }
                break;
        }
    } else {
        int revOffset = offset - ([self infoAddress] - [self baseAddress]);

        switch(revOffset) {
            case UnitField_Charm:
                desc = @"Charm (GUID)";
                break;
            case UnitField_Summon:
                desc = @"Summon (GUID)";
                break;
            case UnitField_Critter:
                desc = @"Critter (GUID)";
                break;
            case UnitField_CharmedBy:
                desc = @"Charmed By (GUID)";
                break;
            case UnitField_SummonedBy:
                desc = @"Summoned By (GUID)";
                break;
            case UnitField_CreatedBy:
                desc = @"Created By (GUID)";
                break;
            case UnitField_Target:
                desc = @"Target (GUID)";
                break;
            case UnitField_Channel_Object:
                desc = @"Channel Target (GUID)";
                break;

            case UnitField_Health:
                desc = @"Health, Current";
                break;
            case UnitField_Power1:
                desc = @"Mana, Current";
                break;
            case UnitField_Power2:
                desc = @"Rage, Current";
                break;
            case UnitField_Power3:
                desc = @"Focus, Current";
                break;
            case UnitField_Power4:
                desc = @"Energy, Current";
                break;
            case UnitField_Power5:
                desc = @"Happiness, Current";
                break;
            case UnitField_Power7:
                desc = @"Runic Power, Current";
                break;

            case UnitField_MaxHealth:
                desc = @"Health, Max";
                break;
            case UnitField_MaxPower1:
                desc = @"Mana, Max";
                break;
            case UnitField_MaxPower2:
                desc = @"Rage, Max";
                break;
            case UnitField_MaxPower3:
                desc = @"Focus, Max";
                break;
            case UnitField_MaxPower4:
                desc = @"Energy, Max";
                break;
            case UnitField_MaxPower5:
                desc = @"Happiness, Max";
                break;
            case UnitField_MaxPower7:
                desc = @"Runic Power, Max";
                break;

            case UnitField_Level:
                desc = @"Level";
                break;
            case UnitField_FactionTemplate:
                desc = @"Faction";
                break;
            case UnitField_Bytes0:
                desc = @"Info Flags (bytes0)";
                break;
            case UnitField_StatusFlags:
                desc = @"Status Flags";
                break;

            case UnitField_MainhandSpeed:
                desc = @"Mainhand Speed";
                break;
            case UnitField_OffhandSpeed:
                desc = @"Offhand Speed";
                break;
            case UnitField_RangedSpeed:
                desc = @"Ranged Speed";
                break;

            case UnitField_BoundingRadius:
                desc = @"Bounding Radius";
                break;
            case UnitField_CombatReach:
                desc = @"Combat Reach";
                break;
            case UnitField_DisplayID:
                desc = @"Display ID";
                break;
            case UnitField_NativeDisplayID:
                desc = @"Native Display ID";
                break;
            case UnitField_MountDisplayID:
                desc = @"Mount Display ID";
                break;

            case UnitField_Bytes_1:
                desc = @"Unit Bytes 1";
                break;

            case UnitField_PetExperience:
                desc = @"Pet Experience";
                break;
            case UnitField_PetNextLevelExp:
                desc = @"Pet Next Level Experience";
                break;

            case UnitField_DynamicFlags:
                desc = @"Dynamic Flags";
                break;
            case UnitField_ModCastSpeed:
                desc = @"Cast Speed Modifier";
                break;
            case UnitField_UnitCreatedBySpell:
                desc = @"Created by Spell";
                break;
            case UnitField_NPCFlags:
                desc = @"NPC Flags";
                break;

            case UnitField_Bytes_2:
                desc = @"Unit Bytes 2";
                break;
        }
        
        /*
        int buffOffset, buffSlots, debuffOffset, debuffSlots;
        if([self isPlayer]) {
            buffOffset      = PLAYER_BUFFS_OFFSET;
            buffSlots       = PLAYER_BUFF_SLOTS;
            debuffOffset    = PLAYER_DEBUFFS_OFFSET;
            debuffSlots     = PLAYER_DEBUFF_SLOTS;
        } else {
            buffOffset      = MOB_BUFFS_OFFSET;
            buffSlots       = MOB_BUFF_SLOTS;
            debuffOffset    = MOB_DEBUFFS_OFFSET;
            debuffSlots     = MOB_DEBUFF_SLOTS;
        }

        // buffs
        if( (revOffset >= buffOffset) && (revOffset < debuffOffset) ) {
            UInt32 buff = 0;
            if([_memory loadDataForObject: self atAddress: ([self infoAddress] + revOffset) Buffer: (Byte*)&buff BufLength: sizeof(buff)] && buff) {
                NSString *name = nil;
                if( (name = [[[SpellController sharedSpells] spellForID: [NSNumber numberWithInt: buff]] name])) {
                    desc = [NSString stringWithFormat: @"[Buff] %@", name];
                } else {
                    desc = [NSString stringWithFormat: @"[Buff] %d", buff];
                }
            } else if(revOffset == buffOffset) {
                desc = [NSString stringWithFormat: @"Buffs Start (%d total)", buffSlots];
            }
        }
        
        // debuffs
        if(revOffset >= debuffOffset && revOffset < (debuffOffset + debuffSlots * 4)) {
            UInt32 buff = 0;
            if([_memory loadDataForObject: self atAddress: ([self infoAddress] + revOffset) Buffer: (Byte*)&buff BufLength: sizeof(buff)] && buff) {
                NSString *name = nil;
                if( (name = [[[SpellController sharedSpells] spellForID: [NSNumber numberWithInt: buff]] name])) {
                    desc = [NSString stringWithFormat: @"[Debuff] %@", name];
                } else {
                    desc = [NSString stringWithFormat: @"[Debuff] %d", buff];
                }
            } else if(revOffset == debuffOffset) {
                desc = [NSString stringWithFormat: @"Debuffs Start (%d total)", debuffSlots];
            }
        }*/
    }
    
    if(desc) return desc;
    
    return [super descriptionForOffset: offset];
}

@end
