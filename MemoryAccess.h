#import <Cocoa/Cocoa.h>


@interface MemoryAccess : NSObject
{
    pid_t AppPid;
    mach_port_t MySlaveTask;
    AuthorizationRef gAuth;
    
    int readsProcessed;
    float throughput;
	
	// statistics info
	int _totalReadsProcessed;
	int _totalWritesProcessed;
    NSDate *_startTime;
	
    NSMutableDictionary *_loaderDict;
}

// we shouldn't really use this
+ (MemoryAccess*)sharedMemoryAccess;


- (id)init;
- (id)initWithPID:(pid_t)PID;
- (BOOL)isValid;

@property float throughput;
@property (readonly) NSDictionary *operationsDictionary;

- (void)resetLoadCount;
- (void)printLoadCount;
- (int)loadCount;

// for statistics
- (float)readsPerSecond;
- (float)writesPerSecond;
- (void)resetCounters;
- (NSDictionary*)operationsByClassPerSecond;

// save record to application addresses
- (BOOL)saveDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

// load record from application addresses
- (BOOL)loadDataForObject: (id)object atAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;
//- (BOOL)loadDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

// raw reading, minimal error checking, actual return result
- (kern_return_t)readAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

@end
