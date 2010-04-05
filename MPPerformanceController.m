//
//  MPPerformanceController.m
//  TaskParser
//
//  Created by admin on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPPerformanceController.h"


@implementation MPPerformanceController
@synthesize currentMeasurements, historyMeasurements;


- (id) init {
	if ((self = [super init])) {
		
		self.currentMeasurements = [NSMutableArray array];
		self.historyMeasurements = [NSMutableArray array];
		maxTime = 100;
		numHistoryMeasurements = 30; // 3 seconds worth
	}
	return self;
}



- (void) dealloc
{
    [currentMeasurements release];
    [historyMeasurements release];
	
    [super dealloc];
}


#pragma mark -

- (void) storeWorkTime:(NSInteger) timeUsed {
	[currentMeasurements addObject: [NSNumber numberWithInt:timeUsed]];
}


- (void) reset {
	
	// find SUM(currentMeasurements)
	NSInteger sum = [self sum:currentMeasurements];
	
	// store in historyArray
	[historyMeasurements addObject:[NSNumber numberWithInt:sum]];
	if ([historyMeasurements count] > numHistoryMeasurements) {
		[historyMeasurements removeObjectAtIndex:0];
	}
	
	// clear currentArray
	[currentMeasurements removeAllObjects];
	
}



- (NSInteger) averageLoad {
	
	NSInteger numElements = [historyMeasurements count];
	
	if (numElements > 0) {
		
		// find SUM(historyArray)
		NSInteger sumHistory = [self sum:historyMeasurements];
		return  sumHistory/numElements;
		
	} else {
		
		return 0;
	}
}



- (NSInteger) lastLoad {
	
	return [[historyMeasurements lastObject] integerValue];
}


- (NSInteger) currentLoad {
	
	//if (count(currentArray) > 0 ) {
	if ([currentMeasurements count] > 0 ) {
		
		//returns SUM(currentArray) 
		return [self sum:currentMeasurements];
		
	} else {
		
		//return [lastLoad]
		return [self lastLoad];
	}
	
}


// remaining load should not return negative numbers.  
- (NSInteger) remainingLoad {
	NSInteger timeLeft = maxTime - [self currentLoad];
	return (timeLeft >0)? timeLeft:0;
}


#pragma mark -
#pragma mark Internal Helpers

- (NSInteger) sum: (NSMutableArray *) myArray {
	NSInteger curSum = 0;
	for (NSNumber* measurement in myArray) {
		curSum += (NSInteger) [measurement integerValue];
	}
	return curSum;
}


@end
