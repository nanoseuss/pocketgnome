//
//  Task.m
//  TaskParser
//
//  Created by Coding Monkey on 8/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTask.h"
#import "MPTaskPar.h"
#import "MPTaskSeq.h"
#import "MPTaskIf.h"
#import "MPTaskWhen.h"
#import "MPTaskUntil.h"
#import "MPTestTask.h"
#import "MPTaskAssist.h"
#import "MPTaskDefend.h"
#import "MPTaskFollow.h"
#import "MPTaskRest.h"
#import "MPTaskRoute.h"
#import "MPTaskPartyWait.h"
#import "MPTaskPull.h"
#import "MPTaskLoot.h"
#import "MPTaskGhostRoute.h"
#import "MPTaskWait.h"
#import "MPParser.h"
#import "MPValue.h"
#import "MPValueInt.h"
#import "MPValueFloat.h"
#import "MPValueBool.h"
#import "MPLocation.h"
#import "Mob.h"
#import "Position.h"
#import "PatherController.h"
#import "PlayerDataController.h"


@implementation MPTask

@synthesize name;
@synthesize parent;
@synthesize subTasks;
@synthesize childTasks;
@synthesize bestTask;
@synthesize definedVariables;
@synthesize currentStatus;
@synthesize patherController;


- (id) init {
	return [self initWithPather:nil];
}


- (id) initWithPather: (PatherController *)controller {
	if ((self = [super init])) {
		
		name = @"MPTask";
		self.parent = nil;
		self.childTasks = nil;
		
		self.subTasks = [NSMutableArray array];
		self.definedVariables = [NSMutableDictionary dictionary];
		
		active = NO;
		
		self.bestTask = nil;
		
		priority = -1;  // priorities should be >= 0
		currentStatus = TaskStatusNoWant;
		
		self.patherController = controller;
	}
	return self;
}


