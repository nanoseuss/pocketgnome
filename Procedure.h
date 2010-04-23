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
#import "Rule.h"

@interface Procedure : NSObject <NSCoding, NSCopying> {
    NSString *_name;
    NSMutableArray *_rules;
}

+ (id)procedureWithName: (NSString*)name;

@property (readwrite, copy) NSString *name;
@property (readonly, retain) NSArray *rules;

- (unsigned)ruleCount;
- (Rule*)ruleAtIndex: (unsigned)index;

- (void)addRule: (Rule*)rule;
- (void)insertRule: (Rule*)rule atIndex: (unsigned)index;
- (void)replaceRuleAtIndex: (int)index withRule: (Rule*)rule;
- (void)removeRule: (Rule*)rule;
- (void)removeRuleAtIndex: (unsigned)index;

@end
