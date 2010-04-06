//
//  BonjourController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/2/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "BonjourController.h"
#import "NSData+SockAddr.h"

#import "Controller.h"
#import "PlayerDataController.h"
#import "MobController.h"
#import "SpellController.h"

#import "Unit.h"
#import "Player.h"
#import "Spell.h"

#import "CGSPrivate.h"
#import "GrabWindow.h"

@interface BonjourController () 
- (void)resetNetworkConnection;
- (void)openNetworkConnection;
@end


@implementation BonjourController

- (id) init
{
    self = [super init];
    if (self != nil) {
        // notifications
#ifdef PGLOGGING
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appFinishedLaunching:) name: @"NSApplicationDidFinishLaunchingNotification" object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appWillTerminate:) name: @"NSApplicationWillTerminateNotification" object: nil];
#endif
    }
    return self;
}


- (void)awakeFromNib {
    
}

- (void) dealloc
{
    [self resetNetworkConnection];
    [super dealloc];
}


@synthesize connection = _connection;
@synthesize netService = _netService;

- (void)resetNetworkConnection {
	// remove notifications
	[[NSNotificationCenter defaultCenter] removeObserver: self 
													name: NSConnectionDidDieNotification 
												  object: nil];
	// stop the NetService
	[self.netService stop];
	self.netService = nil;
	
	// kill the connection
	[self.connection setRootObject: nil];
	[self.connection invalidate];
	self.connection = nil;
}

- (void)appFinishedLaunching:(NSNotification *)aNotification {
	[self openNetworkConnection];
}

- (void)appWillTerminate:(NSNotification *)notification
{
	log(LOG_GENERAL, @"Terminating network connection.");
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
	
	[self resetNetworkConnection];
}

- (void)connectionDied:(NSNotification*)aNotification {
	log(LOG_GENERAL, @"Server connection died: %@", [aNotification object]);
	[[NSNotificationCenter defaultCenter] removeObserver: self 
													name: NSConnectionDidDieNotification
												  object: [aNotification object]];
    
	[self openNetworkConnection];
}

- (void)openNetworkConnection {
	// log(LOG_GENERAL, @"Initiating network connection.");
	// reset any previous state
	[self resetNetworkConnection];
	
	// set up our recieive port
	NSSocketPort *receivePort = [[[NSSocketPort alloc] initWithTCPPort: 0] autorelease];
    
    if(!receivePort) {
        log(LOG_GENERAL, @"Server: Unable to obtain a port from the kernel. Terminating publish.");
        return;
    }
    
    uint16_t chosenPort = [[receivePort address] dataPort];
    
    // set up our incoming NSConnection
    self.connection = [NSConnection connectionWithReceivePort: receivePort 
													  sendPort: nil];
	if(!self.connection) {
		log(LOG_GENERAL, @"Server: Error creating the Connection.");
		self.connection = nil;
    }
	
    [self.connection setRootObject: self];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(connectionDied:) 
												 name: NSConnectionDidDieNotification 
											   object: self.connection];
    
	// Create the NetService
    self.netService = [[[NSNetService alloc] initWithDomain: @"" 
                                                       type: @"_wowremote._tcp." 
                                                       name: [NSString stringWithFormat:@"%@:%d", [[NSProcessInfo processInfo] hostName],
                                                              [[NSProcessInfo processInfo] processIdentifier], nil]
                                                       port: chosenPort] autorelease];
    [self.netService setDelegate: self];
    [self.netService publish];
}

#pragma mark NetService Delegates
- (void)netService:(NSNetService*)service didNotPublish:(NSDictionary *)errorDict {
    log(LOG_GENERAL, @"Error publishing service: %@", errorDict);
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    log(LOG_GENERAL, @"Service published as \"%@\"", [self.netService name]);
}

#pragma mark - 

- (NSNumber*)fps {
    return [NSNumber numberWithFloat: 1.0f/([controller refreshDelayReal]/1000000.0f)];
}
- (BOOL)playerIsValid {
    return [playerController playerIsValid:self];
}

