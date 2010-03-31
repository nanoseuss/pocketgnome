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

#import "Condition.h"


@implementation Condition

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.variety    = 0;
        self.unit       = 0;
        self.quality    = 0;
        self.comparator = 0;
        self.state      = 0;
        self.type       = 0;
        self.value      = nil;
    }
    return self;
}

- (id)initWithVariety: (int)variety unit: (int)unit quality: (int)quality comparator: (int)comparator state: (int)state type: (int)type value: (id)value {
    [self init];
    if(self) {
        self.variety    = variety;
        self.unit       = unit;
        self.quality    = quality;
        self.comparator = comparator;
        self.state      = state;
        self.type       = type;
        self.value      = value;
    }
    return self;
}

+ (id)conditionWithVariety: (int)variety unit: (int)unit quality: (int)quality comparator: (int)comparator state: (int)state type: (int)type value: (id)value {
    return [[[Condition alloc] initWithVariety: variety 
                                          unit: unit 
                                       quality: quality 
                                    comparator: comparator 
                                         state: state 
                                          type: type 
                                         value: value] autorelease];                      
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        self.variety    = [[decoder decodeObjectForKey: @"Variety"] intValue];
        self.unit       = [[decoder decodeObjectForKey: @"Unit"] intValue];
        self.quality    = [[decoder decodeObjectForKey: @"Quality"] intValue];
        self.comparator = [[decoder decodeObjectForKey: @"Comparator"] intValue];
        self.state      = [[decoder decodeObjectForKey: @"State"] intValue];
        self.type       = [[decoder decodeObjectForKey: @"Type"] intValue];
        self.value      = [decoder decodeObjectForKey: @"Value"];
        
        self.enabled = [decoder decodeObjectForKey: @"Enabled"] ? [[decoder decodeObjectForKey: @"Enabled"] boolValue] : YES;
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: [NSNumber numberWithInt: [self variety]] forKey: @"Variety"];
    [coder encodeObject: [NSNumber numberWithInt: [self unit]] forKey: @"Unit"];
    [coder encodeObject: [NSNumber numberWithInt: [self quality]] forKey: @"Quality"];
    [coder encodeObject: [NSNumber numberWithInt: [self comparator]] forKey: @"Comparator"];
    [coder encodeObject: [NSNumber numberWithInt: [self state]] forKey: @"State"];
    [coder encodeObject: [NSNumber numberWithInt: [self type]] forKey: @"Type"];
    [coder encodeObject: [self value] forKey: @"Value"];
    [coder encodeObject: [NSNumber numberWithBool: self.enabled] forKey: @"Enabled"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Condition *copy = [[[self class] allocWithZone: zone] initWithVariety: [self variety] 
                                                                     unit: [self unit]
                                                                  quality: [self quality]
                                                               comparator: [self comparator]
                                                                    state: [self state]
                                                                     type: [self type] 
                                                                    value: [self value]];
    [copy setEnabled: [self enabled]];
        
    return copy;
}

- (void) dealloc
{
    [_value release];
    [super dealloc];
}

@synthesize variety = _variety;
@synthesize unit = _unit;
@synthesize quality = _quality;
@synthesize comparator = _comparator;
@synthesize state = _state;
@synthesize type = _type;

@synthesize value = _value;
@synthesize enabled = _enabled;

- (NSString*)description {
    return [NSString stringWithFormat: @"<Condition Variety: %d, Unit: %d, Qual: %d, Comp: %d, State: %d, Type: %d, Val: %@", _variety, _unit, _quality, _comparator, _state, _type, _value];
}


@end
