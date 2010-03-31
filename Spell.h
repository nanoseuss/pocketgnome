/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import <Cocoa/Cocoa.h>

#define MaxSpellID 1000000

enum mountType {
    MOUNT_NONE       = 0,
    MOUNT_GROUND     = 1,
    MOUNT_AIR        = 2
};

@interface Spell : NSObject {
    NSNumber *_spellID;
    
    NSString *_name;
    NSNumber *_rank;
    NSNumber *_range;
    NSString *_dispelType;
    NSString *_school;
	NSString *_mechanic;
    NSNumber *_cooldown;
    NSNumber *_castTime;
	NSNumber *_speed;		// speed of mount
	NSNumber *_mount;		// 0 = no mount, 1 = ground mount, 2 = air mount
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
- (NSString*)mechanic;
- (void)setMechanic: (NSString*)mechanic;
- (NSString*)dispelType;
- (void)setDispelType: (NSString*)dispelType;
- (NSNumber*)mount;
- (void)setMount: (NSNumber*)mount;
- (NSNumber*)speed;
- (void)setSpeed: (NSNumber*)speed;

@property (readwrite, retain) NSNumber *castTime;

- (BOOL)isInstant;
- (BOOL)isMount;

- (NSString*)fullName;

/*- (NSNumber*)ID;
- (NSString*)name;
- (NSNumber*)rank;
- (NSNumber*)range;
- (NSString*)school;
- (NSNumber*)cooldown; */

- (void)reloadSpellData;


@end
