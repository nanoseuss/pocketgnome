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
		_changed = NO;
		
		// create a new UUID
		self.UUID = [self generateUUID];
		//PGLog(@"created a NEW UUID %@", self.UUID);
	}
		
    return self;
}

@synthesize changed = _changed;
@synthesize UUID = _UUID;

- (id)initWithCoder:(NSCoder *)decoder{
	self = [super init];
	if ( self ) {
		self.UUID = [decoder decodeObjectForKey: @"UUID"];
		
		// create a new UUID?
		if ( !self.UUID || [self.UUID length] == 0 ){
			self.UUID = [self generateUUID];
			//PGLog(@"created a NEW UUID2 %@", self.UUID);
			_changed = YES;
		}
	}
	return self;
}

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

@end
