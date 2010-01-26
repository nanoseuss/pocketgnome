//
//  CombatProfileEditor.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/19/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "CombatProfileEditor.h"

#import "PlayersController.h"
#import "BotController.h"
#import "Controller.h"
#import "MobController.h"
#import "SaveData.h"

#import "Offsets.h"
#import "Mob.h"

@interface CombatProfileEditor ()
@property (readwrite, retain) CombatProfile *currentCombatProfile;
@end

@interface CombatProfileEditor (Internal)
- (void)saveCombatProfiles;
@end

@implementation CombatProfileEditor

static CombatProfileEditor *sharedEditor = nil;

+ (CombatProfileEditor *)sharedEditor {
	if (sharedEditor == nil)
		sharedEditor = [[[self class] alloc] init];
	return sharedEditor;
}

- (id) init {
    self = [super init];
    if(sharedEditor) {
		[self release];
		self = sharedEditor;
    } if (self != nil) {
		sharedEditor = self;
        self.currentCombatProfile = nil;
		_nameBeforeRename = nil;
		
		// old way
		_combatProfiles = [[self loadAllDataForKey:@"CombatProfiles" withClass:[CombatProfile class]] retain];
		
		// new way!
		if ( !_combatProfiles ){
			_combatProfiles = [[self loadAllObjects] retain];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
            
        [NSBundle loadNibNamed: @"CombatProfile" owner: self];
    }
    return self;
}


- (void)awakeFromNib {
    // set a profile as our default loaded
    if( !self.currentCombatProfile && [_combatProfiles count]) {
        self.currentCombatProfile = [_combatProfiles objectAtIndex: 0];
        [ignoreTable reloadData];
    }
}

@synthesize combatProfiles = _combatProfiles;
@synthesize currentCombatProfile = _currentCombatProfile;

- (void)applicationWillTerminate: (NSNotification*)notification {
    [self saveCombatProfiles];
}

- (void)populatePlayerList: (id)popUpButton withGUID:(UInt64)guid{
	
	NSMenu *playerMenu = [[[NSMenu alloc] initWithTitle: @"Player List"] autorelease];
	NSMenuItem *item;
	
	NSArray *friendlyPlayers = [playersController friendlyPlayers];
	
	if ( [friendlyPlayers count] > 0 ){
		
		[controller traverseNameList];
		
		for(Player *player in friendlyPlayers) {
			NSString *name = [playersController playerNameWithGUID:[player GUID]];
			
			item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ %@", name, player] action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setRepresentedObject: [NSNumber numberWithUnsignedLongLong:[player GUID]]];
			[item setTag:[player GUID]];
			[playerMenu addItem: item];
		}
	}
	else{
		item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"No Friendly Players Nearby"] action: nil keyEquivalent: @""] autorelease];
		[item setTag: 0];
		[item setIndentationLevel: 1];
		[item setRepresentedObject: nil];
		[playerMenu addItem: item];
	}
	
	[(NSPopUpButton*)popUpButton setMenu:playerMenu];	
	[(NSPopUpButton*)popUpButton selectItemWithTag:guid];
}

#pragma mark -

// update all 3!
- (void)populatePlayerLists{
	
	// update the list of names!
	[controller traverseNameList];
	
	// update all 3 lists!
	[self populatePlayerList:tankPopUpButton withGUID:self.currentCombatProfile.tankUnitGUID];
	[self populatePlayerList:assistPopUpButton withGUID:self.currentCombatProfile.assistUnitGUID];
	[self populatePlayerList:followPopUpButton withGUID:self.currentCombatProfile.followUnitGUID];
}

- (void)showEditorOnWindow: (NSWindow*)window forProfileNamed: (NSString*)profileName {

	[self populatePlayerLists];
	
	if([profileName length]) {
        for(CombatProfile *profile in [self combatProfiles]) {
            if( [profileName isEqualToString: [profile name]] ) {
                self.currentCombatProfile = profile;
                break;
            }
        }
    }
	
	[NSApp beginSheet: editorPanel
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: @selector(editorDidEnd: returnCode: contextInfo:)
		  contextInfo: nil];
}

- (void)editorDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[self currentCombatProfile].changed = YES;
}

