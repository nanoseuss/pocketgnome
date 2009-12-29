//
//  IgnoreProfile.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/19/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "CombatProfile.h"
#import "Unit.h"
#import "Mob.h"
#import "IgnoreEntry.h"
#import "Offsets.h"

#import "PlayerDataController.h"


@implementation CombatProfile

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.name = nil;
        self.entries = [NSArray array];
        self.combatEnabled = YES;
        self.onlyRespond = NO;
        self.attackNeutralNPCs = YES;
        self.attackHostileNPCs = YES;
        self.attackPlayers = NO;
        self.attackPets = NO;
        self.attackAnyLevel = YES;
        self.ignoreElite = YES;
        self.ignoreLevelOne = YES;
		self.ignoreFlying = YES;
		self.onlyHealInCombat = NO;
		
		// Healing
		self.healingEnabled = NO;
		self.autoFollowTarget = NO;
		self.yardsBehindTarget = 10.0f;
		self.healingRange = 40.0f;
		self.mountEnabled = NO;
		self.selectedTankGUID = 0x0;
		self.healthThreshold = 95;

        self.attackRange = 20.0f;
		self.engageRange = 30.0f;
        self.attackLevelMin = 2;
        self.attackLevelMax = PLAYER_LEVEL_CAP;
    }
	PGLog(@"CombatProfile created with name %@", self.name);
    return self;
}

- (id)initWithName: (NSString*)name {
    self = [self init];
    if (self != nil) {
        self.name = name;
    }
    return self;
}

+ (id)combatProfile {
    return [[[CombatProfile alloc] init] autorelease];
}

+ (id)combatProfileWithName: (NSString*)name {
    return [[[CombatProfile alloc] initWithName: name] autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
    CombatProfile *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
    
    copy.entries = self.entries;
    copy.combatEnabled = self.combatEnabled;
    copy.onlyRespond = self.onlyRespond;
    copy.attackNeutralNPCs = self.attackNeutralNPCs;
    copy.attackHostileNPCs = self.attackHostileNPCs;
    copy.attackPlayers = self.attackPlayers;
    copy.attackPets = self.attackPets;
    copy.attackAnyLevel = self.attackAnyLevel;
    copy.ignoreElite = self.ignoreElite;
    copy.ignoreLevelOne = self.ignoreLevelOne;
	copy.ignoreFlying = self.ignoreFlying;
	copy.onlyHealInCombat = self.onlyHealInCombat;
	
	copy.healingEnabled = self.healingEnabled;
    copy.autoFollowTarget = self.autoFollowTarget;
    copy.yardsBehindTarget = self.yardsBehindTarget;
	copy.healingRange = self.healingRange;
	copy.mountEnabled = self.mountEnabled;
	copy.selectedTankGUID = self.selectedTankGUID;
	copy.healthThreshold = self.healthThreshold;
	
    copy.attackRange = self.attackRange;
	copy.engageRange = self.engageRange;
    copy.attackLevelMin = self.attackLevelMin;
    copy.attackLevelMax = self.attackLevelMax;
    
    return copy;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        self.entries = [decoder decodeObjectForKey: @"IgnoreList"] ? [decoder decodeObjectForKey: @"IgnoreList"] : [NSArray array];

        self.name = [decoder decodeObjectForKey: @"Name"];
        self.combatEnabled = [[decoder decodeObjectForKey: @"CombatEnabled"] boolValue];
        self.onlyRespond = [[decoder decodeObjectForKey: @"OnlyRespond"] boolValue];
        self.attackNeutralNPCs = [[decoder decodeObjectForKey: @"AttackNeutralNPCs"] boolValue];
        self.attackHostileNPCs = [[decoder decodeObjectForKey: @"AttackHostileNPCs"] boolValue];
        self.attackPlayers = [[decoder decodeObjectForKey: @"AttackPlayers"] boolValue];
        self.attackPets = [[decoder decodeObjectForKey: @"AttackPets"] boolValue];
        self.attackAnyLevel = [[decoder decodeObjectForKey: @"AttackAnyLevel"] boolValue];
        self.ignoreElite = [[decoder decodeObjectForKey: @"IgnoreElite"] boolValue];
        self.ignoreLevelOne = [[decoder decodeObjectForKey: @"IgnoreLevelOne"] boolValue];
		self.ignoreFlying = [[decoder decodeObjectForKey: @"IgnoreFlying"] boolValue];
		self.onlyHealInCombat = [[decoder decodeObjectForKey: @"OnlyHealInCombat"] boolValue];

		self.healingEnabled = [[decoder decodeObjectForKey: @"HealingEnabled"] boolValue];
        self.autoFollowTarget = [[decoder decodeObjectForKey: @"AutoFollowTarget"] boolValue];
		self.yardsBehindTarget = [[decoder decodeObjectForKey: @"YardsBehindTarget"] floatValue];
		self.healingRange = [[decoder decodeObjectForKey: @"HealingRange"] floatValue];
		self.mountEnabled = [[decoder decodeObjectForKey: @"MountEnabled"] boolValue];
		self.selectedTankGUID = [[decoder decodeObjectForKey: @"selectedTankGUID"] unsignedLongLongValue];
		self.healthThreshold = [[decoder decodeObjectForKey: @"HealthThreshold"] intValue];
		
		self.engageRange = [[decoder decodeObjectForKey: @"EngageRange"] floatValue];
        self.attackRange = [[decoder decodeObjectForKey: @"AttackRange"] floatValue];
        self.attackLevelMin = [[decoder decodeObjectForKey: @"AttackLevelMin"] intValue];
        self.attackLevelMax = [[decoder decodeObjectForKey: @"AttackLevelMax"] intValue];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: [NSNumber numberWithBool: self.combatEnabled] forKey: @"CombatEnabled"];
    [coder encodeObject: [NSNumber numberWithBool: self.onlyRespond] forKey: @"OnlyRespond"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackNeutralNPCs] forKey: @"AttackNeutralNPCs"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackHostileNPCs] forKey: @"AttackHostileNPCs"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackPlayers] forKey: @"AttackPlayers"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackPets] forKey: @"AttackPets"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackAnyLevel] forKey: @"AttackAnyLevel"];
    [coder encodeObject: [NSNumber numberWithBool: self.ignoreElite] forKey: @"IgnoreElite"];
    [coder encodeObject: [NSNumber numberWithBool: self.ignoreLevelOne] forKey: @"IgnoreLevelOne"];
	[coder encodeObject: [NSNumber numberWithBool: self.ignoreFlying] forKey: @"IgnoreFlying"];
	[coder encodeObject: [NSNumber numberWithBool: self.onlyHealInCombat] forKey: @"OnlyHealInCombat"];
	
	[coder encodeObject: [NSNumber numberWithBool: self.healingEnabled] forKey: @"HealingEnabled"];
    [coder encodeObject: [NSNumber numberWithBool: self.autoFollowTarget] forKey: @"AutoFollowTarget"];
    [coder encodeObject: [NSNumber numberWithFloat: self.yardsBehindTarget] forKey: @"YardsBehindTarget"];
	[coder encodeObject: [NSNumber numberWithFloat: self.healingRange] forKey: @"HealingRange"];
	[coder encodeObject: [NSNumber numberWithBool: self.mountEnabled] forKey: @"MountEnabled"];
	[coder encodeObject: [NSNumber numberWithUnsignedLongLong: self.selectedTankGUID]forKey: @"selectedTankGUID"];
	[coder encodeObject: [NSNumber numberWithInt: self.healthThreshold] forKey: @"HealthThreshold"];
	
	[coder encodeObject: [NSNumber numberWithFloat: self.engageRange] forKey: @"EngageRange"];
    [coder encodeObject: [NSNumber numberWithFloat: self.attackRange] forKey: @"AttackRange"];
    [coder encodeObject: [NSNumber numberWithInt: self.attackLevelMin] forKey: @"AttackLevelMin"];
    [coder encodeObject: [NSNumber numberWithInt: self.attackLevelMax] forKey: @"AttackLevelMax"];

    [coder encodeObject: self.entries forKey: @"IgnoreList"];
}

