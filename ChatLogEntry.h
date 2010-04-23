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

#import <Cocoa/Cocoa.h>


@interface ChatLogEntry : NSObject {
    NSDate *_dateStamp;
    NSNumber *_sequence;
    NSNumber *_timeStamp;
    NSDictionary *_attributes;


    NSUInteger _passNumber, _relativeOrder;
}

+ (ChatLogEntry*)entryWithSequence: (NSInteger)sequence timeStamp: (NSInteger)timeStamp attributes: (NSDictionary*)attribs;

+ (NSString*)nameForChatType: (NSString*)type;


@property (readwrite, assign) NSUInteger passNumber;
@property (readwrite, assign) NSUInteger relativeOrder;

@property (readwrite, retain) NSDate *dateStamp;        // date when PG finds the chat, not when it was actually sent
@property (readwrite, retain) NSNumber *timeStamp;      // number embedded by wow; isn't always right... i'm not actually sure what it is
@property (readwrite, retain) NSNumber *sequence;
@property (readwrite, retain) NSDictionary *attributes;

@property (readonly) NSString *type;
@property (readonly) NSString *typeName;
@property (readonly) NSString *typeVerb;
@property (readonly) NSString *channel;
@property (readonly) NSString *playerName;
@property (readonly) NSString *text;

@property (readonly) BOOL isEmote;
@property (readonly) BOOL isSpoken;
@property (readonly) BOOL isWhisper;
@property (readonly) BOOL isWhisperSent;
@property (readonly) BOOL isWhisperReceived;
@property (readonly) BOOL isChannel;

@property (readonly) NSArray *whisperTypes;

@property (readonly) NSString *wellFormattedText;

@end
