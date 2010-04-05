//
//  MPNavigationController.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPNavigationController.h"
#import "MPNavMeshView.h"
#import "MPLocation.h"
#import "Position.h"
#import "MPSquare.h"
#import "MPPoint.h"
#import "MPPointTree.h"
#import "MPSquareTree.h"
#import "Route.h"
#import "MPPathNode.h"



@interface MPNavigationController (Internal)

- (MPSquare *) findOrCreateSquareContainingLocation: (MPLocation *)aLocation;
- (MPSquare *) newSquareContainingLocation: (MPLocation *) aLocation;

@end


@implementation MPNavigationController
@synthesize allSquares, allPoints, previousSquare, toleranceZ, squareWidth, currentPath;




-(id) init {
	
	if ((self = [super init])) {
//		self.allSquares = [NSMutableArray array];
//		self.allPoints = [NSMutableArray array];
		
		self.previousSquare = nil;
		
		squareWidth = 2.0;  // minimum square width
		toleranceZ = 10.5f;
		self.allPoints = [MPPointTree treeWithZTolerance:toleranceZ];
		self.allSquares = [MPSquareTree treeWithSquareWidth:squareWidth ZTolerance:toleranceZ];
		self.currentPath = nil;
	}
	return self;
}



- (void) dealloc
{
    [allSquares autorelease];
    [allPoints autorelease];
	[previousSquare autorelease];
	
    [super dealloc];
}


#pragma mark -



- (NSArray *) listSquaresInView: (MPNavMeshView *) navMeshView aroundLocation: (MPLocation *)playerPosition {
	
	[[allSquares lock] lock];
	NSArray *listSquares = [[allSquares listSquares] copy];
	[[allSquares lock] unlock];
	
	
	return listSquares;
	
	
	//	return [allSquares listSquares];
	
/*	
	NSMutableArray *listSquares = [NSMutableArray array];
	int numSlices = [navMeshView scaleSetting];
	
	
	float baseX, baseY, halfDistance, posX, posY;
	halfDistance = ((numSlices * squareWidth) /2 );
	baseX = [playerPosition xPosition] - halfDistance;
	baseY = [playerPosition yPosition] - halfDistance;
	
	int indexY, indexX;
	MPSquare *currentSquare, *prevSquare;
	prevSquare = nil;
	
	
	for (indexX = 0; indexX < numSlices; indexX++) {
		posX = baseX + (indexX * squareWidth);
		for (indexY=0; indexY < numSlices; indexY++ ) {
		
			posY = baseY + (indexY * squareWidth);
			
			currentSquare = [allSquares squareAtX:posX Y:posY Z:[playerPosition zPosition]];
			
			if (currentSquare != nil) {
			
				if (currentSquare != prevSquare) {
					
					if (![listSquares containsObject:currentSquare]) {
					
						[listSquares addObject:currentSquare];
					}
				
					prevSquare = currentSquare;
				}
			}
		}
		
	}
	
	
	return listSquares;
*/	
	

	
	/*
	 * Perhaps this isn't all that necessary ...
	 * 
	NSMutableArray *listSquares = [NSMutableArray array];

	// find current square containing position
	MPSquare *playerSquare = [self findOrCreateSquareContainingLocation:playerPosition];
	
	// get rect that should represent our view (translated and Scaled)
	float viewRectX, viewRectY, viewRectWidth, viewRectHeight;
	float halfWidth;
	
	viewRectHeight = ([navMeshView scaleSetting] * squareWidth);
	viewRectWidth  = (viewRectHeight * ( [navMeshView viewWidth] / [navMeshView viewHeight] ));  // since the viewRect isn't actually square ... 
	halfWidth = viewRectHeight/2;
	
	viewRectX = [playerPosition xPosition] - halfWidth;
	viewRectY = [playerPosition yPosition] - halfWidth;
	
	NSRect viewRect = NSMakeRect( viewRectX, viewRectY, viewRectWidth, viewRectHeight);
	
	
	// if (NSIntersectsRect(viewRect, square.rect))
	if ( NSIntersectsRect(viewRect, [playerSquare nsrect])) {
	
		// add square to list
		[listSquares addObject:playerSquare];
		
		[playerSquare compileAdjacentSquaresThatIntersectRect: viewRect  intoList: listSquares];
		
	}
	
	
	// return list
	return listSquares;
	
//	return allSquares;

	*/
	
}



