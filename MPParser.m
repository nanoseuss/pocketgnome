//
//  MPParser.m
//  TaskParser
//
//  Created by Coding Monkey on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPParser.h"
#import "MPStack.h"
#import "ParseKit/ParseKit.h"


@implementation MPParser

@synthesize flagStack, eof, tokenizer, currentFileName, listStrings, tokenizerStack, filePositionStack, fileNameStack, fileContentsStack;


- (id) init
{
    if (( self = [super init] ))
    {
		self.fileContentsStack = [NSMutableArray array]; // what's the right way to do this?
		self.fileNameStack = [NSMutableArray array];
		self.filePositionStack = [NSMutableArray array];
		self.tokenizerStack = [NSMutableArray array];
	
		self.listStrings = nil;
		self.currentFileName = nil;
		currentLineNumber = 0;

		self.tokenizer = nil;
		eof = [PKToken EOFToken];
		
		processingEnabled = 1;
		self.flagStack = [NSMutableArray array];
    }
    return self;
}


- (void) dealloc
{
    [fileContentsStack release];
    [fileNameStack release];
	[filePositionStack release];
	[tokenizerStack release];
	[listStrings release];
	[currentFileName release];
	[tokenizer release];
	[eof release];
	[flagStack release];
	
    [super dealloc];
}

#pragma mark -

//
// 
- (id) loadFile: (NSString*)fileName
 {
	 // Save the current Context if they have values 
	 if ( currentFileName ) {
	 
		[fileContentsStack push:listStrings];
		[fileNameStack push:currentFileName];
		 
		 NSNumber *savePos = [NSNumber numberWithInt:currentLineNumber];
		[filePositionStack push:savePos];
		 
		[tokenizerStack push:tokenizer];
	 
		 
	 }
 
	 // get file contents broken into an array by line ending
	 listStrings = [[NSString stringWithContentsOfFile:fileName encoding:NSASCIIStringEncoding error:nil] componentsSeparatedByString:@"\n"];
	 
	 // setup current file/string/filepos variables
	 currentFileName = fileName;
	 currentLineNumber = 1;  // 1st line in file.
	 
	 // create tokenizer with first string
	 tokenizer = [MPParser tokenizerWithString:[listStrings objectAtIndex: (currentLineNumber -1)]];
	 
	 return self;
 }



// return the next valid string/token
// don't return preprocessor directives
// don't return when preprocessor conditions are false
- (NSString *) nextToken
{
//	PKToken *tok = nil;
	NSString *returnString = nil;
	
	do {
	
		// get string from Token
		returnString = [self nextRawToken];
	
	} while (!processingEnabled);
	
	// if we get to here, there are no special cases, so return it!
	return returnString;  
}



// don't return preprocessor directives
// don't return when preprocessor conditions are false
- (NSString *) nextRawToken
{
	PKToken *tok = nil;
	NSString *returnString = nil;
	

		
		// get current token.
		tok = [tokenizer nextToken];
		// if eof
		if (tok == eof) {
			
			// if there are values still in the listStrings
			if ( currentLineNumber < [listStrings count]) {
				
				// increment currentFilePosition
				currentLineNumber++;
				
				// get new tokenizer with string at currentFilePosition
				tokenizer = [MPParser tokenizerWithString:[listStrings objectAtIndex: (currentLineNumber-1)]];
				
				// return [self nextToken]
				return [self nextRawToken];
				
			} else {
				
				// if there are objects pushed on our context stacks
				if ([fileContentsStack count] > 0 ) {
					
					// free current objects.
					listStrings = nil;
					currentFileName = nil;
					currentLineNumber = 0;
					tokenizer = nil;
					
					
					// pop context from Stacks
					listStrings = [fileContentsStack pop];
					currentFileName = [fileNameStack pop];
					
					NSNumber *restoreValue = [filePositionStack pop];
					currentLineNumber = [restoreValue intValue];
					
					tokenizer = [tokenizerStack pop];
					
					
					// return [self nextToken]
					return [self nextRawToken];
					
					// else
				} else {
					
					// no more strings, no more saved contexts so: return nil
					return nil;
					
				}// end if
			} // end if
		} // end if
		
		// get string from Token
		returnString = [tok stringValue];
		
		// if current string contains a preprocessor directive
		if( [returnString isEqualToString:@"#"] ) {
			
			// get current directive
			NSString * command = [[self nextRawToken] lowercaseString];
			
			// if #include command 
			if ( [command isEqualToString:@"include"] ) {
				
				//// expected format:  #include <path/to/file.psc>
				
				// make sure we pull the path from the tokenizer (don't want to pass it out )
				NSString *nextValue = [self nextValue];   
				
				// if processingEnabled 
				if (processingEnabled) {
					
					// newFile = [self pathFromValue: [self nextValue]  relativeToPath: currentFileName];
					NSString* newFileName = [self pathFromValue: nextValue  relativeToPath: currentFileName];
					
					// [self loadFile:newFile]
					[self loadFile:newFileName];
					
					// return [self nextToken];
					return [self nextRawToken];
					
				} // end if processing enabled 
			} // end if
			
			// if #IF statement (ifzone <zone name>, ifclass <class1,class2,...,classN>, ifrace <race1,race2,...,raceN>, iflevelrange <4,6>, ifkeyequals <Key,Value> )
			if ( [command isEqualToString:@"ifzone"]  || 
				[command isEqualToString:@"ifclass"]  ||
				[command isEqualToString:@"ifrace"]  ||
				[command isEqualToString:@"iflevelrange"]  ||
				[command isEqualToString:@"ifkeyequals"] 
				) {
				//// reference: http://wiki.ppather.net/index.php/Preprocessing
				
				// pull associated value from tokenizer
				NSString* conditionData = [self nextValue];
				
				// push processingEnabled to flagStack  (do this no matter what)
				NSNumber *saveFlag = [NSNumber numberWithInt:processingEnabled];
				[flagStack push:saveFlag];
				
				// if processingEnabled
				if (processingEnabled) {
					
					// eval condition and set processingEnabled to condition
					processingEnabled = [self evaluateCommand: command withData: conditionData];
					
				} // end if
				
				// return nextToken;
				return [self nextRawToken];
				
			} // end if
			
			
			// if #EndIf statement 
			if ( [command isEqualToString:@"endif"] ) {
				
				// pop flagStack to processingEnabled
				NSNumber* restoreFlag = [flagStack pop];
				processingEnabled = [restoreFlag intValue];
				
				// return nextToken
				return [self nextRawToken];
				
			} // end if
		} // end if
		
	
	// if we get to here, there are no special cases, so return it!
	return returnString;  
}




