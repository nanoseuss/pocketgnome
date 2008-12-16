

#import "MemoryAccess.h"
#import <mach/vm_map.h>
#import <mach/mach_traps.h>

#import "Globals.h"
#import "ToolCommon.h"
#import "BetterAuthorizationSampleLib.h"

#import <CoreFoundation/CoreFoundation.h>

@implementation MemoryAccess

- (id)init {
    return [self initWithPID:0];
}

- (id)initWithPID:(pid_t)PID {
    [super init];
    AppPid = PID;
    PGLog(@"Got WoW PID: %d; GodMode: %d", PID, MEMORY_GOD_MODE);
    task_for_pid(current_task(), AppPid, &MySlaveTask);
    
    loaderDict = [[NSMutableDictionary dictionary] retain];
    readsProcessed = 0;
    gAuth = NULL;
    self.throughput = 0.0f;
    
    if(!MEMORY_GOD_MODE) [self performToolVersionCheck];
    [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(refreshThroughput:) userInfo: nil repeats: YES];
    return self;
}

@synthesize throughput;

- (BOOL)isValid {
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    OSStatus err = GetProcessForPID(AppPid, &psn);
    if( err != noErr) {
        usleep(50000);
        err = GetProcessForPID(AppPid, &psn);
        if( err != noErr) {
            PGLog(@"appPID = %d; err = %d; pSN = { %d, %d }", AppPid, err, psn.lowLongOfPSN, psn.highLongOfPSN);
            return NO;
        }
    }
    return YES;
}

- (BOOL)verifyAuthorization {
    if(gAuth == NULL) {
        PGLog(@"gAuth is nil; re-creating...");
        OSStatus status = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &gAuth);
        if( (status == noErr) == (gAuth != NULL) ) {
            PGLog(@"gAuth success.");
            return YES;
        } else {
            PGLog(@"gAuth failure.");
            return NO;
        }
    }
    return YES;
}

- (BOOL)performToolVersionCheck {
    OSStatus        ipcErr;
    NSDictionary    *request;
    CFDictionaryRef response = NULL;
    
    if(![self verifyAuthorization]) return NO;
    
    request = [NSDictionary dictionaryWithObjectsAndKeys: @kGetVersionCommand, @kBASCommandKey, nil];
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    ipcErr = BASExecuteRequestInHelperTool(gAuth, 
                                           kCommandSet, 
                                           (CFStringRef)bundleID, 
                                           (CFDictionaryRef)request, 
                                           &response
                                           );
    
    BOOL toolNeedsInstall = NO;
    BOOL toolInstallSuccess = NO;
    BASFailCode failCode = 0;
    int version = 0;
    
    // if there was no error, verify the version number
    if(ipcErr == noErr) {
        version = [[(NSDictionary*)response objectForKey: @kGetVersionResponse] intValue];
        if(version < kToolCurrentVersion) {
            PGLog(@"Tool needs update: version %d < current version %d", version, kToolCurrentVersion);
            
            toolNeedsInstall = YES;
            failCode = kBASFailNeedsUpdate;
            BASDiagnoseFailure(gAuth, (CFStringRef)bundleID);
        } else {
            PGLog(@"Tool version is up to date! %d >= %d", version, kToolCurrentVersion);
        }
    }
    
    // or if there was an error other than the user cancelling
    if((ipcErr != noErr) && (ipcErr != userCanceledErr)) {
        toolNeedsInstall = YES;
        failCode = BASDiagnoseFailure(gAuth, (CFStringRef) bundleID);
        PGLog(@"Error retrieving version number: failcode %d for IPC error %d.", failCode, ipcErr);
    }
    
    // if we do need to install, present the user with a dialog to confirm
    if(toolNeedsInstall) {
        NSString *displayText = nil;
        
        if(failCode == kBASFailNeedsUpdate)
            displayText = [NSString stringWithFormat: @"Your version of the WoW Memory Tool is out of date.  You have version %d, and the latest is version %d.  Updating the tool requires administrator privileges.  Would you like to install the newest version now?", version, kToolCurrentVersion];
        else
            displayText = @"The WoW Memory Tool needs to be installed before this application will function.  Installing the tool requires administrator privileges.";
        
        int alertResult = NSRunAlertPanel(@"WoW Memory Tool needs install", displayText, @"Install", @"Cancel", NULL);
        if( alertResult == NSAlertDefaultReturn ) {
            ipcErr = BASFixFailure(gAuth, (CFStringRef)bundleID, CFSTR("InstallTool"), CFSTR("MemoryAccessTool"), failCode);
            if(ipcErr == noErr) {
                PGLog(@"Tool successfully updated.");
                toolInstallSuccess = YES;
            } else {
                PGLog(@"Error %d while updating the tool.", ipcErr);
                toolInstallSuccess = NO;
            }
        } else {
            ipcErr = userCanceledErr; // -128
            PGLog(@"User cancelled update.");
            toolInstallSuccess = NO;
        }
    }
    
    if(!toolNeedsInstall || (toolNeedsInstall && toolInstallSuccess))
        return YES;
    return NO;
}

