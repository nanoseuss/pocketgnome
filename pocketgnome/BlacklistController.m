//
//  BlacklistController.m
//  Pocket Gnome
//
//  Created by Josh on 12/13/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "BlacklistController.h"

#import "WoWObject.h"
#import "Unit.h"

@interface BlacklistController (Internal)

@end

@implementation BlacklistController

- (id) init{
    self = [super init];
    if (self != nil) {
		_blacklist = [[NSMutableArray alloc] init];
		
    }
    return self;
}

- (void) dealloc{
	[_blacklist release];
    [super dealloc];
}

#pragma mark Blacklisting

// remove all instances of the object from the blacklist
- (void)removeFromBlacklist: (WoWObject*)obj {
    
    NSMutableArray *blRemove = [NSMutableArray array];
    for ( NSDictionary *black in _blacklist ) {
        if ( [[black objectForKey: @"Object"] isEqualToObject: obj] ){
            [blRemove addObject: black];
		}
    }
	
    [_blacklist removeObjectsInArray: blRemove];
}

// what is the blacklist count?
- (int)blacklistCount: (WoWObject*)obj {
	
	for ( NSDictionary *black in _blacklist ){
		if ( [black objectForKey: @"Object"] == obj ){
			return [[black objectForKey: @"Count"] intValue];
		}
	}
	
    return 0;
}

// simply add an object to our blacklist!
- (void)blacklistObject: (WoWObject*)obj{

	int blackCount = [self blacklistCount:obj];
	
	// new object, add it!
	if ( blackCount == 0) {
		PGLog(@"[Blacklist] Adding object %@", obj);
	}
	// object is already blacklisted! increase count
	else{
		PGLog(@"[Blacklist] Increasing count for object %@ to %d", obj, blackCount + 1);	
	}
	
	[self removeFromBlacklist:obj];
	
	// update our object in our dictionary
	blackCount++;
	[_blacklist addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
							obj,										@"Object",
							[NSDate date],								@"Date", 
							[NSNumber numberWithInt: blackCount],       @"Count", nil]];	
}

// remove old objects from the blacklist
- (void)refreshBlacklist{
	
	if ( [_blacklist count] ){
		
		for ( NSDictionary *black in _blacklist ){
			
			WoWObject *obj = [black objectForKey: @"Object"];
			
			float timeSinceBlacklisted = [[black objectForKey: @"Date"] timeIntervalSinceNow] * -1.0f;
			
			// time to remove our object if it's been 45 seconds
			if ( timeSinceBlacklisted > 45.0f ){
				[self removeFromBlacklist:obj];
				PGLog(@"[Blacklist] Removing object %@ from blacklist after 45 seconds", obj);
			}
			
			// mob/player checks
			if ( [obj isNPC] || [obj isPlayer] ){
				if ( ![obj isValid] || [(Unit*)obj isDead] ){
					[self removeFromBlacklist:obj];
					PGLog(@"[Blacklist] Removing object %@ from blacklist after 45 seconds for being dead(%d) or invalid(%d)", obj, [(Unit*)obj isDead], ![obj isValid]);
				}
			}
		}
	}
}

- (BOOL)isBlacklisted: (WoWObject*)obj {
	
	// refresh the blacklist (we could do this on a timer to be more "efficient"
	[self refreshBlacklist];
	
    int blackCount = [self blacklistCount: obj];
    if ( blackCount == 0 )  return NO;
    if ( blackCount >= 3 )  return YES;
    
    // check the time on the blacklist
	for ( NSDictionary *black in _blacklist ){
		WoWObject *blObj = [black objectForKey: @"Object"];
		
		if ( blObj == obj ){
			int count = [[black objectForKey: @"Count"] intValue];
			if ( count < 1 ) count = 1;
			
			PGLog(@"[Blacklist] %0.2f > %0.2f", [[black objectForKey: @"Date"] timeIntervalSinceNow]*-1.0, (15.0*count) );
			
			if ( [[black objectForKey: @"Date"] timeIntervalSinceNow]*-1.0 > (15.0*count) ) 
				return NO;
		}		
	}
    return YES;
}

- (void)removeAllUnits{
	PGLog(@"[Blacklist] Removing all units...");
}

@end
