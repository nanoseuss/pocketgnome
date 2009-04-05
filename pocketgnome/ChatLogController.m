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

#define ChatLog_Start 0x14A75B0
//0x14A75FC

#define ChatLog_CounterOffset       0x8
#define ChatLog_TimestampOffset     0xC
#define ChatLog_UnitGUIDOffset      0x10
#define ChatLog_UnitNameOffset      0x1C
#define ChatLog_UnitNameLength      0x30
#define ChatLog_DescriptionOffset   0x4C
#define ChatLog_NextEntryOffset     0x17BC

#define ChatLog_TextOffset 0xBB8

@interface ChatLogController (Internal)

- (void)kickOffScan;
- (BOOL)chatLogContainsEntry: (ChatLogEntry*)entry;

@end


static NSUInteger passNumber = 0;

@implementation ChatLogController

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.shouldScan = NO;
        self.lastPassFoundChat = NO;
        _chatLog = [[NSMutableArray array] retain];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsValid:) name: MemoryAccessValidNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsInvalid:) name: MemoryAccessInvalidNotification object: nil];
        
#ifdef PGLOGGING
        [self kickOffScan]; // feel free to turn this off...
#endif
        
        _timestampFormat = [[NSDateFormatter alloc] init];
        [_timestampFormat setDateStyle: NSDateFormatterNoStyle];
        [_timestampFormat setTimeStyle: NSDateFormatterShortStyle];
        
        _passNumberSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"passNumber" ascending: YES];
        _relativeOrderSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"relativeOrder" ascending: YES];
        
        [NSBundle loadNibNamed: @"ChatLog" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [_timestampFormat release];
    [_chatLog release];
    [super dealloc];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Other Players";
}

@synthesize shouldScan = _shouldScan;
@synthesize lastPassFoundChat = _lastPassFoundChat;

- (void)memoryIsValid: (NSNotification*)notification {
    self.shouldScan = YES;
}

- (void)memoryIsInvalid: (NSNotification*)notification {
    self.shouldScan = NO;
}

// this is run in a separate thread
- (void)scanChatLog {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableArray *chatEntries = [NSMutableArray array];
    MemoryAccess *memory = [controller wowMemoryAccess];
    if(self.shouldScan && memory) {
        if(self.lastPassFoundChat) {
            passNumber++;
        }
        self.lastPassFoundChat = NO;
        
        int i;
        UInt32 highestSequence = 0, foundAt = 0, finishedAt = 0;
        for(i = 0; i< 60; i++) {
            finishedAt = i;
            char buffer[400];
            UInt32 logStart = ChatLog_Start + ChatLog_NextEntryOffset*i;
            if([memory loadDataForObject: self atAddress: logStart Buffer: (Byte *)&buffer BufLength: sizeof(buffer)-1])
            {
                //GUID unitGUID = *(GUID*)(buffer + ChatLog_UnitGUIDOffset);
                UInt32 sequence = *(UInt32*)(buffer + ChatLog_CounterOffset);
                //UInt32 timestamp = *(UInt32*)(buffer + ChatLog_TimestampOffset);
                
                // track highest sequence number
                if(sequence > highestSequence) {
                    highestSequence = sequence;
                    foundAt = i;
                }
                NSString *chatEntry = [NSString stringWithUTF8String: buffer + ChatLog_DescriptionOffset ];
                if([chatEntry length]) {
                    NSMutableDictionary *chatComponents = [NSMutableDictionary dictionary];
                    for(NSString *component in [chatEntry componentsSeparatedByString: @"], "]) {
                        NSArray *keyValue = [component componentsSeparatedByString: @": ["];
                        // "Text: [blah blah blah]"
                        if([keyValue count] == 2) {
                            // now we have "key" and "[value]"
                            NSString *key = [keyValue objectAtIndex: 0];
                            NSString *value = [[keyValue objectAtIndex: 1] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"[]"]];
                            [chatComponents setObject: value forKey: key];
                        } else {
                            // bad data
                            NSLog(@"Throwing out bad data: \"%@\"", component);
                        }
                    }
                    if([chatComponents count]) {
                        ChatLogEntry *newEntry = [ChatLogEntry entryWithSequence: i timeStamp: sequence attributes: chatComponents];
                        if(newEntry) {
                            [chatEntries addObject: newEntry];
                        }
                    }
                } else {
                    break;
                }
            }
        }
        
        for(ChatLogEntry *entry in chatEntries) {
            [entry setPassNumber: passNumber];
            NSUInteger sequence = [[entry sequence] unsignedIntegerValue];
            if(sequence >= foundAt) {
                [entry setRelativeOrder: sequence - foundAt];
            } else {
                [entry setRelativeOrder: 60 - foundAt + sequence];
            }
        }
        [chatEntries sortUsingDescriptors: [NSArray arrayWithObject: _relativeOrderSortDescriptor]];
    }
    
    [self performSelectorOnMainThread: @selector(scanCompleteWithNewEntries:) withObject: chatEntries waitUntilDone: YES];
    [pool drain];
}

