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

// THIS CLASS IS IN NO WAY READY FOR ANYTHING.

#import <Cocoa/Cocoa.h>


@interface ChatAction : NSObject <NSCopying> {
    NSString *_name;
    NSPredicate *_predicate;
    BOOL _actionStopBot, _actionStartBot;
    BOOL _actionQuit, _actionHearth;
    BOOL _actionEmail, _actionIM;
    NSString *_emailAddress, *_imName;
}

+ (ChatAction*)chatActionWithName: (NSString*)name;

@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSPredicate *predicate;

@property (readwrite, assign) BOOL actionStopBot;
@property (readwrite, assign) BOOL actionHearth;
@property (readwrite, assign) BOOL actionQuit;
@property (readwrite, assign) BOOL actionStartBot;
@property (readwrite, assign) BOOL actionEmail;
@property (readwrite, assign) BOOL actionIM;

@property (readwrite, retain) NSString *emailAddress;
@property (readwrite, retain) NSString *imName;

@end