// this function is no longer used, and requires a helper tool.
// it turned out using a helper tool was too slow
- (BOOL)loadDataFromAddress: (UInt32)address intoBuffer: (Byte*)buffer ofLength: (vm_size_t)size {

    if(![self isValid])                 return NO;
    if(![self verifyAuthorization])     return NO;
    if(address == 0)                    return NO;
    if(buffer == NULL)                  return NO;
    if(size <= 0)                       return NO;
    
    BOOL loadSuccess = NO;
    CFDictionaryRef response = NULL;
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    // create our request
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys: 
                             @kLoadMemoryCommand,                         @kBASCommandKey, 
                             [NSNumber numberWithUnsignedInt: AppPid],    @kWarcraftPID,
                             [NSNumber numberWithUnsignedInt: address],   @kMemoryAddress,
                             [NSNumber numberWithUnsignedInt: size],      @kMemoryLength,
                             nil];
    
    // execute request
    OSStatus ipcErr = BASExecuteRequestInHelperTool(gAuth, 
                                                    kCommandSet, 
                                                    (CFStringRef)bundleID, 
                                                    (CFDictionaryRef)request, 
                                                    &response
                                                    );
    
    // check to see if there was an IPC error
    if ( (ipcErr != noErr) && (ipcErr != userCanceledErr) ) {
       PGLog(@"Communication with the tool failed with error: %d", ipcErr);
    }
    
    if (ipcErr == noErr) {
        OSStatus commandErr = BASGetErrorFromResponse(response);
        
        if (commandErr == kMemToolNoError) {
            //PGLog(@"all went well, response has command results: %@", (NSDictionary*)response);
            NSData *memContents = [(NSDictionary*)response objectForKey: @kMemoryContents];
            //PGLog(@"Got memory contents: %@", [memContents description]);
            
            if( [memContents length] >= size) {
                //PGLog(@"Memory length valid: %d", [memContents length]);
                [memContents getBytes: buffer length: size];
                loadSuccess = YES;
            }
            
        } else {
            if(commandErr == kMemToolBadAddress) {
                PGLog(@"Bad Address Error: 0x%X", address);
            } else if(commandErr == kMemToolBadPID) {
                PGLog(@"Bad PID Error: %d", AppPid);
            } else {
                PGLog(@"[LOAD: handle command error %ld ...]", (long)commandErr);
            }
        }
    } else {
        PGLog(@"Residual IPC error %d", ipcErr);
    }
    
    if (response != NULL) {
        CFRelease(response);
    }
    
    return loadSuccess;
}

