//
//  MPCustomClass.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPCustomClass.h"
#import "Unit.h"
#import "PatherController.h"
#import "Mob.h"
#import "MobController.h"
#import "PlayerDataController.h"


@implementation MPCustomClass
@synthesize currentMob, patherController;

- (id) init {
	return [self initWithController:nil];
}

- (id) initWithController:(PatherController*)controller {
	if ((self = [super init])) {
		self.currentMob = nil;
		self.patherController = controller;
	}
	return self;
}

- (void) dealloc
{
    [patherController release];
	[currentMob autorelease];
	
    [super dealloc];
}

#pragma mark -

- (NSString *) name {
	return @"MPCustomClass -- Name Undefined";
}

// action to perform before attacking target
- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob {
	
	
}


// actions to kill your Target(s)
- (MPCombatState) killTarget: (Mob *) aTarget {
	// subclasses really need to do something here.
	return CombatStateInCombat;
}


// do what you need to do to rest up
- (BOOL) rest {
	return YES;  // done = [customClass rest];
}


// do your actions for buffing
- (void) runningAction {
	
	
	
}



- (void) setup {
	
	
}

#pragma mark -
#pragma mark Helper methods

- (NSArray *) mobsAttackingMe {
	
	NSMutableArray *list = [NSMutableArray array];
	UInt32 myGUID = [[PlayerDataController sharedController] lowGUID];
	NSArray *allMobs = [[MobController sharedController] allMobs];
	for (Mob *mob in allMobs) {
		
		if ([mob targetID] == myGUID) {
			[list addObject:mob];
		}
	}
	return list;
	
}


#pragma mark -

+ (id) classWithController: (PatherController *) controller {

	return [[[MPCustomClass alloc] initWithController:controller] autorelease];
}

@end
