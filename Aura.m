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

#import "Aura.h"

@implementation Aura

+ (id)auraEntryID: (UInt32)entryID GUID: (GUID)guid bytes: (UInt32)bytes duration: (UInt32)duration expiration: (UInt32)expiration {
    Aura *aura = [[Aura alloc] init];
    if(aura) {
        aura.guid = guid;
        aura.entryID = entryID;
        aura.bytes = bytes;
        aura.duration = duration;
        aura.expiration = expiration;
    }
    return [aura autorelease];
}

- (void) dealloc
{
    [super dealloc];
}


@synthesize guid;
@synthesize entryID;
@synthesize bytes;
@synthesize duration;
@synthesize expiration;

- (UInt32)stacks {
    return (([self bytes] >> 16) & 0xFF);
}

- (UInt32)level {
    return (([self bytes] >> 8) & 0xFF);
}

- (BOOL)isDebuff {
    return (([self bytes] >> 7) & 1);
}

- (BOOL)isActive {
     return (([self bytes] >> 5) & 1);
}

- (BOOL)isPassive {
    return (([self bytes] >> 4) & 1) && ![self isActive];
}

- (BOOL)isHidden {
    return (([self bytes] >> 7) & 1);
}
@end