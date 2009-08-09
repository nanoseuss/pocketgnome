//
//  Behavior.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Procedure.h"

#define PreCombatProcedure  @"PreCombatProcedure"
#define HealingProcedure    @"HealingProcedure"
#define CombatProcedure     @"CombatProcedure"
#define PostCombatProcedure @"PostCombatProcedure"
#define RegenProcedure      @"RegenProcedure"
#define PatrollingProcedure @"PatrollingProcedure"

@interface Behavior : NSObject <NSCoding, NSCopying> {
    NSString *_name;
    BOOL _meleeCombat, _usePet;
    NSMutableDictionary *_procedures;
}

+ (id)behaviorWithName: (NSString*)name;

@property (readwrite, copy) NSString *name;
@property (readonly, retain) NSDictionary *procedures;
@property BOOL meleeCombat;
@property BOOL usePet;

- (Procedure*)procedureForKey: (NSString*)key;

@end
