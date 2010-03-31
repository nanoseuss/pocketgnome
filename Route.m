/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import "Route.h"

@interface Route ()
@property (readwrite, retain) NSArray *waypoints;
@end

@implementation Route

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.waypoints = [NSArray array];
    }
    return self;
}

+ (id)route {
    Route *route = [[Route alloc] init];
    
    return [route autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.waypoints = [decoder decodeObjectForKey: @"Waypoints"] ? [decoder decodeObjectForKey: @"Waypoints"] : [NSArray array];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.waypoints forKey: @"Waypoints"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Route *copy = [[[self class] allocWithZone: zone] init];
    copy.waypoints = self.waypoints;
    
    // PGLog(@"Old route: %@", self.waypoints);
    // PGLog(@"New route: %@", copy.waypoints);
    
    return copy;
}

- (void) dealloc
{
    self.waypoints = nil;
    [super dealloc];
}

#pragma mark -

- (NSString*)description {
    return [NSString stringWithFormat: @"<0x%X Route: %d waypoints>", self, [self waypointCount]];
}

@synthesize waypoints = _waypoints;

- (void)setWaypoints: (NSArray*)waypoints {
    [_waypoints autorelease];
    if(waypoints) {
        _waypoints = [[NSMutableArray alloc] initWithArray: waypoints copyItems: YES];
    } else {
        _waypoints = nil;
    }
}

- (unsigned)waypointCount {
    return _waypoints ? [_waypoints count] : 0;
}

- (Waypoint*)waypointAtIndex: (unsigned)index {
    if(index >= 0 && index < [_waypoints count])
        return [[[_waypoints objectAtIndex: index] retain] autorelease];
    return nil;
}

- (Waypoint*)waypointClosestToPosition: (Position*)position {
    Waypoint *closestWP = nil;
    float minDist = INFINITY, tempDist = 0;
    for ( Waypoint *waypoint in [self waypoints] ) {
        tempDist = [position distanceToPosition: [waypoint position]];
		//PGLog(@" %0.2f < %0.2f  %@", tempDist, minDist, waypoint);
        if ( (tempDist < minDist) && (tempDist >= 0.0f) ) {
            minDist = tempDist;
            closestWP = waypoint;
        }
    }

	PGLog(@"[Move] Closest WP found at a distance of %0.2f  Vertical Distance: %0.2f Total waypoints searched: %d", minDist, [position verticalDistanceToPosition:[closestWP position]], [[self waypoints] count]);
	
    return [[closestWP retain] autorelease];
}

- (void)addWaypoint: (Waypoint*)waypoint {
    if(waypoint != nil)
        [_waypoints addObject: waypoint];
    else
        PGLog(@"addWaypoint: failed; waypoint is nil");
}

- (void)insertWaypoint: (Waypoint*)waypoint atIndex: (unsigned)index {
    if(waypoint != nil && index >= 0 && index <= [_waypoints count])
        [_waypoints insertObject: waypoint atIndex: index];
    else
        PGLog(@"insertWaypoint:atIndex: failed; either waypoint is nil or index is out of bounds");
}

- (void)removeWaypoint: (Waypoint*)waypoint {
    if(waypoint == nil) return;
    [_waypoints removeObject: waypoint];
}

- (void)removeWaypointAtIndex: (unsigned)index {
    if(index >= 0 && index < [_waypoints count])
        [_waypoints removeObjectAtIndex: index];
}
@end