- (MPSquare *) squareContainingLocation: (MPLocation *) aLocation {
	
	return [allSquares squareAtLocation:aLocation];
	/*
	NSArray *copySquares = [allSquares copy]; // prevents threading problem
	for( MPSquare *square in copySquares) {
		if ([square containsLocation:aLocation]) {
			return square;
		}
	}
	return nil;
	 */
}



- (MPSquare *) findOrCreateSquareContainingLocation: (MPLocation *)aLocation {

	// updatedSquare = nil
	MPSquare *updatedSquare = nil;
	
	
	// ok, scanning the whole list of squares can get time consuming on large meshes ...
	// lets see if we can reduce our overhead by :
	
	
	//// checking the last square we worked with:
	// if previousSquare contains location
	if (previousSquare != nil) {
		if ([previousSquare containsLocation:aLocation]) {
			updatedSquare = previousSquare;
		}
		
		//// checking an adjacent square from the last one we worked with:
		// if updatedSquare == nil
// (OK, now that we use AVL trees ... just go find the square)
//		if (updatedSquare == nil) {
//			updatedSquare = [previousSquare adjacentSquareContainingLocation: aLocation];
//		}
		
	}
	
	
	
	
	//// ok, fine: check the whole graph then:
	// if updatedSquare == nil
	if (updatedSquare == nil) {
		updatedSquare = [self squareContainingLocation: aLocation];
	}
	
	
	//// still no?  must be a new location!
	// if updatedSquare == nil
	if (updatedSquare == nil) {
		updatedSquare = [self newSquareContainingLocation: aLocation];
	}
	
	return updatedSquare;
	
}


- (void) updateMeshAtLocation: (MPLocation*)aLocation isTraversible:(BOOL)canTraverse {
	

	MPSquare *updatedSquare = [self findOrCreateSquareContainingLocation:aLocation];
	
	// if updatedSquare != nil
	if (updatedSquare != nil) {
		
		// updatedSquare isTraversible:canTraverse
		[updatedSquare setIsTraversible:canTraverse];
		
		// previousSquare = updatedSquare
		self.previousSquare = updatedSquare;
		
	} // end if
	
}


- (void) resetSquareDisplay {
	PGLog(@"Resetting Square Displays ... ");
	/*
	for( MPSquare *square in allSquares) {
		square.myDrawRect = nil;
	}
	 */
}



