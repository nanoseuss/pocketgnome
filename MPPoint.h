//
//  MPPoint.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPLocation;
@class MPSquare;



@interface MPPoint : NSObject {
	MPLocation *location;
	NSMutableArray *squaresContainedIn;
}
@property (readwrite, retain) MPLocation *location;
@property (readwrite, retain) NSMutableArray *squaresContainedIn;

-(id) init;
-(id) initWithLocation: (MPLocation *) aLocation;

- (void) setX: (float)xPos;
- (void) setY: (float)yPos;
- (void) setZ: (float)zPos;

- (BOOL) isAt: (MPLocation *)aLocation withinZTolerance:(float) zTolerance;
- (float) zDistanceTo: (MPLocation *)aLocation;

- (void) containedInSquare: (MPSquare *) aSquare;
- (void) removeContainingSquare: (MPSquare *) aSquare;
- (MPSquare *) squareWherePointIsInPosition: (int) position;

- (NSString *) describe;

+ (MPPoint *) pointAtX: (float)locX Y:(float) locY Z:(float) locZ;

@end
