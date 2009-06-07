//
//  MemoryViewController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "MemoryViewController.h"
#import "Controller.h"

#import "WoWObject.h"

@interface MemoryViewController ()
@property (readwrite, retain) NSNumber *currentAddress;
@property (readwrite, retain) id wowObject;
@end

@interface MemoryViewController (Internal)
- (void)setBaseAddress: (NSNumber*)address;
- (void)setBaseAddress: (NSNumber*)address withCount: (int)count;
@end

@implementation MemoryViewController

- (id) init
{
    self = [super init];
    if (self != nil) {
        [NSBundle loadNibNamed: @"Memory" owner: self];
        self.currentAddress = nil;
        _displayCount = 0;
        self.wowObject = nil;
    }
    return self;
}

- (void)dealloc {
    self.currentAddress = nil;
    
    [super dealloc];
}

- (void)awakeFromNib {
    
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;

    [memoryTable setDoubleAction: @selector(tableDoubleClick:)];
    [(NSTableView*)memoryTable setTarget: self];
    
    [self setRefreshFrequency: 0.5];
}

@synthesize view;
@synthesize refreshFrequency;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize currentAddress;
@synthesize wowObject = _wowObject;

- (NSString*)sectionTitle {
    return @"Memory";
}

- (void)setRefreshFrequency: (float)frequency {
    [_refreshTimer invalidate];
    [_refreshTimer release];

    [self willChangeValueForKey: @"refreshFrequency"];
    refreshFrequency = frequency;
    [self didChangeValueForKey: @"refreshFrequency"];

    _refreshTimer = [NSTimer scheduledTimerWithTimeInterval: frequency target: self selector: @selector(reloadData:) userInfo: nil repeats: YES];
    [_refreshTimer retain];
}

- (int)displayFormat {
    return _displayFormat;
}

- (void)setDisplayFormat: (int)displayFormat {
    _displayFormat = displayFormat;
    [memoryTable reloadData];
}


- (void)showObjectMemory: (id)object {
    if( [object conformsToProtocol: @protocol(WoWObjectMemory)]) {
        self.wowObject = object;
		
		PGLog(@"Count: %d", (([object memoryEnd] - [object memoryStart]) / sizeof(UInt32)));
        [self setBaseAddress: [NSNumber numberWithUnsignedInt: [object baseAddress]] 
                   withCount: (([object memoryEnd] - [object memoryStart] + 0x1000) / sizeof(UInt32))];
    } else {
        self.wowObject = nil;
    }
}

- (void)setBaseAddress: (NSNumber*)address {
    self.wowObject = nil;
    [self setBaseAddress: address withCount: 5000];
}

- (void)setBaseAddress: (NSNumber*)address withCount: (int)count {
    _displayCount = count;
    
    self.currentAddress = address;
    
    [memoryTable reloadData];
}

- (IBAction)setCustomAddress: (id)sender {
    
    if( [[sender stringValue] length]) {
        NSScanner *scanner = [NSScanner scannerWithString: [sender stringValue]];
        uint32_t addr;
        [scanner scanHexInt: &addr];
        [self setBaseAddress: [NSNumber numberWithUnsignedInt: addr]];
    } else {
        self.currentAddress = nil;
    }
    
    [memoryTable reloadData];
}

- (IBAction)clearTable: (id)sender {
    self.currentAddress = nil;
    _displayCount = 0;
    self.wowObject = nil;
}

- (IBAction)snapshotMemory: (id)sender {
    
    UInt32 startAddress = [self.currentAddress unsignedIntValue];
    MemoryAccess *memory = [controller wowMemoryAccess];
    
    if(!startAddress || !memory || ([self displayFormat] == 2)) {
        NSBeep();
        return;
    }
    
    int i = 0;
    UInt32 buffer = 0;
    //Byte buffer[4] = { 0, 0, 0, 0 };
    NSString *export = @"";
    
    for(i=0; i<_displayCount; i++) {
        if([memory loadDataForObject: self atAddress: (startAddress + sizeof(buffer)*i) Buffer: (Byte*)&buffer BufLength: sizeof(buffer)]) {
            if([self displayFormat] == 0)
                export = [NSString stringWithFormat: @"%@\n0x%X: %u", export, 4*i, (UInt32)buffer];
            if([self displayFormat] == 1)
                export = [NSString stringWithFormat: @"%@\n0x%X: %d", export, 4*i, (int)buffer];
            if([self displayFormat] == 3) {
                export = [NSString stringWithFormat: @"%@\n0x%X: %f", export, 4*i, *(float*)&buffer];
            }
            if([self displayFormat] == 4) {
                export = [NSString stringWithFormat: @"%@\n0x%X: 0x%X", export, 4*i, (UInt32)buffer];
            }
        } else {
            export = [NSString stringWithFormat: @"%@\n0x%X: err", export, 4*i];
        }
    }
    
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories: YES];
    [savePanel setTitle: @"Save Snapshot"];
    [savePanel setMessage: @"Please choose a destination for this snapshot."];
    int ret = [savePanel runModalForDirectory: @"~/" file: [[NSString stringWithFormat: @"%X", startAddress] stringByAppendingPathExtension: @"txt"]];
    
	if(ret == NSFileHandlingPanelOKButton) {
        NSString *saveLocation = [savePanel filename];
        [export writeToFile: saveLocation atomically: YES encoding: NSUTF8StringEncoding error: NULL];
    }
}
    
