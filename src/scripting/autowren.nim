from strutils import `%`
import macros, tables
import terminal

import ../lib/wren/src/wren

type
  WrenForeignType* = object
    methods, stMethods: TableRef[string, WrenForeignMethodFn]
    allocFn: proc (vm: ptr WrenVM) {.cdecl.}
    finalizeFn: proc (data: pointer) {.cdecl.}

var wrenTypes: TableRef[string, WrenForeignType] = newTable[string, WrenForeignType]()

proc declWrenClass*(name: string): WrenForeignType =

  wrenTypes.add(name, WrenForeignType(
    methods: newTable[string, WrenForeignMethodFn](),
    stMethods: newTable[string, WrenForeignMethodFn]()
  ))

proc declWrenMethodWrapper*(class, name, signature: string, impl: WrenForeignMethodFn) =
  wrenTypes[class].methods.add(signature, impl)

proc newAutowrenVM*(): ptr WrenVM =
  var conf = wren.defaultConfig()

  conf.writeFn = proc (vm: ptr WrenVM, str: cstring) {.cdecl.} =
    write(stdout, $str)

  conf.errorFn = proc (vm: ptr WrenVM, err: WrenErrorType, modl: cstring, ln: cint, msg: cstring) {.cdecl.} =
    styledEcho(fgRed, "err: ", fgWhite, styleDim, "in $1 @ ln $2" % [$modl, $ln], styleBright, $msg)

  conf.bindForeignClassFn =
    proc (vm: ptr WrenVM, modl, class: cstring): WrenForeignClassMethods {.cdecl.} =
      result = WrenForeignClassMethods()
      if $class in wrenTypes:
        let t = wrenTypes[$class]
        result.allocate = t.allocFn
        result.finalize = t.finalizeFn

  conf.bindForeignMethodFn =
    proc (vm: ptr WrenVM, modl, class: cstring, isStatic: bool, sign: cstring): WrenForeignMethodFn {.cdecl.} =
      if $class in wrenTypes:
        let t = wrenTypes[$class]
        if not isStatic:
          result = t.methods[$sign]
        else:
          result = t.stMethods[$sign]

type
  TestAutowrenType = object
    data: string
var w_TestAutowrenType = declWrenClass("TestAutowrenType")

proc newTestAutowrenType(data: string): TestAutowrenType =
  result = TestAutowrenType(
    data: data
  )

proc w_TestAutowrenType_alloc(vm: ptr WrenVM) =
  var point = cast[ptr TestAutowrenType](vm.setSlotNewForeign(0, 0, sizeof(pointer)))
  let
    args_data = $vm.getSlotString(1)
  point[] = newTestAutowrenType($args_data)
w_TestAutowrenType.allocFn = w_TestAutowrenType_alloc
w_TestAutowrenType.finalizeFn = nil

proc `data=`(t: var TestAutowrenType, data: string) =
  t.data = data

proc w_setData(vm: ptr WrenVM) =
  var point = cast[ptr TestAutowrenType](vm.getSlotForeign(0))
  let
    args_data = $vm.getSlotString(1)
  `data=`(point[], args_data)

var vm = newAutowrenVM()
