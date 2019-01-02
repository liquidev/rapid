import strutils
import macros, tables
import terminal

import ../lib/wren/src/wren

type
  WrenForeignType = object
    methods, stMethods: TableRef[string, WrenForeignMethod]
    ctors: seq[WrenConstructor]
    allocFn: WrenForeignMethodFn
    finalizeFn: WrenFinalizerFn
  WrenForeignMethod = object
    decl: string
    impl: WrenForeignMethodFn
  WrenConstructor = object
    decl: string
    impl: string

var wrenTypes: TableRef[string, WrenForeignType] = newTable[string, WrenForeignType]()

proc declWrenClass*(name: string) =
  let ftype = WrenForeignType(
    methods: newTable[string, WrenForeignMethod](),
    stMethods: newTable[string, WrenForeignMethod]()
  )
  wrenTypes.add(name, ftype)

proc declWrenAllocFn*(class: string, fn: WrenForeignMethodFn) =
  wrenTypes[class].allocFn = fn

proc declWrenFinalizeFn*(class: string, fn: WrenFinalizerFn) =
  wrenTypes[class].finalizeFn = fn

proc declWrenCtor*(class, decl: string, impl: string = "") =
  wrenTypes[class].ctors.add(WrenConstructor(decl: decl, impl: impl))

proc declWrenMethodWrapper*(class, signature, decl: string, impl: WrenForeignMethodFn) =
  wrenTypes[class].methods.add(signature, WrenForeignMethod(decl: decl, impl: impl))

proc genWrenWrapperScript*(): string =
  for name, wtype in wrenTypes:
    result.add("class $1 {\n" % name)
    for ctor in wtype.ctors:
      result.add("  construct $1 {" % ctor.decl)
      if ctor.impl == "": result.add("}\n")
      else: result.add("\n$1\n  }\n" % ctor.impl.indent(2))
    for sig, fn in wtype.methods:
      result.add("  foreign $1\n" % fn.decl)
    for sig, fn in wtype.stMethods:
      result.add("  foreign static $1\n" % fn.decl)
    result.add("}\n")

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
          result = t.methods[$sign].impl
        else:
          result = t.stMethods[$sign].impl

  result = newVM(conf)

type
  TestAutowrenType = object
    data: string
declWrenClass("TestAutowrenType")
declWrenCtor("TestAutowrenType", "new(data)")

proc newTestAutowrenType(data: string): TestAutowrenType =
  result = TestAutowrenType(
    data: data
  )

proc w_TestAutowrenType_alloc(vm: ptr WrenVM) {.cdecl.} =
  var point = cast[ptr TestAutowrenType](vm.setSlotNewForeign(0, 0, sizeof(ptr TestAutowrenType)))
  let
    args_data = $vm.getSlotString(1)
  point[] = newTestAutowrenType($args_data)
declWrenAllocFn("TestAutowrenType", w_TestAutowrenType_alloc)

proc data(t: TestAutowrenType): string =
  result = t.data

proc w_data(vm: ptr WrenVM) {.cdecl.} =
  var val = cast[ptr TestAutowrenType](vm.getSlotForeign(0))
  vm.setSlotString(0, data(val[]))
  declWrenMethodWrapper("TestAutowrenType", "data", "data", w_data)

proc `data=`(t: var TestAutowrenType, data: string) =
  t.data = data

proc `w_data=`(vm: ptr WrenVM) {.cdecl.} =
  var val = cast[ptr TestAutowrenType](vm.getSlotForeign(0))
  let
    args_data = $vm.getSlotString(1)
  `data=`(val[], args_data)
declWrenMethodWrapper("TestAutowrenType", "data=(_)", "data=(value)", `w_data=`)

var vm = newAutowrenVM()

let awResult = vm.interpret("<main>", genWrenWrapperScript())

let mainResult = vm.interpret("<main>", """
var o = TestAutowrenType.new("hello")
System.print(o)
o.data = "test"
System.print(o.data)
""")

echo awResult
# echo mainResult
