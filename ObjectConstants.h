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
    
    TYPEID_AIGROUP          = 8,
    TYPEID_AREATRIGGER      = 9,
    
    TYPEID_MAX              = 10
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
    TYPE_AIGROUP            = 256,
    TYPE_AREATRIGGER        = 512
};

enum eObjectBase {
   OBJECT_BASE_ID           = 0x0,  // UInt32
   OBJECT_FIELDS_PTR        = 0x4,  // UInt32
   OBJECT_FIELDS_END_PTR    = 0x8,  // UInt32
   OBJECT_UNKNOWN1          = 0xC,  // UInt32
   OBJECT_TYPE_ID           = 0x10, // UInt32
   OBJECT_GUID_LOW32        = 0x14, // UInt32
   OBJECT_STRUCT1_POINTER   = 0x18, // other struct ptr
   OBJECT_STRUCT2_POINTER   = 0x1C, // "parent?"
   // 0x24 is a duplicate of the value at 0x34
   OBJECT_STRUCT4_POINTER_COPY = 0x24,
   OBJECT_GUID_ALL64        = 0x28, // GUID
   OBJECT_STRUCT3_POINTER   = 0x30, // "previous?"
   OBJECT_STRUCT4_POINTER   = 0x34, // "next?"
   
};

enum eObjectFields {
   OBJECT_FIELD_GUID                             = 0x0  , // Type: Guid , Size: 2
   OBJECT_FIELD_TYPE                             = 0x8  , // Type: Int32, Size: 1
   OBJECT_FIELD_ENTRY                            = 0xC  , // Type: Int32, Size: 1
   OBJECT_FIELD_SCALE_X                          = 0x10 , // Type: Float, Size: 1
   OBJECT_FIELD_PADDING                          = 0x14 , // Type: Int32, Size: 1
};
