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

#import "Corpse.h"
#import "WoWObject.h"
#import "Position.h"

@implementation Corpse

+ (id)corpseWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory {
    return [[[Corpse alloc] initWithAddress: address inMemory: memory] autorelease];
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<%@: %d; Addr: %@, Parent: %d>",
            [self className],
            [self entryID], 
            [NSString stringWithFormat: @"0x%X", [self baseAddress]],
			[self parentLowGUID]];
}

- (UInt32)parentLowGUID{
	
	UInt32 value = 0;
    if([_memory loadDataForObject: self atAddress: ([self infoAddress] + CorpseField_OwnerGUID) Buffer: (Byte *)&value BufLength: sizeof(value)]) {
		return value;
	}
	
	return 0;
}

- (Position*)position{
	float pos[3] = {-1.0f, -1.0f, -1.0f };
    if([_memory loadDataForObject: self atAddress: ([self baseAddress] + CorpseField_XLocation) Buffer: (Byte *)&pos BufLength: sizeof(float)*3])
        return [Position positionWithX: pos[0] Y: pos[1] Z: pos[2]];
    return nil;
}

@end
