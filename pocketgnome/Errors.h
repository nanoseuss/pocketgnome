/*
 *  Errors.h
 *  Pocket Gnome
 *
 *  Created by Josh on 6/9/09.
 *  Copyright 2007 Savory Software, LLC. All rights reserved.
 *
 */

// Return types for performAction
//	More errors here: http://www.wowwiki.com/WoW_Constants/Errors
typedef enum CastError {
    ErrNone = 0,
	ErrNotFound = 1,
    ErrInventoryFull = 2,				// @"Inventory is Full"
    ErrTargetNotInLOS = 3,				// 
} CastError;

#define INV_FULL			@"Inventory is Full"
#define TARGET_LOS			@"Target not in line of sight"
