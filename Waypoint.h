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

#import <Cocoa/Cocoa.h>
#import "Position.h"

@class Action;
@class Rule;

@interface Waypoint : NSObject <UnitPosition, NSCoding, NSCopying>  {
    Position *_position;
    Action *_action;
	NSString *_title;	// this is a description
	
	// list of actions (in order)
	// list of conditions (procedure?)
	// name for the WP Actions (i.e. repair)
	NSMutableArray *_actions;
	Rule *_rule;
}

- (id)initWithPosition: (Position*)position;
+ (id)waypointWithPosition: (Position*)position;

@property (readwrite, copy) Position *position;
@property (readwrite, copy) Action *action;
@property (readwrite, copy) NSString *title;

@property (readonly, retain) NSArray *actions;
@property (readwrite, retain) Rule *rule;

// actions
- (void)addAction: (Action*)action;
- (void)setActions: (NSArray*)actions;

@end
