//
//  MPLine.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPLocation;


@interface MPLine : NSObject {

	float A, B, C, xMin, xMax, yMin, yMax;
}
@property (readonly) float A, B, C;
@property (readwrite) float xMin, xMax, yMin, yMax;

-(id) init;
-(id) initWithA:(float)valA B:(float)valB C:(float)valC;

- (MPLocation *) locationOfIntersectionWithLine: (MPLine *)line;
- (BOOL) locationWithinBounds: (MPLocation *) location;

+ (MPLine *) lineStartingAt: (MPLocation *)startLocation endingAt:(MPLocation *) endingLocation;
@end
