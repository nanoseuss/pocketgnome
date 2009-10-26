

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
	_totalReadsProcessed = 0;
	_totalWritesProcessed = 0;
    
    //if(!MEMORY_GOD_MODE) [self performToolVersionCheck];
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
	
	_totalWritesProcessed++;
    
    if(MEMORY_GOD_MODE) {
        bool retVal;
        NS_DURING
        retVal = (KERN_SUCCESS == vm_write(MySlaveTask,Address,(vm_offset_t)DataBuffer,Bytes));
        NS_HANDLER
        retVal = false;
        NS_ENDHANDLER
        
        return retVal;
        
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
	_totalReadsProcessed++;
    
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
        
    }
}

// basically just a raw reading function.
// use this method if you need the actual return value from the kernel and want to do your own error checking.
- (kern_return_t)readAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes {

    if(![self isValid])                 return KERN_FAILURE;
    if(address == 0)                    return KERN_FAILURE;
    if(DataBuffer == NULL)              return KERN_FAILURE;
    if(Bytes <= 0)                      return KERN_FAILURE;
    
	_totalReadsProcessed++;
	
    vm_size_t retBytes = Bytes;
    return vm_read_overwrite(MySlaveTask, address, Bytes, (vm_address_t)DataBuffer, &retBytes);
}

- (void)refreshThroughput: (id)timer {
    self.throughput = [self loadCount]/5.0f;
}

@end
