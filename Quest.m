//
//  Quest.m
//  Pocket Gnome
//
//  Created by Josh on 4/23/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Quest.h"
#import "QuestItem.h"

@interface Quest (internal)
- (void)loadQuestData;
@end

@implementation Quest

@synthesize _bytes1;
@synthesize _bytes2;
@synthesize _bytes3;

- (id) init
{
    self = [super init];
    if (self != nil) {
        _questID = nil;
        _itemRequirements = nil;
        _description = nil;
        _rewards = nil;
        _startNPC = nil;
        _endNPC = nil;
		_level = nil;
		_requiredLevel = nil;
		
    }
    return self;
}

- (id)initWithQuestID: (NSNumber*)questID {
    self = [self init];
    if(self) {
        if( ([questID intValue] <= 0) || ([questID intValue] > MaxQuestID)) {
            [self release];
            return nil;
        }
        _questID = [questID retain];
		
		// Lets grab quest data...
		//[self reloadQuestData];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.ID = [decoder decodeObjectForKey: @"QuestID"];
        self.name = [decoder decodeObjectForKey: @"Name"];
		self.level = [decoder decodeObjectForKey: @"Level"];
		self.requiredlevel = [decoder decodeObjectForKey: @"RequiredLevel"];
		self.startnpc = [decoder decodeObjectForKey: @"StartNPC"];
		self.endnpc = [decoder decodeObjectForKey: @"EndNPC"];
		self.itemrequirements = [decoder decodeObjectForKey: @"ItemRequirements"];
        
        if(self.name) {
            NSRange range = [self.name rangeOfString: @"html>"];
            if( ([self.name length] == 0) || (range.location != NSNotFound)) {
                PGLog(@"Name for quest %@ is invalid.", self.ID);
                self.name = nil;
            }
        }
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.ID forKey: @"QuestID"];
    [coder encodeObject: self.name forKey: @"Name"];
	[coder encodeObject: self.level forKey: @"Level"];
	[coder encodeObject: self.requiredlevel forKey: @"RequiredLevel"];
	[coder encodeObject: self.startnpc forKey: @"StartNPC"];
	[coder encodeObject: self.endnpc forKey: @"EndNPC"];
	[coder encodeObject: self.endnpc forKey: @"ItemRequirements"];
	
	
}

- (void)dealloc {
    self.ID = nil;
    self.name = nil;
	self.level = nil;
	self.requiredlevel = nil;
	self.startnpc = nil;
	self.itemrequirements = nil;
	
	[_itemRequirements release];
    [_connection release];
    [_downloadData release];
    
    [super dealloc];
}

#pragma mark -

- (NSNumber*)ID {
    NSNumber *temp = nil;
    @synchronized (@"ID") {
        temp = [_questID retain];
    }
    return [temp autorelease];
}

- (void)setID: (NSNumber*)ID {
    id temp = nil;
    [ID retain];
    @synchronized (@"ID") {
        temp = _questID;
        _questID = ID;
    }
    [temp release];
}

- (NSString*)name {
    NSString *temp = nil;
    @synchronized (@"Name") {
        temp = [_name retain];
    }
    return [temp autorelease];
}

- (void)setName: (NSString*)name {
    id temp = [name retain];
    @synchronized (@"Name") {
        temp = _name;
        _name = name;
    }
    [temp release];
}

- (NSNumber*)level {
    NSNumber *temp = nil;
    @synchronized (@"Level") {
        temp = [_level retain];
    }
    return [temp autorelease];
}

- (void)setLevel: (NSNumber*)level {
    id temp = nil;
    [level retain];
    @synchronized (@"Level") {
        temp = _level;
        _level = level;
    }
    [temp release];
}

- (NSNumber*)requiredlevel {
    NSNumber *temp = nil;
    @synchronized (@"RequiredLevel") {
        temp = [_requiredLevel retain];
    }
    return [temp autorelease];
}

- (void)setRequiredlevel: (NSNumber*)requiredlevel {
    id temp = nil;
    [requiredlevel retain];
    @synchronized (@"RequiredLevel") {
        temp = _requiredLevel;
        _requiredLevel = requiredlevel;
    }
    [temp release];
}

- (NSNumber*)startnpc {
    NSNumber *temp = nil;
    @synchronized (@"StartNPC") {
        temp = [_startNPC retain];
    }
    return [temp autorelease];
}

- (void)setStartnpc: (NSNumber*)startnpc {
    id temp = nil;
    [startnpc retain];
    @synchronized (@"StartNPC") {
        temp = _startNPC;
        _startNPC = startnpc;
    }
    [temp release];
}

