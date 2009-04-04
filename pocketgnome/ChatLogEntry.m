//
//  ChatLogEntry.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/3/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "ChatLogEntry.h"

#define ChatEntryTypeKey @"Type"
#define ChatEntryChannelKey @"Channel"
#define ChatEntryPlayerNameKey @"Player Name"
#define ChatEntryTextKey @"Text"

@implementation ChatLogEntry

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.sequence = -1;
        self.attributes = nil;
    }
    return self;
}

- (void) dealloc
{
    self.attributes = nil;
    self.timestamp = nil;
    [super dealloc];
}

+ (ChatLogEntry*)entryWithSequence: (NSInteger)sequence attributes: (NSDictionary*)attribs {
    ChatLogEntry *newEntry = [[ChatLogEntry alloc] init];
    newEntry.timestamp = [NSDate date];
    newEntry.sequence = sequence;
    newEntry.attributes = attribs;
    return [newEntry autorelease];
}

- (BOOL)isEqual: (id)object {
    if( [object isKindOfClass: [self class]] ) {
        ChatLogEntry *other = (ChatLogEntry*)object;
        return (self.sequence == other.sequence &&
                [self.type isEqualToString: other.type] &&
                [self.channel isEqualToString: other.channel] &&
                [self.playerName isEqualToString: other.playerName] &&
                [self.text isEqualToString: other.text]);
    }
    return NO;
}

+ (NSString*)nameForChannel: (NSString*)channel {
    NSInteger chan = [channel integerValue];
    switch(chan) {
        case 0:
            return @"Addon"; break;
        case 1:
            return @"Say"; break;
        case 2:
            return @"Party"; break;
        case 3:
            return @"Raid"; break;
        case 4:
            return @"Guild"; break;
        case 5:
            return @"Officer"; break;
        case 6:
            return @"Yell"; break;
        case 7:
            return @"Whisper (Received)"; break;
        case 8:
            return @"Whisper (Mob)"; break;
        case 9:
            return @"Whisper (Sent)"; break;
        case 10:
            return @"Emote"; break;
        case 11:
            return @"Emote (Text)"; break;
        case 12:
            return @"Monster (Say)"; break;
        case 13:
            return @"Monster (Party)"; break;
        case 14:
            return @"Monster (Yell)"; break;
        case 15:
            return @"Monster (Whisper)"; break;
        case 16:
            return @"Monster (Emote)"; break;
        case 17:
            return @"Channel"; break;
        case 18:
            return @"Channel (Join)"; break;
        case 19:
            return @"Channel (Leave)"; break;
        case 20:
            return @"Channel (List)"; break;
        case 21:
            return @"Channel (Notice)"; break;
        case 22:
            return @"Channel (Notice User)"; break;
        case 23:
            return @"AFK"; break;
        case 24:
            return @"DND"; break;
        case 25:
            return @"Ignored"; break;
        case 26:
            return @"Skill"; break;
        case 27:
            return @"Loot"; break;
        case 28:
            return @"System"; break;
            // lots of unknown in here [29-34]
        case 35:
            return @"BG (Neutral)"; break;
        case 36:
            return @"BG (Alliance)"; break;
        case 37:
            return @"BG (Horde)"; break;
        case 38:
            return @"Combat Faction Change (wtf?)"; break;
        case 39:
            return @"Raid Leader"; break;
        case 40:
            return @"Raid Warning"; break;
        case 41:
            return @"Raid Warning (Widescreen)"; break;
            // 42 ???
        case 43:
            return @"Filtered"; break;
        case 44:
            return @"Battleground"; break;
        case 45:
            return @"Battleground (Leader)"; break;
        case 46:
            return @"Restricted"; break;
    }
    return [NSString stringWithFormat: @"Unknown (%@)", channel];
}

@synthesize sequence = _sequence;
@synthesize timestamp = _timestamp;
@synthesize attributes = _attributes;

- (NSString*)type {
    return [self.attributes objectForKey: ChatEntryTypeKey];
}

- (NSString*)channel {
    return [self.attributes objectForKey: ChatEntryChannelKey];
}

- (NSString*)playerName {
    return [self.attributes objectForKey: ChatEntryPlayerNameKey];
}

- (NSString*)text {
    return [self.attributes objectForKey: ChatEntryTextKey];
}

- (NSString*)description {
    return [NSString stringWithFormat: @"<%@ -%d- [%@] %@: \"%@\"%@>", isa, self.sequence, [ChatLogEntry nameForChannel: self.type], self.playerName, self.text, ([self.channel length] ? [NSString stringWithFormat: @" (%@)", self.channel] : @"")];
}
@end
