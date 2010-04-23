//
//  SaveData.m
//  Pocket Gnome
//
//  Created by Josh on 1/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "SaveData.h"
#import "SaveDataObject.h"

#define APPLICATION_SUPPORT_FOLDER	@"~/Library/Application Support/PocketGnome/"

@interface SaveData (Internal)
- (NSString*)pathForObjectName:(NSString*)objName withExtension:(BOOL)extension;
- (id)getObjectFromDisk:(NSString*)fileName;
@end

@implementation SaveData	

- (id) init {
    self = [super init];
    if ( self != nil ) {

		// create directory?
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *folder = APPLICATION_SUPPORT_FOLDER;
		
		// create folder?
		folder = [folder stringByExpandingTildeInPath];
		if ( [fileManager fileExistsAtPath: folder] == NO ) {
			log(LOG_GENERAL, @"[FileManager] Save data folder does not exist! Creating %@", folder);
			[fileManager createDirectoryAtPath: folder attributes: nil];
		}
		
		_objects = [[self loadAllObjects] retain];
	}
	
    return self;
}

- (void) dealloc{
	[_objects release];
	
    [super dealloc];
}

- (NSString*)objectExtension{
	
	// route
	/*if ( [obj isKindOfClass:[RouteSet class]] ){
		return @"route";
	}
	// route collection
	else if ( [obj isKindOfClass:[RouteCollection class]] ){
		return @"routecollection";
	}
	// combat profile
	else if ( [obj isKindOfClass:[CombatProfile class]] ){
		return @"combatprofile";
	}
	// behavior
	else if ( [obj isKindOfClass:[Behavior class]] ){
		return @"behavior";
	}*/
	
	return @"";
}

// returns the name of the object
- (NSString*)objectName:(id)object{
	return @"";
}

#pragma mark Main Saving Functions

// file location for our object
- (NSString*)pathForObjectName:(NSString*)objName withExtension:(BOOL)extension{ 
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *folder = APPLICATION_SUPPORT_FOLDER;
	
	// only return folder
	if ( objName == nil ){
		folder = [folder stringByExpandingTildeInPath];
		return folder;
	}
	
	// create folder?
	folder = [folder stringByExpandingTildeInPath];
	if ( [fileManager fileExistsAtPath: folder] == NO ) {
		[fileManager createDirectoryAtPath: folder attributes: nil];
	}
	
	NSString *filePathWithoutExt = [folder stringByAppendingPathComponent: objName];
	
	if ( !extension ){
		return filePathWithoutExt;
	}
	
	NSString *ext = [self objectExtension];
	
	// in theory should never occur, but error checking isn't bad amirite?
	if ( !ext || [ext length] == 0 ){
		return NO;
	}
	
	return [NSString stringWithFormat:@"%@.%@", filePathWithoutExt, ext];
}

// delete all objects
- (void)deleteAllObjects{
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *dir = [self pathForObjectName:nil withExtension:NO];
	NSArray *directoryList = [fileManager contentsOfDirectoryAtPath:dir error:&error];
	if ( error ){
		log(LOG_GENERAL, @"[FileManager] Error when deleting your objects from %@! %@", directoryList, error);
		return;
	}
	
	// if we get here then we're good!
	if ( directoryList && [directoryList count] ){
		
		// loop through directory list
		for ( NSString *fileName in directoryList ){
			
			// valid object file
			if ( [[fileName pathExtension] isEqualToString: [self objectExtension]] ){
				
				NSString *filePath = [dir stringByAppendingPathComponent: fileName];
				
				log(LOG_GENERAL, @"[FileManager] Removing %@", filePath);
				if ( ![fileManager removeItemAtPath:filePath error:&error] ){
					log(LOG_GENERAL, @"[FileManager] Error %@ when trying to delete object %@", error, filePath);
				}
			}
		}
	}
}

// delete the object
- (void)deleteObject:(id)object{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *objectName = [self objectName:object];
	NSString *filePath = [self pathForObjectName:objectName withExtension:YES];
	
	if ( [fileManager fileExistsAtPath: filePath] ){
		NSError *error = nil;
		if ( ![fileManager removeItemAtPath:filePath error:&error] ){
			log(LOG_GENERAL, @"[FileManager] Error %@ when trying to delete object %@", error, filePath);
		}
	}
}

