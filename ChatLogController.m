//
//  ChatLogController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/3/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "ChatLogController.h"

#import "Controller.h"
#import "MemoryAccess.h"
#import "ChatLogEntry.h"

#define ChatLog_Start 0x14A75FC
#define ChatLog_Offset 0x17BC

@interface ChatLogController (Internal)

- (void)kickOffScan;

@end


@implementation ChatLogController

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.shouldScan = NO;
        _chatLog = [[NSMutableArray array] retain];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsValid:) name: MemoryAccessValidNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsInvalid:) name: MemoryAccessInvalidNotification object: nil];
        
#ifdef PGLOGGING
        [self kickOffScan]; // feel free to turn this off...
#endif
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [_chatLog release];
    [super dealloc];
}


@synthesize shouldScan = _shouldScan;

- (void)memoryIsValid: (NSNotification*)notification {
    self.shouldScan = YES;
}

- (void)memoryIsInvalid: (NSNotification*)notification {
    self.shouldScan = NO;
}

// this is run in a separate thread
- (void)scanChatLog {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(self.shouldScan && memory) {
        int i;
        NSMutableArray *chatEntries = [NSMutableArray array];
        for(i = 0; i< 60; i++) {
            char buffer[317];
            UInt32 logStart = ChatLog_Start + ChatLog_Offset*i;
            if([memory loadDataForObject: self atAddress: logStart Buffer: (Byte *)&buffer BufLength: sizeof(buffer)-1])
            {
                NSString *chatEntry = [NSString stringWithUTF8String: buffer];
                if([chatEntry length]) {
                    NSMutableDictionary *chatComponents = [NSMutableDictionary dictionary];
                    for(NSString *component in [chatEntry componentsSeparatedByString: @", "]) {
                        NSArray *keyValue = [component componentsSeparatedByString: @": "];
                        if([keyValue count] == 2) {
                            // now we have "key" and "[value]"
                            NSString *key = [keyValue objectAtIndex: 0];
                            NSString *value = [[keyValue objectAtIndex: 1] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"[]"]];
                            [chatComponents setObject: value forKey: key];
                        } else {
                            // bad data
                        }
                    }
                    if([chatComponents count]) {
                        ChatLogEntry *newEntry = [ChatLogEntry entryWithSequence: i attributes: chatComponents];
                        if(![_chatLog containsObject: newEntry]) {
                            [chatEntries addObject: newEntry];
                        }
                    }
                } else {
                    break;
                }
            }
        }
        if([chatEntries count]) {
            NSLog(@"%@", chatEntries);
            [_chatLog addObjectsFromArray: chatEntries];
        }
        
        
    }
    
    [self performSelectorOnMainThread: @selector(scanComplete) withObject: nil waitUntilDone: NO];
    [pool drain];
}


- (void)scanComplete {
    [self performSelector: @selector(kickOffScan) withObject: nil afterDelay: 5.0];
}

- (void)kickOffScan {
    [self performSelectorInBackground: @selector(scanChatLog) withObject: nil];
}

@end
