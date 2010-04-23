//
//  MPActivityApproach.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityApproach.h"
#import "MPTask.h"
#import	"Unit.h"
#import "MovementController.h"
#import "PlayerDataController.h"
#import "PatherController.h"
#import "Position.h"
#import "MPTimer.h"
#import "MPMover.h"


@implementation MPActivityApproach
@synthesize unit, mover, useMount;



- (id) initWithUnit: (Unit*)aUnit andDistance:(float)howClose andTask:(MPTask*)aTask  {
	
	if ((self = [super initWithName:@"Approach" andTask:aTask])) {
		self.unit = aUnit;
		distance = howClose;
		
		self.mover = [MPMover sharedMPMover];

	}
	return self;
}



- (void) dealloc
{
    [unit release];
	[mover release];

	
    [super dealloc];
}



#pragma mark -



- (void) start {

	[mover moveTowards:(MPLocation *)[unit position] within:distance facing:(MPLocation *)[unit position]];

}



// Make sure we are making progress towards the target.  Stop when in range.
- (BOOL) work {
	
//	return (![mover moveTowards:(MPLocation *)[unit position] within:distance facing:(MPLocation *)[unit position]]);
	
	// let's try cutting it off when within distance (and not worried about facing as well)
	[mover moveTowards:(MPLocation *)[unit position] within:distance facing:(MPLocation *)[unit position]];
	return ([task myDistanceToPosition:[unit position]] <= distance);

}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
	
	[mover stopAllMovement];
}



#pragma mark -



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (unit != nil) {
		
//		Position *playerPosition = [playerDataController position];
		float currentDistance = [task myDistanceToMob:(Mob *)unit];
	
		[text appendFormat:@"  approaching [%@]  [%0.2f / %0.2f]", [unit name], currentDistance, distance];
		
	} else {
		[text appendString:@"  no unit to approach"];
	}
	
	return text;
}



#pragma mark -



+ (id) approachUnit:(Unit*)aUnit withinDistance:(float) howClose forTask:(MPTask *)aTask {

	return [[[MPActivityApproach alloc] initWithUnit:aUnit andDistance:howClose andTask:aTask] autorelease];

}
@end
