//
//  MPNavigationController.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPNavMeshView;
@class MPPoint;
@class MPSquare;
@class MPLocation;
@class MPPointTree;
@class MPSquareTree;
@class Route;
@class MPPathNode;


@interface MPNavigationController : NSObject {
//	NSMutableArray *allSquares;
	MPSquareTree *allSquares;
//	NSMutableArray *allPoints;
	MPPointTree *allPoints;

	MPSquare *previousSquare;
	float squareWidth;
	float toleranceZ; // the z tolerance for graph considerations
	MPPathNode *currentPath;
}
@property (retain) MPSquareTree *allSquares; 
@property (retain) MPPointTree *allPoints;
@property (retain) MPSquare *previousSquare;
@property (readwrite) float toleranceZ;
@property (readonly) float squareWidth;
@property (retain) MPPathNode *currentPath;

/*!
 * @function listSquaresInView
 * @abstract Returns a list of MPSquares that will appear in the given navMeshView
 * @discussion
 *	
 */
- (NSArray *) listSquaresInView: (MPNavMeshView *) navMeshView aroundLocation: (MPLocation *)playerPosition ;


/*!
 * @function squareContainingLocation
 * @abstract Returns the MPSquare that contains the given location
 * @discussion
 *	If no square is found, then nil is returned.
 */
- (MPSquare *) squareContainingLocation: (MPLocation *) aLocation;

- (void) resetSquareDisplay;

/*!
 * @function pointAtLocation
 * @abstract Returns the MPPoint that is at the given location
 * @discussion
 *	NOTE: this returns a match at the same x,y location.  if there are numerous
 *  points with this x,y then the one with the closest Z location is returned. if none
 *  are found, then return nil.
 */
- (MPPoint *) pointAtLocation: (MPLocation *) aLocation withinZTolerance: (float) zTolerance;
- (MPPoint *) findOrCreatePointAtLocation: (MPLocation *) aLocation withinZTolerance: (float) zTolerance;

/*!
 * @function updateMeshAtLocation
 * @abstract Updates the MPSquare at aLocation to be traversible.
 * @discussion
 *	If no square is found, then a new MPSquare is created that contains aLocation, and it
 *  will be marked traversible.
 */
- (void) updateMeshAtLocation: (MPLocation*)aLocation isTraversible:(BOOL)canTraverse;

#pragma mark -
#pragma mark Navigation and Routing

/*!
 * @function routeToLocation
 * @abstract Generates a Route from our current location to the given location
 */
- (Route *) routeFromLocation: (MPLocation*)startLocation toLocation: (MPLocation*)destLocation;


- (MPPathNode *) pathFromSquare: (MPSquare *)currentSquare toLocation:(MPLocation *)destLocation;
- (MPPathNode *) lowestCostNodeInArray:(NSMutableArray*) anArray;
- (BOOL ) isSquare: (MPSquare *)aSquare inNodeList: (NSArray*) nodeList;
- (MPPathNode *) nodeWithSquare: (MPSquare *)aSquare fromNodeList: (NSArray *) nodeList;


- (int) costFromNode: (MPPathNode *) currentNode  toNode:(MPPathNode *)aNode;
- (int) costFromNode: (MPPathNode *)currentNode  toLocation:(MPLocation *) location ;

- (void) updateRouteDisplay: (MPPathNode *)aNode;
- (NSMutableArray *) listLocationsFromPathNode:pathNode;
- (NSMutableArray *) reduceLocations: (NSMutableArray *)listAllLocations;

@end
