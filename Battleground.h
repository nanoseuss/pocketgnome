//
//  Battleground.h
//  Pocket Gnome
//
//  Created by Josh on 2/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RouteCollection;

@interface Battleground : NSObject {

	NSString *_name;
	int _zone;		// what zone is this BG associated with?
	BOOL _enabled;
	
	// we'll never actually save this to the disk (it will be part of PvPBehavior, so we have to track this)
	BOOL _changed;
	
	RouteCollection *_routeCollection;	
}

@property (readonly) int zone;
@property (readonly, retain) NSString *name;
@property (readwrite, assign) BOOL enabled;
@property (readwrite, retain) RouteCollection *routeCollection;
@property (readwrite, assign) BOOL changed;

+ (id)battlegroundWithName: (NSString*)name andZone: (int)zone;

@end
