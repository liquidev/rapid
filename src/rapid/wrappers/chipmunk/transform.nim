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

import
  types, vect, bb

## / Identity transform matrix.

var cpTransformIdentity*: cpTransform = cpTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0)

## / Construct a new transform matrix.
## / (a, b) is the x basis vector.
## / (c, d) is the y basis vector.
## / (tx, ty) is the translation.

proc cpTransformNew*(a: cpFloat; b: cpFloat; c: cpFloat; d: cpFloat; tx: cpFloat;
                    ty: cpFloat): cpTransform {.inline.} =
  var t: cpTransform = cpTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  return t

## / Construct a new transform matrix in transposed order.

proc cpTransformNewTranspose*(a: cpFloat; c: cpFloat; tx: cpFloat; b: cpFloat;
                             d: cpFloat; ty: cpFloat): cpTransform {.inline.} =
  var t: cpTransform = cpTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  return t

## / Get the inverse of a transform matrix.

proc cpTransformInverse*(t: cpTransform): cpTransform {.inline.} =
  var inv_det: cpFloat = 1.0 / (t.a * t.d - t.c * t.b)
  return cpTransformNewTranspose(t.d * inv_det, -(t.c * inv_det),
                                (t.c * t.ty - t.tx * t.d) * inv_det, -(t.b * inv_det),
                                t.a * inv_det, (t.tx * t.b - t.a * t.ty) * inv_det)

## / Multiply two transformation matrices.

proc cpTransformMult*(t1: cpTransform; t2: cpTransform): cpTransform {.inline.} =
  return cpTransformNewTranspose(t1.a * t2.a + t1.c * t2.b, t1.a * t2.c + t1.c * t2.d,
                                t1.a * t2.tx + t1.c * t2.ty + t1.tx,
                                t1.b * t2.a + t1.d * t2.b, t1.b * t2.c + t1.d * t2.d,
                                t1.b * t2.tx + t1.d * t2.ty + t1.ty)

## / Transform an absolute point. (i.e. a vertex)

proc cpTransformPoint*(t: cpTransform; p: cpVect): cpVect {.inline.} =
  return cpv(t.a * p.x + t.c * p.y + t.tx, t.b * p.x + t.d * p.y + t.ty)

## / Transform a vector (i.e. a normal)

proc cpTransformVect*(t: cpTransform; v: cpVect): cpVect {.inline.} =
  return cpv(t.a * v.x + t.c * v.y, t.b * v.x + t.d * v.y)

## / Transform a cpBB.

proc cpTransformbBB*(t: cpTransform; bb: cpBB): cpBB {.inline.} =
  var center: cpVect = cpBBCenter(bb)
  var hw: cpFloat = (bb.r - bb.l) * 0.5
  var hh: cpFloat = (bb.t - bb.b) * 0.5
  var
    a: cpFloat = t.a * hw
    b: cpFloat = t.c * hh
    d: cpFloat = t.b * hw
    e: cpFloat = t.d * hh
  var hw_max: cpFloat = cpfmax(cpfabs(a + b), cpfabs(a - b))
  var hh_max: cpFloat = cpfmax(cpfabs(d + e), cpfabs(d - e))
  return cpBBNewForExtents(cpTransformPoint(t, center), hw_max, hh_max)

## / Create a transation matrix.

proc cpTransformTranslate*(translate: cpVect): cpTransform {.inline.} =
  return cpTransformNewTranspose(1.0, 0.0, translate.x, 0.0, 1.0, translate.y)

## / Create a scale matrix.

proc cpTransformScale*(scaleX: cpFloat; scaleY: cpFloat): cpTransform {.inline.} =
  return cpTransformNewTranspose(scaleX, 0.0, 0.0, 0.0, scaleY, 0.0)

## / Create a rotation matrix.

proc cpTransformRotate*(radians: cpFloat): cpTransform {.inline.} =
  var rot: cpVect = cpvforangle(radians)
  return cpTransformNewTranspose(rot.x, -rot.y, 0.0, rot.y, rot.x, 0.0)

## / Create a rigid transformation matrix. (transation + rotation)

proc cpTransformRigid*(translate: cpVect; radians: cpFloat): cpTransform {.inline.} =
  var rot: cpVect = cpvforangle(radians)
  return cpTransformNewTranspose(rot.x, -rot.y, translate.x, rot.y, rot.x, translate.y)

## / Fast inverse of a rigid transformation matrix.

proc cpTransformRigidInverse*(t: cpTransform): cpTransform {.inline.} =
  return cpTransformNewTranspose(t.d, -t.c, (t.c * t.ty - t.tx * t.d), -t.b, t.a,
                                (t.tx * t.b - t.a * t.ty))

## MARK: Miscellaneous (but useful) transformation matrices.
##  See source for documentation...

proc cpTransformWrap*(outer: cpTransform; inner: cpTransform): cpTransform {.inline.} =
  return cpTransformMult(cpTransformInverse(outer), cpTransformMult(inner, outer))

proc cpTransformWrapInverse*(outer: cpTransform; inner: cpTransform): cpTransform {.
    inline.} =
  return cpTransformMult(outer, cpTransformMult(inner, cpTransformInverse(outer)))

proc cpTransformOrtho*(bb: cpBB): cpTransform {.inline.} =
  return cpTransformNewTranspose(2.0 / (bb.r - bb.l), 0.0,
                                -((bb.r + bb.l) / (bb.r - bb.l)), 0.0,
                                2.0 / (bb.t - bb.b),
                                -((bb.t + bb.b) / (bb.t - bb.b)))

proc cpTransformBoneScale*(v0: cpVect; v1: cpVect): cpTransform {.inline.} =
  var d: cpVect = cpvsub(v1, v0)
  return cpTransformNewTranspose(d.x, -d.y, v0.x, d.y, d.x, v0.y)

proc cpTransformAxialScale*(axis: cpVect; pivot: cpVect; scale: cpFloat): cpTransform {.
    inline.} =
  var A: cpFloat = axis.x * axis.y * (scale - 1.0)
  var B: cpFloat = cpvdot(axis, pivot) * (1.0 - scale)
  return cpTransformNewTranspose(scale * axis.x * axis.x + axis.y * axis.y, A, axis.x * B, A,
                                axis.x * axis.x + scale * axis.y * axis.y, axis.y * B)