- (MPSquare *) newSquareContainingLocation: (MPLocation *) aLocation {
	
	
	// ok get the surrounding points for this location:
	float locX, locY, locZ;
	locX = [aLocation xPosition];
	locY = [aLocation yPosition];
	locZ = [aLocation zPosition];
	
	float lowerX, upperX, lowerY, upperY, nextVal;
	nextVal = (locX >=0)? 1.0f: -1.0f;
	if ( locX >= 0 ) {
	
		lowerX = ( (int) (locX / squareWidth) * squareWidth);
		upperX = lowerX + (nextVal * squareWidth);
		
	} else {
		upperX = ( (int) (locX / squareWidth) * squareWidth);
		lowerX = upperX + (nextVal * squareWidth);
	}
	
	nextVal = (locY >=0)? 1.0f: -1.0f;
	if (locY >= 0) {
		lowerY = ( (int)(locY / squareWidth) * squareWidth);
		upperY = lowerY + (nextVal * squareWidth);
	} else {
		upperY = ( (int)(locY / squareWidth) * squareWidth);
		lowerY = upperY + (nextVal * squareWidth);
	}
	
	NSMutableArray *pointList = [NSMutableArray array];
	
	
	//// The order here is important:
	////   0  --  3    0(lowerX,upperY),   3(upperX, upperY)
	////   |      |
	////   1  --  2    1(lowerX,lowerY),   2(upperX, lowerY)
	////
	
	
	// Point 0:  
	MPLocation *location0 = [MPLocation locationAtX:lowerX Y:upperY Z:locZ];
	MPPoint *point0 = [self findOrCreatePointAtLocation: location0 withinZTolerance: toleranceZ];
	[pointList addObject:point0];
	
	// Point 1:  
	MPLocation *location1 = [MPLocation locationAtX:lowerX Y:lowerY Z:locZ];
	MPPoint *point1 = [self findOrCreatePointAtLocation: location1 withinZTolerance: toleranceZ];
	[pointList addObject:point1];
	
	// Point 2:  
	MPLocation *location2 = [MPLocation locationAtX:upperX Y:lowerY Z:locZ];
	MPPoint *point2 = [self findOrCreatePointAtLocation: location2 withinZTolerance: toleranceZ];
	[pointList addObject:point2];
	
	// Point 3:  
	MPLocation *location3 = [MPLocation locationAtX:upperX Y:upperY Z:locZ];
	MPPoint *point3 = [self findOrCreatePointAtLocation: location3 withinZTolerance: toleranceZ];
	[pointList addObject:point3];
	
	
	MPSquare *newSquare = [MPSquare squareWithPoints:pointList];
	
	
	// the [MPSquare squareWithPoints] did some initial border checks based upon existing
	// point assignments.
	// but now we need to do more extensive checks based upon squares containing my points
	
	//// NOTE: don't have to worry about existing square returning from [squareContaintingLocation] because
	//// it hasn't been added to our list yet.
	
	MPSquare *possibleBorder = nil;
	
	// if topBorder is empty
	if (([newSquare.topBorderConnections count] == 0) || ([newSquare.leftBorderConnections count] == 0)) {
	
		// possibleBorder = self squareContainingLocation: [newSquare point0].location
		possibleBorder = [self squareContainingLocation:[[newSquare pointAtPosition:0] location]];
		
		// if (possibleBorder != nil)
		if (possibleBorder != nil) {
		
		
			// if possibleBorder containsLocation [newSquare point3].location
			if ([possibleBorder containsLocation:[[newSquare pointAtPosition:3] location]]) {
			
				// newSquare addTopBorder possibleBorder
				[newSquare addTopBorderConnection: possibleBorder];
				[possibleBorder addBottomBorderConnection:newSquare];
			}
			
			// if possibleBorder containsLocation [newSquare point1].location
			if ([possibleBorder containsLocation:[[newSquare pointAtPosition:1] location]]) {
			
				// newSquare addLeftBorder possibleBorder
				[newSquare addLeftBorderConnection: possibleBorder];
				[possibleBorder addRightBorderConnection:newSquare];
			}
			
		}
	}
	
	// if botomBorder is empty
	if (([newSquare.bottomBorderConnections count] == 0) || ([newSquare.rightBorderConnections count] == 0)) {
	
		// possibleBorder = self squareContainingLocation: [newSquare point2].location
		possibleBorder = [self squareContainingLocation:[[newSquare pointAtPosition:2] location]];
		
		// if (possibleBorder != nil)
		if (possibleBorder != nil) {
		
		
			// if possibleBorder containsLocation [newSquare point1].location
			if ([possibleBorder containsLocation:[[newSquare pointAtPosition:1] location]]) {
			
				// newSquare addBottomBorder possibleBorder
				[newSquare addBottomBorderConnection: possibleBorder];
				[possibleBorder addTopBorderConnection:newSquare];
			}
			
			// if possibleBorder containsLocation [newSquare point3].location
			if ([possibleBorder containsLocation:[[newSquare pointAtPosition:3] location]]) {
			
				// newSquare addRightBorder possibleBorder
				[newSquare addRightBorderConnection: possibleBorder];
				[possibleBorder addLeftBorderConnection:newSquare];
			}
			
		}
	}


	//// Now we have a new Square fully connected to our Graph (right?)
	//// so add to our list of squares :
	[allSquares addSquare: newSquare];
	
	
	return newSquare;
	
	
}

// if it can't find an existing point, then create a new one
- (MPPoint *) findOrCreatePointAtLocation: (MPLocation *) aLocation withinZTolerance: (float) zTolerance {
	
	MPPoint *point = [self pointAtLocation:aLocation withinZTolerance: zTolerance];
	
	if (point == nil) {
	
		point = [MPPoint pointAtX:[aLocation xPosition] Y:[aLocation yPosition] Z:[aLocation zPosition]];
		
		// add this point to our list of points
//		[allPoints addObject:point];
		[allPoints addPoint:point];
	}
	return point;
}

