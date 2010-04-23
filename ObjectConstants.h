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
 * $Id$
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