- (void) dealloc
{
    [name autorelease];
    [parent autorelease];
	[subTasks autorelease];
	[childTasks autorelease];
	[definedVariables autorelease];
	[bestTask autorelease];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Task File Parsing 


- (void)parseTaskDataWithParser: (MPParser*) parser {

	NSString * currentToken;
	MPTask* childTask;
	
	do {
		// curr = nextToken
		currentToken = [parser nextToken];
		
		// if (curr != '{' and '}')
		if ( ![currentToken isEqualToString:@"{"] && ![currentToken isEqualToString:@"}"] ) {
		
			// if == '$' then
			if ( [currentToken isEqualToString:@"$"] ) {
			
				// pullInVariableInfo]
				[self pullTaskVariableInfo: parser];
				
			} else {
			
				// childTask = [self taskFromKey: curr];
				childTask = [MPTask taskFromKey:currentToken withPather:patherController];
				
				// childTask setParentTask: self]
				[childTask setParent: self];
				
				// self addChildTAsk:childTask]
				[self addSubTask:childTask];
				
		
				// childTask parseTaskDataWithParser: parser]
				[childTask parseTaskDataWithParser:parser];
				
			} // end if== '$'
			
		} // end if != "{" & "}"
		
	} while (![currentToken isEqualToString:@"}"]);

	// optimization Step: NSArray * childTasks = [subTasks copy];
	self.childTasks = [subTasks copy];
	
	// now process your variable data into MPValues
	[self setup];
	
}



- (void)pullTaskVariableInfo: (MPParser*) parser {

	// name = nextToken]
	NSString* nameString = [parser nextToken];
	
	// op = nextToken]
	NSString* op = [parser nextToken];
	
	// if op != '='  ->  indicate an Error message
	if (![op isEqualToString:@"="]) {
	
		PGLog(@" Error in MPTask::pullTaskVariable: Variable definition (%@) did not have '=' token after name. File: %@  Line: %d", nameString, [parser fileName], [parser lineNumber]);
	}
	
	// currentValue = ''
	NSString* currentValue = @"";
	NSMutableString* value = [NSMutableString stringWithString:@""];
	
	do { 
	
		// value append: currentValue
		[value appendString:currentValue];
		
		// currentValue = nextToken]
		currentValue = [parser nextToken];
	
	} while ( ![currentValue isEqualToString:@";"]); // while( currentValue != ';');
	
	// store lc(name) => value
	[definedVariables setObject:value forKey:[nameString lowercaseString]];
	
}


- (void)addSubTask: (MPTask*) aTask {
	
	[subTasks addObject: aTask];
}



#pragma mark -
#pragma mark TreeView Data Source & Display 


- (NSInteger) numberOfChildren {
	return [childTasks count];
}


- (MPTask *) childAtIndex:(NSInteger)index {
	return [childTasks objectAtIndex:index];  // should I do error checking here?
}

- (NSString *) showStatusName {
	return name;
}

- (NSString *) showStatusText {
	NSMutableString* value = [NSMutableString stringWithString:@""];
	
	[value appendFormat:@"p[%d]", [self priority]];
	return [value retain];
}

- (BOOL) isActive {
	return active;
}

- (void) updateWantSatus:(BOOL)wantTo {
	if (wantTo) {
		currentStatus = TaskStatusWant;
	} else {
		currentStatus = TaskStatusNoWant;
	}	
}


- (void) updateFinishedStatus:(BOOL)amI {
	if (amI) {
		currentStatus = TaskStatusFinished;
	}
}


#pragma mark -
#pragma mark Common Task Data initialization 



- (BOOL) boolFromVariable: (NSString *) variableName orReturnDefault:(BOOL) defaultValue {
	
	NSString *varData;
	
	// if name exists in dictionary
	varData = (NSString *)[definedVariables objectForKey:variableName];
	if ( varData != nil) {
		// return it without any Quotes
		varData = [varData lowercaseString];
		return ( [varData isEqualToString:@"y"] ||
				 [varData isEqualToString:@"yes"] ||
				 [varData isEqualToString:@"t"] ||
				 [varData isEqualToString:@"true"] ||
				 [varData isEqualToString:@"1"]
		  );
		
	} else {
		return defaultValue;
	}// end if
}



- (MPValue *) conditionFromVariable: (NSString *) variableName orReturnDefault:(BOOL) defaultValue {
	
	NSString *varData;
	
	// if name exists in dictionary
	
	varData = [definedVariables objectForKey:variableName];
	if ( varData != nil) {
		
		// get var Data
		// new Parser with varData
		PKTokenizer* tokenizer = [MPParser equationTokenizerWithString:varData];
		
		return [MPValue parseEquation:tokenizer withDesiredType:@"int" withPather:patherController];
		
	} else {
		return [MPValueBool initWithData:defaultValue];
	}// end if
}


- (MPValue *) integerFromVariable: (NSString *) variableName orReturnDefault:(NSInteger) defaultValue {

	NSString *varData;
	
	// if name exists in dictionary
	
	varData = [definedVariables objectForKey:variableName];
	if ( varData != nil) {
		
		// get var Data
		// new Parser with varData
		PKTokenizer* tokenizer = [MPParser equationTokenizerWithString:varData];
		
		return [MPValue parseEquation:tokenizer withDesiredType:@"int" withPather:patherController];
	
	} else {
		return [MPValueInt intFromData:defaultValue];
	}// end if
}


- (MPValue *) floatFromVariable: (NSString *) variableName orReturnDefault:(float) defaultValue {

	NSString *varData;
	
	// if name exists in dictionary
	
	varData = [definedVariables objectForKey:variableName];
	if ( varData != nil) {
		
		// get var Data
		// new Parser with varData
		PKTokenizer* tokenizer = [MPParser equationTokenizerWithString:varData];
		
		return [MPValue parseEquation:tokenizer withDesiredType:@"float" withPather:patherController];
	
	} else {
		return [MPValueFloat initWithFloat:defaultValue];
	}// end if
}



- (NSString *) stringFromVariable: (NSString *) variableName orReturnDefault:(NSString *) defaultValue {
	
	NSString *varData;
	
	// if name exists in dictionary
	varData = (NSString *)[definedVariables objectForKey:variableName];
	if ( varData != nil) {
		// return it without any Quotes
		NSString *returnData = [[varData stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByReplacingOccurrencesOfString:@"'" withString:@""];
		return [returnData retain];
		
	} else {
		return defaultValue;
	}// end if
}




- (NSArray *) locationsFromVariable: (NSString *) variableName {
	
	NSMutableArray* tempLocations, *compileLocations;
	NSArray *finalCopyLocations;
	
	tempLocations = nil;
	compileLocations = [NSMutableArray array];
	
	NSString *varData;
	
	// if name exists in dictionary
	varData = (NSString *)[definedVariables objectForKey:variableName];
	if ( varData != nil) {
	
		PKTokenizer* tokenizer = [MPParser tokenizerWithString:varData];
		
		// ok if we 1st pull off the first '[' then parseArray will return the value as we expect.
		// otherwise it will embed our expected result in an array[array[array[string,string,string]...]]
		varData = [[tokenizer nextToken] stringValue];
		
		tempLocations =  [MPValue parseArray:tokenizer];
		
		
		// tempLocations should now be an array[ array[string1,string2,string3], array[string1,string2,string3]...]
		// we want array[ MPLocation, MPLocation, ... ]
		for( NSArray *item in tempLocations) {
			[compileLocations addObject:[MPLocation locationFromVariableData:item]];
		}
		
	} 
	
	finalCopyLocations = [compileLocations copy];  //<-- NSArray faster to work with than NSMutableArray
	return finalCopyLocations;
}



- (NSArray *) arrayStringsFromVariable: (NSString *) variableName {
	
	NSMutableArray* tempStrings, *cleanedStrings;
	NSArray *finalCopyStrings;
	
	tempStrings = nil;
	
	NSString *varData;
	
	// if name exists in dictionary
	varData = (NSString *)[definedVariables objectForKey:variableName];
	if ( varData != nil) {
	
		PKTokenizer* tokenizer = [MPParser tokenizerWithString:varData];
		
		// ok if we 1st pull off the first '[' then parseArray will return the value as we expect.
		// otherwise it will embed our expected result in an array[array[array[string,string,string]...]]
		varData = [[tokenizer nextToken] stringValue];
		
		if ([varData isEqualToString:@"["]) {
		
			// looks like an array so parse it.
			tempStrings =  [MPValue parseArray:tokenizer];
			
		} else {
			// not valid array format: assume single entry string and return that in an array
			PGLog(@"MPTask->arrayStringsFromVariable( %@ ) : data format not proper array.  Assuming single entry string." );
			
			tempStrings = [NSMutableArray array];
			[tempStrings addObject:varData];
		}
		

		
	} else {
	
		tempStrings = [NSMutableArray array]; // empty array if variable not found.
	}
	
	// the tempStrings might be in format: array[ "string1", "string2", ..., "stringN"]
	// we need them without '"'
	cleanedStrings = [NSMutableArray array];
	for( NSString* unconverted in tempStrings) {
		[cleanedStrings addObject:[unconverted stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
	}
	finalCopyStrings = [cleanedStrings copy]; //<-- NSArray faster to work with than NSMutableArray
	return finalCopyStrings;
}



- (NSArray *) arrayNumbersFromVariable: (NSString *) variableName withExpectedType:(NSString*)type {
	
	NSMutableArray* tempNumbers, *compileNumbers;
	NSArray *finalCopyNumbers;
	
	tempNumbers = nil;
	compileNumbers = [NSMutableArray array];
	
	NSString *varData;
	
	// if name exists in dictionary
	varData = (NSString *)[definedVariables objectForKey:variableName];
	if ( varData != nil) {
	
		PKTokenizer* tokenizer = [MPParser tokenizerWithString:varData];
		
		// ok if we 1st pull off the first '[' then parseArray will return the value as we expect.
		// otherwise it will embed our expected result in an array[array[array[string,string,string]...]]
		varData = [[tokenizer nextToken] stringValue];
		
		if ([varData isEqualToString:@"["]) {
		
			// looks like an array so parse it.
			tempNumbers =  [MPValue parseArray:tokenizer];
			
			
			// tempNumbers should now be an array[string1,string2,string3]
			// we want array[NSNumber, NSNumber, ... ]
			for( NSString *item in tempNumbers) {
				if ([type isEqualToString:@"int"]) {
					[compileNumbers addObject:[NSNumber numberWithInt:[item intValue]]];
				} else {
					[compileNumbers addObject:[NSNumber numberWithFloat:[item floatValue]]];
				}
			}
			
		} else {
			// not valid array format: assume single entry string and return that in an array
			PGLog(@"MPTask->arrayNumbersFromVariable( %@ ) : data format not proper array.  Assuming single entry string." );
			
			if ([type isEqualToString:@"int"]) {
				[compileNumbers addObject:[NSNumber numberWithInt:[varData intValue]]];
			} else {
				[compileNumbers addObject:[NSNumber numberWithFloat:[varData floatValue]]];
			}
		}
		
	} 
	
	finalCopyNumbers = [compileNumbers copy];  //<-- NSArray faster to work with than NSMutableArray
	return finalCopyNumbers;
}





- (void) setup {
	
	
}


#pragma mark -
#pragma mark Common Task Operation Methods


- (NSInteger) priority{
	
	if (priority == -1) {
		
		priority = 1000;
		
		// if current Task has a prio defined:
		priority = (NSInteger)[[self  integerFromVariable: @"prio" orReturnDefault:1000] value];
		if ( priority == 1000) {
			
			// current node didn't define a $Prio value.  Look to parent's value then.
			 if (parent != nil) {
			
				priority = [parent priority];
			 }
		}
	}
	return priority;
}

// 
- (MPLocation *) location {
	return nil;
}


- (void) restart { }


- (BOOL) wantToDoSomething {
	return NO;
}


- (BOOL) isFinished {
	return YES;
}


- (MPActivity *) activity {
	return nil;
}


- (BOOL) activityDone: (MPActivity*)activity {
	return YES; // ??
}


- (MPTask *) bestTask {
	return nil;
}


- (void) clearBestTask{
	bestTask = nil;
	for( MPTask *task in childTasks) {
		[task clearBestTask];
	}
}




- (void) markActive {

	active = YES;
	if (parent != nil) {
		[parent markActive];
	}
	
}


- (void) markInactive {

	active = NO;
	if (parent != nil) {
		[parent markInactive];
	}
	
}


- (NSString *) description {

	NSMutableString *text = [NSMutableString stringWithFormat:@" task[%@] \n  unimplemented [description]", self.name];
	return text;
}

#pragma mark -
#pragma mark Task Helpers

- (float) myDistanceToMob:(Mob *)mob {
	return [self myDistanceToPosition: [mob position]];
}


- (float) myDistanceToPosition:(Position *)position {

	Position *playerPosition = [[patherController playerData] position];
	return [playerPosition distanceToPosition: position];
}


- (Position *) myPosition {
	return [[patherController playerData] position];
}


#pragma mark -
#pragma mark Convienience Methods

// Command to begin
+ (MPTask*)rootTaskFromFile: (NSString *) fileName {
	return [self rootTaskFromFile:fileName withPather:nil];
}

+ (MPTask*)rootTaskFromFile: (NSString *) fileName withPather:(PatherController*)controller {
	
	MPTask * tempRootTask = nil;
	
	MPParser * parser = [MPParser initWithFile:fileName];
//	PKToken *eof = [PKToken EOFToken];
	NSString *tok = nil;
	
	// pull the first entry 
	if ((tok = [parser nextToken]) != nil) {
		PGLog(@" root Task(%@)", tok);
		
		tempRootTask = [MPTask taskFromKey:tok withPather:controller];
		[tempRootTask parseTaskDataWithParser:parser];
	}
	return  tempRootTask;
}


+ (MPTask*)taskFromKey: (NSString*) taskKey {
	return  [self taskFromKey:taskKey withPather:nil];
}

+ (MPTask*)taskFromKey: (NSString*) taskKey withPather:(PatherController*)controller {
	
	NSString* lcTaskName = [taskKey lowercaseString];
	
	if ([lcTaskName isEqualToString:@"par"]) {
		return [MPTaskPar initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"seq"]) {
		return [MPTaskSeq initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"if"]) {
		return [MPTaskIf initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"when"]) {
		return [MPTaskWhen initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"until"]) {
		return [MPTaskUntil initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"assist"]) {
		return [MPTaskAssist initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"defend"]) {
		return [MPTaskDefend initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"follow"]) {
		return [MPTaskFollow initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"ghostroute"]) {
		return [MPTaskGhostRoute initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"loot"]) {
		return [MPTaskLoot initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"partywait"]) {
		return [MPTaskPartyWait initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"pull"]) {
		return [MPTaskPull initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"rest"]) {
		return [MPTaskRest initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"route"]) {
		return [MPTaskRoute initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"wait"]) {
		return [MPTaskWait initWithPather:controller];
	}
	if ([lcTaskName isEqualToString:@"test"]) {
		return [MPTestTask initWithPather:controller];
	}
	return [[[MPTask alloc] init] autorelease];
}

@end
