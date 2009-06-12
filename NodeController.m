//
//  WorldObjectController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/29/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "NodeController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "MemoryViewController.h"
#import "MovementController.h"
#import "Waypoint.h"
#import "Offsets.h"

#import "ImageAndTextCell.h"

#import <Growl/GrowlApplicationBridge.h>

typedef enum {
    Filter_All              = -100,
    Filter_Mine_Herb        = -4,
    Filter_Container_Quest  = -3,
    Filter_Herbs            = -2,
    Filter_Minerals         = -1,
    Filter_Transport        = 11,
} FilterType;

@interface NodeController ()
@property (readwrite, assign) int nodeTypeFilter;
@property (readwrite, retain) NSString *filterString;
@end

@interface NodeController (Internal)

- (int)nodeLevel: (Node*)node;
- (BOOL)trackingNode: (Node*)trackingNode;
- (void)reloadNodeData: (id)sender;
- (void)fishingCheck;

@end

@implementation NodeController

- (id) init
{
    self = [super init];
    if (self != nil) {
        
        _nodeList = [[NSMutableArray array] retain];
        _nodeDataList = [[NSMutableArray array] retain];
        _finishedNodes = [[NSMutableArray array] retain];
        
        // load in our gathering dictionaries
        NSDictionary *gatheringDict = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Gathering" ofType: @"plist"]];
        if(gatheringDict) {
            _miningDict = [[gatheringDict objectForKey: @"Mining"] retain];
            _herbalismDict = [[gatheringDict objectForKey: @"Herbalism"] retain];
        } else {
            PGLog(@"Unable to load Gathering information.");
        }
        
        // load in node names
        //id nodeNames = [[NSUserDefaults standardUserDefaults] objectForKey: @"NodeNames"];
//        if(nodeNames) {
//            _nodeNames = [[NSKeyedUnarchiver unarchiveObjectWithData: nodeNames] mutableCopy];            
//        } else
//            _nodeNames = [[NSMutableDictionary dictionary] retain];
            
        self.nodeTypeFilter = Filter_All;
        _updateTimer = nil;
        [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObject: @"1.0" forKey: @"NodeControllerUpdateFrequency"]];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:) 
                                                     name: NSApplicationWillTerminateNotification 
                                                   object: nil];
        
        //[[NSNotificationCenter defaultCenter] addObserver: self
        //                                         selector: @selector(nodeNameLoaded:) 
        //                                             name: NodeNameLoadedNotification 
        //                                           object: nil];

        [NSBundle loadNibNamed: @"Nodes" owner: self];
    }
    return self;
}

- (void)awakeFromNib {

    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
    
    self.updateFrequency = [[NSUserDefaults standardUserDefaults] floatForKey: @"NodeControllerUpdateFrequency"];
    
    [nodeTable setDoubleAction: @selector(tableDoubleClick:)];
    [(NSTableView*)nodeTable setTarget: self];
    
    ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable: NO];
    [[nodeTable tableColumnWithIdentifier: @"Name"] setDataCell: imageAndTextCell];
}

- (void)applicationWillTerminate: (NSNotification*)notification {
//    [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: _nodeNames] forKey: @"NodeNames"];
//    [MyUserDefaults synchronize];
}


#pragma mark Basic Accessors

@synthesize view;
@synthesize updateFrequency = _updateFrequency;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize nodeTypeFilter = _nodeTypeFilter;
@synthesize filterString;

- (NSString*)sectionTitle {
    return @"Nodes";
}

- (void)setUpdateFrequency: (float)frequency {
    if(frequency < 0.5) frequency = 0.5;
    
    [self willChangeValueForKey: @"updateFrequency"];
    _updateFrequency = [[NSString stringWithFormat: @"%.2f", frequency] floatValue];
    [self didChangeValueForKey: @"updateFrequency"];
    
    [[NSUserDefaults standardUserDefaults] setFloat: _updateFrequency forKey: @"NodeControllerUpdateFrequency"];

    [_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval: _updateFrequency target: self selector: @selector(reloadNodeData:) userInfo: nil repeats: YES];
}

#pragma mark Notification/Timer Callbacks

//- (void)nodeNameLoaded: (NSNotification*)notification {
//    Node *node = (Node*)[notification object];
//    
//    NSString *name = [node name];
//    if(name) {
//        PGLog(@"Saving node: %@", node);
//        [_nodeNames setObject: name forKey: [NSNumber numberWithInt: [node entryID]]];
//    }
//}

