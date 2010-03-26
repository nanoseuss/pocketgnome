//
//  PvPBehavior.m
//  Pocket Gnome
//
//  Created by Josh on 2/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "PvPBehavior.h"

#import "Battleground.h"
#import "SaveDataObject.h"

#define TotalBattlegrounds			6

@implementation PvPBehavior

- (id) init{
	
    self = [super init];
    if ( self != nil ){
		
		// initiate our BGs
		_bgAlteracValley			= [[Battleground battlegroundWithName:@"Alterac Valley" andZone:ZoneAlteracValley] retain];
		_bgArathiBasin				= [[Battleground battlegroundWithName:@"Arathi Basin" andZone:ZoneArathiBasin] retain];
		_bgEyeOfTheStorm			= [[Battleground battlegroundWithName:@"Eye of the Storm" andZone:ZoneEyeOfTheStorm] retain];
		_bgIsleOfConquest			= [[Battleground battlegroundWithName:@"Isle of Conquest" andZone:ZoneIsleOfConquest] retain];
		_bgStrandOfTheAncients		= [[Battleground battlegroundWithName:@"Strand of the Ancients" andZone:ZoneStrandOfTheAncients] retain];
		_bgWarsongGulch				= [[Battleground battlegroundWithName:@"Warsong Gulch" andZone:ZoneWarsongGulch] retain];
		
		_random = NO;
		_stopHonor = 0;
		_stopHonorTotal = 75000;
		
		_leaveIfInactive = YES;
		
		_name = [[NSString stringWithFormat:@"Unknown"] retain];
    }
    return self;
}

- (void) dealloc{
	[_bgAlteracValley release];
	[_bgArathiBasin release];
	[_bgEyeOfTheStorm release];
	[_bgIsleOfConquest release];
	[_bgStrandOfTheAncients release];
	[_bgWarsongGulch release];
	[_name release];
	
	// TO DO: remove observers!
	//[self removeObserver: self forKeyPath: @"numberOfDays"];
	
    [super dealloc];
}

- (id)initWithName:(NSString*)name{
	self = [self init];
    if (self != nil) {
		self.name = name;
	}
	return self;
}

