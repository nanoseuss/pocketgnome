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

#import "ChatAction.h"


@implementation ChatAction

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.name = nil;
        self.predicate = nil;
        self.emailAddress = nil;
        self.imName = nil;
    }
    return self;
}

- (void) dealloc
{
    self.name = nil;
    self.predicate = nil;
    self.emailAddress = nil;
    self.imName = nil;
    [super dealloc];
}

+ (ChatAction*)chatActionWithName: (NSString*)name {
    ChatAction *newAction = [[ChatAction alloc] init];
    newAction.name = name;
    return [newAction autorelease];
}

- (id)copyWithZone: (NSZone*)zone {
    ChatAction *newAction = [[ChatAction alloc] init];
    newAction.name = self.name;
    newAction.predicate = self.predicate;
    newAction.actionStopBot = self.actionStopBot;
    newAction.actionStartBot = self.actionStartBot;
    newAction.actionHearth = self.actionHearth;
    newAction.actionQuit = self.actionQuit;
    newAction.actionEmail = self.actionEmail;
    newAction.actionIM = self.actionIM;
    newAction.emailAddress = self.emailAddress;
    newAction.imName = self.imName;
    return newAction;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        self.name = [decoder decodeObjectForKey: @"Name"];
        self.predicate = [decoder decodeObjectForKey: @"Predicate"];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: self.predicate forKey: @"Predicate"];
}


@synthesize name = _name;
@synthesize predicate = _predicate;
@synthesize actionStopBot = _actionStopBot;
@synthesize actionHearth = _actionHearth;
@synthesize actionQuit = _actionQuit;
@synthesize actionStartBot = _actionStartBot;
@synthesize actionEmail = _actionEmail;
@synthesize actionIM = _actionIM;

@synthesize emailAddress = _emailAddress;
@synthesize imName = _imName;


@end
