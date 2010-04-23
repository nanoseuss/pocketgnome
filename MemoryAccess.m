#import "MemoryAccess.h"
#import <mach/vm_map.h>
#import <mach/mach_traps.h>

#import "Globals.h"
#import "ToolCommon.h"
#import "BetterAuthorizationSampleLib.h"

#import <CoreFoundation/CoreFoundation.h>

@implementation MemoryAccess

static MemoryAccess *sharedMemoryAccess = nil;

- (id)init {
    return [self initWithPID:0];
}

- (id)initWithPID:(pid_t)PID {
    [super init];
    AppPid = PID;
    log(LOG_MEMORY, @"Got WoW PID: %d; GodMode: %d", PID, MEMORY_GOD_MODE);
    task_for_pid(current_task(), AppPid, &MySlaveTask);
    
    _loaderDict = [[NSMutableDictionary dictionary] retain];
    readsProcessed = 0;
    gAuth = NULL;
    self.throughput = 0.0f;
	_totalReadsProcessed = 0;
	_totalWritesProcessed = 0;
	_startTime = [[NSDate date] retain];
    
    //if(!MEMORY_GOD_MODE) [self performToolVersionCheck];
    [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(refreshThroughput:) userInfo: nil repeats: YES];
	
	// for those using shared memory - lets hope not many!!
	if ( sharedMemoryAccess ){
		[sharedMemoryAccess release];
	}
	sharedMemoryAccess = [self retain];
	
    return self;
}

+ (MemoryAccess*)sharedMemoryAccess{
	if (sharedMemoryAccess == nil)
		sharedMemoryAccess = [[[self class] alloc] init];
	return sharedMemoryAccess;
}

@synthesize throughput;
@synthesize operationsDictionary = _loaderDict;

- (BOOL)isValid {
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    OSStatus err = GetProcessForPID(AppPid, &psn);
    if( err != noErr) {
        usleep(50000);
        err = GetProcessForPID(AppPid, &psn);
        if( err != noErr) {
            log(LOG_MEMORY, @"appPID = %d; err = %d; pSN = { %d, %d }", AppPid, err, psn.lowLongOfPSN, psn.highLongOfPSN);
            return NO;
        }
    }
    return YES;
}

- (void)resetLoadCount {
    readsProcessed = 0;
}

- (void)printLoadCount {
    log(LOG_MEMORY, @"%@ has processed %d reads.", self, readsProcessed);
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
    
    
    NSString *className = [object className];
    if( [_loaderDict objectForKey: className]) {
        [_loaderDict setObject: [NSNumber numberWithInt: [[_loaderDict objectForKey: className] intValue]+1] forKey: className];
    } else {
        [_loaderDict setObject: [NSNumber numberWithInt: 1] forKey: className];
    }
	
	/*
    if(readsProcessed % 20000 == 0) {
        [self printLoadCount];
        log(LOG_MEMORY, @"Loader Dict: %@", loaderDict);
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

- (float)readsPerSecond{
	if ( !_startTime || !_totalReadsProcessed )
		return 0.0f;
	
	NSTimeInterval timeIntervalInSeconds = [[NSDate date] timeIntervalSinceDate:_startTime];
	return _totalReadsProcessed/timeIntervalInSeconds;
}

- (float)writesPerSecond{
	if ( !_startTime || !_totalWritesProcessed )
		return 0.0f;
	
	NSTimeInterval timeIntervalInSeconds = [[NSDate date] timeIntervalSinceDate:_startTime];
	return _totalWritesProcessed/timeIntervalInSeconds;
}

// return a new dictionary that's value per class is the memory reads/second
- (NSDictionary*)operationsByClassPerSecond{
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSTimeInterval timeIntervalInSeconds = [[NSDate date] timeIntervalSinceDate:_startTime];
	NSArray *keys = [_loaderDict allKeys];
	
	// loop through + re-calculate
	for ( NSString *key in keys ){
		NSNumber *readsPerSecond = [NSNumber numberWithInt:[[_loaderDict objectForKey:key] intValue]/timeIntervalInSeconds];
		
		[dict setObject:readsPerSecond forKey:key];		
	}
	
	return dict;	
}

- (void)resetCounters{
	_totalReadsProcessed = 0;
	_totalWritesProcessed = 0;
	[_loaderDict removeAllObjects];
	[_startTime release];_startTime=nil;
	_startTime = [[NSDate date] retain];
	[_loaderDict removeAllObjects];
}

@end
