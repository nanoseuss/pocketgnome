//
//  MPAVLTree.h
//  Pocket Gnome
//
//  Created by admin on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPTreeNode;

@interface MPAVLTree : NSObject {
	MPTreeNode *root;
	
}
@property (retain) MPTreeNode *root;

- (void) addObject: (id) object withValue: (float) value;
- (void) removeObjectWithValue: (float) value;
- (id) objectForValue: (float) value;


- (void) balanceTreeStartingAtNode: (MPTreeNode*) currentNode;

// print out a description of the tree in the consol log
- (void) dump;


+ (id) tree;

@end