- (NSNumber*)endnpc {
    NSNumber *temp = nil;
    @synchronized (@"EndNPC") {
        temp = [_endNPC retain];
    }
    return [temp autorelease];
}

- (void)setEndnpc: (NSNumber*)endnpc {
    id temp = nil;
    [endnpc retain];
    @synchronized (@"EndNPC") {
        temp = _endNPC;
        _endNPC = endnpc;
    }
    [temp release];
}

- (NSMutableArray*)itemrequirements {
    NSNumber *temp = nil;
    @synchronized (@"ItemRequirements") {
        temp = [_itemRequirements retain];
    }
    return [temp autorelease];
}

- (void)setItemrequirements: (NSMutableArray*)itemrequirements {
    id temp = nil;
    [itemrequirements retain];
    @synchronized (@"ItemRequirements") {
        temp = _itemRequirements;
        _itemRequirements = itemrequirements;
    }
    [temp release];
}

- (int)requiredItemTotal{
	return [_itemRequirements count];
}
- (NSNumber*)requiredItemIDIndex: (int)index{
	if ( index < [_itemRequirements count] ){
		QuestItem *tmp = [_itemRequirements objectAtIndex:index];
		if (tmp){
			return [tmp item];
		}
		else{
			return 0;
		}
	}
	else{
		NSLog(@"Requested invalid Index for _itemRequirements: %d", index);
	}
	
	return 0;
}
- (NSNumber*)requiredItemQuantityIndex: (int)index{
	if ( index < [_itemRequirements count] ){
		QuestItem *tmp = [_itemRequirements objectAtIndex:index];
		if (tmp){
			return [tmp quantity];
		}
		else{
			return 0;
		}
	}
	else{
		NSLog(@"Requested invalid Index for _itemRequirements: %d", index);
	}
	
	return 0;
}

//requiredItemQuantityIndex
#pragma mark -

//#define NAME_SEPARATOR      @"<table class=ttb width=300><tr><td colspan=2>"
//#define RANGE_SEPARATOR     @"<th>Range</th>		<td>"
//#define COOLDOWN_SEPARATOR  @"<tr><th>Cooldown</th><td>"

#define NAME_SEPARATOR			@"<title>"
#define LEVEL_SEPERATOR			@"<div>Level: "
#define REQD_LEVEL_SEPRATOR		@"<div>Requires level "
#define START_SEPERATOR			@"Start: <a href=\"/?npc="
#define END_SEPERATOR			@"End: <a href=\"/?npc="
#define ITEM_SEPERATOR			@"?item="
#define ITEM_NUM_SEPERATOR		@"</a></span>&nbsp;("
#define REWARDS_SEPERATOR		@"<h3>Rewards</h3>"

#define RANK_SEPARATOR      @"<b class=\"q0\">Rank "
#define SCHOOL_SEPARATOR    @"School</th><td>"
#define DISPEL_SEPARATOR    @"Dispel type</th><td style=\"border-bottom: 0\">"
#define COST_SEPARATOR      @"Cost</th><td style=\"border-top: 0\">"
#define RANGE_SEPARATOR     @"<th>Range</th><td>"
#define CASTTIME_SEPARATOR  @"<th>Cast time</th><td>"
#define COOLDOWN_SEPARATOR  @"<th>Cooldown</th><td>"
#define GLOBAL_COOLDOWN_SEPARATOR   @"<div style=\"width: 65%; float: right\">Global cooldown: "