- (void) dealloc
{
    self.name = nil;
    self.entries = nil;
    [super dealloc];
}

@synthesize name = _name;
@synthesize entries = _combatEntries;
@synthesize combatEnabled;
@synthesize onlyRespond;
@synthesize attackNeutralNPCs;
@synthesize attackHostileNPCs;
@synthesize attackPlayers;
@synthesize attackPets;
@synthesize attackAnyLevel;
@synthesize ignoreElite;
@synthesize ignoreLevelOne;
@synthesize ignoreFlying;
@synthesize onlyHealInCombat;

@synthesize healingEnabled;
@synthesize autoFollowTarget;
@synthesize yardsBehindTarget;
@synthesize healingRange;
@synthesize mountEnabled;
@synthesize selectedTankGUID;
@synthesize healthThreshold;

@synthesize engageRange;
@synthesize attackRange;
@synthesize attackLevelMin;
@synthesize attackLevelMax;

- (BOOL)unitShouldBeIgnored: (Unit*)unit{
	
	// check our internal blacklist
    for ( IgnoreEntry *entry in [self entries] ) {
        if( [entry type] == IgnoreType_EntryID) {
            if( [[entry ignoreValue] intValue] == [unit entryID])
                return YES;
        }
        if( [entry type] == IgnoreType_Name) {
            if(![entry ignoreValue] || ![[entry ignoreValue] length] || ![unit name])
                continue;
			
            NSRange range = [[unit name] rangeOfString: [entry ignoreValue] 
                                               options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound) {
                return YES;
            }
        }
    }
	
	return NO;
}

- (void)setEntries: (NSArray*)newEntries {
    [self willChangeValueForKey: @"entries"];
    [_combatEntries autorelease];
    if(newEntries) {
        _combatEntries = [[NSMutableArray alloc] initWithArray: newEntries copyItems: YES];
    } else {
        _combatEntries = nil;
    }
    [self didChangeValueForKey: @"entries"];
}

- (unsigned)entryCount {
    return [self.entries count];
}

- (IgnoreEntry*)entryAtIndex: (unsigned)index {
    if(index >= 0 && index < [self entryCount])
        return [[[_combatEntries objectAtIndex: index] retain] autorelease];
    return nil;
}

- (void)addEntry: (IgnoreEntry*)entry {
    if(entry != nil)
        [_combatEntries addObject: entry];
}

- (void)removeEntry: (IgnoreEntry*)entry {
    if(entry == nil) return;
    [_combatEntries removeObject: entry];
}

- (void)removeEntryAtIndex: (unsigned)index; {
    if(index >= 0 && index < [self entryCount])
        [_combatEntries removeObjectAtIndex: index];
}

@end
