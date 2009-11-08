//
//  Position.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/17/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Position.h"


@implementation Position

+ (void)initialize {
    [self exposeBinding: @"xPosition"];
    [self exposeBinding: @"yPosition"];
    [self exposeBinding: @"zPosition"];
}

- (id) init
{
    return [self initWithX: -1 Y: -1 Z: -1];
}

- (id)initWithX: (float)xLoc Y: (float)yLoc Z: (float)zLoc {
    self = [super init];
    if (self != nil) {
        self.xPosition = xLoc;
        self.yPosition = yLoc;
        self.zPosition = zLoc;
    }
    return self;
}

+ (id)positionWithX: (float)xLoc Y: (float)yLoc Z: (float)zLoc {
    Position *position = [[Position alloc] initWithX: xLoc Y: yLoc Z: zLoc];
    
    return [position autorelease];
}


@synthesize xPosition = _xPosition;
@synthesize yPosition = _yPosition;
@synthesize zPosition = _zPosition;

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.xPosition = [[decoder decodeObjectForKey: @"xPosition"] floatValue];
        self.yPosition = [[decoder decodeObjectForKey: @"yPosition"] floatValue];
        self.zPosition = [[decoder decodeObjectForKey: @"zPosition"] floatValue];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: [NSNumber numberWithFloat: self.xPosition] forKey: @"xPosition"];
    [coder encodeObject: [NSNumber numberWithFloat: self.yPosition] forKey: @"yPosition"];
    [coder encodeObject: [NSNumber numberWithFloat: self.zPosition] forKey: @"zPosition"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Position *copy = [[[self class] allocWithZone: zone] initWithX: self.xPosition Y: self.yPosition Z: self.zPosition];
    
    return copy;
}

- (void) dealloc
{
    [super dealloc];
}


- (NSString*)description {
    return [NSString stringWithFormat: @"<Position X: %.2f Y: %.2f Z: %.2f>", [self xPosition], [self yPosition], [self zPosition]];
}

#pragma mark -

// 10 yards away from self
- (Position*)positionAtDistance:(float)distance withDestination:(Position*)playerPosition {
	distance = 10.0f;
	
	float angle = [self angleTo:playerPosition];
	
	PGLog(@"Angle to player: %0.2f", angle);
	
	
	// Q I
	if ( angle <= M_PI/2 ){
		// do nothing
		PGLog(@"Q I");
	}
	// Q II
	else if ( angle <= M_PI ){
		//angle -= M_PI/2;
		PGLog(@"Q II");
		
	}
	// Q III
	else if ( angle <= (3*M_PI)/2 ){
		PGLog(@"Q III");
	}
	
	// Q VI
	else{
		//angle -= (3*M_PI)/2;
		PGLog(@"Q VI");
	}
	
	PGLog(@"Angle to destination corrected: %0.2f", angle);
	
	float x = distance * cosf(angle);
	float y = distance * sinf(angle);
	float z = [self zPosition];
	
	PGLog(@"x: %0.2f y: %0.2f", x, y);
	
	Position *newPosition = [[Position alloc] initWithX:x+[self xPosition] Y:y+[self yPosition] Z:z];
	return newPosition;
}


- (float)angleTo: (Position*)position {
    
    // create unit vector in direction of the mob
    float xDiff = [position xPosition] - [self xPosition];
    float yDiff = [position yPosition] - [self yPosition];
    float distance = [self distanceToPosition2D: position];
    NSPoint mobUnitVector = NSMakePoint(xDiff/distance, yDiff/distance);
    // PGLog(@"Unit Vector to Mob: %@", NSStringFromPoint(mobUnitVector));
    
    // create unit vector of player facing angle
    //float angle = [playerDataController playerDirection];
    //NSPoint playerUnitVector = NSMakePoint(cosf(angle), sinf(angle));
    NSPoint northUnitVector = NSMakePoint(1, 0);
    
    // determine the angle between the Mob and North
    float angleBetween = mobUnitVector.x*northUnitVector.x + mobUnitVector.y*northUnitVector.y;
    float angleOffset = acosf(angleBetween);
    // PGLog(@"Cosine of angle between: %f", angleBetween);
    // PGLog(@"Angle (rad) between: %f", angleOffset);
    
    if(mobUnitVector.y > 0) // mob is in N-->W-->S half of the compass
        return angleOffset;
    else                    // mob is in N-->E-->S half of the compass
        return ((6.2831853f) - angleOffset);
}


- (float)verticalAngleTo: (Position*)position {
    
    // create unit vector in direction of the mob
    float xDiff = [position xPosition] - [self xPosition];
    float yDiff = [position yPosition] - [self yPosition];
    float zDiff = [position zPosition] - [self zPosition];
    float distance = [self distanceToPosition: position];
    
    float mobUVx = xDiff/distance;
    float mobUVy = yDiff/distance;
    float mobUVz = zDiff/distance;
    
    // create unit vector toward mob at current elevation
    float distance2D = [self distanceToPosition2D: position];
    
    float levelUVx = xDiff/distance2D;
    float levelUVy = yDiff/distance2D;
    float levelUVz = 0.0f;
    
    // cosine of the angle between them is: (A x B) / |A||B| (but since magnitudes are 1...)
    float cosine = mobUVx*levelUVx + mobUVy*levelUVy + mobUVz*levelUVz;
    if(cosine > 1.0f) cosine = 1.0f; // values over 1.0 are invalid for acosf().
    float angleBetween = acosf(cosine);

    // now, adjust the sign
    if(zDiff < 0.0f) {
        angleBetween = 0.0f - angleBetween;
    }

    //PGLog(@"Got vertical angle between: %f; cosine: %f", angleBetween, cosine);
    return angleBetween;
}

- (float)distanceToPosition2D: (Position*)position {
    
    float distance;
    if([self xPosition] != INFINITY && [self yPosition] != INFINITY) {
        float xDiff = [position xPosition] - [self xPosition];
        float yDiff = [position yPosition] - [self yPosition];
        distance = sqrt(xDiff*xDiff + yDiff*yDiff);
    } else {
        distance = INFINITY;
    }
    return distance;
}

- (float)distanceToPosition: (Position*)position {
    
    float distance = INFINITY;
    if(position && ([self xPosition] != INFINITY && [self yPosition] != INFINITY && [self zPosition] != INFINITY)) {
        float xDiff = [position xPosition] - [self xPosition];
        float yDiff = [position yPosition] - [self yPosition];
        float zDiff = [position zPosition] - [self zPosition];
        distance = sqrt(xDiff*xDiff + yDiff*yDiff + zDiff*zDiff);
    }
    return distance;
}

- (float)verticalDistanceToPosition: (Position*)position {
    return fabsf([position zPosition] - [self zPosition]);
}

- (float)dotProduct: (Position*)position {
	return [self xPosition]*[position xPosition] + [self yPosition]*[position yPosition] + [self zPosition]*[position zPosition];
}

- (Position*)difference: (Position*)position {
	Position *diff = [[Position alloc] initWithX:[self xPosition] - [position xPosition]
											   Y:[self yPosition] - [position yPosition]
											   Z:[self zPosition] - [position zPosition]];
	return diff;
}

- (BOOL)isEqual:(Position*)other {
	
	if ( other == self ){
		return YES;
	}
	if ( self.xPosition == other.xPosition && self.yPosition == other.yPosition && self.zPosition == other.zPosition ){
		return YES;
	}
	
	return NO;
}

@end