+ (id)pvpBehaviorWithName: (NSString*)name {
    return [[[PvPBehavior alloc] initWithName: name] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder{
	self = [self init];
	if ( self ) {
		
		self.AlteracValley			= [decoder decodeObjectForKey: @"AlteracValley"];
		self.ArathiBasin			= [decoder decodeObjectForKey: @"ArathiBasin"];
		self.EyeOfTheStorm			= [decoder decodeObjectForKey: @"EyeOfTheStorm"];
		self.IsleOfConquest			= [decoder decodeObjectForKey: @"IsleOfConquest"];
		self.StrandOfTheAncients	= [decoder decodeObjectForKey: @"StrandOfTheAncients"];
		self.WarsongGulch			= [decoder decodeObjectForKey: @"WarsongGulch"];
		
		self.random = [[decoder decodeObjectForKey: @"Random"] boolValue];
		self.stopHonor = [[decoder decodeObjectForKey: @"StopHonor"] intValue];
		self.stopHonorTotal = [[decoder decodeObjectForKey: @"StopHonorTotal"] intValue];
		
		self.name = [decoder decodeObjectForKey:@"Name"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	
	[coder encodeObject: self.AlteracValley forKey:@"AlteracValley"];
	[coder encodeObject: self.ArathiBasin forKey:@"ArathiBasin"];
	[coder encodeObject: self.EyeOfTheStorm forKey:@"EyeOfTheStorm"];
	[coder encodeObject: self.IsleOfConquest forKey:@"IsleOfConquest"];
	[coder encodeObject: self.StrandOfTheAncients forKey:@"StrandOfTheAncients"];
	[coder encodeObject: self.WarsongGulch forKey:@"WarsongGulch"];
	
	[coder encodeObject: [NSNumber numberWithBool:self.random] forKey:@"Random"];
	[coder encodeObject: [NSNumber numberWithInt: self.stopHonor] forKey:@"StopHonor"];
	[coder encodeObject: [NSNumber numberWithInt: self.stopHonorTotal] forKey:@"StopHonorTotal"];
	
	[coder encodeObject: self.name forKey:@"Name"];
}

- (id)copyWithZone:(NSZone *)zone{
    PvPBehavior *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
	
	copy.AlteracValley = self.AlteracValley;
	copy.ArathiBasin = self.ArathiBasin;
	copy.EyeOfTheStorm = self.EyeOfTheStorm;
	copy.IsleOfConquest = self.IsleOfConquest;
	copy.StrandOfTheAncients = self.StrandOfTheAncients;
	copy.WarsongGulch = self.WarsongGulch;
	
	copy.random = self.random;
	copy.stopHonor = self.stopHonor;
	copy.stopHonorTotal = self.stopHonorTotal;
	
    return copy;
}

@synthesize AlteracValley = _bgAlteracValley;
@synthesize ArathiBasin = _bgArathiBasin;
@synthesize EyeOfTheStorm = _bgEyeOfTheStorm;
@synthesize IsleOfConquest = _bgIsleOfConquest;
@synthesize StrandOfTheAncients = _bgStrandOfTheAncients;
@synthesize WarsongGulch = _bgWarsongGulch;

@synthesize name = _name;

@synthesize random = _random;
@synthesize stopHonor = _stopHonor;
@synthesize stopHonorTotal = _stopHonorTotal;
@synthesize leaveIfInactive = _leaveIfInactive;

- (void)addObservers{
	[self addObserver: self forKeyPath: @"AlteracValley" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"ArathiBasin" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"EyeOfTheStorm" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"IsleOfConquest" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"StrandOfTheAncients" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"WarsongGulch" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"random" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"name" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"stopHonor" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"stopHonorTotal" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"leaveIfInactive" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	PGLog(@"%@ changed! %@ %@", self, keyPath, change);
	self.changed = YES;
}

// little helper
- (BOOL)isValid{
	
	int totalEnabled = 0;
	
	if ( self.AlteracValley.enabled && self.AlteracValley.routeCollection != nil )
		totalEnabled++;
	if ( self.ArathiBasin.enabled && self.ArathiBasin.routeCollection != nil )
		totalEnabled++;
	if ( self.EyeOfTheStorm.enabled && self.EyeOfTheStorm.routeCollection != nil )
		totalEnabled++;
	if ( self.IsleOfConquest.enabled && self.IsleOfConquest.routeCollection != nil )
		totalEnabled++;
	if ( self.StrandOfTheAncients.enabled && self.StrandOfTheAncients.routeCollection != nil )
		totalEnabled++;
	if ( self.WarsongGulch.enabled && self.WarsongGulch.routeCollection != nil )
		totalEnabled++;
	
	// don't have the total for random!
	if ( self.random && totalEnabled != TotalBattlegrounds ){
		return NO;
	}
	// none enabled
	else if ( totalEnabled == 0 ){
		return NO;
	}
	
	return YES;	
}

// we need a route collection for each BG
- (BOOL)canDoRandom{
	int totalEnabled = 0;
	
	if ( self.AlteracValley.enabled && self.AlteracValley.routeCollection != nil )
		totalEnabled++;
	if ( self.ArathiBasin.enabled && self.ArathiBasin.routeCollection != nil )
		totalEnabled++;
	if ( self.EyeOfTheStorm.enabled && self.EyeOfTheStorm.routeCollection != nil )
		totalEnabled++;
	if ( self.IsleOfConquest.enabled && self.IsleOfConquest.routeCollection != nil )
		totalEnabled++;
	if ( self.StrandOfTheAncients.enabled && self.StrandOfTheAncients.routeCollection != nil )
		totalEnabled++;
	if ( self.WarsongGulch.enabled && self.WarsongGulch.routeCollection != nil )
		totalEnabled++;	
	
	if ( totalEnabled == TotalBattlegrounds ){
		return YES;
	}
	
	return NO;
}

#pragma mark Accessors

// over-write our default changed!
- (BOOL)changed{
	
	if ( _changed )
		return YES;
	
	// any of the BGs change?
	if ( self.AlteracValley.changed )
		return YES;
	if ( self.ArathiBasin.changed )
		return YES;
	if ( self.EyeOfTheStorm.changed )
		return YES;
	if ( self.IsleOfConquest.changed )
		return YES;
	if ( self.StrandOfTheAncients.changed )
		return YES;
	if ( self.WarsongGulch.changed )
		return YES;
	
	return NO;
}

- (void)setChanged:(BOOL)changed{
	_changed = changed;
	
	// tell the BGs they're not changed!
	if ( changed == NO ){
		[self.AlteracValley setChanged:NO];
		[self.ArathiBasin setChanged:NO];
		[self.EyeOfTheStorm setChanged:NO];
		[self.IsleOfConquest setChanged:NO];
		[self.StrandOfTheAncients setChanged:NO];
		[self.WarsongGulch setChanged:NO];
	}
}

#pragma mark -

- (NSArray*)validBattlegrounds{

	NSMutableArray *validBGs = [NSMutableArray array];
	
	if ( [self.AlteracValley isValid] )
		[validBGs addObject:self.AlteracValley];
	if ( [self.ArathiBasin isValid] )
		[validBGs addObject:self.ArathiBasin];
	if ( [self.EyeOfTheStorm isValid] )
		[validBGs addObject:self.EyeOfTheStorm];
	if ( [self.IsleOfConquest isValid] )
		[validBGs addObject:self.IsleOfConquest];
	if ( [self.StrandOfTheAncients isValid] )
		[validBGs addObject:self.StrandOfTheAncients];
	if ( [self.WarsongGulch isValid] )
		[validBGs addObject:self.WarsongGulch];
	
	return [[validBGs retain] autorelease];
}

- (Battleground*)battlegroundForIndex:(int)index{
	
	NSArray *validBGs = [self validBattlegrounds];
	
	if ( [validBGs count] == 0 || index < 0 || index >= [validBGs count]) {
		return nil;
	}
	
	return [validBGs objectAtIndex:index];
}

- (Battleground*)battlegroundForZone:(UInt32)zone{
	
	if ( zone == [self.AlteracValley zone] ){
		return self.AlteracValley;
	}
	else if ( zone == [self.ArathiBasin zone] ){
		return self.ArathiBasin;	
	}
	else if ( zone == [self.EyeOfTheStorm zone] ){
		return self.EyeOfTheStorm;
	}
	else if ( zone ==  [self.IsleOfConquest zone] ){
		return self.StrandOfTheAncients;
	}
	else if ( zone == [self.StrandOfTheAncients zone] ){
		return self.StrandOfTheAncients;
	}
	else if ( zone == [self.WarsongGulch zone] ){
		return self.WarsongGulch;
	}

	return nil;
}

@end
