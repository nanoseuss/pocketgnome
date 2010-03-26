//
//  MyUserDefaults.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/21/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SecureUserDefaults : NSObject {
    NSString *prefPath;
}

@property (readwrite, retain) NSString *prefPath;

+ (SecureUserDefaults *)secureUserDefaults;

- (BOOL)updatePermissions;

@end