#pragma mark -

- (void)reloadData: (id)timer {
    if([memoryTable editedRow] == -1)
        [memoryTable reloadData];
}

- (BOOL)validState {
    return (self.currentAddress && [controller wowMemoryAccess]);
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    if([self validState]) {
        return _displayCount;
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1)      return nil;
    if(![self validState])  return nil;
    
    uint32_t value32 = 0;
    //uint64_t value64, targetID = 0;
    unsigned startAddress = [self.currentAddress unsignedIntValue];
    size_t size = ([self displayFormat] == 2) ? sizeof(uint64_t) : sizeof(uint32_t);
    
    uint32_t addr = startAddress + rowIndex*size;
    
    if( [[aTableColumn identifier] isEqualToString: @"Address"] ) {
        return [NSString stringWithFormat: @"0x%X", addr];
    }
    if( [[aTableColumn identifier] isEqualToString: @"Offset"] ) {
        return [NSString stringWithFormat: @"+0x%X", (addr - startAddress)];
    }
    
    if( [[aTableColumn identifier] isEqualToString: @"Value"] ) {
        MemoryAccess *memory = [controller wowMemoryAccess];
        int ret = [memory readAddress: addr Buffer: (Byte*)&value32 BufLength: sizeof(value32)];
        if((ret == KERN_SUCCESS)) {

            if([self displayFormat] == 0)
                return [NSString stringWithFormat: @"%u", value32];
            if([self displayFormat] == 1)
                return [NSString stringWithFormat: @"%d", value32];
            if([self displayFormat] == 2) {
                uint64_t value64;
                [memory loadDataForObject: self atAddress: addr Buffer: (Byte*)&value64 BufLength: sizeof(uint64_t)];
                return [NSString stringWithFormat: @"%llu", value64];
            }
            if([self displayFormat] == 3) {
                float floatVal;
                [memory loadDataForObject: self atAddress: addr Buffer: (Byte*)&floatVal BufLength: sizeof(float)];
                return [NSString stringWithFormat: @"%f", floatVal];
            }
            if([self displayFormat] == 4) {
                return [NSString stringWithFormat: @"0x%X", value32];
            }
        } else {
            return [NSString stringWithFormat: @"(error: %d)", ret];
        }
    }
    
    if( [[aTableColumn identifier] isEqualToString: @"Info"] ) {
        id info = nil;
        if([self.wowObject respondsToSelector: @selector(descriptionForOffset:)])
            info = [self.wowObject descriptionForOffset: (addr - startAddress)];
        
        if(!info || ![info length]) {
            char str[5];
            str[4] = '\0';
            [[controller wowMemoryAccess] loadDataForObject: self atAddress: addr Buffer: (Byte*)&str BufLength: 4];
            
            NSString *tehString = [NSString stringWithUTF8String: str];
            if([tehString length])
                return [NSString stringWithFormat: @"\"%@\"", [NSString stringWithUTF8String: str]];
        }
        return info;
    }
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if([[aTableColumn identifier] isEqualToString: @"Value"])
        return YES;
    return NO;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    //PGLog(@"Setting %@ at row %d", anObject, rowIndex);
    
    int type = [self displayFormat];
    if(type == 0 || type == 4) {
        UInt32 value = [anObject intValue];
        [[controller wowMemoryAccess] saveDataForAddress: ([self.currentAddress unsignedIntValue] + rowIndex*4) Buffer: (Byte*)&value BufLength: sizeof(value)];
    }
    if(type == 1) {
        SInt32 value = [anObject intValue];
        [[controller wowMemoryAccess] saveDataForAddress: ([self.currentAddress unsignedIntValue] + rowIndex*4) Buffer: (Byte*)&value BufLength: sizeof(value)];
    }
    if(type == 2) {
        UInt64 value = [anObject longLongValue];
        [[controller wowMemoryAccess] saveDataForAddress: ([self.currentAddress unsignedIntValue] + rowIndex*4) Buffer: (Byte*)&value BufLength: sizeof(value)];
    }
    if(type == 3) {
        float value = [anObject floatValue];
        [[controller wowMemoryAccess] saveDataForAddress: ([self.currentAddress unsignedIntValue] + rowIndex*4) Buffer: (Byte*)&value BufLength: sizeof(value)];
    }
}

- (void)tableDoubleClick: (id)sender {
    if( [sender clickedRow] == -1 ) return;
    
    unsigned startAddress = [self.currentAddress unsignedIntValue];
    size_t size = ([self displayFormat] == 2) ? sizeof(uint64_t) : sizeof(uint32_t);
    
    uint32_t addr = startAddress + [sender clickedRow]*size;
    
    uint32_t value = 0;
    if([[controller wowMemoryAccess] loadDataForObject: self atAddress: addr Buffer: (Byte*)&value BufLength: sizeof(value)] && value) {
        if(value >= startAddress && value <= startAddress + _displayCount*size) {
            int line = (value - startAddress)/4;
            [memoryTable scrollRowToVisible: line];
            [memoryTable selectRowIndexes: [NSIndexSet indexSetWithIndex: line] byExtendingSelection: NO];
        }
    }
}

@end
