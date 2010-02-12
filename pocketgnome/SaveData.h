//
//  SaveData.h
//  Pocket Gnome
//
//  Created by Josh on 1/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SaveData : NSObject {

}

// should not be implemented by the subclass, only called!
- (void)deleteObject:(id)object;				// delete an object
- (void)deleteObjectWithName:(NSString*)name;	// delete an object (needed for renames)
- (void)saveObject: (id)object;					// save an object
- (NSArray*)loadAllObjects;						// return an array w/all objects found in the app support folder
- (void)deleteAllObjects;

// UI
- (IBAction)showInFinder: (id)sender;

// should be implemented by the subclass
- (NSString*)objectExtension;
- (NSString*)objectName:(id)object;

// for backwards compatibility
- (NSArray*)loadAllDataForKey: (NSString*)key withClass:(id)objClass;

@end
