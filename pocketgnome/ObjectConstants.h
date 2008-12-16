/*
 *  ObjectConstants.h
 *  Pocket Gnome
 *
 *  Created by Jon Drummond on 5/20/08.
 *  Copyright 2008 Savory Software, LLC. All rights reserved.
 *
 */

enum eObjectTypeID {
    TYPEID_UNKNOWN          = 0,

    TYPEID_ITEM             = 1,
    TYPEID_CONTAINER        = 2,
    TYPEID_UNIT             = 3,
    TYPEID_PLAYER           = 4,
    TYPEID_GAMEOBJECT       = 5,
    TYPEID_DYNAMICOBJECT    = 6,
    TYPEID_CORPSE           = 7,

    TYPEID_MAX              = 8
};

enum eObjectTypeMask {
    TYPE_OBJECT             = 1,
    TYPE_ITEM               = 2,
    TYPE_CONTAINER          = 4,
    TYPE_UNIT               = 8,
    TYPE_PLAYER             = 16,
    TYPE_GAMEOBJECT         = 32,
    TYPE_DYNAMICOBJECT      = 64,
    TYPE_CORPSE             = 128,
};
