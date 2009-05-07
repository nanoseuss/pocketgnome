//
//  Quest.h
//  Pocket Gnome
//
//  Created by Josh on 4/23/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RouteSet;

#define MaxQuestID 1000000

@interface Quest : NSObject {
    NSNumber *_questID;
    
    NSString *_name;
	NSString *_description;
	
	NSMutableArray *_itemRequirements;		// List of items that are needed to complete the quest
	NSMutableArray *_rewards;				// List of items
	
	NSNumber *_startNPC;
	NSNumber *_endNPC;
	
	NSNumber *_level;
	NSNumber *_requiredLevel;
	
	NSURLConnection *_connection;
    NSMutableData *_downloadData;
	
	NSNumber *_bytes1;
	NSNumber *_bytes2;
	NSNumber *_bytes3;
	
	// Store route info for this quest!
	RouteSet *_route;
	RouteSet *_routeToTurnIn;
	NSNumber *_enabled;
	NSNumber *_order;
}

@property (readwrite, retain) RouteSet *route;
@property (readwrite, retain) RouteSet *routeToTurnIn;
@property (readwrite, retain) NSNumber *enabled;
@property (readwrite, retain) NSNumber *order;


@property (retain) NSNumber *_bytes1;
@property (retain) NSNumber *_bytes2;
@property (retain) NSNumber *_bytes3;

/*- (void)setRoute: (id) route;
- (void)setEnabled: (id) enabled;
*/
- (id)initWithQuestID: (NSNumber*)questID: (NSNumber*) order;

- (NSNumber*)ID;
- (void)setID: (NSNumber*)ID;
- (NSString*)name;
- (void)setName: (NSString*)name;
- (NSNumber*)level;
- (void)setLevel: (NSNumber*)level;
- (NSNumber*)requiredlevel;
- (void)setRequiredlevel: (NSNumber*)requiredlevel;
- (NSNumber*)startnpc;
- (void)setStartnpc: (NSNumber*)startnpc;
- (NSNumber*)endnpc;
- (void)setEndnpc: (NSNumber*)endnpc;
- (NSMutableArray*)itemrequirements;
- (void)setItemrequirements: (NSMutableArray*)itemrequirements;


- (int)requiredItemTotal;
- (NSNumber*)requiredItemIDIndex: (int)index;
- (NSNumber*)requiredItemQuantityIndex: (int)index;

- (void)reloadQuestData;

@end
