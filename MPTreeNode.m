//
//  MPTreeNode.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTreeNode.h"


@implementation MPTreeNode
@synthesize left, right, parent, balance, depth, value, content;


- (id) init {
	
	if ((self = [super init])) {
		
		self.left = nil;
		self.right = nil;
		self.parent = nil;
		balance = 0;
		depth = 0;
		leftDepth = 0;
		rightDepth = 0;
		value = 0;
		
		self.content = nil;
		
	}
	return self;
}


- (void) dealloc
{
/*
    [left autorelease];
	[right autorelease];
	[parent autorelease];
	[content autorelease];
*/
 
 
    [super dealloc];
}


#pragma mark -

- (void) addNode: (MPTreeNode *)node forValue: (float) nodeValue  {

	if ([self isEqual:nodeValue]) {
		
		// unexpected behavior for our application ... should only add unique values
		self.content = node.content;
		
	} else {
        
		// if givenValue is < MyValue
		if ([self isGreaterThan: nodeValue]) {
			
			if (left != nil) {
                
				[left addNode:node forValue:nodeValue];
				
			} else {
                
				self.left = node;
				[node setParent:self];
				
			}
			
			
			// now make sure depth calculations are correct:
//			leftDepth = [left depth] + 1;
            
            
		} else {
            
			if (right != nil) {
                
				[right addNode:node forValue:nodeValue];
				
			} else {
                
				self.right = node;
				[node setParent:self];
                
			}
			
//			rightDepth = [right depth] + 1;
            
		}
		
		[self refreshDepthAndBalance];
		
	}
	
}


- (MPTreeNode *)  nodeForValue: (float) searchValue {

	if ([self isEqual:searchValue]) {
		return self;
	}
	if ([self isGreaterThan:searchValue]) {
		if (left != nil) {
			return [left nodeForValue:searchValue];
		}
		return nil;
	} else {
		if (right != nil) {
			return [right nodeForValue:searchValue];
		}
		return nil;
	}
}


- (MPTreeNode *) largestNode {

	if (right != nil) {
		return [right largestNode];
	}
	
	return self;
}

- (MPTreeNode *) smallestNode {

	if (left != nil) {
		return [left smallestNode];
	}
	return self;
}


- (BOOL) isEqual: (float) givenValue {
	return (self.value == givenValue);
}


- (BOOL) isGreaterThan: (float) givenValue {
	return (self.value > givenValue);
}


- (BOOL) isLessThan: (float) givenValue {
	return (self.value < givenValue);
}


- (void) refreshDepthAndBalance {

	// make sure depth calculations are correct:
	leftDepth = 0;
	if (left != nil) {
		leftDepth = [left depth] + 1;
	}

	rightDepth = 0;
	if (right != nil) {
		rightDepth = [right depth] + 1;
	}
	
	self.depth = MAX( leftDepth, rightDepth);
	
	
	// update current Balance 
	self.balance = leftDepth - rightDepth;
}


- (void) refreshToRoot {

	/*
	[self refreshDepthAndBalance];
	if (self.parent != nil) {
		[parent refreshToRoot];
	}
	 */
	
	// non recursive way:
	MPTreeNode *refreshNode = self;
	while (refreshNode != nil) {
		[refreshNode refreshDepthAndBalance];
		refreshNode = [refreshNode parent];
	}
	
}

#pragma mark -
#pragma mark Debug 

- (void) debug: (NSString*) spacerString {

	PGLog( @"%@ %@  b:%d d:%d  L[%@] R[%@]  P[%@]", spacerString, content, balance, depth, [left content], [right content], [parent content] );
	NSMutableString *newSpacer = [NSMutableString stringWithFormat:@"     %@", spacerString];
	[left debug: newSpacer];
	[right debug: newSpacer];
}

#pragma mark -
#pragma mark Convienience Methods

+ (id) nodeWithObject: (id) object forValue:(float)objectValue {
	MPTreeNode *newNode = [[[MPTreeNode alloc] init] autorelease];
	[newNode setContent:object];
	[newNode setValue:objectValue];
	
	return newNode;
	
}

@end
