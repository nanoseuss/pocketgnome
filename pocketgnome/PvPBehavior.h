//
//  PvPBehavior.h
//  Pocket Gnome
//
//  Created by Josh on 2/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SaveDataObject.h"

@class Battleground;

@interface PvPBehavior : SaveDataObject {

	NSString *_name;
	
	// battlegrounds
	Battleground *_bgAlteracValley, *_bgArathiBasin, *_bgEyeOfTheStorm, *_bgIsleOfConquest, *_bgStrandOfTheAncients, *_bgWarsongGulch;

	// options
	BOOL _random;
	BOOL _stop;
	int _stopNumOfMarks;
	int _stopMarkType;
	BOOL _stopHonor;
	int _stopHonorTotal;
	BOOL _leaveIfInactive;
}

@property (readwrite, retain) Battleground *AlteracValley;
@property (readwrite, retain) Battleground *ArathiBasin;
@property (readwrite, retain) Battleground *EyeOfTheStorm;
@property (readwrite, retain) Battleground *IsleOfConquest;
@property (readwrite, retain) Battleground *StrandOfTheAncients;
@property (readwrite, retain) Battleground *WarsongGulch;
@property (readwrite, copy) NSString *name;

@property (readwrite, assign) BOOL random;
@property (readwrite, assign) BOOL stop;
@property (readwrite, assign) int stopNumOfMarks;
@property (readwrite, assign) int stopMarkType;
@property (readwrite, assign) BOOL stopHonor;
@property (readwrite, assign) int stopHonorTotal;
@property (readwrite, assign) BOOL leaveIfInactive;

+ (id)pvpBehaviorWithName: (NSString*)name;

- (BOOL)isValid;

@end
