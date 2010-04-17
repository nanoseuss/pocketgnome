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

#import "Action.h"
#import "RouteSet.h"
#import "Route.h"
#import "Spell.h"
#import "SpellController.h"

@implementation Action

- (id) init
{
    return [self initWithType: ActionType_None value: nil];
}

- (id)initWithType: (ActionType)type value: (id)value {
    self = [super init];
    if (self != nil) {
        self.type = type;
        self.value = value;
		self.enabled = YES;
		self.useMaxRank = NO;
        //self.delay = delay;
        //self.actionID = actionID;
    }
    return self;
}

+ (id)actionWithType: (ActionType)type value: (id)value {
    return [[[[self class] alloc] initWithType: type value: value] autorelease];
}

+ (id)action {
    return [[self class] actionWithType: ActionType_None value: nil];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.type = [[decoder decodeObjectForKey: @"Type"] unsignedIntValue];
        self.value = ([decoder decodeObjectForKey: @"Value"] ? [decoder decodeObjectForKey: @"Value"] : nil);
		self.enabled = [decoder decodeObjectForKey: @"Enabled"] ? [[decoder decodeObjectForKey: @"Enabled"] boolValue] : YES;
		self.useMaxRank = [decoder decodeObjectForKey: @"UseMaxRank"] ? [[decoder decodeObjectForKey: @"UseMaxRank"] boolValue] : NO;
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: [NSNumber numberWithUnsignedInt: self.type]    forKey: @"Type"];
    if(self.type > ActionType_None){
        [coder encodeObject: self.value                                 forKey: @"Value"];
		[coder encodeObject: [NSNumber numberWithBool: self.enabled] forKey: @"Enabled"];
		[coder encodeObject: [NSNumber numberWithBool: self.useMaxRank] forKey: @"UseMaxRank"];
	}
}

- (id)copyWithZone:(NSZone *)zone
{
    Action *copy = [[[self class] allocWithZone: zone] initWithType: self.type value: self.value];
	
	copy.useMaxRank = self.useMaxRank;
    
    return copy;
}

- (void) dealloc
{
    self.value = nil;
    [super dealloc];
}


@synthesize type = _type;
@synthesize value = _value;
@synthesize enabled = _enabled;
@synthesize useMaxRank = _useMaxRank;

- (void)setType: (ActionType)type {
    if(type < ActionType_None || (type >= ActionType_Max)) {
        type = ActionType_None;
    }
    
    _type = type;
}

- (float)delay {
    if(self.type == ActionType_Delay) {
        return [self.value floatValue];
    }
    return 0.0f;
}

- (UInt32)actionID {
	
	if ( self.type == ActionType_Spell && self.useMaxRank ){
		Spell *highest = [[SpellController sharedSpells] highestRankOfSpellForPlayer:[[SpellController sharedSpells] spellForID:self.value]];
		if ( [self.value unsignedIntValue] != [[highest ID] unsignedIntValue] ){
			PGLog(@"[Action] Higher spell ID found! Using %d over %d", [[highest ID] unsignedIntValue], [self.value unsignedIntValue]);
			self.value = [[highest ID] copy];
		}
	}

    if(self.type == ActionType_Spell || self.type == ActionType_Item || self.type == ActionType_Macro) {
        return [self.value unsignedIntValue];
    }
    return 0;
}

- (RouteSet*)route{
	
	if ( self.type == ActionType_SwitchRoute ){
		return (RouteSet*)self.value;
	}
	
	return nil;
}

@end
