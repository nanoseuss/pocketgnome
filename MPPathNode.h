//
//  MPPathNode.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPSquare;
@class MPPoint;
@class MPLocation;



@interface MPPathNode : NSObject {

	int costG, costH;
	MPPathNode *parent;
	MPSquare *square;
	MPPoint *referencePoint;
}
@property (readwrite) int costG, costH;
@property (retain) MPPathNode *parent;
@property (retain) MPSquare *square;
@property (retain) MPPoint *referencePoint;



- (void) setReferencePointTowardsLocation: (MPLocation *) aLocation;

- (int) cost;



+(id)node;
+(id)nodeWithSquare: (MPSquare *)aSquare;

@end
