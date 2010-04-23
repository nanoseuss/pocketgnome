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

#import "Procedure.h"

@interface Procedure ()
@property (readwrite, retain) NSArray *rules;
@end

@implementation Procedure

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.name = nil;
        self.rules = [NSArray array];
    }
    return self;
}

- (id)initWithName: (NSString*)name {
    self = [self init];
    if (self != nil) {
        self.name = name;
    }
    return self;
}

+ (id)procedureWithName: (NSString*)name {
    return [[[[self class] alloc] initWithName: name] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        self.rules = [decoder decodeObjectForKey: @"Rules"] ? [decoder decodeObjectForKey: @"Rules"] : [NSArray array];
        self.name = [decoder decodeObjectForKey: @"Name"];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: self.rules forKey: @"Rules"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Procedure *copy = [[[self class] allocWithZone: zone] initWithName: self.name];

    copy.rules = self.rules;
            
    return copy;
}

- (void) dealloc {
    self.name = nil;
    self.rules = nil;
    [super dealloc];
}

#pragma mark -

- (NSString*)description {
    return [NSString stringWithFormat: @"<Procedure %@: %d rules>", [self name], [self ruleCount]];
}

@synthesize name = _name;
@synthesize rules = _rules;

- (void)setRules: (NSArray*)rules {
    [_rules autorelease];
    if(rules) {
        _rules = [[NSMutableArray alloc] initWithArray: rules copyItems: YES];
    } else {
        _rules = nil;
    }
}

- (unsigned)ruleCount {
    return [self.rules count];
}

- (Rule*)ruleAtIndex: (unsigned)index {
    if(index >= 0 && index < [self ruleCount])
        return [[[_rules objectAtIndex: index] retain] autorelease];
    return nil;
}

- (void)addRule: (Rule*)rule {
    if(rule != nil)
        [_rules addObject: rule];
    else
        PGLog(@"addRule: failed; rule is nil");
}

- (void)insertRule: (Rule*)rule atIndex: (unsigned)index {
    if(rule != nil && index >= 0 && index <= [_rules count])
        [_rules insertObject: rule atIndex: index];
    else
        PGLog(@"insertRule:atIndex: failed; rule %@ index %d is out of bounds", rule, index);
}

- (void)replaceRuleAtIndex: (int)index withRule: (Rule*)rule {

    if((rule != nil) && (index >= 0) && (index < [self ruleCount])) {
        [_rules replaceObjectAtIndex: index withObject: rule];
    }else
        PGLog(@"replaceRule:atIndex: failed; either rule is nil or index is out of bounds");
}

- (void)removeRule: (Rule*)rule {
    if(rule == nil) return;
    [_rules removeObject: rule];
}

- (void)removeRuleAtIndex: (unsigned)index {
    if(index >= 0 && index < [self ruleCount])
        [_rules removeObjectAtIndex: index];
}

@end
