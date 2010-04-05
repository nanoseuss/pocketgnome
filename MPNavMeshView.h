//
//  NavMeshView.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PatherController;

@interface MPNavMeshView : NSView {
	
	IBOutlet PatherController *patherController;
	
	
	float manualAdjustmentX, manualAdjustmentY;
	float viewWidth, viewHeight;
	float scaleSetting;
	
	float playerDotRadius;
	
	
	NSArray *displayedSquares;
	

}
@property (retain) NSArray *displayedSquares;
@property (readwrite) float scaleSetting;
@property (readonly) float viewWidth, viewHeight;

@end