- (void)reloadQuestData {
    
    if([[self ID] intValue] < 0 || [[self ID] intValue] > MaxQuestID)
        return;
    
    [_connection cancel];
    [_connection release];
    _connection = [[NSURLConnection alloc] initWithRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://www.wowhead.com/?quest=%@", [self ID]]]] delegate: self];
    if(_connection) {
        [_downloadData release];
        _downloadData = [[NSMutableData data] retain];
        //[_connection start];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_downloadData setLength: 0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_downloadData appendData: data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [_connection release];  _connection = nil;
    [_downloadData release]; _downloadData = nil;
	
    // inform the user
    PGLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // get the download as a string
    NSString *wowhead = [[[NSString alloc] initWithData: _downloadData encoding: NSUTF8StringEncoding] autorelease];
    
    // release the connection, and the data object
    [_connection release];  _connection = nil;
    [_downloadData release]; _downloadData = nil;
	
	// parse out the name
    if(wowhead && [wowhead length]) {
        NSScanner *scanner = [NSScanner scannerWithString: wowhead];
        
        // check to see if this is a valid quest
        if( ([scanner scanUpToString: @"Error - Wowhead" intoString: nil]) && ![scanner isAtEnd]) {
            int questID = [[self ID] intValue];
            switch(questID) {
                default:
                    self.name = @"[Unknown]";
                    break;
            }
            
            PGLog(@"Quest %d does not exist on wowhead.", questID);
            return;
        } else {
            if( [scanner scanUpToString: @"Bad Request" intoString: nil] && ![scanner isAtEnd]) {
                int questID = [[self ID] intValue];
                PGLog(@"Error loading quest %d.", questID);
                return;
            } else {
                [scanner setScanLocation: 0];
            }
        }
        
        // get the quest name
        int scanSave = [scanner scanLocation];
        if([scanner scanUpToString: NAME_SEPARATOR intoString: nil] && [scanner scanString: NAME_SEPARATOR intoString: nil]) {
            NSString *newName = nil;
            if([scanner scanUpToString: @" - Quest" intoString: &newName]) {
                if(newName && [newName length]) {
                    self.name = newName;
					
                } else {
                    self.name = @"";
                }
            }
        }
		else {
            [scanner setScanLocation: scanSave];
        }
		
		// Get the Level reco
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: LEVEL_SEPERATOR intoString: nil] && [scanner scanString: LEVEL_SEPERATOR intoString: nil]) {
            int level = 0;
            if([scanner scanInt: &level] && level) {
                self.level = [NSNumber numberWithInt: level];
            } else {
                self.level = [NSNumber numberWithInt: 0];
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
		
		// Get the required level
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: REQD_LEVEL_SEPRATOR intoString: nil] && [scanner scanString: REQD_LEVEL_SEPRATOR intoString: nil]) {
            int requiredLevel = 0;
            if([scanner scanInt: &requiredLevel] && requiredLevel) {
                self.requiredlevel = [NSNumber numberWithInt: requiredLevel];
            } else {
                self.requiredlevel = [NSNumber numberWithInt: 0];
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
		
		// Where does the quest start!
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: START_SEPERATOR intoString: nil] && [scanner scanString: START_SEPERATOR intoString: nil]) {
            int start = 0;
            if([scanner scanInt: &start] && start) {
                self.startnpc = [NSNumber numberWithInt: start];
            } else {
                self.startnpc = [NSNumber numberWithInt: 0];
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
		
		// Where does the quest end!
        scanSave = [scanner scanLocation];
        if([scanner scanUpToString: END_SEPERATOR intoString: nil] && [scanner scanString: END_SEPERATOR intoString: nil]) {
            int endnpc = 0;
            if([scanner scanInt: &endnpc] && endnpc) {
                self.endnpc = [NSNumber numberWithInt: endnpc];
            } else {
                self.endnpc = [NSNumber numberWithInt: 0];
            }
        } else {
            [scanner setScanLocation: scanSave];
        }
		
		// Are there any quest items required?
        scanSave = [scanner scanLocation];
		
		// Lets scan up to the Rewards section.. so any item before that we can assume is required for completion...
		NSString *upToRewards = nil;
		[scanner scanUpToString: REWARDS_SEPERATOR intoString: &upToRewards];
		[scanner setScanLocation: scanSave];
		
		if ( upToRewards ){
			//NSLog(@"//// %@ ^n////", upToRewards );
			// Set up a new scanner for just the above string
			NSScanner *scannerUpToRewards = [NSScanner scannerWithString: upToRewards];
			
			BOOL searching = true;
			NSMutableArray *items = [[NSMutableArray array] retain];
			while(searching){
				if([scannerUpToRewards scanUpToString: ITEM_SEPERATOR intoString: nil] && [scannerUpToRewards scanString: ITEM_SEPERATOR intoString: nil]) {
					int itemID = 0;
					QuestItem *questItem = [[QuestItem alloc] init];
					if([scannerUpToRewards scanInt: &itemID] && itemID) {
						
						// At this point we have the item ID #... now lets check to see if there is a quantity associated w/it
						int quantity = 1;//_itemRequirements
						if([scannerUpToRewards scanUpToString: ITEM_NUM_SEPERATOR intoString: nil] && [scannerUpToRewards scanString: ITEM_NUM_SEPERATOR intoString: nil]) {
							[scannerUpToRewards scanInt: &quantity];
						}
						questItem.quantity = [NSNumber numberWithInt: quantity];
						
						// Set the item ID
						questItem.item = [NSNumber numberWithInt: itemID];
						
						// Add it to our required items list
						[items addObject:questItem];
						//PGLog(@"%@ %@ %@", self.name, questItem.item, questItem.quantity );
					}
				} else {
					searching = false;
				}
			}
			
			// Make sure we save the items - duh!
			self.itemrequirements = items;
		}
	}
	
	// Could do some other things 
	
	
	
	
	//PGLog(@"%@ %@ %@ %@ %@", self.name, self.level, self.requiredlevel, self.startnpc, self.endnpc);
}

@end
