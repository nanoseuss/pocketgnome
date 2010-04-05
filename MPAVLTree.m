//
//  MPAVLTree.m
//  Pocket Gnome
//
//  Created by admin on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPAVLTree.h"
#import "MPTreeNode.h"



@interface MPAVLTree (Internal)


- (void) leftRotateAtNode: (MPTreeNode *)rootNode;
- (void) rightRotateAtNode: (MPTreeNode *) rootNode;

@end

@implementation MPAVLTree
@synthesize root;


- (id) init {

	if ((self = [super init])) {
		
		self.root = nil;
	}
	return self;
}


- (void) dealloc
{
    [root autorelease];
	
    [super dealloc];
}


#pragma mark -



- (void) addObject: (id) object withValue: (float) value {
	
	MPTreeNode *objectNode = [MPTreeNode nodeWithObject: object forValue:value];
	
	if (root == nil) {
		self.root = objectNode;
	} else {
		[root addNode:objectNode forValue:value];
		[self balanceTreeStartingAtNode:objectNode];
	}
	
}




- (void) removeObjectWithValue:(float)value {

	MPTreeNode *removeNode = [root nodeForValue:value];
	
	MPTreeNode *rebalanceNode = nil;
        
        // if node found
        if (removeNode != nil) {
        
        
            // if node is a leaf, delete it.
            if ( (removeNode.left == nil) && (removeNode.right == nil)) {
                
                // mark node's parent for rebalanceing
                rebalanceNode = removeNode.parent;
                MPTreeNode *removeParent = removeNode.parent;
				if (removeParent != nil) {
					if ( removeParent.left == rebalanceNode) {
						removeParent.left = nil;
					} else {
						removeParent.right = nil;
					}
				}
				
				if (removeNode == root) {
					self.root = nil;
				}
                
            } else {
            
            
				// if node has left sub tree
				if (removeNode.left != nil) {
				
					// get largestNode from left subTree
					MPTreeNode *previousNode = [removeNode.left largestNode];
					
					// mark node's parent for rebalancing
					rebalanceNode = previousNode.parent;
					
					//// replace node with largestSubNode (ie, no right sub node)
					// remove previousNode from tree
					MPTreeNode *previousParent = previousNode.parent;
					if (previousParent != removeNode) {
						previousParent.right = previousNode.left;
						if (previousNode.left != nil) {
							previousNode.left.parent = previousParent;
						}
					}
					
					// attach previousNode to removeNode's location
					MPTreeNode *removeParent = removeNode.parent;
					if (removeParent.left == removeNode) {
					
						removeParent.left = previousNode;
					} else {
						removeParent.right = previousNode;
					}
					previousNode.parent = removeParent;
					
					// attach any sub nodes from removeNode to previousNode
					if (removeNode.left != previousNode) {
						previousNode.left = removeNode.left;
						if (removeNode.left != nil) {
							removeNode.left.parent = previousNode;
						}
					} else {
						previousNode.left = nil;
					}
					
					if (removeNode.right != previousNode) {
						previousNode.right = removeNode.right;
						if (removeNode.right != nil) {
							removeNode.right.parent = previousNode;
						}
					} else {
						previousNode.right = nil;
					}
					
					if ( root == removeNode) {
						self.root = previousNode;
					}
					
					
				} else {
				
					// get smallestNode from right subTree
					MPTreeNode *nextNode = [removeNode.right smallestNode];
					
					
					// mark node's parent for rebalancing
					rebalanceNode = nextNode.parent;
					if (rebalanceNode == removeNode) {
						rebalanceNode = removeNode.parent;
					}
					
			
					//// replace node with smallestNode
					// remove nextNode from tree
					MPTreeNode *nextParent = nextNode.parent;
					if (nextParent != removeNode) {
						nextParent.left = nextNode.right;
						if (nextNode.right != nil) {
							nextNode.right.parent = nextParent;
						}
					}
					
					// attach nextNode to removeNode's location
					MPTreeNode *removeParent = removeNode.parent;
					if (removeParent.right == removeNode) {
					
						removeParent.right = nextNode;
					} else {
						removeParent.left = nextNode;
					}
					nextNode.parent = removeParent;
					
					// attach any sub nodes from removeNode to previousNode
					if (removeNode.left != nextNode) {
						nextNode.left = removeNode.left;
						if (removeNode.left != nil) {
							removeNode.left.parent = nextNode;
						}
					} else {
						nextNode.left = nil;
					}
					
					if (removeNode.right != nextNode) {
						nextNode.right = removeNode.right;
						if (removeNode.right != nil) {
							removeNode.right.parent = nextNode;
						}
					} else {
						nextNode.right = nil;
					}
					
					if ( root == removeNode) {
						self.root = nextNode;
					}
	 
				}
            
			}
            
            // rebalance starting with rebalanceNode
			[rebalanceNode refreshToRoot];
            [self balanceTreeStartingAtNode: rebalanceNode];
        
/*
 * should I do this?
 *
			removeNode.left = nil;
			removeNode.right = nil;
			removeNode.parent = nil;
            [removeNode release];
 * when I try it gives me a BAD_ACCESS error.
 */
        }
	
	
}



