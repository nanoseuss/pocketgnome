//
//  MyUserDefaults.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/21/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "SecureUserDefaults.h"
#import "UKKQueue.h"

@interface SecureUserDefaults ()
- (void)buildPath;
@end

@implementation SecureUserDefaults

#define SecureOwnerID       0
#define SecureOwnerGroupID  0
#define SecurePermissions   0600

static SecureUserDefaults* secureDefaults = nil;

+ (SecureUserDefaults *)secureUserDefaults {
	if (secureDefaults == nil)
		secureDefaults = [[[self class] alloc] init];
	return secureDefaults;
}

- (id) init {
    self = [super init];
	if(secureDefaults) {
		[self release];
		self = secureDefaults;
	} else if(self != nil) {
        secureDefaults = self;
        
        [self buildPath];
        
        if(self.prefPath) {
            [self updatePermissions];

            // watch this path
            [[UKKQueue sharedFileWatcher] setDelegate: self];
            [[UKKQueue sharedFileWatcher] addPathToQueue: prefPath];
        } else {
            log(LOG_GENERAL, @"Preferences cannot be secured because the file cannot be found.");
        }
        
    }
    return self;
}

- (void) dealloc
{
    [[UKKQueue sharedFileWatcher] setDelegate: nil];
    [[UKKQueue sharedFileWatcher] removePathFromQueue: self.prefPath];
    self.prefPath = nil;

    [super dealloc];
}


@synthesize prefPath;

- (void)buildPath {
    NSString *path = [[[[[@"~/" stringByExpandingTildeInPath] stringByAppendingPathComponent: @"Library"] stringByAppendingPathComponent: @"Preferences"] stringByAppendingPathComponent: [[NSDictionary dictionaryWithContentsOfFile: [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Contents"] stringByAppendingPathComponent: @"Info.plist"]] objectForKey: @"CFBundleIdentifier"]] stringByAppendingPathExtension: @"plist"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath: path]) {
        self.prefPath = path;
    } else {
        self.prefPath = nil;
    }
}

- (void)watcher: (id<UKFileWatcher>)kq receivedNotification: (NSString*)nm forPath: (NSString*)fpath {
    [self updatePermissions];
    [[UKKQueue sharedFileWatcher] addPathToQueue: fpath];
}

- (BOOL)updatePermissions {
    if([[[NSUserDefaults standardUserDefaults] objectForKey: @"SecurityPreferencesUnreadable"] boolValue]) {
        if([[NSFileManager defaultManager] fileExistsAtPath: self.prefPath]) {
            
            // validate current owner and perimissions
            NSDictionary *fileAttr = [[NSFileManager defaultManager] fileAttributesAtPath: self.prefPath traverseLink: YES];
            unsigned ownerID = [[fileAttr objectForKey: NSFileOwnerAccountID] unsignedLongValue];
            unsigned groupID = [[fileAttr objectForKey: NSFileGroupOwnerAccountID] unsignedLongValue];
            unsigned posixPm = [[fileAttr objectForKey: NSFilePosixPermissions] unsignedLongValue];
            
            if( (ownerID == SecureOwnerID) && (groupID == SecureOwnerGroupID) && (posixPm == SecurePermissions) ) {
                return YES; // we're good already
            } else {
                // current permissions are bad
                // log(LOG_GENERAL, @"Permissions %d:%d %O are incorrect.", ownerID, groupID, posixPm);
            }
            
            NSDictionary *newPermissions = [NSDictionary dictionaryWithObjectsAndKeys: 
                                            [NSNumber numberWithUnsignedLong: SecurePermissions],   NSFilePosixPermissions,             // owner RW only
                                            [NSNumber numberWithUnsignedLong: SecureOwnerID],       NSFileOwnerAccountID,               // root
                                            [NSNumber numberWithUnsignedLong: SecureOwnerGroupID],  NSFileGroupOwnerAccountID,          // wheel
                                            nil];
            
            // reset permissions
            NSError *error;
            if(![[NSFileManager defaultManager] setAttributes: newPermissions ofItemAtPath: self.prefPath error: &error]) {
                log(LOG_GENERAL, @"Error %@ setting permissions on preferences file.", error);
                return NO;
            }
            // log(LOG_GENERAL, @"Secured preferences.");
        } else {
            // preferences file does not exist
            return NO;
        }
    }
    
    return YES;
}

@end
