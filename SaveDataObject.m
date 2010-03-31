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

#import "SaveDataObject.h"

@interface SaveDataObject ()
@property (readwrite, retain) NSString *UUID;

- (NSString*)generateUUID;
@end

@implementation SaveDataObject

- (id) init{
    self = [super init];
    if (self != nil) {
		self.changed = NO;
		
		// create a new UUID
		self.UUID = [self generateUUID];
		
		// start observing! (so we can detect changes)
		[self performSelector:@selector(addObservers) withObject:nil afterDelay:1.0f];
	}
		
    return self;
}

@synthesize changed = _changed;
@synthesize UUID = _UUID;

// called when loading from disk!
- (id)initWithCoder:(NSCoder *)decoder{
	self = [super init];
	if ( self ) {
		self.UUID = [decoder decodeObjectForKey: @"UUID"];
		
		// create a new UUID?
		if ( !self.UUID || [self.UUID length] == 0 ){
			self.UUID = [self generateUUID];
			self.changed = YES;
		}
	}
	
	return self;
}

// called when we're saving a file
- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeObject: self.UUID forKey: @"UUID"];
}

- (id)copyWithZone:(NSZone *)zone{
	return nil;
}

- (NSString*)generateUUID{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *uuid = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	
	return [uuid retain];
}

- (void)setChanged:(BOOL)val{
	//PGLog(@"[Changed] Set from %d to %d for %@", _changed, val, self);
	_changed = val;
}

// Observations (to detect when an object changes)

- (void)addObservers{
	
}

@end
