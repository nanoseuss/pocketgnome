//
//  SpellController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/20/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "SpellController.h"
#import "Controller.h"
#import "Offsets.h"
#import "Spell.h"
#import "PlayerDataController.h"

#pragma mark Note: LastSpellCast/Timer Disabled
#pragma mark -

@interface SpellController (Internal)
- (BOOL)isSpellListValid;
- (void)buildSpellMenu;
- (void)synchronizeSpells;

@end

@implementation SpellController

static SpellController *sharedSpells = nil;

+ (SpellController *)sharedSpells {
	if (sharedSpells == nil)
		sharedSpells = [[[self class] alloc] init];
	return sharedSpells;
}

- (id) init {
    self = [super init];
	if(sharedSpells) {
		[self release];
		self = sharedSpells;
	} else if(self != nil) {
        
		sharedSpells = self;
        
        //_knownSpells = [[NSMutableArray array] retain];
        _playerSpells = [[NSMutableArray array] retain];
        _cooldowns = [[NSMutableDictionary dictionary] retain];
    
        
        NSData *spellBook = [[NSUserDefaults standardUserDefaults] objectForKey: @"SpellBook"];
        if(spellBook) {
            _spellBook = [[NSKeyedUnarchiver unarchiveObjectWithData: spellBook] mutableCopy];
        } else
            _spellBook = [[NSMutableDictionary dictionary] retain];
        
        // populate known spells array
        //for(Spell *spell in [_spellBook allValues]) {
        //    [_knownSpells addObject: spell];
        //}
        
        // register notifications
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:) 
                                                     name: NSApplicationWillTerminateNotification 
                                                   object: nil];
                                                   
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsValid:) 
                                                     name: PlayerIsValidNotification 
                                                   object: nil];
        
        [NSBundle loadNibNamed: @"Spells" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = [self.view frame].size;
    
}

@synthesize view;
@synthesize selectedSpell;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Spells";
}

- (void)playerIsValid: (NSNotification*)notification {
    [self reloadPlayerSpells];
    
    int numLoaded = 0;
    for(Spell *spell in [self playerSpells]) {
        if( ![spell name] || ![[spell name] length] || [[spell name] isEqualToString: @"[Unknown]"]) {
            numLoaded++;
            [spell reloadSpellData];
        }
    }
    
    if(numLoaded > 0) {
        // PGLog(@"[Spells] Loading %d unknown spells from wowhead.", numLoaded);
    }
}


- (void)applicationWillTerminate: (NSNotification*)notification {
    [self synchronizeSpells];
}


#pragma mark -
#pragma mark Internal

- (BOOL)isSpellListValid {
    // check to see if our very first spell is 'Attack' (6603)
    // or for gnomes, 'Arcane Resistance' (20592)
    // blood elves: 'Arcane Affinity' (28877)
    // for everyone: 'Alchemy' (2259, 3101, 3464, 11611, 28596)
    uint32_t value = 0;
    if([[controller wowMemoryAccess] loadDataForObject: self atAddress: KNOWN_SPELLS_STATIC Buffer: (Byte *)&value BufLength: sizeof(value)] && value) {
        return ( (value > 0) && (value < 100000) );
        /*
        return (value == 6603 ||    // "Attack"
                value == 20592 ||   // "Arcane Resistance" (Gnomes)
                value == 28877 ||   // "Arcane Affinity" (Blood Elves)
                value == 2259 ||    // "Alchemy" (1)
                value == 3101 ||    // "Alchemy" (2)
                value == 3464 ||    // "Alchemy" (3)
                value == 11611 ||   // "Alchemy" (4)
                value == 28596 ||   // "Alchemy" (5)
                value == 674);      // "Ambidextrie" (French for Dual Wield)
        */
    }
    return NO;
}

- (void)synchronizeSpells {
    [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: _spellBook] forKey: @"SpellBook"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)reloadPlayerSpells {
    [_playerSpells removeAllObjects];
    MemoryAccess *memory = [controller wowMemoryAccess];
    if( !memory ) return;
    
    int i;
    uint32_t value = 0;

    // scan the list of known spells
    NSMutableArray *playerSpells = [NSMutableArray array];
    if( [playerController playerIsValid] && [self isSpellListValid] ) {
        for(i=0; ; i++) {
            // load all known spells into a temp array
            if([memory loadDataForObject: self atAddress: KNOWN_SPELLS_STATIC + (i*4) Buffer: (Byte *)&value BufLength: sizeof(value)] && value) {
                Spell *spell = [self spellForID: [NSNumber numberWithUnsignedInt: value]];
                if( !spell ) {
                    // create a new spell if necessary
                    spell = [Spell spellWithID: [NSNumber numberWithUnsignedInt: value]];
                    [self addSpellAsRecognized: spell];
                }
                [playerSpells addObject: spell];
            } else {
                break;
            }
        }
    }
    
    // update list of known spells
    [_playerSpells addObjectsFromArray: playerSpells];
    [self buildSpellMenu];
}

