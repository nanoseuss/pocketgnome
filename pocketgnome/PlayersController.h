//
//  PlayersController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/25/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Player;

@class Controller;
@class PlayerDataController;
@class MemoryViewController;
@class MovementController;

@interface PlayersController : NSObject {
    IBOutlet Controller *controller;
    IBOutlet PlayerDataController *playerData;
    IBOutlet MemoryViewController *memoryViewController;
    IBOutlet MovementController *movementController;

    IBOutlet NSView *view;
    IBOutlet NSTableView *playerTable;
    IBOutlet NSButton *playerColorByLevel;
    
    IBOutlet id trackFriendly;
    IBOutlet id trackHostile;

    NSMutableArray *_playerList;
    NSMutableArray *_playerDataList;

    int cachedPlayerLevel;
    NSTimer *_updateTimer;
    NSSize minSectionSize, maxSectionSize;
    float updateFrequency;
}

@property (readonly) unsigned playerCount;
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property float updateFrequency;

+ (PlayersController *)sharedPlayers;
- (NSArray*)allPlayers;
- (Player*)playerTarget;
- (Player*)playerWithGUID: (GUID)guid;
- (void)addAddresses: (NSArray*)addresses;
//- (BOOL)addPlayer: (Player*)player;
- (void)resetAllPlayers;

- (NSArray*)playersWithinDistance: (float)distance
                       levelRange: (NSRange)range
                  includeFriendly: (BOOL)friendly
                   includeNeutral: (BOOL)neutral
                   includeHostile: (BOOL)hostile;
- (NSArray*)friendlyPlayers;

- (IBAction)facePlayer: (id)sender;
- (IBAction)targetPlayer: (id)sender;
- (IBAction)resetPlayerList: (id)sender;

- (IBAction)updateTracking: (id)sender;
@end