// delete the object
- (void)deleteObjectWithName:(NSString*)name{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = [self pathForObjectName:name withExtension:YES];
	
	if ( [fileManager fileExistsAtPath: filePath] ){
		NSError *error = nil;
		if ( ![fileManager removeItemAtPath:filePath error:&error] ){
			log(LOG_GENERAL, @"[FileManager] Error %@ when trying to delete object %@", error, filePath);
		}
	}
}

// save the object
- (void)saveObject: (id)object { 
	NSString *filePath = [self pathForObjectName:[self objectName:object] withExtension:YES];
	
	log(LOG_GENERAL, @"[FileManager] Saving %@ to %@", object, filePath);
	[NSKeyedArchiver archiveRootObject: object toFile: filePath];
}

// grab a single object
- (id)getObjectFromDisk:(NSString*)fileName{
	NSString *path = [self pathForObjectName:fileName withExtension:NO];
	
	// verify the file exists
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ( [fileManager fileExistsAtPath: path] == NO ) {
		log(LOG_GENERAL, @"[FileManager] Object %@ is missing! Unable to load", fileName);
		return nil;
	}
	
	id rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	
	// not sure why i saved it as a dictionary before, i am r tard
	if ( [rootObject isKindOfClass:[NSDictionary class]] ){
		rootObject = [rootObject valueForKey:@"Route"];
	}
	
	return rootObject;
}

// load all data into an array!
- (NSArray*)loadAllObjects{
	
	// load a list of files at the directory
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *directoryList = [fileManager contentsOfDirectoryAtPath:[self pathForObjectName:nil withExtension:NO] error:&error];
	if ( error ){
		log(LOG_GENERAL, @"[FileManager] Error when reading your objects from %@! %@", directoryList, error);
		return nil;
	}
	
	NSMutableArray *objectList = [NSMutableArray array];

	// if we get here then we're good!
	if ( directoryList && [directoryList count] ){
		
		// loop through directory list
		for ( NSString *fileName in directoryList ){
			
			// is this a directory?
			/*BOOL isDir = NO;
			 if ( [fileManager fileExistsAtPath:[directory stringByAppendingPathComponent: fileName] isDirectory:&isDir] && isDir ) {
			 // recursive call?
			 //	before this works, we need to associate a route w/a directory
			 }*/
			
			// valid object file
			if ( [[fileName pathExtension] isEqualToString: [self objectExtension]] ){
				
				id object = [self getObjectFromDisk:fileName];
				
				// we JUST loaded this from the disk, we need to make sure we know it's not changed
				[(SaveDataObject*)object setChanged:NO];
				
				// valid route - add it!
				if ( object != nil ){
					[objectList addObject:object];
				}
			}
		}
	}
	
	if ( [objectList count] )
		log(LOG_GENERAL, @"[FileManager] Loaded %d objects of type %@", [objectList count], [self objectExtension]);
	
	return [objectList retain];
}

// old method, before we started storing them in files
- (NSArray*)loadAllDataForKey: (NSString*)key withClass:(id)objClass{
	
	// do we have data?
	id data = [[NSUserDefaults standardUserDefaults] objectForKey: key];
	
	if ( data ){
		NSArray *allData = [NSKeyedUnarchiver unarchiveObjectWithData: data];
		
		// do a check to see if this is old-style information (not stored in files)
		if ( allData != nil && [allData count] > 0 ){

			// is this the correct kind of class?
			if ( [[allData objectAtIndex:0] isKindOfClass:objClass] ){
				
				NSMutableArray *objects = [NSMutableArray array];
				
				for ( SaveDataObject *obj in allData ){
					obj.changed = YES;
					[objects addObject:obj];
				}
				
				log(LOG_GENERAL, @"[FileManager] Imported %d objects of type %@", [objects count], [self objectExtension]);
				
				return objects;
			}
		}
	}

	return nil;
}

#pragma mark UI Options (optional)

- (IBAction)showInFinder: (id)sender {
	
	NSString *filePath = [NSString stringWithFormat:@"%@/", [self pathForObjectName:nil withExtension:NO]];
	
	// show in finder!
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	[ws openFile: filePath];
}

- (IBAction)saveAllObjects: (id)sender{
	for ( SaveDataObject *obj in _objects ){
		[self saveObject:obj];
	}
}

@end
