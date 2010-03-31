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
#import "Position.h"
#import "Unit.h"


@interface Mob : Unit {
    UInt32  _stateFlags;
    
    NSString *_name;
    UInt32 _nameEntryID;
}
+ (id)mobWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

- (UInt32)experience;

- (void)select;
- (void)deselect;
- (BOOL)isSelected;

// npc type
- (BOOL)isVendor;
- (BOOL)canRepair;
- (BOOL)isFlightMaster;
- (BOOL)canGossip;
- (BOOL)isTrainer;
- (BOOL)isYourClassTrainer;
- (BOOL)isYourProfessionTrainer;
- (BOOL)isQuestGiver;
- (BOOL)isStableMaster;
- (BOOL)isBanker;
- (BOOL)isAuctioneer;
- (BOOL)isInnkeeper;
- (BOOL)isFoodDrinkVendor;
- (BOOL)isReagentVendor;
- (BOOL)isSpiritHealer;
- (BOOL)isBattlemaster;

// status
- (BOOL)isTapped;
- (BOOL)isTappedByMe;
- (BOOL)isTappedByOther;
- (BOOL)isBeingTracked;


@end
