from strutils import `%`
import macros, tables
import terminal

import ../lib/wren/src/wren

type
  WrenForeignType* = object
    methods*, stMethods*: TableRef[string, WrenForeignMethodFn]
    allocFn*: proc (vm: ptr WrenVM) {.cdecl.}
    finalizeFn*: proc (data: pointer) {.cdecl.}

var wrenTypes: TableRef[string, WrenForeignType] = newTable[string, WrenForeignType]()

proc declWrenClass*(name: string): WrenForeignType =
  result = WrenForeignType(
    methods: newTable[string, WrenForeignMethodFn](),
    stMethods: newTable[string, WrenForeignMethodFn]()
  )
  wrenTypes.add(name, result)

proc declWrenMethodWrapper*(class, signature: string, impl: WrenForeignMethodFn) =
  wrenTypes[class].methods.add(signature, impl)

proc newAutowrenVM*(): ptr WrenVM =
  var conf = wren.emptyConfig()

  conf.writeFn = proc (vm: ptr WrenVM, str: cstring) {.cdecl.} =
    stdout.write($str)

  conf.errorFn = proc (vm: ptr WrenVM, err: WrenErrorType, modl: cstring, ln: cint, msg: cstring) {.cdecl.} =
    case err
    of WREN_ERROR_COMPILE:
      let
        smod = if modl == nil: "<anonymous>" else: $modl
        smsg = if msg == nil: "–" else: $msg
      styledEcho(
        fgRed, "err: ",
        resetStyle, styleDim, "in $1 @ ln $2" % [smod, $ln],
        resetStyle, styleBright, " ", smsg
      )
    of WREN_ERROR_RUNTIME:
      styledEcho(
        fgRed, "err: ",
        resetStyle, styleBright, $msg
      )
    of WREN_ERROR_STACK_TRACE:
      styledEcho(
        fgWhite, styleDim, "  at ",
        resetStyle, styleBright, $msg,
        resetStyle, " in $1 @ ln $2" % [$modl, $ln]
      )

  conf.bindForeignClassFn =
    proc (vm: ptr WrenVM, modl, class: cstring): WrenForeignClassMethods {.cdecl.} =
      result = WrenForeignClassMethods()
      echo result
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

  result = newVM(conf)

type
  TestAutowrenType = object
    data: string
var w_TestAutowrenType = declWrenClass("TestAutowrenType")

proc newTestAutowrenType(data: string): TestAutowrenType =
  result = TestAutowrenType(
    data: data
  )

proc w_TestAutowrenType_alloc(vm: ptr WrenVM) {.cdecl.} =
  var point = cast[ptr TestAutowrenType](vm.setSlotNewForeign(0, 0, sizeof(pointer)))
  let
    args_data = $vm.getSlotString(1)
  point[] = newTestAutowrenType($args_data)
w_TestAutowrenType.allocFn = w_TestAutowrenType_alloc
w_TestAutowrenType.finalizeFn = nil

proc `data=`(t: var TestAutowrenType, data: string) =
  t.data = data
  echo t.data

proc `w_data=`(vm: ptr WrenVM) {.cdecl.} =
  var point = cast[ptr TestAutowrenType](vm.getSlotForeign(0))
  let
    args_data = $vm.getSlotString(1)
  `data=`(point[], args_data)
declWrenMethodWrapper("TestAutowrenType", "data=(_)", `w_data=`)

var vm = newAutowrenVM()

let result = vm.interpret("main", """
System.print("decl class")
foreign class TestAutowrenType {
  construct new(data) {}

  foreign data=(value)
}

System.print("inst class")
var o = TestAutowrenType.new("hello")
""")

echo result