// helper tool version of regular save.  no longer used.
- (BOOL)saveDataToAddress: (UInt32)address fromBuffer: (Byte*)buffer ofLength: (vm_size_t)size {
    if(![self verifyAuthorization])     return NO;
    
    BOOL saveSuccess = NO;
    CFDictionaryRef response = NULL;
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    PGLog(@"saveDataToAddress: 0x%X, sizeof(buffer) = %d; size = %d", address, sizeof(*buffer), size);
    
    // create our request
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys: 
                             @kSaveMemoryCommand,                         @kBASCommandKey, 
                             [NSNumber numberWithUnsignedInt: AppPid],    @kWarcraftPID,
                             [NSNumber numberWithUnsignedInt: address],   @kMemoryAddress,
                             [NSData dataWithBytes: buffer length: size], @kMemoryContents,
                             nil];
    
    // execute request
    OSStatus ipcErr = BASExecuteRequestInHelperTool(gAuth, 
                                                    kCommandSet, 
                                                    (CFStringRef)bundleID, 
                                                    (CFDictionaryRef)request, 
                                                    &response
                                                    );
        // check to see if there was an IPC error
    if ( (ipcErr != noErr) && (ipcErr != userCanceledErr) ) {
       PGLog(@"Communication with the tool failed with error: %d", ipcErr);
    }
    
    if (ipcErr == noErr) {
        OSStatus commandErr = BASGetErrorFromResponse(response);
        
        if (commandErr == kMemToolNoError) {
            PGLog(@"Save success");
            saveSuccess = YES;
        } else {
            if(commandErr == kMemToolBadAddress) {
                PGLog(@"Bad Address Error: 0x%X", address);
            } else if(commandErr == kMemToolBadPID) {
                PGLog(@"Bad PID Error: %d", AppPid);
            } else {
                PGLog(@"[SAVE: handle command error %ld ...]", (long)commandErr);
            }
        }
    } else {
        PGLog(@"Residual IPC error %d", ipcErr);
    }
    
    if (response != NULL) {
        CFRelease(response);
    }
    
    return saveSuccess;
}

- (void)resetLoadCount {
    readsProcessed = 0;
}

- (void)printLoadCount {
    PGLog(@"%@ has processed %d reads.", self, readsProcessed);
}

- (int)loadCount {
    return readsProcessed;
}


- (BOOL)saveDataForAddress:(UInt32)Address Buffer:(Byte *)DataBuffer BufLength:(vm_size_t)Bytes
{
    if(![self isValid])                 return NO;
    if(Address == 0)                    return NO;
    if(DataBuffer == NULL)              return NO;
    if(Bytes <= 0)                      return NO;
    
    if(MEMORY_GOD_MODE) {
        bool retVal;
        NS_DURING
        retVal = (KERN_SUCCESS == vm_write(MySlaveTask,Address,(vm_offset_t)DataBuffer,Bytes));
        NS_HANDLER
        retVal = false;
        NS_ENDHANDLER
        
        return retVal;
        
    } else {
        return [self saveDataToAddress: Address fromBuffer: DataBuffer ofLength: Bytes];
    }
}

// this is the main memory reading function.
- (BOOL)loadDataForObject: (id)object atAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;
{
    if(![self isValid])                 return NO;
    if(address == 0)                    return NO;
    if(DataBuffer == NULL)              return NO;
    if(Bytes <= 0)                      return NO;
    
    readsProcessed++;
    
    /*
    NSString *className = [object className];
    if( [loaderDict objectForKey: className]) {
        [loaderDict setObject: [NSNumber numberWithInt: [[loaderDict objectForKey: className] intValue]+1] forKey: className];
    } else {
        [loaderDict setObject: [NSNumber numberWithInt: 1] forKey: className];
    }
    
    if(readsProcessed % 20000 == 0) {
        [self printLoadCount];
        PGLog(@"Loader Dict: %@", loaderDict);
    }*/

    if(MEMORY_GOD_MODE) {
        bool retVal;
        vm_size_t retBytes = Bytes;
        NS_DURING
        retVal = ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,address,Bytes,(vm_address_t)DataBuffer,&retBytes)) && (retBytes == Bytes) );
        NS_HANDLER
        retVal = false;
        NS_ENDHANDLER
        
        return retVal;
        
    } else {
        return [self loadDataFromAddress: address intoBuffer: DataBuffer ofLength: Bytes];
    }
}

// basically just a raw reading function.
// use this method if you need the actual return value from the kernel and want to do your own error checking.
- (kern_return_t)readAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes {

    if(![self isValid])                 return KERN_FAILURE;
    if(address == 0)                    return KERN_FAILURE;
    if(DataBuffer == NULL)              return KERN_FAILURE;
    if(Bytes <= 0)                      return KERN_FAILURE;
    
    vm_size_t retBytes = Bytes;
    return vm_read_overwrite(MySlaveTask, address, Bytes, (vm_address_t)DataBuffer, &retBytes);
}

- (void)refreshThroughput: (id)timer {
    self.throughput = [self loadCount]/5.0f;
}

@end
