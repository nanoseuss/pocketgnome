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

@class Unit;
@class PlayerDataController;

#define BuffGainNotification @"BuffGainNotification"
#define BuffFadeNotification @"BuffFadeNotification"

#define DispelTypeMagic     @"Magic"
#define DispelTypeCurse     @"Curse"
#define DispelTypePoison    @"Poison"
#define DispelTypeDisease   @"Disease"

@interface AuraController : NSObject {
    IBOutlet id controller;
    IBOutlet PlayerDataController *playerController;
    IBOutlet id spellController;
    IBOutlet id mobController;

    BOOL _firstRun;
    NSMutableArray *_auras;
    
    IBOutlet NSPanel *aurasPanel;
    IBOutlet NSTableView *aurasPanelTable;
    NSMutableArray *_playerAuras;
}
+ (AuraController *)sharedController;

- (void)showAurasPanel;

// IDs: NO - returns an array of Auras
// IDs: YES - returns an array of NSNumbers (spell ID)
- (NSArray*)aurasForUnit: (Unit*)unit idsOnly: (BOOL)IDs;

// hasAura & hasAuraNamed functions return the stack count of the spell (even though it says BOOL)
// auraType functions only return a BOOL
- (BOOL)unit: (Unit*)unit hasAura: (unsigned)spellID;
- (BOOL)unit: (Unit*)unit hasAuraNamed: (NSString*)spellName;
- (BOOL)unit: (Unit*)unit hasAuraType: (NSString*)spellName;

// return stack count
- (BOOL)unit: (Unit*)unit hasDebuff: (unsigned)spellID;
- (BOOL)unit: (Unit*)unit hasBuff: (unsigned)spellID;

// return stack count
- (BOOL)unit: (Unit*)unit hasDebuffNamed: (NSString*)spellName;
- (BOOL)unit: (Unit*)unit hasBuffNamed: (NSString*)spellName;

- (BOOL)unit: (Unit*)unit hasBuffType: (NSString*)type;
- (BOOL)unit: (Unit*)unit hasDebuffType: (NSString*)type;

//- (BOOL)playerHasBuffNamed: (NSString*)spellName;

//- (BOOL)unit: (Unit*)unit hasBuff: (unsigned)spellID;
//- (BOOL)unit: (Unit*)unit hasDebuff: (unsigned)spellID;

//- (BOOL)unit: (Unit*)unit hasBuffNamed: (NSString*)spellName;
//- (BOOL)unit: (Unit*)unit hasDebuffNamed: (NSString*)spellName;

//- (BOOL)unit: (Unit*)unit hasBuffType: (NSString*)type;
//- (BOOL)unit: (Unit*)unit hasDebuffType: (NSString*)type;

@end
