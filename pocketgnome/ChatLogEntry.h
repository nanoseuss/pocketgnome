//
//  ChatLogEntry.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/3/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ChatLogEntry : NSObject {
    NSInteger _sequence;
    NSDictionary *_attributes;
    NSDate *_timestamp;
}

+ (ChatLogEntry*)entryWithSequence: (NSInteger)sequence attributes: (NSDictionary*)attribs;

@property (readwrite, retain) NSDate *timestamp;
@property (readwrite, assign) NSInteger sequence;
@property (readwrite, retain) NSDictionary *attributes;

@property (readonly) NSString *type;
@property (readonly) NSString *channel;
@property (readonly) NSString *playerName;
@property (readonly) NSString *text;

@end
