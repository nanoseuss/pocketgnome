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
#import "SaveDataObject.h"

@class RouteSet;

@interface RouteCollection : SaveDataObject {
	NSString *_name;
	NSMutableArray *_routes;
	
	NSString *_startUUID;
	
	BOOL _startRouteOnDeath;
}

+ (id)routeCollectionWithName: (NSString*)name;

@property (readonly, retain) NSMutableArray *routes;
@property (readwrite, copy) NSString *name;
@property BOOL startRouteOnDeath;

- (void)moveRouteSet:(RouteSet*)route toLocation:(int)index;
- (void)addRouteSet:(RouteSet*)route;
- (BOOL)removeRouteSet:(RouteSet*)route;
- (BOOL)containsRouteSet:(RouteSet*)route;

- (RouteSet*)startingRoute;
- (void)setStartRoute:(RouteSet*)route;
- (BOOL)isStartingRoute:(RouteSet*)route;

@end