- (id) objectForValue: (float) value {
	
	MPTreeNode *nodeWithValue = [root nodeForValue: value];
	if (nodeWithValue != nil) {
		return [nodeWithValue content];
	}
	return nil;
}



#pragma mark -
#pragma mark TreeBalancing 

- (void) balanceTreeStartingAtNode:(MPTreeNode *)currentNode {

	NSInteger currentBalance, rightBalance, leftBalance;
	
   while (currentNode != nil) {
	
		// if this node is out of balance
		currentBalance = [currentNode balance];
		if ((currentBalance < -1) || (currentBalance > 1)) {
		
			if (currentBalance < -1) {
				// Right Sub Tree is out of balance
				
				rightBalance = [[currentNode right] balance];
				if (rightBalance == -1) {
				
					// Left Rotation needed
					[self leftRotateAtNode:currentNode];
					
				} else {
				
					// double Left Rotation needed
					[self rightRotateAtNode: currentNode.right];
					[self leftRotateAtNode: currentNode];
				}
				
			} else {
				// Left Sub Tree is out of balance
			
				leftBalance = [[currentNode left] balance];
				if (leftBalance == 1) {
				
					// Right Rotation needed
					[self rightRotateAtNode:currentNode];
					
				} else {
				
					// double Right Rotation needed
					[self leftRotateAtNode: currentNode.left];
					[self rightRotateAtNode: currentNode];

				}
			}
		
			// after adjustment, balanceCheckNode is now in a sub node.
			// correct to proper level
			currentNode = [currentNode parent];
			
			// now update node balances up to root after rotations:
			[currentNode refreshToRoot];
			
		} //end if out of balance
		
		// now proceed on to parent
		currentNode = [currentNode parent];
		
	} // end while

}


- (void) leftRotateAtNode:(MPTreeNode *)rootNode {
	
	MPTreeNode *pivot = rootNode.right;
	MPTreeNode *rootParent = rootNode.parent;
        
	if (rootParent != nil) {
		if (rootParent.left == rootNode) {
			rootParent.left = pivot;
		} else {
			rootParent.right = pivot;
		}
	}
	[pivot setParent: rootParent];
	[rootNode setRight: pivot.left];
	[pivot.left setParent: rootNode];
	
	[pivot setLeft: rootNode];
	[rootNode setParent: pivot];

	[rootNode refreshDepthAndBalance];
	[pivot refreshDepthAndBalance];
	
	// make sure our root node is updated properly
	if (root == rootNode) {
		self.root = pivot;
	}
	
}

- (void) rightRotateAtNode:(MPTreeNode *)rootNode {

	MPTreeNode *pivot = rootNode.left;
	MPTreeNode *rootParent = rootNode.parent;

	if (rootParent != nil) {
	if (rootParent.left == rootNode) {
		rootParent.left = pivot;
	} else {
		rootParent.right = pivot;
	}
	}
	[pivot setParent: rootParent];

	[rootNode setLeft: pivot.right];
	[pivot.right setParent: rootNode];
	
	[pivot setRight: rootNode];
	[rootNode setParent: pivot];

	[rootNode refreshDepthAndBalance];
	[pivot refreshDepthAndBalance];
	
	// make sure our root node is updated properly
	if (root == rootNode) {
		self.root = pivot;
	}
}

#pragma mark -
#pragma mark debug

- (void) dump{

	PGLog (@"----------------------------");
	[root debug: @"" ];
	PGLog (@"----------------------------");
	
}

#pragma mark -
#pragma mark Convienience Methods

+ (id) tree {
	return [[[MPAVLTree alloc] init] autorelease];
}

@end
