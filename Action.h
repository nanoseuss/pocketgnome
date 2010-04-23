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

typedef enum ActionType {
    ActionType_None				= 0,
    ActionType_Spell			= 1,
    ActionType_Item				= 2,
    ActionType_Macro			= 3,
    ActionType_Delay			= 4,
    ActionType_InteractNPC		= 5,
	ActionType_Jump				= 6,
	ActionType_SwitchRoute		= 7,
	ActionType_QuestTurnIn		= 8,
	ActionType_QuestGrab		= 9,
	ActionType_Vendor			= 10,
	ActionType_Mail				= 11,
	ActionType_Repair			= 12,
	ActionType_ReverseRoute		= 13,
	ActionType_CombatProfile	= 14,
    ActionType_InteractObject	= 15,
	ActionType_JumpToWaypoint	= 16,
    ActionType_Max,
} ActionType;

@class RouteSet;

@interface Action : NSObject <NSCoding, NSCopying>  {
    ActionType	_type;
    id			_value;
	BOOL        _enabled;
	BOOL		_useMaxRank;
}

- (id)initWithType: (ActionType)type value: (id)value;
+ (id)actionWithType: (ActionType)type value: (id)value;
+ (id)action;

@property (readwrite, assign) ActionType type;
@property (readwrite, copy) id value;
@property BOOL useMaxRank;

@property BOOL enabled;

// in order to play nice with old code
@property (readonly) float      delay;
@property (readonly) UInt32     actionID;

- (RouteSet*)route;

@end