- (NSString*)playerName {
    return [playerController playerName];
}
- (NSNumber*)playerLevel {
    return [NSNumber numberWithInt: [playerController level]];
}
- (NSString*)playerClass {
    return [Unit stringForClass: [[playerController player] unitClass]];
}
- (NSString*)playerRace {
    return [Unit stringForRace: [[playerController player] race]];
}

- (NSNumber*)playerHealth {
    return [NSNumber numberWithInt: [[playerController player] currentHealth]];
}

- (NSNumber*)playerHealthMax {
    return [NSNumber numberWithInt: [[playerController player] maxHealth]];
}

- (NSNumber*)playerPower {
    return [NSNumber numberWithInt: [[playerController player] currentPower]];
}

- (NSNumber*)playerPowerMax {
    return [NSNumber numberWithInt: [[playerController player] maxPower]];
}

- (NSNumber*)playerSpeed {
    return [NSNumber numberWithFloat: [playerController speed]];
}

- (bycopy NSString*)playerPetName {
    GUID petID = [[playerController player] petGUID];
    if(petID > 0) {
        Unit *unit = [[MobController sharedController] mobWithGUID: petID];
        if( [unit isValid] ) {
            NSString *name = [unit name];
            if( name && [name length]) {
                return name;
            } else {
                return @"Unknown Name";
            }
        } else {
            return @"Unknown Pet";
        }
    } else {
        return @"No Pet";
    }
}

- (bycopy NSString*)playerStatus {
    return [controller currentStatus];
}


- (NSString*)castingSpell {
    NSNumber *spellID = [NSNumber numberWithInt: [playerController spellCasting]];
    Spell *spell = [[SpellController sharedSpells] spellForID: spellID];
    if([spell fullName]) {
        return [spell fullName];
    } else {
        if([spellID intValue] > 0)
            return [spellID stringValue];
        else
            return @"None";
    }
    return @"Unknown";
}

- (NSNumber*)castPercentage {
    if([playerController isCasting]) {
        float time = [playerController castTime];
        float rema = [playerController castTimeRemaining];
        if(time > 0) {
            return [NSNumber numberWithFloat: rema / time];
        }
    }
    return [NSNumber numberWithInt: 0];
}


// target
- (bycopy NSString*)targetName {
    GUID targetID = [playerController targetID];
    
    if(targetID) {
        Unit *unit = [[MobController sharedController] mobWithGUID: targetID];
        if( [unit isValid] ) {
            NSString *name = [unit name];
            if( name && [name length]) {
                return name;
            } else {
                return @"Unknown Name";
            }
        } else {
            if(targetID == [[playerController player] GUID]) {
                return [self playerName];
            }
            return @"Unknown Target";
        }
    } else {
        return @"No Target";
    }
}

- (bycopy NSNumber*)targetHealth {
    GUID targetID = [playerController targetID];
    if(targetID) {
        Unit *unit = [[MobController sharedController] mobWithGUID: targetID];
        if( [unit isValid] ) {
            return [NSNumber numberWithInt: [unit percentHealth]];
        }
    }
    return nil;
}

- (bycopy NSNumber*)targetLevel {
    GUID targetID = [playerController targetID];
    if(targetID) {
        Unit *unit = [[MobController sharedController] mobWithGUID: targetID];
        if( [unit isValid] ) {
            return [NSNumber numberWithInt: [unit level]];
        }
    }
    return nil;
}

- (bycopy NSData*)windowImage {
    NSBitmapImageRep *ss = [NSBitmapImageRep bitmapRepWithWindow: [controller getWOWWindowID]];
    
    if(ss) {
        return [[[NSImage imageWithBitmapRep: ss] thumbnailWithMaxDimension: 480.0f] TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: 1.0];
        //return [ss TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: 1.0];
    }
    return nil;
}

@end
