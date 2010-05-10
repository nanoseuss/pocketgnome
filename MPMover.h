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
@class MPTimer;
@class PatherController;
@class Position;


#define MP_PI_8        0.392699081698724   /* pi/8 */

@interface MPMover : NSObject {

	
	BOOL rotateLeft, oldRotateLeft;
	BOOL rotateRight, oldRotateRight;
	BOOL runBackwards, oldRunBackwards;
	BOOL runForwards, oldRunForwards;
	BOOL strafeLeft, oldStrafeLeft;
	BOOL strafeRight, oldStrafeRight;
	BOOL swimUp, oldSwimUp;
	
	float closeEnough, angleTolerance;
	MPLocation *destinationLocation, *facingLocation;
	
	// Stuck Checking
	MPTimer *timerStuckCheck;
	Position *referencePosition;
	BOOL thinkStuck, isStuck;
	int unstickAttempt;
	
	PatherController *patherController;
}
@property (retain) PatherController *patherController;
@property (retain) MPTimer *timerStuckCheck;
@property (retain) Position *referencePosition;
@property (retain) MPLocation *destinationLocation, *facingLocation;

// Reset all movement states.  (should stop)
- (void) resetMovementState;


- (void) stopRotate;
- (void) stopMove;
- (void) stopAllMovement;

- (int) directionOfPosition: (Position *)position;	// <-- Testing: should be internal
- (float) angleTurnTowards: (Position *)position;	// <-- Testing: should be internal

- (void) faceLocation: (MPLocation *) location;

- (BOOL) shouldMoveTowards: (MPLocation *)locDestination within:(float)howClose facing:(MPLocation *)locFacing;
- (BOOL) shouldMoveTowards: (MPLocation *)locDestination within:(float)howClose facing:(MPLocation *)locFacing withinTolerance:(float) toleranceAngle;
- (BOOL) moveTowards: (MPLocation *)locDestination within:(float)howClose facing:(MPLocation *)locFacing;
- (BOOL) moveTowards: (MPLocation *)locDestination within:(float)howClose facing:(MPLocation *)locFacing withinTolerance:(float) toleranceAngle;


// The actual movement work is done here
- (void) action;

#pragma mark -
#pragma mark Basic Movements

- (void) backwards: (BOOL) go;
- (void) forwards: (BOOL) go;
- (void) rotateLeft: (BOOL) go;
- (void) rotateRight: (BOOL) go;
- (void) strafeLeft: (BOOL) go;
- (void) strafeRight: (BOOL) go;
- (void) swimUp: (BOOL) go;

// 
- (id) init;
- (id) initWithController: (PatherController*)controller;
//+ (id) moverWithController:(PatherController*)controller;
+ (MPMover *)sharedMPMover;

@end
