//
//  SaveDataObject.m
//  Pocket Gnome
//
//  Created by Josh on 1/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

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
		
		PGLog(@" %@ new", self);
		
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