- (void)reloadNodeData: (id)sender {
    if( ![[nodeTable window] isVisible] ) return;
    if(![playerController playerIsValid]) return;
    
    [_nodeDataList removeAllObjects];
    
    for(Node *node in _nodeList) {
        NSString *name = [node name];
        name = ((name && [name length]) ? name : @"Unknown");
        
        float distance = [[(PlayerDataController*)playerController position] distanceToPosition: [node position]];
        
        NSString *type = nil;
        int typeVal = [node nodeType];
        if( [_miningDict objectForKey: name])       type = @"Mining";
        if( [_herbalismDict objectForKey: name])    type = @"Herbalism";
        
        // first, do type filter
        if(self.nodeTypeFilter < 0) {
            // all              = -100
            // minerals         = -1
            // herbs            = -2
            // quest container  = -3
            // mine/herb        = -4
            // transport        = 11

            if((self.nodeTypeFilter == Filter_Minerals)     && ![type isEqualToString: @"Mining"])       continue;
            if((self.nodeTypeFilter == Filter_Herbs)        && ![type isEqualToString: @"Herbalism"])    continue;
            if((self.nodeTypeFilter == Filter_Mine_Herb)    && !type)                                   continue;
            if((self.nodeTypeFilter == Filter_Container_Quest)) {
                if((typeVal != 3) || (([node flags] & GAMEOBJECT_FLAG_CANT_TARGET) != GAMEOBJECT_FLAG_CANT_TARGET)) {
                    continue;   // must be a container, and flagged as quest
                }
            }
            
        } else {
            if(self.nodeTypeFilter == Filter_Transport) {
                if((typeVal != 11) || (typeVal != 15)) continue; // both types of transport
            } else {
                if(self.nodeTypeFilter != typeVal)
                    continue;
            }
        }
        
        // then, do string filter
        if(self.filterString) {
            if([[node name] rangeOfString: self.filterString options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location == NSNotFound) {
                continue;
            }
        }
        
        // get the string if we don't have it already
        if( !type)  type = [node stringForNodeType: typeVal];
        
        // invalid no longer working in 3.0.2
        name = ([node validToLoot] ? name : [name stringByAppendingString: @" [Invalid]"]);
        
        [_nodeDataList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                   node,                                                        @"Node",
                                   name,                                                        @"Name",
                                   [NSNumber numberWithInt: [node entryID]],                    @"ID",
                                   [NSString stringWithFormat: @"0x%X", [node baseAddress]],    @"Address",
                                   [NSNumber numberWithFloat: distance],                        @"Distance",
                                   type,                                                        @"Type",
                                   [node imageForNodeType: [node nodeType]],                    @"NameIcon",
                                   nil]];
    }

    [_nodeDataList sortUsingDescriptors: [nodeTable sortDescriptors]];
    [nodeTable reloadData];
}

#pragma mark Dataset Modification

- (void)addAddresses: (NSArray*)addresses {
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    NSMutableArray *dataList = _nodeList;
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(![memory isValid]) return;
    
    [self willChangeValueForKey: @"nodeCount"];

    // enumerate current object addresses
    // determine which objects need to be removed
    for(WoWObject *obj in dataList) {
        if([obj isValid] && [(Node*)obj validToLoot]) {
            [addressDict setObject: obj forKey: [NSNumber numberWithUnsignedLongLong: [obj baseAddress]]];
        } else {
            [objectsToRemove addObject: obj];
        }
    }
    
    // remove any if necessary
    if([objectsToRemove count]) {
        [dataList removeObjectsInArray: objectsToRemove];
        [_finishedNodes removeObjectsInArray: objectsToRemove];
    }

    // add new objects if they don't currently exist
    NSDate *now = [NSDate date];
    for(NSNumber *address in addresses) {
        if( ![addressDict objectForKey: address] ) {
            [dataList addObject: [Node nodeWithAddress: address inMemory: memory]];
        } else {
            [[addressDict objectForKey: address] setRefreshDate: now];
        }
    }
    
    [self didChangeValueForKey: @"nodeCount"];
}

/*- (BOOL)addNode: (Node*)newNode {
    if(newNode && ![self trackingNode: newNode] && [newNode isValid]) {
        
        // if(![self nodeName: newNode]) [newNode loadNodeName];
        
        [self willChangeValueForKey: @"nodeCount"];
        [_nodeList addObject: newNode];
        [self didChangeValueForKey: @"nodeCount"];
        //PGLog(@"Adding node: %@", newNode);
        return YES;
    }
    return NO;
}*/

- (unsigned)nodeCount {
    return [_nodeList count];
}