- (NSString*) nextValue 
{

	// value = ''
	// getNextToken
	NSMutableString* value = [NSMutableString  stringWithString:[self nextRawToken]];
	
	// if "[" or "<"  (the beginning array tokens)
	if ( [value isEqualToString:@"["] || [value isEqualToString:@"<"] ) {
	
		// value = "[" + [self nextArrayValue]
		[value appendString: [self nextArrayValue]];
		
	} // end if
	
	// return value
	return value;
}



- (NSString*) nextArrayValue 
{

	// value = ''
	// curr = ''
	NSMutableString* value = [NSMutableString stringWithString:@""];
	NSString * currentValue;
	
	do { 
	
		// curr = nextValue
		currentValue = [self nextValue];
		
		// value += curr
		[value appendString:currentValue];
		
	// while ( curr != ']' && curr != '>' );
	} while ( ![currentValue isEqualToString:@"]"] && ![currentValue isEqualToString:@">"] );
	
	// return value
	return value;
}



- (NSString*) pathFromValue: (NSString*) aValue 
{
	//// expected format aValue:  <path/to/file.psc>
	
	// remove '<' && '>' from aValue
	// return remaining value
	return [[aValue stringByReplacingOccurrencesOfString:@"<" withString:@""]
					stringByReplacingOccurrencesOfString:@">" withString:@""];
}



- (NSString*) pathFromValue: (NSString*) aValue relativeToPath: (NSString *) relativePath
{
	// newPath = relative Path without fileName
	NSString* properRelativePath = [relativePath stringByDeletingLastPathComponent];
	
	// newPath += [self pathFromValue: aValue]
	NSMutableString* newPath = [NSMutableString stringWithString:properRelativePath];
	[newPath appendString:@"/"];
	[newPath appendString:[self pathFromValue:aValue]];
	
	// return [newPath stringByStandardizingPath];
	return [newPath stringByStandardizingPath];
}



- (NSInteger) lineNumber
{
	return currentLineNumber;
}


- (NSString *) fileName
{
	return currentFileName;
}


- (NSInteger) evaluateCommand: (NSString*) command withData: (NSString*) conditionData 
{
	return 1;
}




+ (id) initWithFile: (NSString*)fileName
{
	return [[[self alloc] init] loadFile:fileName];
}



+ (id) tokenizerWithString: (NSString*)s
{
	PKTokenizer *t = [PKTokenizer tokenizerWithString:s];
    if ( t )
    {
		// Now add our specific token modifications for Pather files
        [t.symbolState add:@"!="];
		[t.symbolState add:@"&&"];
		[t.symbolState add:@"||"];
		[t.wordState setWordChars:NO from: '-' to: '-'];  // don't allow '-' to be in a word. so $MyLevel - 3 != "$MyLevel-3"
    }
    return t;
}

+ (id) equationTokenizerWithString: (NSString*)s
{
	PKTokenizer *t = [MPParser tokenizerWithString:s];
    if ( t )
    {
		// For Equations, we don't allow numbers to begin with '-'
		[t setTokenizerState:t.symbolState from:'-' to:'-'];
		[t.symbolState add:@"-"];
	}
    return t;
}

@end
