//
//  BonjourController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/2/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//
//  This class implements basic network/bonjour support for the iPhone app I never finished.
//  

#import <Cocoa/Cocoa.h>


@protocol WoWRemoteProtocol
@required

// general
- (bycopy NSNumber*)fps;
- (BOOL)playerIsValid;

// player
- (bycopy NSString*)playerName;
- (bycopy NSNumber*)playerLevel;
- (bycopy NSString*)playerClass;
- (bycopy NSString*)playerRace;

- (bycopy NSNumber*)playerHealth;
- (bycopy NSNumber*)playerHealthMax;
- (bycopy NSNumber*)playerPower;
- (bycopy NSNumber*)playerPowerMax;

- (bycopy NSNumber*)playerSpeed;

- (bycopy NSString*)playerPetName;
- (bycopy NSString*)playerStatus;

// spells
- (bycopy NSString*)castingSpell;
- (bycopy NSNumber*)castPercentage;

// target
- (bycopy NSString*)targetName;
- (bycopy NSNumber*)targetHealth;
- (bycopy NSNumber*)targetLevel;

- (bycopy NSData*)windowImage;

@end

@class Controller;
@class PlayerDataController;

@interface BonjourController : NSObject <WoWRemoteProtocol> {
    IBOutlet Controller *controller;
    IBOutlet PlayerDataController *playerController;

	NSConnection *_connection;
    NSNetService *_netService;
}

@property (readwrite, retain) NSConnection *connection;
@property (readwrite, retain) NSNetService *netService;


@end
