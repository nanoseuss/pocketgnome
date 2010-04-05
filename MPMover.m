//
//  MPMover.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 3/30/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <Carbon/Carbon.h>

#import "MPLocation.h"
#import "MPMover.h"
#import "PatherController.h"
#import "Controller.h"




@interface MPMover (Internal)

- (void) pressKey: (CGKeyCode) keyCode;
- (void) releaseKey: (CGKeyCode) keyCode;
@end




@implementation MPMover
@synthesize destinationLocation, facingPosition, patherController;


- (id) init {
	return [self initWithController:nil];
}

- (id) initWithController: (PatherController*)controller {
	
	if ((self = [super init])) {
		
		self.destinationLocation = nil;
		self.facingPosition = nil;
		
		[self resetMovementState];
		self.patherController = controller;
	}
	return self;
}


- (void) dealloc
{
	[destinationLocation release];
	[facingPosition release];
    [patherController release];

    [super dealloc];
}


#pragma mark -


- (void) resetMovementState {
	
	runForwards = oldRunForwards	= NO;
	runBackwards = oldRunBackwards	= NO;
	strafeLeft	= oldStrafeLeft		= NO;
	strafeRight = oldStrafeRight	= NO;
	rotateLeft	= oldRotateLeft		= NO;
	rotateRight	= oldRotateRight	= NO;
	swimUp		= oldSwimUp			= NO;
	
}

#pragma mark -
#pragma mark Movement Info

- (BOOL) isMoving {
	return (runForwards || runBackwards || strafeLeft || strafeRight );
}

- (BOOL) isRotating {
	return (rotateLeft || rotateRight);
}

- (BOOL) isRotateingLeft {
	return rotateLeft;
}

- (BOOL) isRotatingRight {
	return rotateRight;
}


#pragma mark -
#pragma mark Stop Commands

- (void) stopRotate {
	
	if (rotateLeft || rotateRight) {
		PGLog(@"Stop Rotate");
	}
	
	self.facingPosition = nil;
	
	rotateLeft = NO;
	rotateRight = NO;
}


- (void) stopMove {
	
	if (runForwards || runBackwards || strafeLeft || strafeRight || rotateLeft || rotateRight || swimUp){
		PGLog(@"Stop Move");
	}
	
	self.destinationLocation = nil;
	self.facingPosition = nil;
	
	runForwards  =  NO;
	runBackwards =  NO;
	strafeLeft	 =  NO;
	strafeRight  =  NO;
	rotateLeft	 =  NO;
	rotateRight	 =  NO;
	swimUp		 =  NO;
	
	// should I pause here?
	
}

- (void) stopAllMovement {
	
	// release all keys
	
	[self resetMovementState];
	
	[self stopMove];
	
	[self stopRotate];
}


#pragma mark - 
#pragma mark Key Pressing

- (void) pressKey: (CGKeyCode) keyCode {
//	[self setIsMoving: YES];
    ProcessSerialNumber wowPSN = [[patherController controller] getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, keyCode, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}


- (void) releaseKey: (CGKeyCode) keyCode {
	//	[self setIsMoving: NO];
    ProcessSerialNumber wowPSN = [[patherController controller] getWoWProcessSerialNumber];
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, keyCode, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
}

#pragma mark -
#pragma mark Convienience Constructors

+ (id) moverWithController:(PatherController*)controller  {
	
	MPMover *newMover = [[MPMover alloc] initWithController:controller];
	return [newMover autorelease];
}

@end
