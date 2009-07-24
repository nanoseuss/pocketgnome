//
//  Action.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 9/6/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum ActionType {
    ActionType_None     = 0,
    ActionType_Spell    = 1,
    ActionType_Item     = 2,
    ActionType_Macro    = 3,
    ActionType_Delay    = 4,
    ActionType_Interact = 5,
    ActionType_Max,
} ActionType;

@interface Action : NSObject <NSCoding, NSCopying>  {
    ActionType _type;
    NSNumber *_value;
}

- (id)initWithType: (ActionType)type value: (NSNumber*)value;
+ (id)actionWithType: (ActionType)type value: (NSNumber*)value;
+ (id)action;

@property (readwrite, assign) ActionType type;
@property (readwrite, copy) NSNumber *value;

@property (readonly) BOOL       isPerform;

// in order to play nice with old code
@property (readonly) float      delay;
@property (readonly) UInt32     actionID;

@end