- (void)buildSpellMenu {
    
    NSMenu *spellMenu = [[[NSMenu alloc] initWithTitle: @"Spells"] autorelease];
    
    // load the player spells into arrays by spell school
    NSMutableDictionary *organizedSpells = [NSMutableDictionary dictionary];
    for(Spell *spell in _playerSpells) {
        if([spell school]) {
            if( ![organizedSpells objectForKey: [spell school]] )
                [organizedSpells setObject: [NSMutableArray array] forKey: [spell school]];
            [[organizedSpells objectForKey: [spell school]] addObject: spell];
        } else {
            if( ![organizedSpells objectForKey: @"Unknown"] )
                [organizedSpells setObject: [NSMutableArray array] forKey: @"Unknown"];
            [[organizedSpells objectForKey: @"Unknown"] addObject: spell];
        }
    }
    
    NSMenuItem *spellItem;
    NSSortDescriptor *nameDesc = [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease];
    for(NSString *key in [organizedSpells allKeys]) {
        // create menu header for spell school name
        spellItem = [[[NSMenuItem alloc] initWithTitle: key action: nil keyEquivalent: @""] autorelease];
        [spellItem setAttributedTitle: [[[NSAttributedString alloc] initWithString: key 
                                                                        attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 0], NSFontAttributeName, nil]] autorelease]];
        [spellItem setTag: 0];
        [spellMenu addItem: spellItem];
        
        // then, sort the array so its in alphabetical order
        NSMutableArray *schoolArray = [organizedSpells objectForKey: key];
        [schoolArray sortUsingDescriptors: [NSArray arrayWithObject: nameDesc]];
        
        // loop over the array and add in all the spells
        for(Spell *spell in schoolArray) {
            if( [spell name]) {
                spellItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ - %@", [spell fullName], [spell ID] ] action: nil keyEquivalent: @""];
            } else {
                spellItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@", [spell ID]] action: nil keyEquivalent: @""];
            }
            [spellItem setTag: [[spell ID] unsignedIntValue]];
            [spellItem setRepresentedObject: spell];
            [spellItem setIndentationLevel: 1];
            [spellMenu addItem: [spellItem autorelease]];
        }
        [spellMenu addItem: [NSMenuItem separatorItem]];
    }
    
    int tagToSelect = 0;
    if( [_playerSpells count] == 0) {
        //for(NSMenuItem *item in [spellMenu itemArray]) {
       //     [spellMenu removeItem: item];
        //}
        spellItem = [[NSMenuItem alloc] initWithTitle: @"There are no available spells." action: nil keyEquivalent: @""];
        [spellItem setTag: 0];
        [spellMenu addItem: [spellItem autorelease]];
    } else {
        tagToSelect = [[spellDropDown selectedItem] tag];
    }
    
    [spellDropDown setMenu: spellMenu];
    [spellDropDown selectItemWithTag: tagToSelect];
}

#pragma mark -

- (Spell*)spellForName: (NSString*)name {
    if(!name || ![name length]) return nil;
    // PGLog(@"Searching for spell \"%@\"", name);
    for(Spell *spell in [_spellBook allValues]) {
        if([spell name]) {
            NSRange range = [[spell name] rangeOfString: name 
                                                options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound)
                return spell;
        }
    }
    return nil;
}

- (Spell*)spellForID: (NSNumber*)spellID {
    return [_spellBook objectForKey: spellID];
}

- (Spell*)highestRankOfSpell: (Spell*)incSpell {
    if(!incSpell) return nil;
    
    Spell *highestRankSpell = incSpell;
    for(Spell *spell in [_spellBook allValues]) {
        // if the spell names match
        if([spell name] && [spell rank] && [[spell name] isEqualToString: [incSpell name]]) {
            // see which one has the higher rank
            if( [[spell rank] intValue] > [[highestRankSpell rank] intValue])
                highestRankSpell = spell;
        }
    }
    
    return highestRankSpell;
}

- (Spell*)playerSpellForName: (NSString*)spellName{
	if(!spellName) return nil;
    
    Spell *highestIDSpell = nil;
    for(Spell *spell in [self playerSpells]) {
        // if the spell names match
        if([spell name] && [[spell name] isEqualToString: spellName]) {
			return spell;
        }
    }
	
	return nil;	
}

