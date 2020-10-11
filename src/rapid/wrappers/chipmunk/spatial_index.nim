##  Copyright (c) 2013 Scott Lembcke and Howling Moon Software
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in
##  all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##  SOFTWARE.
##
## *
## 	@defgroup cpSpatialIndex cpSpatialIndex
## 	
## 	Spatial indexes are data structures that are used to accelerate collision detection
## 	and spatial queries. Chipmunk provides a number of spatial index algorithms to pick from
## 	and they are programmed in a generic way so that you can use them for holding more than
## 	just cpShape structs.
## 	
## 	It works by using @c void pointers to the objects you add and using a callback to ask your code
## 	for bounding boxes when it needs them. Several types of queries can be performed an index as well
## 	as reindexing and full collision information. All communication to the spatial indexes is performed
## 	through callback functions.
## 	
## 	Spatial indexes should be treated as opaque structs.
## 	This meanns you shouldn't be reading any of the struct fields.
## 	@{
##
## MARK: Spatial Index
## / Spatial index bounding box callback function type.
## / The spatial index calls this function and passes you a pointer to an object you added
## / when it needs to get the bounding box associated with that object.

import bb, types

type
  cpSpatialIndexBBFunc* = proc (obj: pointer): cpBB

## / Spatial index/object iterator callback function type.

type
  cpSpatialIndexIteratorFunc* = proc (obj: pointer; data: pointer)

## / Spatial query callback function type.

type
  cpSpatialIndexQueryFunc* = proc (obj1: pointer; obj2: pointer; id: cpCollisionID;
                                data: pointer): cpCollisionID

## / Spatial segment query callback function type.

type
  cpSpatialIndexSegmentQueryFunc* = proc (obj1: pointer; obj2: pointer; data: pointer): cpFloat

## / @private


