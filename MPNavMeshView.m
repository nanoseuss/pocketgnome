//
//  NavMeshView.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPNavMeshView.h"

#import "PatherController.h"
#import "PlayerDataController.h"
#import "MPNavigationController.h"
#import "MPLocation.h"
#import "Position.h"
#import "MPSquare.h"


@implementation MPNavMeshView
@synthesize displayedSquares;
@synthesize scaleSetting;
@synthesize viewWidth, viewHeight;


- (id)initWithFrame:(NSRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self)
    {
		manualAdjustmentX = 0;
		manualAdjustmentY = 0;
		
		viewWidth = 1;
		viewHeight = 1;
		
		scaleSetting = 50.0f;
		
		playerDotRadius = 0.1;
		
    	self.displayedSquares = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    [displayedSquares release];
	
	
    [super dealloc];
}



- (void)awakeFromNib
{
    viewWidth = [self bounds].size.width;
	viewHeight = [self bounds].size.height;
}


#pragma mark -
#pragma mark Display Routine

- (void)drawRect:(NSRect)rect
{
	//// Draw Background
	[[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	//// Save Current Graphics Context
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	
	
	// for testing only:
//	Position *playerPosition = [MPLocation locationAtX: 1.25 Y:1.34 Z: 1.0];
	Position *playerPosition = [[patherController playerData] position];
	
	
	float playerX = [playerPosition xPosition];
	float playerY = [playerPosition yPosition];
	
	//// Create Transform to show player position in center of display
//	float adjX = (-playerX - (viewWidth /2)) + manualAdjustmentX;  // manualAdjX&Y can come from interface.
//	float adjY = (-playerY - (viewHeight /2)) + manualAdjustmentY;
	float squareWidth = [[patherController navigationController] squareWidth];
	float adjX = -playerX+((squareWidth/2) * scaleSetting);  // manualAdjX&Y can come from interface.
	float adjY = -playerY+((squareWidth/2) * scaleSetting);

	
	
	NSAffineTransform *locationTransform = [NSAffineTransform transform];
	[locationTransform translateXBy:adjX yBy:adjY];
	
	
	//// Adjust scale 
	float scaleFactor = MIN(viewHeight, viewWidth) /( scaleSetting * squareWidth);
	NSAffineTransform *scaleTransform = [NSAffineTransform transform];
	[scaleTransform scaleBy:scaleFactor];
	
	
	
	//// Apply Transform to current View
	NSAffineTransform *transform = [NSAffineTransform transform];	
	[transform appendTransform:locationTransform];
	[transform appendTransform:scaleTransform];
	[transform concat];
	
	
	//// Now display all the squares we are told to display.
	for ( MPSquare *square in displayedSquares) {
		
		[square display];
	}
	
	
	
	//// Display Player Position
	// create a rect at the center of the top section
	
	
	// make sure the radius of the player's dot doesn't get scaled into oblivion ...
	float scaledPlayerDotRadius = playerDotRadius;
	if ((scaledPlayerDotRadius * scaleFactor) < 2) {
		scaledPlayerDotRadius = 2 / scaleFactor;
	}
	
	NSRect rect3 = NSMakeRect ( playerX  - scaledPlayerDotRadius,
							   playerY   - scaledPlayerDotRadius,
							   scaledPlayerDotRadius *2,
							   scaledPlayerDotRadius *2);
	
	// create an oval with the rect and fill it with orange
	NSBezierPath *path3 = [NSBezierPath bezierPathWithOvalInRect: rect3];
	[[NSColor orangeColor] set];
	[path3 fill];
	
	
	 
	//// Restore Graphics Context
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
}

@end
