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


@interface Aura : NSObject {
    GUID  guid;
    UInt32  entryID;        // spell ID
    UInt32  bytes;          // [8 unk ] [8 stack count ] [8 unk ] [8 unk ]
    UInt32  duration;       // milliseconds
    UInt32  expiration;     // game time
}

+ (id)auraEntryID: (UInt32)entryID GUID: (GUID)guid bytes: (UInt32)bytes duration: (UInt32)duration expiration: (UInt32)expiration;

@property (readwrite, assign) GUID guid;
@property (readwrite, assign) UInt32 entryID;
@property (readwrite, assign) UInt32 bytes;
@property (readonly) UInt32 stacks;
@property (readonly) UInt32 level;
@property (readonly) BOOL isDebuff;
@property (readonly) BOOL isActive;
@property (readonly) BOOL isPassive;
@property (readwrite, assign) UInt32 duration;
@property (readwrite, assign) UInt32 expiration;

@end