- (void)finishedNode: (Node*)node {
    if(node && ![_finishedNodes containsObject: node]) {
        [_finishedNodes addObject: node];
    }
}

- (void)resetAllNodes {
    [self willChangeValueForKey: @"nodeCount"];
    [_nodeList removeAllObjects];
    [_nodeDataList removeAllObjects];
    [self didChangeValueForKey: @"nodeCount"];
}

#pragma mark Internal

- (int)nodeLevel: (Node*)node {
    NSString *key = [node name];
    if([_herbalismDict objectForKey: key])
        return [[[_herbalismDict objectForKey: key] objectForKey: @"Skill"] intValue];
    if([_miningDict objectForKey: key])
        return [[[_miningDict objectForKey: key] objectForKey: @"Skill"] intValue];
    return 0;
}

//- (NSString*)nodeName: (Node*)node {
//    return [node name];
//
//    NSNumber *keyNum = [NSNumber numberWithInt: [node entryID]];
//    NSString *keyStr = [keyNum stringValue];
//    if([_herbalismDict objectForKey: keyStr])
//        return [[_herbalismDict objectForKey: keyStr] objectForKey: @"Name"];
//    if([_miningDict objectForKey: keyStr])
//        return [[_miningDict objectForKey: keyStr] objectForKey: @"Name"];
//    if([_fishingDict objectForKey: keyStr])
//        return [[_fishingDict objectForKey: keyStr] objectForKey: @"Name"];
//    if([_otherDict objectForKey: keyStr])
//        return [[_otherDict objectForKey: keyStr] objectForKey: @"Name"];
//        
//    if([_nodeNames objectForKey: keyNum])
//        return [_nodeNames objectForKey: keyNum];
//        
//    return nil;
//}


- (BOOL)trackingNode: (Node*)trackingNode {
    for(Node *node in _nodeList) {
        if( [node isEqualToObject: trackingNode] ) {
            return YES;
        }
    }
    return NO;
}

#pragma mark External Query

- (NSArray*)allFishingSchools{
	NSArray *nodeList = [[_nodeList copy] autorelease];
	NSMutableArray *nodes = [NSMutableArray array];
    
    for(Node *node in nodeList) {
		if ( [node nodeType] == GAMEOBJECT_TYPE_FISHINGHOLE ){
			[nodes addObject: node];
		}
    }
    
    return nodes;
}

- (NSArray*)allFishingBobbers{
	
	// Make a copy or we will run into some "Collection <NSCFArray: 0x13a0e0> was mutated while being enumerated." errors and crash
	//   Mainly b/c we access this from another thread
	NSArray *nodeList = [[_nodeList copy] autorelease];
	NSMutableArray *nodes = [NSMutableArray array];
    
	for(Node *node in nodeList) {
		if ( [node nodeType] == GAMEOBJECT_TYPE_FISHING_BOBBER ){
			[nodes addObject: node];
		}
	}
    
	return nodes;
}

- (NSArray*)allMiningNodes {
    NSMutableArray *nodes = [NSMutableArray array];
    
    for(Node *node in _nodeList) {
        if( [_miningDict objectForKey: [node name]])
            [nodes addObject: node];
    }
    
    return nodes;
}

- (NSArray*)allHerbalismNodes {
    NSMutableArray *nodes = [NSMutableArray array];
    
    for(Node *node in _nodeList) {
        if( [_herbalismDict objectForKey: [node name]])
            [nodes addObject: node];
    }
    
    return nodes;
}

- (NSArray*)nodesWithinDistance: (float)distance ofAbsoluteType: (GameObjectType)type {
    NSMutableArray *finalList = [NSMutableArray array];
    Position *playerPosition = [(PlayerDataController*)playerController position];
    for(Node* node in _nodeList) {
        if(   [node isValid]
           && [node validToLoot]
           && ([playerPosition distanceToPosition: [node position]] <= distance)
           && ([node nodeType] == type)) {
            [finalList addObject: node];
        }
    }
    return finalList;
}

- (NSArray*)nodesWithinDistance: (float)distance ofType: (NodeType)type maxLevel: (int)level {
    NSArray *nodeList = nil;
    NSMutableArray *finalList = [NSMutableArray array];
    if(type == AnyNode)         nodeList = _nodeList;
    if(type == MiningNode)      nodeList = [self allMiningNodes];
    if(type == HerbalismNode)   nodeList = [self allHerbalismNodes];
    
    Position *playerPosition = [(PlayerDataController*)playerController position];
    for(Node* node in nodeList) {
        if(   [node isValid]
           && [node validToLoot]
           && ([playerPosition distanceToPosition: [node position]] <= distance)
           && ([self nodeLevel: node] <= level)
           && ![_finishedNodes containsObject: node]) {
            [finalList addObject: node];
        }
    }
    return finalList;
}