- (BOOL)addSpellAsRecognized: (Spell*)spell {
    if(![spell ID]) return NO;
    if([[spell ID] unsignedIntValue] > 1000000) return NO;
    if( ![self spellForID: [spell ID]] ) {
        // PGLog(@"Adding spell %@ as recognized.", spell);
        [_spellBook setObject: spell forKey: [spell ID]];
        [self synchronizeSpells];
        return YES;
    }
    return NO;
}

#pragma mark -

- (void)didCastSpell: (Spell*)spell {
    [self didCastSpellWithID: [spell ID]];
}

- (void)didCastSpellWithID: (NSNumber*)spellID {
    Spell *spell = [self spellForID: spellID];
    if(spell && ([[spell cooldown] floatValue] > 0)) {
        // save the spell and the time in our cooldown dict
        PGLog(@"Starting %@ sec cooldown for %@.", [spell cooldown], spell);
        [_cooldowns setObject: [NSDate date] forKey: [spell ID]];
    }
}

- (BOOL)canCastSpellWithID: (NSNumber*)spellID {
    
    Spell *spell = [self spellForID: spellID];
    NSDate *castTime = [_cooldowns objectForKey: [spell ID]];
    if(spell && castTime && ([[spell cooldown] floatValue] > 0)) {
        NSDate *currentTime = [NSDate date];
        if( [currentTime timeIntervalSinceDate: castTime] > [[spell cooldown] floatValue]) {
            [_cooldowns removeObjectForKey: [spell ID]];
            //PGLog(@"Cooldown for %@ has expired %.2f > %.2f.", spell, [currentTime timeIntervalSinceDate: castTime], [[spell cooldown] floatValue]);
            return YES;
        } else {
            //PGLog(@"Cooldown NOT expired for %@ %.2f < %.2f.", spell, [currentTime timeIntervalSinceDate: castTime], [[spell cooldown] floatValue]);
            return NO;
        }
    }
    return YES;
}

#pragma mark -

- (BOOL)isPlayerSpell: (Spell*)aSpell {
    for(Spell *spell in [self playerSpells]) {
        if([spell isEqualToSpell: aSpell])
            return YES;
    }
    return NO;
}

- (NSArray*)playerSpells {
    return [[_playerSpells retain] autorelease];
}

- (NSMenu*)playerSpellsMenu {
    [self reloadPlayerSpells];
    return [[[spellDropDown menu] copy] autorelease];
}

- (UInt32)lastAttemptedActionID {
    UInt32 value = 0;
    [[controller wowMemoryAccess] loadDataForObject: self atAddress: LAST_SPELL_THAT_DIDNT_CAST_STATIC Buffer: (Byte*)&value BufLength: sizeof(value)];
    return value;
    
    // the following static variables we're both removed in WoW 3.0.2 :(
    //[[controller wowMemoryAccess] loadDataForObject: self atAddress: LAST_SPELL_ATTEMPTED_CAST_STATIC Buffer: (Byte*)&value BufLength: sizeof(value)];
    //[[controller wowMemoryAccess] loadDataForObject: self atAddress: LAST_SPELL_ACTUALLY_CAST_STATIC Buffer: (Byte*)&value2 BufLength: sizeof(value2)];
    //if(value == value2)     return value;   // they are the same
    //if(value && !value2)    return value;   // value2 is 0, value is good (no target, out of range)
    //if(!value && value2)    return value2;  // value is 0, value 2 is good
    //if(value && value2) {
    //    ;// PGLog(@"LastAttemptedActionID discrepancy: %d vs. %d", value, value2);
    //}
    //if(value != 6788)   // Weakened Soul
    //    return value;
    //return value2;
}

#pragma mark -
#pragma mark IBActions

- (IBAction)reloadMenu: (id)sender {
    [self reloadPlayerSpells];
}

- (IBAction)spellLoadAllData:(id)sender {
    
    // make sure our state is valid
    MemoryAccess *memory = [controller wowMemoryAccess];
    if( !memory || ![self isSpellListValid] )  {
        NSBeep();
        return;
    }

    [self reloadPlayerSpells];

    if([_playerSpells count]) {
        [spellLoadingProgress setHidden: NO];
        [spellLoadingProgress setMaxValue: [_playerSpells count]];
        [spellLoadingProgress setDoubleValue: 0];
        [spellLoadingProgress setUsesThreadedAnimation: YES];
    } else {
        return;
    }
    
    for(Spell *spell in _playerSpells) {
        [spell reloadSpellData];
        [spellLoadingProgress incrementBy: 1.0];
        [spellLoadingProgress displayIfNeeded];
    }
    
    // finish up
    [spellLoadingProgress setHidden: YES];
    [self synchronizeSpells];
    [self reloadPlayerSpells];
}

@end
