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

#import "EventController.h"
#import "Controller.h"
#import "BotController.h"
#import "PlayerDataController.h"
#import "OffsetController.h"

#import "Player.h"
#import "MemoryAccess.h"

@interface EventController (Internal)

@end

@implementation EventController

- (id) init{
    self = [super init];
    if (self != nil) {
		
		_uberQuickTimer = nil;
		_oneSecondTimer = nil;
		_fiveSecondTimer = nil;
		_twentySecondTimer = nil;
		
		_lastPlayerZone = -1;
		_lastBGStatus = -1;
		_lastBattlefieldWinnerStatus = -1;
		_memory = nil;
	
		// Notifications
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(playerIsValid:) 
													 name: PlayerIsValidNotification 
												   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsInvalid:) 
                                                     name: PlayerIsInvalidNotification 
                                                   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryValid:) 
                                                     name: MemoryAccessValidNotification 
                                                   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryInvalid:) 
                                                     name: MemoryAccessInvalidNotification 
                                                   object: nil];
		
    }
    return self;
}

- (void) dealloc{
	[_memory release]; _memory = nil;
    [super dealloc];
}

#pragma mark Notifications

- (void)playerIsValid: (NSNotification*)not {
	_uberQuickTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1f target: self selector: @selector(uberQuickTimer:) userInfo: nil repeats: YES];
	_oneSecondTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f target: self selector: @selector(oneSecondTimer:) userInfo: nil repeats: YES];
	//_fiveSecondTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0f target: self selector: @selector(fiveSecondTimer:) userInfo: nil repeats: YES];
	//_twentySecondTimer = [NSTimer scheduledTimerWithTimeInterval: 10.0f target: self selector: @selector(twentySecondTimer:) userInfo: nil repeats: YES];
}

- (void)playerIsInvalid: (NSNotification*)not {
	[_uberQuickTimer invalidate]; _uberQuickTimer = nil;
	[_fiveSecondTimer invalidate]; _fiveSecondTimer = nil;
	[_oneSecondTimer invalidate]; _oneSecondTimer = nil;
	[_twentySecondTimer invalidate]; _twentySecondTimer = nil;
}

- (void)memoryValid: (NSNotification*)not {
	_memory = [[controller wowMemoryAccess] retain];
}

- (void)memoryInvalid: (NSNotification*)not {
	[_memory release]; _memory = nil;
}

#pragma mark Timers

- (void)twentySecondTimer: (NSTimer*)timer {
	
}

- (void)oneSecondTimer: (NSTimer*)timer {

	if ( _memory && [_memory isValid] ){
		UInt32 offset = [offsetController offset:@"Lua_GetBattlefieldWinner"], status = 0;
		[_memory loadDataForObject: self atAddress: offset Buffer: (Byte*)&status BufLength: sizeof(status)];
		
		if ( status != _lastBattlefieldWinnerStatus ){
			
			if ( _lastBattlefieldWinnerStatus != -1 && status != 0 ){
				[[NSNotificationCenter defaultCenter] postNotificationName: EventBattlegroundOver object: nil];
			}
			PGLog(@"[Events] BattlefieldStatus changed to %d", status);
			_lastBattlefieldWinnerStatus = status;
		}
	}
}

- (void)fiveSecondTimer: (NSTimer*)timer {

}

- (void)uberQuickTimer: (NSTimer*)timer {
	
	// check for a zone change!
	int currentZone = [playerController zone];
	if ( _lastPlayerZone != currentZone ){
		// only send notification if the zone had been set already!
		if ( _lastPlayerZone != -1 ){
			[[NSNotificationCenter defaultCenter] postNotificationName: EventZoneChanged object: [NSNumber numberWithInt:_lastPlayerZone]];
		}
	}
	
	int bgStatus = [playerController battlegroundStatus];
	if ( _lastBGStatus != bgStatus ){
		// only send notification if the zone had been set already!
		if ( _lastBGStatus != -1 ){
			[[NSNotificationCenter defaultCenter] postNotificationName: EventBattlegroundStatusChange object: [NSNumber numberWithInt:bgStatus]];
		}
		PGLog(@"[Events] BGStatus change from %d to %d", _lastBGStatus, bgStatus);
	}
	
	_lastBGStatus = bgStatus;
	_lastPlayerZone = currentZone;
}

@end
