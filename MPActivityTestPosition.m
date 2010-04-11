//
//  MPActivityTestPosition.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/9/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPActivityTestPosition.h"
#import "MPActivity.h"
#import "MPTask.h"
#import "PatherController.h"
#import "PlayerDataController.h"

#import "MobController.h"
#import "Mob.h"
#import "Waypoint.h"
#import "Position.h"
#import "Offsets.h"

#import "MPMover.h"

@implementation MPActivityTest
@synthesize key, targetName;


- (id) init {
	return [self initWithTask:nil];
}

- (id) initWithTask:(MPTask*)aTask {
	
	if ((self = [super initWithName:@"Test Task" andTask:aTask])) {
		
		
		key = nil;
		targetName = nil;
		
//		self.timerWaitTime =  [MPTimer randomTimerFrom:20 To:80];
		
		
	}
	return self;
}


- (void) dealloc
{
 //   [timerWaitTime release];
    [super dealloc];
}


#pragma mark -



- (void) start {
	MPMover *mover = [MPMover sharedMPMover];
	[mover resetMovementState];
}


- (BOOL) work {
	
	if ((key == nil) || ([key isEqualToString:@"positioncheck"])) {
		
		
		
//		Position *myPosition = [[[task patherController] playerData] position];
		Mob *targetMob = nil;
		NSArray *mobList = [[[task patherController] mobController] allMobs];
		for (Mob *mob in mobList) {
//			PGLog(@" checking mob[%@]",[mob name]);
			if ([targetName isEqualToString:[mob name]]) {
				targetMob = mob;
			}
		}
		
		
		if (targetMob != nil) {
			
			/*
			PlayerDataController *player = [PlayerDataController sharedController];
			Position *myPosition = [player position];
			float angle = [myPosition angleTo:[targetMob position]];
			float myDirection = [player directionFacing];
			
			if ( fabsf(angle - myDirection) > M_PI ){
                if ( angle < myDirection )	angle += (M_PI*2);
                else								myDirection += (M_PI*2);
            }
            
            // find the difference between the angles
            float angleTo = (angle - myDirection), absAngleTo = fabsf(angleTo);
			
			PGLog(@"checking direction angle[%0.3f] my directionFacing[%0.3f]", angle, [player directionFacing]);
			PGLog(@"  angleTo[%0.3f]  absAngleTo[%0.3f]", angleTo, absAngleTo);
			
			if ( (angleTo < M_PI_4) && (angleTo > -M_PI_4)) {
				PGLog(@"   ---> Front");
			}
			if ( (angleTo <= -M_PI_4) && (angleTo > -3*M_PI_4)) {
				PGLog(@"   ---> Right");
			}
			if ( (angleTo <= -3*M_PI_4) || (angleTo >= 3*M_PI_4) ) {
				PGLog(@"   ---> Back");
			}
			if ( (angleTo >= M_PI_4) && (angleTo < 3*M_PI_4)) {
				PGLog(@"   ---> Left");
			}
			*/
			
			MPMover *mover = [MPMover sharedMPMover];
			int direction = [mover directionOfPosition:[targetMob position]];
			PGLog(@" ---> mover directionOfPosition: %d  angleTowards[%0.4f]", direction, [mover angleTurnTowards:[targetMob position]]);
			
			MPLocation *testLoc = [MPLocation locationBehindTarget:targetMob atDistance:5.0f];
			
//			[mover moveTowards:(MPLocation *)[targetMob position] within:3.0f facing:(MPLocation *)[targetMob position]];
			[mover moveTowards:testLoc within:1.0f facing:(MPLocation *)[targetMob position]];
			[mover action];
			
		} else {
			PGLog(@" Position Check: mob[%@] not found", targetName);
		}
		
	}
//	NSInteger testVal = [[task patherController] getMyLevel];
//	PGLog(@" the patherController's test value[%d]", testVal );
	
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}


- (void) stop{}


#pragma mark -

+ (id) activityForTask: (MPTask*) aTask andDict:(NSDictionary *)dict{
	
	MPActivityTest *newActivity = [[MPActivityTest alloc] initWithTask: aTask];
	newActivity.key = [dict objectForKey:@"actionKey"];
	newActivity.targetName = [dict objectForKey:@"targetName"];
	return newActivity;
}

@end
