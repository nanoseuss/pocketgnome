/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import "PvPBehavior.h"

#import "Battleground.h"
#import "SaveDataObject.h"

@implementation PvPBehavior

- (id) init{
	
    self = [super init];
    if ( self != nil ){
		
		// initiate our BGs
		_bgAlteracValley			= [[Battleground battlegroundWithName:@"Alterac Valley" andZone:2597] retain];
		_bgArathiBasin				= [[Battleground battlegroundWithName:@"Arathi Basin" andZone:3358] retain];
		_bgEyeOfTheStorm			= [[Battleground battlegroundWithName:@"Eye of the Storm" andZone:3820] retain];
		_bgIsleOfConquest			= [[Battleground battlegroundWithName:@"Isle of Conquest" andZone:4710] retain];
		_bgStrandOfTheAncients		= [[Battleground battlegroundWithName:@"Strand of the Ancients" andZone:4384] retain];
		_bgWarsongGulch				= [[Battleground battlegroundWithName:@"Warsong Gulch" andZone:3277] retain];
		
		_random = NO;
		_stop = NO;
		_stopMarkType = 0;
		_stopNumOfMarks = 100;
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
		self.stop = [[decoder decodeObjectForKey: @"Stop"] boolValue];
		self.stopMarkType = [[decoder decodeObjectForKey: @"StopMarkType"] intValue];
		self.stopNumOfMarks = [[decoder decodeObjectForKey: @"StopNumOfMarks"] intValue];
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
	[coder encodeObject: [NSNumber numberWithBool:self.stop] forKey:@"Stop"];
	[coder encodeObject: [NSNumber numberWithInt: self.stopMarkType] forKey:@"StopMarkType"];
	[coder encodeObject: [NSNumber numberWithInt: self.stopNumOfMarks] forKey:@"StopNumOfMarks"];
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
	copy.stop = self.stop;
	copy.stopMarkType = self.stopMarkType;
	copy.stopNumOfMarks = self.stopNumOfMarks;
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
@synthesize stop = _stop;
@synthesize stopNumOfMarks = _stopNumOfMarks;
@synthesize stopMarkType = _stopMarkType;
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
	[self addObserver: self forKeyPath: @"stop" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"stopNumOfMarks" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
	[self addObserver: self forKeyPath: @"stopMarkType" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: nil];
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
	
	if ( self.AlteracValley.enabled && self.AlteracValley.routeCollection != nil )
		return YES;
	if ( self.ArathiBasin.enabled && self.ArathiBasin.routeCollection != nil )
		return YES;
	if ( self.EyeOfTheStorm.enabled && self.EyeOfTheStorm.routeCollection != nil )
		return YES;
	if ( self.IsleOfConquest.enabled && self.IsleOfConquest.routeCollection != nil )
		return YES;
	if ( self.StrandOfTheAncients.enabled && self.StrandOfTheAncients.routeCollection != nil )
		return YES;
	if ( self.WarsongGulch.enabled && self.WarsongGulch.routeCollection != nil )
		return YES;	
	
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

@end
