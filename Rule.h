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
#import "Action.h"

/*typedef enum RuleResult {
    ResultNone      = 0,
    ResultSpell     = 1,
    ResultItem      = 2,
    ResultMacro     = 3,
    ResultSpecial   = 4,
} ResultType;*/

typedef enum TargetType {
	TargetNone = 0,
	TargetSelf = 1,
	TargetEnemy = 2,
	TargetFriend = 3,	
	TargetAdd = 4,
	TargetPet = 5,
} TargetType;

@interface Rule : NSObject <NSCoding, NSCopying> {
    BOOL _matchAll;
    NSString *_name;
    NSMutableArray *_conditionsList;
    
    Action *_action;
	int _target;
    
    //ResultType _resultType;
    //unsigned _actionID;
}

@property (readwrite, copy) NSString *name;
@property BOOL isMatchAll;
@property (readwrite, copy) Action *action;
//@property ResultType resultType;
//@property unsigned actionID;
@property (readwrite, retain) NSArray *conditions;
@property (readwrite, assign) int target;

// play nice methods
@property (readonly) ActionType resultType;
@property (readonly) UInt32 actionID;

@end
