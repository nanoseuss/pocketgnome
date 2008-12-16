//
//  Rule.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"

/*typedef enum RuleResult {
    ResultNone      = 0,
    ResultSpell     = 1,
    ResultItem      = 2,
    ResultMacro     = 3,
    ResultSpecial   = 4,
} ResultType;*/

@interface Rule : NSObject <NSCoding, NSCopying> {
    BOOL _matchAll;
    NSString *_name;
    NSMutableArray *_conditionsList;
    
    Action *_action;
    
    //ResultType _resultType;
    //unsigned _actionID;
}

@property (readwrite, copy) NSString *name;
@property BOOL isMatchAll;
@property (readwrite, copy) Action *action;
//@property ResultType resultType;
//@property unsigned actionID;
@property (readwrite, retain) NSArray *conditions;

// play nice methods
@property (readonly) ActionType resultType;
@property (readonly) UInt32 actionID;

@end