- (void)saveCombatProfiles {
	
	// save all for now
	for ( CombatProfile *profile in _combatProfiles ){
		//if ( profile.changed ){
			[self saveObject:profile];
		//}
	}

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CombatProfiles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray*)combatProfiles {
    return [[_combatProfiles retain] autorelease];
}

- (void)addCombatProfile: (CombatProfile*)profile {
    int num = 2;
    BOOL done = NO;
    
    if(![[profile name] length]) return;
    
    // check to see if a route exists with this name
    NSString *originalName = [profile name];
    while(!done) {
        BOOL conflict = NO;
        for(CombatProfile *aProfile in self.combatProfiles) {
            if( [[aProfile name] isEqualToString: [profile name]]) {
                [profile setName: [NSString stringWithFormat: @"%@ %d", originalName, num++]];
                conflict = YES;
                break;
            }
        }
        if(!conflict) done = YES;
    }
    
    // save this route into our array
    [self willChangeValueForKey: @"combatProfiles"];
    [_combatProfiles addObject: profile];
    [self didChangeValueForKey: @"combatProfiles"];

    // update the current route
    self.currentCombatProfile = profile;
	
	// we will want to save this later!
	[self currentCombatProfile].changed = YES;
    
    [self saveCombatProfiles];
    [ignoreTable reloadData];
}

- (IBAction)createCombatProfile: (id)sender {
    // make sure we have a valid name
    NSString *name = [sender stringValue];
    if( [name length] == 0) {
        NSBeep();
        return;
    }
    
    [self addCombatProfile: [CombatProfile combatProfileWithName: name]];
    [sender setStringValue: @""];
}

- (IBAction)loadCombatProfile: (id)sender {
	[self currentCombatProfile].changed = YES;
    [ignoreTable reloadData];
}


- (IBAction)renameCombatProfile: (id)sender {
	
	_nameBeforeRename = [[self.currentCombatProfile name] copy];
	
	[NSApp beginSheet: renamePanel
	   modalForWindow: editorPanel
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
}

- (IBAction)closeRename: (id)sender {
    [[sender window] makeFirstResponder: [[sender window] contentView]];
    [NSApp endSheet: renamePanel returnCode: 1];
    [renamePanel orderOut: nil];
    [self saveCombatProfiles];
	
	// did the name change?
	if ( ![_nameBeforeRename isEqualToString:[[self currentCombatProfile] name]] ){
		[self currentCombatProfile].changed = YES;
		[self deleteObjectWithName:_nameBeforeRename];
	}
}

- (IBAction)duplicateCombatProfile: (id)sender {
    [self addCombatProfile: [self.currentCombatProfile copy]];
}

- (IBAction)deleteCombatProfile: (id)sender {
    if(self.currentCombatProfile) {
        
        int ret = NSRunAlertPanel(@"Delete Combat Profile?", [NSString stringWithFormat: @"Are you sure you want to delete the combat profile \"%@\"?", [self.currentCombatProfile name]], @"Delete", @"Cancel", NULL);
        if(ret == NSAlertDefaultReturn) {
            [self willChangeValueForKey: @"combatProfiles"];
            [_combatProfiles removeObject: self.currentCombatProfile];
			
			[self deleteObject:self.currentCombatProfile];
            
            if([self.combatProfiles count])
                self.currentCombatProfile = [self.combatProfiles objectAtIndex: 0];
            else
                self.currentCombatProfile = nil;
            
            [self didChangeValueForKey: @"combatProfiles"];
            [self saveCombatProfiles];
            [ignoreTable reloadData];
        }
    }
}

- (id)importCombatProfileAtPath: (NSString*)path {
    id importedProfile;
    NS_DURING {
        importedProfile = [NSKeyedUnarchiver unarchiveObjectWithFile: path];
    } NS_HANDLER {
        importedProfile = nil;
    } NS_ENDHANDLER
    
    if(importedProfile && [importedProfile isKindOfClass: [CombatProfile class]]) {
        [self addCombatProfile: importedProfile];
		
		return importedProfile;
    } else {
        NSRunAlertPanel(@"Profile not Valid", [NSString stringWithFormat: @"The file at %@ cannot be imported because it does not contain a valid profile.", path], @"Okay", NULL, NULL);
    }
	return nil;
}

- (IBAction)importCombatProfile: (id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	[openPanel setCanChooseDirectories: NO];
	[openPanel setCanCreateDirectories: NO];
	[openPanel setPrompt: @"Import Combat Profile"];
	[openPanel setCanChooseFiles: YES];
    [openPanel setAllowsMultipleSelection: YES];
	
	int ret = [openPanel runModalForTypes: [NSArray arrayWithObject: @"combatProfile"]];
    
	if(ret == NSFileHandlingPanelOKButton) {
        for(NSString *behaviorPath in [openPanel filenames]) {
            [self importCombatProfileAtPath: behaviorPath];
        }
	}
}

- (IBAction)exportCombatProfile: (id)sender {

    if(!self.currentCombatProfile) return;
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories: YES];
    [savePanel setTitle: @"Export Combat Profile"];
    [savePanel setMessage: @"Please choose a destination for this profile."];
    int ret = [savePanel runModalForDirectory: @"~/" file: [[self.currentCombatProfile name] stringByAppendingPathExtension: @"combatProfile"]];
    
	if(ret == NSFileHandlingPanelOKButton) {
        NSString *saveLocation = [savePanel filename];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: self.currentCombatProfile];
        if(!data || ![data writeToFile: saveLocation atomically: YES]) {
            NSBeep();
            PGLog(@"Error while exporting %@", self.currentCombatProfile);
        }
    }
}

