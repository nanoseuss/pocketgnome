//
//  MPMover.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 3/30/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//
//  This object is to handle PG-Pathers movement:
//		- it presses the keys
//		- it knows a destination (destPosition)
//		- it knows a location to face while moving (facingPosition)
//		- it detects being stuck (using MPStuckDetector)
//
//  Called by MPRouteFeeder
//

#import <Cocoa/Cocoa.h>
@class MPLocation;
@class PatherController;


@interface MPMover : NSObject {

	
	BOOL rotateLeft, oldRotateLeft;
	BOOL rotateRight, oldRotateRight;
	BOOL runBackwards, oldRunBackwards;
	BOOL runForwards, oldRunForwards;
	BOOL strafeLeft, oldStrafeLeft;
	BOOL strafeRight, oldStrafeRight;
	BOOL swimUp, oldSwimUp;
	
	MPLocation *destinationLocation, *facingPosition;
	
	PatherController *patherController;
}
@property (retain) PatherController *patherController;
@property (retain) MPLocation *destinationLocation, *facingPosition;

// Reset all movement states.  (should stop)
- (void) resetMovementState;


- (void) stopRotate;
- (void) stopMove;
- (void) stopAllMovement;

// 
- (id) init;
- (id) initWithController: (PatherController*)controller;
+ (id) moverWithController:(PatherController*)controller;

@end
