#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import macros

macro dataSpec*(body: untyped): untyped =
  ## A DSL for ``RData`` construction.
  runnableExamples:
    let tc = (fltNearest, fltNearest, wrapRepeat)
    var data = dataSpec:
      "myIcon" <- image("myIcon.png", tc)
      "mySound" <- sound("bleep.wav")
      "spr_*" <- dir(resImage, "sprites/")

  var stmts = newStmtList()
  stmts.add(newVarStmt(ident("d"), newCall("newRData")))
  for decl in body:
    doAssert decl.kind == nnkInfix and eqIdent(decl[0], "<-"),
      "Resource declaration must follow the form: \"id\" <- res"
    let id = decl[1]
    var call = decl[2]
    call[0] = newDotExpr(ident("d"), call[0])
    call.insert(1, id)
    stmts.add(call)
  stmts.add(ident("d"))
  result = newBlockStmt(stmts)