- (MPPoint *) pointAtLocation: (MPLocation *) aLocation withinZTolerance: (float) zTolerance {
	
	/*
	NSMutableArray *listPoints = [NSMutableArray array];
	NSArray *copyPoints = [allPoints copy]; // prevents Threading Problems
	for (MPPoint* point in copyPoints ) {
		if ([point isAt:aLocation withinZTolerance:zTolerance] ) {
			[listPoints addObject:point];
		}
	}
	
	float currentDistance = 0.0f;
	float selectedDistance = INFINITY;
	MPPoint *selectedPoint = nil;
	for( MPPoint *point in listPoints) {
		currentDistance = [point zDistanceTo:aLocation];
		if (currentDistance < selectedDistance) {
			selectedDistance = currentDistance;
			selectedPoint = point;
		}
	}
	
	return selectedPoint;
	*/
	return [allPoints pointAtX:[aLocation xPosition] Y:[aLocation yPosition] Z:[aLocation zPosition]];
}


#pragma mark -
#pragma mark Navigation and Routing


- (Route *) routeFromLocation: (MPLocation*)startLocation toLocation: (MPLocation*)destLocation {
	
	Route *newRoute = [Route route];
	
	
	// find square with current location
	MPSquare *currentSquare = [allSquares squareAtX:[startLocation xPosition] Y:[startLocation yPosition] Z:[startLocation zPosition]];
	
	if (currentSquare != nil) {
		
		// use A* Routing to find series of squares from here to given destLocation
		MPPathNode * pathNode = [self pathFromSquare:currentSquare toLocation:destLocation];
		
		[self updateRouteDisplay:pathNode];
		
		// create list of points in mid-point of square edges
		NSMutableArray *listAllLocations = [self listLocationsFromPathNode:pathNode];
		[listAllLocations insertObject:startLocation atIndex:0];
		[listAllLocations addObject:destLocation]; // add destination location at end
		
		
		// optimize the points (remove unnecessary)
		NSMutableArray *listLocations = [self reduceLocations:listAllLocations];
		
		// convert remaining points into waypoints and insert into newRoute
		for( MPLocation *location in listLocations) {
			[newRoute addWaypoint:[Waypoint waypointWithPosition:location]];
		}
	}
	
	return newRoute;
	
}


- (MPPathNode *) pathFromSquare: (MPSquare *)currentSquare toLocation:(MPLocation *)destLocation {
	
	NSMutableArray *openList, *closedList;
	openList = [NSMutableArray array];
	closedList = [NSMutableArray array];
	
	MPPathNode *currentNode = nil;
	MPPathNode *aNode = nil;
	MPPathNode *startNode = [MPPathNode nodeWithSquare:currentSquare];
	[startNode setReferencePointTowardsLocation:destLocation];
	
	[startNode setCostG: 0 ];
	[startNode setCostH: 0 ];
	
	[openList addObject:startNode];
	
	while( [openList count] ) {
		
		currentNode = [self lowestCostNodeInArray:openList];
		if ( [[currentNode square] containsLocation:destLocation] ) {
			
			//// Path Found
			return currentNode;
			
			
		} else {
			
			[closedList addObject:currentNode];
			[openList removeObject:currentNode];
			
			NSArray *adjacentSquares = [[currentNode square] adjacentSquares];
			
			for (MPSquare *square in adjacentSquares ) {
				
				if ([square isTraversible] ) {
			
					if (![self isSquare:square inNodeList:closedList]) {
						
						
						aNode = [self nodeWithSquare: square fromNodeList: openList];
						if (aNode == nil) {
							
							aNode = [MPPathNode nodeWithSquare:square];
							[aNode setParent:currentNode];
							[aNode setReferencePointTowardsLocation: destLocation];
							
							int costH = [self costFromNode: aNode toLocation:destLocation];
							[aNode setCostH: costH];
							[openList addObject:aNode];
						}
						
						
						int costG = [currentNode costG] + [self costFromNode:currentNode  toNode:aNode];
						
					
						if ([aNode costG] != 0) {
						
							if ([aNode costG] > costG) {
								
								[aNode setCostG: costG];
								[aNode setParent:currentNode];
							}
							
						} else {
							[aNode setCostG:costG];
						}
					
					
					}
				}
			}
			
		}
		
	}
	
	return currentNode;
}


