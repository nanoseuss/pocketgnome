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

@class Controller;
@class PlayerDataController;
@class MobController;
@class OffsetController;
@class MacroController;
@class BotController;

@interface QuestController : NSObject {
    IBOutlet Controller             *controller;
	IBOutlet BotController			*botController;
	IBOutlet PlayerDataController   *playerController;
	IBOutlet MobController			*mobController;
	IBOutlet OffsetController		*offsetController;
	IBOutlet MacroController		*macroController;
	
	NSMutableArray			*_playerQuests;
}

// Holds all of our quest info
- (NSArray*)playerQuests;

// This populates the playerQuests array with quest data
- (void)reloadPlayerQuests;

// This dumps the playerQuests array to PGLog
- (void)dumpQuests;

// ----- NPC Related -----

// available quests from the selected NPC
- (int)GetNumAvailableQuests;

// quests you already have with the quest giver
- (int)GetNumActiveQuests;

- (void)turnInAllQuests;

- (BOOL)getAvailableQuests;

- (BOOL)isQuestComplete: (int)index;

@end