#pragma mark -
#pragma mark Ignore Entries

- (IBAction)addIgnoreEntry: (id)sender {
    if(!self.currentCombatProfile) return;
    
    [self.currentCombatProfile addEntry: [IgnoreEntry entry]];
	[self currentCombatProfile].changed = YES;
    [ignoreTable reloadData];
}

- (IBAction)addIgnoreFromTarget: (id)sender {
    if(!self.currentCombatProfile) return;
    
    Mob *mob = [mobController playerTarget];
    
    if(!mob) {
        NSBeep();
        return;
    }
    
    IgnoreEntry *entry = [IgnoreEntry entry];
    entry.ignoreType = [NSNumber numberWithInt: 0];
    entry.ignoreValue = [NSNumber numberWithInt: [mob entryID]];
    [self.currentCombatProfile addEntry: entry];
	[self currentCombatProfile].changed = YES;
    [ignoreTable reloadData];
}

- (IBAction)deleteIgnoreEntry: (id)sender {
    NSIndexSet *rowIndexes = [ignoreTable selectedRowIndexes];
    if([rowIndexes count] == 0 || ![self currentCombatProfile]) return;
    
    int row = [rowIndexes lastIndex];
    while(row != NSNotFound) {
        [[self currentCombatProfile] removeEntryAtIndex: row];
        row = [rowIndexes indexLessThanIndex: row];
    }

    [ignoreTable selectRow: [rowIndexes firstIndex] byExtendingSelection: NO]; 
    
    [ignoreTable reloadData];
	[self currentCombatProfile].changed = YES;
}


- (IBAction)closeEditor: (id)sender {
    [[sender window] makeFirstResponder: [[sender window] contentView]];
    [NSApp endSheet: editorPanel returnCode: NSOKButton];
    [editorPanel orderOut: nil];
	[botController updateStatus:nil];
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    if(aTableView == ignoreTable) {
        return [self.currentCombatProfile entryCount];
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if(rowIndex == -1) return nil;
    if(aTableView == ignoreTable) {
        if(rowIndex >= [self.currentCombatProfile entryCount]) return nil;
        
        if([[aTableColumn identifier] isEqualToString: @"Type"])
            return [[self.currentCombatProfile entryAtIndex: rowIndex] ignoreType];
        
        if([[aTableColumn identifier] isEqualToString: @"Value"]) {
            return [[self.currentCombatProfile entryAtIndex: rowIndex] ignoreValue];
        }
    }
    
    return nil;
}


- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if([[aTableColumn identifier] isEqualToString: @"Type"])
        [[self.currentCombatProfile entryAtIndex: rowIndex] setIgnoreType: anObject];
    
    if([[aTableColumn identifier] isEqualToString: @"Value"]) {
        [[self.currentCombatProfile entryAtIndex: rowIndex] setIgnoreValue: anObject];
    }
}

#pragma mark SaveData
// for saving
- (NSString*)objectExtension{
	return @"combatprofile";
}

- (NSString*)objectName:(id)object{
	return [(CombatProfile*)object name];
}

@end
