//
//  TargetClassConditionController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/17/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;


@interface TargetClassConditionController : ConditionController {
    IBOutlet BetterSegmentedControl *qualitySegment;
    IBOutlet NSPopUpButton *valuePopUp;
    
    IBOutlet NSMenu *creatureTypeMenu;
    IBOutlet NSMenu *playerClassMenu;
}

@end