#pragma mark Tableview Bullshit


- (void)tableView:(NSTableView *)aTableView  sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [_nodeDataList sortUsingDescriptors: [aTableView sortDescriptors]];
    [nodeTable reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_nodeDataList count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1) return nil;
    
    if([[aTableColumn identifier] isEqualToString: @"Distance"])
        return [NSString stringWithFormat: @"%.2f", [[[_nodeDataList objectAtIndex: rowIndex] objectForKey: @"Distance"] floatValue]];
    
    return [[_nodeDataList objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex
{
    if( aRowIndex == -1 || aRowIndex >= [_nodeDataList count]) return;

    if ([[aTableColumn identifier] isEqualToString: @"Name"]) {
        [(ImageAndTextCell*)aCell setImage: [[_nodeDataList objectAtIndex: aRowIndex] objectForKey: @"NameIcon"]];
    }
}

//- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
//    [nodeTable reloadData];
//}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (void)tableDoubleClick: (id)sender {
    if( [sender clickedRow] == -1 ) return;
    
    [memoryViewController showObjectMemory: [[_nodeDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Node"]];
    [controller showMemoryView];
}

#pragma mark IB Actions

- (IBAction)resetList: (id)sender {
    [self resetAllNodes];
    [nodeTable reloadData];
}

- (IBAction)filterNodes: (id)sender {
    if([[sender stringValue] length]) {
        self.filterString = [sender stringValue];
    } else {
        self.filterString = nil;
    }
    [self reloadNodeData: nil];
}

- (IBAction)faceNode: (id)sender {
    int selectedRow = [nodeTable selectedRow];
    if(selectedRow == -1) return;
    
    // !!!: remove this hack when 10.5.7 ships
    //[controller makeWoWFront];
    
    Node *node = [[_nodeDataList objectAtIndex: selectedRow] objectForKey: @"Node"];
    
    [movementController turnToward: [node position]];
}

- (IBAction)targetNode: (id)sender {

    int selectedRow = [nodeTable selectedRow];
    if(selectedRow == -1) return;
    
    Node *node = [[_nodeDataList objectAtIndex: selectedRow] objectForKey: @"Node"];
    
    [playerController setPrimaryTarget: [node GUID]];
}

- (IBAction)filterList: (id)sender {
    self.nodeTypeFilter = [sender selectedTag];
    [self reloadNodeData: nil];
}

- (IBAction)moveToStart: (id)sender {
    int tag = [moveToList selectedTag];
    if(tag <= 0) return;
    
    Node *nodeToMove = nil;
    
    if(tag == 1) {
        // move to selected node
        
        int selectedRow = [nodeTable selectedRow];
        if(selectedRow == -1) {
            NSBeep();
            return;
        }
        
        nodeToMove = [[_nodeDataList objectAtIndex: selectedRow] objectForKey: @"Node"];
    } else {
        // move to node of ID 'tag'
        
        // create a list of nodes with this tag
        NSMutableArray *nodeList = [NSMutableArray array];
        Position *playerPosition = [(PlayerDataController*)playerController position];
        for(Node *node in _nodeList) {
            if([node entryID] == tag) {
                
                float distance = [playerPosition distanceToPosition: [node position]];
                [nodeList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                      node,                                                 @"Node",
                                      [NSNumber numberWithFloat: distance],                 @"Distance", nil]];
            }
        }
        PGLog(@"Found %d nodes of type %d.", [nodeList count], tag);
        
        // sort the list by distance
        [nodeList sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"Distance" ascending: YES] autorelease]]];
        
        if([nodeList count]) {
            nodeToMove = [[nodeList objectAtIndex: 0] objectForKey: @"Node"];
        }
    }
    
    if(nodeToMove) {
        // !!!: remove this hack when 10.5.7 ships
        //[controller makeWoWFront];
        
        PGLog(@"Moving to node: %@", nodeToMove);
        [movementController moveToObject: nodeToMove andNotify: NO];
        //Position *nodePosition = [nodeToMove position];
        //[movementController moveToWaypoint: [Waypoint waypointWithPosition: nodePosition]];
    }
}

- (IBAction)moveToStop: (id)sender {
    [movementController setPatrolRoute: nil];
}

@end
