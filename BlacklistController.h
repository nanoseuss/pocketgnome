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

// created a controller for this, as I don't want to implement the exact same versions for Combat and for nodes

@class WoWObject;

@class MobController;
@class PlayersController;

@interface BlacklistController : NSObject {
	
	IBOutlet MobController		*mobController;
	IBOutlet PlayersController	*playersController;
	

	NSMutableDictionary *_blacklist;
	NSMutableDictionary *_attemptList;

}

// reasons to be blacklisted!
enum{
	Reason_None					= 0,
	Reason_NotInLoS				= 1,
	Reason_NodeMadeMeFall		= 2,
	Reason_CantReachObject		= 4,
	Reason_NotInCombatAfter10	= 8,
	
};

- (void)blacklistObject:(WoWObject *)obj withReason:(int)reason;
- (void)blacklistObject: (WoWObject*)obj;
- (BOOL)isBlacklisted: (WoWObject*)obj;
- (void)removeAllUnits;

// sick of putting more dictionaries in bot controller, will just use this
- (int)attemptsForObject:(WoWObject*)obj;
- (void)incrementAttemptForObject:(WoWObject*)obj;
- (void)clearAttemptsForObject:(WoWObject*)obj;
- (void)clearAttempts;

- (void)clearAll;

@end
