//
//  WoWDb.m
//  Pocket Gnome
//
//  Created by Josh on 3/31/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "WoWDb.h"

#define ClientDb_RegisterBase	0x1863D0		// 3.3.3a

@implementation WoWDb

- (id) init{
    self = [super init];
    if ( self != nil ){
		
		_tables = [[NSMutableDictionary dictionary] retain];
		
		// add Spell DB for now
		//[_tables setObject:[NSNumber numberWithUnsignedInt:0xD2E300] forKey:[NSNumber numberWithUnsignedInt:0x194];
	
		// ideally I'd like to loop through this and read all of the table info, to be done later ;)
    }
    return self;
}

- (void)dealloc{
    [super dealloc];
}

@synthesize tables = _tables;

#pragma mark -



@end
