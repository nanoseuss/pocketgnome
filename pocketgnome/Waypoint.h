//
//  Waypoint.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Position.h"

@class Action;

@interface Waypoint : NSObject <UnitPosition, NSCoding, NSCopying>  {
    Position *_position;
    Action *_action;
}

- (id)initWithPosition: (Position*)position;
+ (id)waypointWithPosition: (Position*)position;

@property (readwrite, copy) Position *position;
@property (readwrite, copy) Action *action;

@end
