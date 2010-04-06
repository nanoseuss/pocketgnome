//
//  PvPBehavior.h
//  Pocket Gnome
//
//  Created by Josh on 2/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SaveDataObject.h"

#define ZoneAlteracValley			2597
#define ZoneArathiBasin				3358
#define ZoneEyeOfTheStorm			3820
#define ZoneIsleOfConquest			4710
#define ZoneStrandOfTheAncients		4384
#define ZoneWarsongGulch			3277

@class Battleground;

@interface PvPBehavior : SaveDataObject {
	
	NSString *_name;
	
	// battlegrounds
	Battleground *_bgAlteracValley, *_bgArathiBasin, *_bgEyeOfTheStorm, *_bgIsleOfConquest, *_bgStrandOfTheAncients, *_bgWarsongGulch;
	
	// options
	BOOL _random;
	BOOL _stopHonor;
	int _stopHonorTotal;
	BOOL _leaveIfInactive;
	BOOL _preparationDelay;
	BOOL _waitToLeave;
	float _waitTime;
}

@property (readwrite, retain) Battleground *AlteracValley;
@property (readwrite, retain) Battleground *ArathiBasin;
@property (readwrite, retain) Battleground *EyeOfTheStorm;
@property (readwrite, retain) Battleground *IsleOfConquest;
@property (readwrite, retain) Battleground *StrandOfTheAncients;
@property (readwrite, retain) Battleground *WarsongGulch;
@property (readwrite, copy) NSString *name;

@property (readwrite, assign) BOOL random;
@property (readwrite, assign) BOOL stopHonor;
@property (readwrite, assign) int stopHonorTotal;
@property (readwrite, assign) BOOL leaveIfInactive;
@property (readwrite, assign) BOOL preparationDelay;
@property (readwrite, assign) BOOL waitToLeave;
@property (readwrite, assign) float waitTime;

+ (id)pvpBehaviorWithName: (NSString*)name;

- (Battleground*)battlegroundForIndex:(int)index;
- (Battleground*)battlegroundForZone:(UInt32)zone;
- (BOOL)isValid;
- (BOOL)canDoRandom;

- (NSString*)formattedForJoinMacro;

@end
