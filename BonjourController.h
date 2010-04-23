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