type
  cpSpatialIndexDestroyImpl* = proc (index: ptr cpSpatialIndex)
  cpSpatialIndexCountImpl* = proc (index: ptr cpSpatialIndex): cint
  cpSpatialIndexEachImpl* = proc (index: ptr cpSpatialIndex;
                               `func`: cpSpatialIndexIteratorFunc; data: pointer)
  cpSpatialIndexContainsImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                   hashid: cpHashValue): cpBool
  cpSpatialIndexInsertImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                 hashid: cpHashValue)
  cpSpatialIndexRemoveImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                 hashid: cpHashValue)
  cpSpatialIndexReindexImpl* = proc (index: ptr cpSpatialIndex)
  cpSpatialIndexReindexObjectImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                        hashid: cpHashValue)
  cpSpatialIndexReindexQueryImpl* = proc (index: ptr cpSpatialIndex;
                                       `func`: cpSpatialIndexQueryFunc;
                                       data: pointer)
  cpSpatialIndexQueryImpl* = proc (index: ptr cpSpatialIndex; obj: pointer; bb: cpBB;
                                `func`: cpSpatialIndexQueryFunc; data: pointer)
  cpSpatialIndexSegmentQueryImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                       a: cpVect; b: cpVect; t_exit: cpFloat;
                                       `func`: cpSpatialIndexSegmentQueryFunc;
                                       data: pointer)
  cpSpatialIndexClass* {.importc: "cpSpatialIndexClass",
                        header: "<chipmunk/chipmunk.h>", bycopy.} = object
    destroy* {.importc: "destroy".}: cpSpatialIndexDestroyImpl
    count* {.importc: "count".}: cpSpatialIndexCountImpl
    each* {.importc: "each".}: cpSpatialIndexEachImpl
    contains* {.importc: "contains".}: cpSpatialIndexContainsImpl
    insert* {.importc: "insert".}: cpSpatialIndexInsertImpl
    remove* {.importc: "remove".}: cpSpatialIndexRemoveImpl
    reindex* {.importc: "reindex".}: cpSpatialIndexReindexImpl
    reindexObject* {.importc: "reindexObject".}: cpSpatialIndexReindexObjectImpl
    reindexQuery* {.importc: "reindexQuery".}: cpSpatialIndexReindexQueryImpl
    query* {.importc: "query".}: cpSpatialIndexQueryImpl
    segmentQuery* {.importc: "segmentQuery".}: cpSpatialIndexSegmentQueryImpl
  cpSpatialIndex* {.importc: "cpSpatialIndex", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    klass* {.importc: "klass".}: ptr cpSpatialIndexClass
    bbfunc* {.importc: "bbfunc".}: cpSpatialIndexBBFunc
    staticIndex* {.importc: "staticIndex".}: ptr cpSpatialIndex
    dynamicIndex* {.importc: "dynamicIndex".}: ptr cpSpatialIndex


## MARK: Spatial Hash


## / Allocate a spatial hash.

type cpSpaceHash* {.importc, incompleteStruct.} = object

proc cpSpaceHashAlloc*(): ptr cpSpaceHash {.importc: "cpSpaceHashAlloc",
                                        header: "<chipmunk/chipmunk.h>".}
## / Initialize a spatial hash.

proc cpSpaceHashInit*(hash: ptr cpSpaceHash; celldim: cpFloat; numcells: cint;
                     bbfunc: cpSpatialIndexBBFunc; staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpSpaceHashInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a spatial hash.

proc cpSpaceHashNew*(celldim: cpFloat; cells: cint; bbfunc: cpSpatialIndexBBFunc;
                    staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpSpaceHashNew", header: "<chipmunk/chipmunk.h>".}
## / Change the cell dimensions and table size of the spatial hash to tune it.
## / The cell dimensions should roughly match the average size of your objects
## / and the table size should be ~10 larger than the number of objects inserted.
## / Some trial and error is required to find the optimum numbers for efficiency.

proc cpSpaceHashResize*(hash: ptr cpSpaceHash; celldim: cpFloat; numcells: cint) {.
    importc: "cpSpaceHashResize", header: "<chipmunk/chipmunk.h>".}
## MARK: AABB Tree


## / Allocate a bounding box tree.

type cpBBTree* {.importc, incompleteStruct.} = object

proc cpBBTreeAlloc*(): ptr cpBBTree {.importc: "cpBBTreeAlloc",
                                  header: "<chipmunk/chipmunk.h>".}
## / Initialize a bounding box tree.

proc cpBBTreeInit*(tree: ptr cpBBTree; bbfunc: cpSpatialIndexBBFunc;
                  staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpBBTreeInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a bounding box tree.

proc cpBBTreeNew*(bbfunc: cpSpatialIndexBBFunc; staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpBBTreeNew", header: "<chipmunk/chipmunk.h>".}
## / Perform a static top down optimization of the tree.

proc cpBBTreeOptimize*(index: ptr cpSpatialIndex) {.importc: "cpBBTreeOptimize",
    header: "<chipmunk/chipmunk.h>".}
## / Bounding box tree velocity callback function.
## / This function should return an estimate for the object's velocity.

type
  cpBBTreeVelocityFunc* = proc (obj: pointer): cpVect

## / Set the velocity function for the bounding box tree to enable temporal coherence.

proc cpBBTreeSetVelocityFunc*(index: ptr cpSpatialIndex;
                             `func`: cpBBTreeVelocityFunc) {.
    importc: "cpBBTreeSetVelocityFunc", header: "<chipmunk/chipmunk.h>".}
## MARK: Single Axis Sweep


## / Allocate a 1D sort and sweep broadphase.

type cpSweep1D* {.importc, incompleteStruct.} = object

proc cpSweep1DAlloc*(): ptr cpSweep1D {.importc: "cpSweep1DAlloc",
                                    header: "<chipmunk/chipmunk.h>".}
## / Initialize a 1D sort and sweep broadphase.

proc cpSweep1DInit*(sweep: ptr cpSweep1D; bbfunc: cpSpatialIndexBBFunc;
                   staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpSweep1DInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a 1D sort and sweep broadphase.

proc cpSweep1DNew*(bbfunc: cpSpatialIndexBBFunc; staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpSweep1DNew", header: "<chipmunk/chipmunk.h>".}
## MARK: Spatial Index Implementation


## / Destroy and free a spatial index.

proc cpSpatialIndexFree*(index: ptr cpSpatialIndex) {.importc: "cpSpatialIndexFree",
    header: "<chipmunk/chipmunk.h>".}
## / Collide the objects in @c dynamicIndex against the objects in @c staticIndex using the query callback function.

proc cpSpatialIndexCollideStatic*(dynamicIndex: ptr cpSpatialIndex;
                                 staticIndex: ptr cpSpatialIndex;
                                 `func`: cpSpatialIndexQueryFunc; data: pointer) {.
    importc: "cpSpatialIndexCollideStatic", header: "<chipmunk/chipmunk.h>".}
## / Destroy a spatial index.

proc cpSpatialIndexDestroy*(index: ptr cpSpatialIndex) {.inline.} =
  if index.klass != nil:
    index.klass.destroy(index)

## / Get the number of objects in the spatial index.

proc cpSpatialIndexCount*(index: ptr cpSpatialIndex): cint {.inline.} =
  return index.klass.count(index)

## / Iterate the objects in the spatial index. @c func will be called once for each object.

proc cpSpatialIndexEach*(index: ptr cpSpatialIndex;
                        `func`: cpSpatialIndexIteratorFunc; data: pointer) {.inline.} =
  index.klass.each(index, `func`, data)

## / Returns true if the spatial index contains the given object.
## / Most spatial indexes use hashed storage, so you must provide a hash value too.

proc cpSpatialIndexContains*(index: ptr cpSpatialIndex; obj: pointer;
                            hashid: cpHashValue): cpBool {.inline.} =
  return index.klass.contains(index, obj, hashid)

## / Add an object to a spatial index.
## / Most spatial indexes use hashed storage, so you must provide a hash value too.

proc cpSpatialIndexInsert*(index: ptr cpSpatialIndex; obj: pointer;
                          hashid: cpHashValue) {.inline.} =
  index.klass.insert(index, obj, hashid)

## / Remove an object from a spatial index.
## / Most spatial indexes use hashed storage, so you must provide a hash value too.

proc cpSpatialIndexRemove*(index: ptr cpSpatialIndex; obj: pointer;
                          hashid: cpHashValue) {.inline.} =
  index.klass.remove(index, obj, hashid)

## / Perform a full reindex of a spatial index.

proc cpSpatialIndexReindex*(index: ptr cpSpatialIndex) {.inline.} =
  index.klass.reindex(index)

## / Reindex a single object in the spatial index.

proc cpSpatialIndexReindexObject*(index: ptr cpSpatialIndex; obj: pointer;
                                 hashid: cpHashValue) {.inline.} =
  index.klass.reindexObject(index, obj, hashid)

## / Perform a rectangle query against the spatial index, calling @c func for each potential match.

proc cpSpatialIndexQuery*(index: ptr cpSpatialIndex; obj: pointer; bb: cpBB;
                         `func`: cpSpatialIndexQueryFunc; data: pointer) {.inline.} =
  index.klass.query(index, obj, bb, `func`, data)

## / Perform a segment query against the spatial index, calling @c func for each potential match.

proc cpSpatialIndexSegmentQuery*(index: ptr cpSpatialIndex; obj: pointer; a: cpVect;
                                b: cpVect; t_exit: cpFloat;
                                `func`: cpSpatialIndexSegmentQueryFunc;
                                data: pointer) {.inline.} =
  index.klass.segmentQuery(index, obj, a, b, t_exit, `func`, data)

## / Simultaneously reindex and find all colliding objects.
## / @c func will be called once for each potentially overlapping pair of objects found.
## / If the spatial index was initialized with a static index, it will collide it's objects against that as well.

proc cpSpatialIndexReindexQuery*(index: ptr cpSpatialIndex;
                                `func`: cpSpatialIndexQueryFunc; data: pointer) {.
    inline.} =
  index.klass.reindexQuery(index, `func`, data)

## /@}