- (BOOL)chatLogContainsEntry: (ChatLogEntry*)entry {
    BOOL contains = NO;
    @synchronized(_chatLog) {
        contains = [_chatLog containsObject: entry];
    }
    return contains;
}

- (void)scanCompleteWithNewEntries: (NSArray*)newEntries {
    if([newEntries count]) {
        // NSMutableArray *actualNewEntries = [NSMutableArray array];
        int lastRow = [_chatLog count] - 1;
        for(ChatLogEntry *entry in newEntries) {
            if(![_chatLog containsObject: entry]) {
                // NSLog(@"%@", entry);
                [_chatLog addObject: entry];
                self.lastPassFoundChat = YES;
                
                if(passNumber > 0 && ![entry isWhisperSent] && ![controller isWoWFront]) {
                    if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
                        [GrowlApplicationBridge notifyWithTitle: [entry isSpoken] ? [NSString stringWithFormat: @"%@ %@...", [entry playerName], [entry typeVerb]] : [NSString stringWithFormat: @"%@ (%@)", [entry playerName], [entry isChannel] ? [entry channel] : [entry typeName]]
                                                    description: [entry text]
                                               notificationName: @"PlayerReceivedMessage"
                                                       iconData: [[NSImage imageNamed: @"Trade_Engraving"] TIFFRepresentation]
                                                       priority: [entry isWhisperReceived] ? 100 : 0
                                                       isSticky: [entry isWhisperReceived] ? YES : NO
                                                   clickContext: nil];             
                    }
                }
            }
        }
        
        if(self.lastPassFoundChat) {
            [_chatLog sortUsingDescriptors: [NSArray arrayWithObjects: _passNumberSortDescriptor, _relativeOrderSortDescriptor, nil]];
            [chatLogTable reloadData];
            
            // if the previous last row of chat was visible, then we want to scroll the table down
            // if it was not visible, then we will not scroll.
            NSRange rowsInRect = [chatLogTable rowsInRect: [chatLogTable visibleRect]];
            int firstVisibleRow = rowsInRect.location, lastVisibleRow = rowsInRect.location + rowsInRect.length;
            if((passNumber == 0) || (lastRow >= 0 && (lastRow >= firstVisibleRow) && (lastRow <= lastVisibleRow))) {
                [chatLogTable scrollRowToVisible: [_chatLog count] - 1];
            }
        }
    }
    [self performSelector: @selector(kickOffScan) withObject: nil afterDelay: 5.0];
}

- (void)kickOffScan {
    [self performSelectorInBackground: @selector(scanChatLog) withObject: nil];
}


#pragma mark -
#pragma mark TableView Delegate & Datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_chatLog count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if((rowIndex == -1) || (rowIndex >= [_chatLog count]))
        return nil;
    
    if(aTableView == chatLogTable) {
        ChatLogEntry *entry = [_chatLog objectAtIndex: rowIndex];
        return [NSString stringWithFormat: @"[%u:%@] [%@] [%@] %@", entry.relativeOrder, entry.timeStamp, entry.sequence, [_timestampFormat stringFromDate: [entry dateStamp]], [entry wellFormattedText]];
    }
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}
- (BOOL)tableViewCopy: (NSTableView*)tableView {
    NSIndexSet *rowIndexes = [tableView selectedRowIndexes];
    if([rowIndexes count] == 0) {
        return NO;
    }
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes: [NSArray arrayWithObjects: NSStringPboardType, nil] owner: nil];
    
    NSMutableString *stringVal = [NSMutableString string];
    int row = [rowIndexes firstIndex];
    while(row != NSNotFound) {
        [stringVal appendFormat: @"%@\n", [[_chatLog objectAtIndex: row] wellFormattedText]];
        row = [rowIndexes indexGreaterThanIndex: row];
    }
    [pboard setString: stringVal forType: NSStringPboardType];
    
    return YES;
}

@end
