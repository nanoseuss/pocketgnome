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
- (void) castBuffs {

}



#pragma mark -

+ (id) classWithController: (PatherController *) controller {

	return [[[MPCustomClass alloc] initWithController:controller] autorelease];
}

@end
