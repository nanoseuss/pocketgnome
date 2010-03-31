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
#import "Node.h"
#import "ObjectController.h"

@class PlayerDataController;
@class ObjectsController;

typedef enum {
    AnyNode = 0,
    MiningNode = 1,
    HerbalismNode = 2,
	FishingSchool = 3,
} NodeType;

@interface NodeController : ObjectController {
    IBOutlet id botController;
    IBOutlet id movementController;
    IBOutlet id memoryViewController;
	IBOutlet ObjectsController	*objectsController;
    
    IBOutlet NSPopUpButton *moveToList;

    NSMutableArray *_finishedNodes;
    
    // NSMutableDictionary *_nodeNames;

    NSDictionary *_miningDict;
    NSDictionary *_herbalismDict;
	
    int _nodeTypeFilter;
}

- (unsigned)nodeCount;

- (NSArray*)nodesOfType:(UInt32)nodeType shouldLock:(BOOL)lock;
- (NSArray*)allMiningNodes;
- (NSArray*)allHerbalismNodes;
- (NSArray*)nodesWithinDistance: (float)distance ofAbsoluteType: (GameObjectType)type;
- (NSArray*)nodesWithinDistance: (float)distance ofType: (NodeType)type maxLevel: (int)level;
- (NSArray*)nodesWithinDistance: (float)nodeDistance NodeIDs: (NSArray*)nodeIDs position:(Position*)position;
- (NSArray*)nodesWithinDistance: (float)nodeDistance EntryID: (int)entryID position:(Position*)position;
- (Node*)closestNode:(UInt32)entryID;
- (Node*)closestNodeForInteraction:(UInt32)entryID;
- (Node*)nodeWithEntryID:(UInt32)entryID;

- (NSArray*)uniqueNodesAlphabetized;
- (Node*)closestNodeWithName:(NSString*)nodeName;
/*
- (IBAction)filterNodes: (id)sender;
- (IBAction)resetList: (id)sender;
- (IBAction)faceNode: (id)sender;
- (IBAction)targetNode: (id)sender;
- (IBAction)filterList: (id)sender;

- (IBAction)moveToStart: (id)sender;
- (IBAction)moveToStop: (id)sender;*/

@end