- (MPPathNode *) lowestCostNodeInArray:(NSMutableArray*) anArray {
	//Finds the node in a given array which has the lowest cost
	MPPathNode *n, *lowest;
	lowest = nil;
	NSEnumerator *e = [anArray objectEnumerator];
	if(e)
	{
		while((n = [e nextObject]))
		{
			if(lowest == nil)
			{
				lowest = n;
			}
			else
			{
				if(n.cost < lowest.cost)
				{
					lowest = n;
				}
			}
		}
		return lowest;
	}
	return nil;
}
					


- (BOOL ) isSquare: (MPSquare *)aSquare inNodeList: (NSArray*) nodeList {
	
	MPPathNode *node;
		
	NSEnumerator *e = [nodeList objectEnumerator];
	if(e)
	{
		while((node = [e nextObject]))
		{
			if (aSquare == [node square]) {
				return YES;
			}
		}
	}
	return NO;
}
						
						
- (MPPathNode *) nodeWithSquare: (MPSquare *)aSquare fromNodeList: (NSArray *) nodeList {
	MPPathNode *node;
	
	NSEnumerator *e = [nodeList objectEnumerator];
	if(e)
	{
		while((node = [e nextObject]))
		{
			if (aSquare == [node square]) {
				return node;
			}
		}
	}
	return nil;
}

					
- (int) costFromNode: (MPPathNode *) currentNode  toNode:(MPPathNode *)aNode {
	
	return [self costFromNode:currentNode toLocation: [[aNode referencePoint] location]];
}



- (int) costFromNode: (MPPathNode *)currentNode  toLocation:(MPLocation *) location {
		
	// for now just do raw distance.  I'm sure there is a better way 
	float rawDistance = [[[currentNode referencePoint] location] distanceToPosition:location];
	int distance = (int) (rawDistance * 10.0);
	return distance;
}


- (void) updateRouteDisplay: (MPPathNode *)aNode {
	
	MPPathNode *currentNode = self.currentPath;
	
	// erase the previous path settings
	while (currentNode != nil) {
		[[currentNode square] setOnPath:NO];
		currentNode = [currentNode parent];
	}
	
	// now mark current path settings
	currentNode = aNode;
	while (currentNode != nil) {
		[[currentNode square] setOnPath:YES];
		currentNode = [currentNode parent];
	}
	
	self.currentPath = aNode;
}



- (NSMutableArray *) listLocationsFromPathNode:pathNode {
	
	NSMutableArray *listLocations = [NSMutableArray array];
	
	MPPathNode *current, *next;
	current = pathNode;
	next = [current parent];
	
	MPSquare *currentSquare, *nextSquare;
	
	MPLocation *intersectionLocation = nil;
	
	while (next != nil) {
		
		currentSquare = [current square];
		nextSquare = [next square];
		
		intersectionLocation = [currentSquare locationOfIntersectionWithSquare:nextSquare];
		
		[listLocations insertObject:intersectionLocation atIndex:0];
		
		current = next;
		next = [current parent];
	}
	
	return listLocations;
}

- (NSMutableArray *) reduceLocations: (NSMutableArray *)listAllLocations {
	
	int locationA, locationB, locationC;
	
	NSMutableArray *locations = [NSMutableArray array];
	
	locationC = [listAllLocations count] -1;
	locationB = locationC -1;
	locationA = locationB -1;
	
	[locations addObject:[listAllLocations lastObject]];
	
	MPSquare *startSquare = nil;
	MPLocation *startLocation, *endLocation;
	
	while (locationA >= 0) {
	
		startLocation = [listAllLocations objectAtIndex:locationA];
		endLocation = [listAllLocations objectAtIndex:locationC];
		
		startSquare = [allSquares squareAtLocation:[listAllLocations objectAtIndex:locationA]];
		
		if ([startSquare hasClearPathFrom:startLocation to:endLocation]) {
			
			locationB = locationA;
			locationA --;
			
		} else {
			
			[locations addObject:[listAllLocations objectAtIndex:locationB]];
			locationC = locationB;
			locationB = locationA;
			locationA --;
		}
		
	}
	
	[locations addObject:[listAllLocations objectAtIndex:0]];
	
	return locations;
	
}
@end
