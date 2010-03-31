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

#import "CorpseController.h"
#import "Corpse.h"
#import "MemoryAccess.h"
#import "Controller.h"
#import "Position.h"


@implementation CorpseController

- (id) init
{
    self = [super init];
    if (self != nil) {
        _corpseList = [[NSMutableArray array] retain];
    }
    return self;
}

- (void) dealloc
{
    [_corpseList release];
    [super dealloc];
}

- (int)totalCorpses{
	return [_corpseList count];
}

- (Position *)findPositionbyGUID: (GUID)GUID{
	
	
	// Loop through the corpses
	for(Corpse *corpse in _corpseList) {
		
		// found
		if ( [corpse parentLowGUID] == GUID ){
			//PGLog(@"Player corpse found: %qu", GUID);
			
			return [corpse position];
		}
		//PGLog(@"Corpse: %@ Name: %@", corpse, [corpse name]);
	}
	
	return nil;
}

- (void)addAddresses: (NSArray*)addresses {
	
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    NSMutableArray *dataList = _corpseList;
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(![memory isValid]) return;
    
    //[self willChangeValueForKey: @"corpseCount"];
	
    // enumerate current object addresses
    // determine which objects need to be removed
    for(WoWObject *obj in dataList) {
        if([obj isValid]) {
            [addressDict setObject: obj forKey: [NSNumber numberWithUnsignedLongLong: [obj baseAddress]]];
        } else {
            [objectsToRemove addObject: obj];
        }
    }
    
    // remove any if necessary
    if([objectsToRemove count]) {
        [dataList removeObjectsInArray: objectsToRemove];
    }
    
    // add new objects if they don't currently exist
    NSDate *now = [NSDate date];
    for(NSNumber *address in addresses) {
		
        if( ![addressDict objectForKey: address] ) {
            [dataList addObject: [Corpse corpseWithAddress: address inMemory: memory]];
        } else {
            [[addressDict objectForKey: address] setRefreshDate: now];
        }
    }
    
    //[self didChangeValueForKey: @"corpseCount"];
    //[self updateTracking: nil];
}

@end
