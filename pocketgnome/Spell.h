//
//  Spell.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/22/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MaxSpellID 1000000

@interface Spell : NSObject {
    NSNumber *_spellID;
    
    NSString *_name;
    NSNumber *_rank;
    NSNumber *_range;
    NSString *_dispelType;
    NSString *_school;
    NSNumber *_cooldown;
    NSNumber *_castTime;
    BOOL _spellDataLoading;
    
    NSURLConnection *_connection;
    NSMutableData *_downloadData;
}
+ (id)spellWithID: (NSNumber*)spellID;
- (BOOL)isEqualToSpell: (Spell*)spell;

- (NSNumber*)ID;
- (void)setID: (NSNumber*)ID;
- (NSString*)name;
- (void)setName: (NSString*)name;
- (NSNumber*)rank;
- (void)setRank: (NSNumber*)rank;
- (NSNumber*)range;
- (void)setRange: (NSNumber*)range;
- (NSNumber*)cooldown;
- (void)setCooldown: (NSNumber*)cooldown;
- (NSString*)school;
- (void)setSchool: (NSString*)school;
- (NSString*)dispelType;
- (void)setDispelType: (NSString*)dispelType;

@property (readwrite, retain) NSNumber *castTime;

- (BOOL)isInstant;

- (NSString*)fullName;

/*- (NSNumber*)ID;
- (NSString*)name;
- (NSNumber*)rank;
- (NSNumber*)range;
- (NSString*)school;
- (NSNumber*)cooldown; */

- (void)reloadSpellData;


@end
