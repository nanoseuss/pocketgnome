/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id: ProfileController.m 315 2010-04-17 04:12:45Z Tanaris4 $
 *
 */

#import "ProfileController.h"
#import "Profile.h"
#import "MailActionProfile.h"
#import "FileController.h"

@implementation ProfileController

- (id) init
{
    self = [super init];
    if (self != nil) {
		_profiles = [[NSMutableArray array] retain];
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
    }
    return self;
}

- (void)awakeFromNib {
	
	self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
	
	if ( fileController == nil ){
		fileController = [[FileController sharedFileController] retain];
	}
	
	NSArray *mailActionProfiles = [fileController getObjectsWithClass:[MailActionProfile class]];
	[_profiles addObjectsFromArray:mailActionProfiles];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: ProfilesLoaded object: self];
}

@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Profiles";
}

- (void)dealloc{
	[_profiles release]; _profiles = nil;
	[super dealloc];
}

// pass a class, and receive ALL the objects of that type! ezmode!
- (NSArray*)profilesOfClass:(Class)objectClass{
	
	NSMutableArray *objects = [NSMutableArray array];
	
	for ( id profile in _profiles ){
		if ( [profile isKindOfClass:objectClass] ){
			[objects addObject:profile];
		}
	}
	
	return [[objects retain] autorelease];
}

- (Profile*)profileForUUID:(NSString*)uuid{
	for ( Profile *profile in _profiles ){
		if ( [[profile UUID] isEqualToString:uuid] ){
			return [[profile retain] autorelease];
		}
	}
	return nil;
}

// add a profile
- (void)addProfile:(Profile*)profile{
	
	int num = 2;
    BOOL done = NO;
    if( ![[profile name] length] ) return;
    
    // check to see if a route exists with this name
    NSString *originalName = [profile name];
    while( !done ) {
        BOOL conflict = NO;
        for ( id existingProfile in _profiles ) {
			
			// UUID's match?
			if ( [[existingProfile UUID] isEqualToString:[profile UUID]] ){
				[profile updateUUUID];
			}
			
			// same profile type + same name! o noes!
			if ( [existingProfile isKindOfClass:[profile class]] && [[existingProfile name] isEqualToString: [profile name]] ){
                [profile setName: [NSString stringWithFormat: @"%@ %d", originalName, num++]];
                conflict = YES;
                break;
            }
        }
        if( !conflict ) done = YES;
    }
	
	profile.changed = YES;
	
	[_profiles addObject:profile];
}

- (BOOL)deleteProfile:(Profile*)prof{
	
	Profile *profToDelete = nil;
	for ( Profile *profile in _profiles ){
		
		if ( [profile isKindOfClass:[prof class]] && [[profile name] isEqualToString:[prof name]] ){
			profToDelete = profile;
			break;
		}
	}
	
	NSLog(@" %@ %@", prof, profToDelete);
	
	[fileController deleteObject:profToDelete];
	[_profiles removeObject:profToDelete];
	
	if ( profToDelete )
		return YES;
	
	return NO;      
}

// just return a list of profiles by class
- (NSArray*)profilesByClass{
	
	NSMutableArray *list = [NSMutableArray array];
	
	// form a list of the unique classes
	NSMutableArray *classList = [NSMutableArray array];
	for ( id profile in _profiles ){
		if ( ![classList containsObject:[profile class]] ){
			[classList addObject:[profile class]];
		}
	}
	
	// woohoo lets set up arrays by class!
	for ( id class in classList ){
		NSMutableArray *profiles = [NSMutableArray array];
		for ( Profile *profile in _profiles ){
			if ( [profile class] == class ){
				[profiles addObject:profile];
			}			
		}
		[list addObject:profiles];
	}

	return list;	
}


#pragma mark Notifications

- (void)applicationWillTerminate: (NSNotification*)notification {
	NSLog(@"saving %d objects! to %@", [_profiles count], fileController);
	for ( FileObject *obj in _profiles ){
		NSLog(@" %@ %d", obj, [obj changed]);
	}
    [fileController saveObjects:_profiles];
}

@end