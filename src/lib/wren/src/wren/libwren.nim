import ospaths

{.deadCodeElim: on.}
# I didn't want dynamic linking in rapid, static linking ftw

const pwd = currentSourcePath.splitPath.head
{.passC: "-I" & (pwd / "include"),
  passC: "-I" & (pwd / "vm"),
  compile: "vm/wren_compiler.c", compile: "vm/wren_core.c",
  compile: "vm/wren_debug.c", compile: "vm/wren_primitive.c",
  compile: "vm/wren_utils.c", compile: "vm/wren_value.c",
  compile: "vm/wren_vm.c".}

const
  WREN_VERSION_MAJOR* = 0
  WREN_VERSION_MINOR* = 1
  WREN_VERSION_PATCH* = 0

  WREN_VERSION_STRING* = "0.1.0"

  WREN_VERSION_NUMBER* = (
    WREN_VERSION_MAJOR * 1000000 +
    WREN_VERSION_MINOR * 1000 +
    WREN_VERSION_PATCH)


type
  WrenVM* {.bycopy.} = object

  WrenHandle* {.bycopy.} = object

  WrenReallocateFn* = proc (memory: pointer; newSize: csize): pointer {.cdecl.}

  WrenForeignMethodFn* = proc (vm: ptr WrenVM) {.cdecl.}

  WrenFinalizerFn* = proc (data: pointer) {.cdecl.}

  WrenResolveModuleFn* = proc (vm: ptr WrenVM, importer: cstring, name: cstring): cstring {.cdecl.}

  WrenLoadModuleFn* = proc (vm: ptr WrenVM; name: cstring): cstring {.cdecl.}

  WrenBindForeignMethodFn* = proc (
    vm: ptr WrenVM; module: cstring; className: cstring; isStatic: bool;
    signature: cstring): WrenForeignMethodFn {.cdecl.}

  WrenWriteFn* = proc (vm: ptr WrenVM; text: cstring) {.cdecl.}

  WrenErrorType* {.size: sizeof(cint).} = enum
    WREN_ERROR_COMPILE,
    WREN_ERROR_RUNTIME,
    WREN_ERROR_STACK_TRACE

  WrenErrorFn* = proc (
    vm: ptr WrenVM; `type`: WrenErrorType; module: cstring; line: cint;
    message: cstring) {.cdecl.}

  WrenForeignClassMethods* {.bycopy.} = object
    allocate*: WrenForeignMethodFn
    finalize*: WrenFinalizerFn

  WrenBindForeignClassFn* = proc (
    vm: ptr WrenVM; module: cstring; className: cstring
  ): WrenForeignClassMethods {.cdecl.}

  WrenConfiguration* {.bycopy.} = object
    reallocateFn*: WrenReallocateFn
    resolveModuleFn*: WrenResolveModuleFn
    loadModuleFn*: WrenLoadModuleFn
    bindForeignMethodFn*: WrenBindForeignMethodFn
    bindForeignClassFn*: WrenBindForeignClassFn
    writeFn*: WrenWriteFn
    errorFn*: WrenErrorFn
    initialHeapSize*: csize
    minHeapSize*: csize
    heapGrowthPercent*: cint
    userData*: pointer

  WrenInterpretResult* {.size: sizeof(cint).} = enum
    WREN_RESULT_SUCCESS,
    WREN_RESULT_COMPILE_ERROR,
    WREN_RESULT_RUNTIME_ERROR

  WrenType* {.size: sizeof(cint).} = enum
    WREN_TYPE_BOOL,
    WREN_TYPE_NUM,
    WREN_TYPE_FOREIGN,
    WREN_TYPE_LIST,
    WREN_TYPE_NULL,
    WREN_TYPE_STRING,
    WREN_TYPE_UNKNOWN

proc initConfiguration*(configuration: ptr WrenConfiguration)
  {.cdecl, importc: "wrenInitConfiguration", header: "wren.h".}

proc newVM*(configuration: ptr WrenConfiguration): ptr WrenVM
  {.cdecl, importc: "wrenNewVM", header: "wren.h".}

proc freeVM*(vm: ptr WrenVM) {.cdecl, importc: "wrenFreeVM", header: "wren.h".}

proc collectGarbage*(vm: ptr WrenVM)
  {.cdecl, importc: "wrenCollectGarbage", header: "wren.h".}

proc interpret*(vm: ptr WrenVM, module, source: cstring): WrenInterpretResult
  {.cdecl, importc: "wrenInterpret", header: "wren.h".}

proc makeCallHandle*(vm: ptr WrenVM; signature: cstring): ptr WrenHandle
  {.cdecl, importc: "wrenMakeCallHandle", header: "wren.h".}

proc call*(vm: ptr WrenVM; `method`: ptr WrenHandle): WrenInterpretResult
  {.cdecl, importc: "wrenCall", header: "wren.h".}

proc releaseHandle*(vm: ptr WrenVM; handle: ptr WrenHandle)
  {.cdecl, importc: "wrenReleaseHandle", header: "wren.h".}

proc getSlotCount*(vm: ptr WrenVM): cint
  {.cdecl, importc: "wrenGetSlotCount", header: "wren.h".}

proc ensureSlots*(vm: ptr WrenVM; numSlots: cint)
  {.cdecl, importc: "wrenEnsureSlots", header: "wren.h".}

proc getSlotType*(vm: ptr WrenVM; slot: cint): WrenType
  {.cdecl, importc: "wrenGetSlotType", header: "wren.h".}

proc getSlotBool*(vm: ptr WrenVM; slot: cint): bool
  {.cdecl, importc: "wrenGetSlotBool", header: "wren.h".}

proc getSlotBytes*(vm: ptr WrenVM; slot: cint; length: ptr cint): cstring
  {.cdecl, importc: "wrenGetSlotBytes", header: "wren.h".}

proc getSlotDouble*(vm: ptr WrenVM; slot: cint): cdouble
  {.cdecl, importc: "wrenGetSlotDouble", header: "wren.h".}

proc getSlotForeign*(vm: ptr WrenVM; slot: cint): pointer
  {.cdecl, importc: "wrenGetSlotForeign", header: "wren.h".}

proc getSlotString*(vm: ptr WrenVM; slot: cint): cstring
  {.cdecl, importc: "wrenGetSlotString", header: "wren.h".}

proc getSlotHandle*(vm: ptr WrenVM; slot: cint): ptr WrenHandle
  {.cdecl, importc: "wrenGetSlotHandle", header: "wren.h".}

proc setSlotBool*(vm: ptr WrenVM; slot: cint; value: bool)
  {.cdecl, importc: "wrenSetSlotBool", header: "wren.h".}

proc setSlotBytes*(vm: ptr WrenVM; slot: cint; bytes: cstring; length: csize)
  {.cdecl, importc: "wrenSetSlotBytes", header: "wren.h".}

proc setSlotDouble*(vm: ptr WrenVM; slot: cint; value: cdouble)
  {.cdecl, importc: "wrenSetSlotDouble", header: "wren.h".}

proc setSlotNewForeign*(vm: ptr WrenVM; slot: cint; classSlot: cint; size: csize): pointer
  {.cdecl, importc: "wrenSetSlotNewForeign", header: "wren.h".}

proc setSlotNewList*(vm: ptr WrenVM; slot: cint)
  {.cdecl, importc: "wrenSetSlotNewList", header: "wren.h".}

proc setSlotNull*(vm: ptr WrenVM; slot: cint)
  {.cdecl, importc: "wrenSetSlotNull", header: "wren.h".}

proc setSlotString*(vm: ptr WrenVM; slot: cint; text: cstring)
  {.cdecl, importc: "wrenSetSlotString", header: "wren.h".}

proc setSlotHandle*(vm: ptr WrenVM; slot: cint; handle: ptr WrenHandle)
  {.cdecl, importc: "wrenSetSlotHandle", header: "wren.h".}

proc getListCount*(vm: ptr WrenVM; slot: cint): cint
  {.cdecl, importc: "wrenGetListCount", header: "wren.h".}

proc getListElement*(vm: ptr WrenVM; listSlot: cint; index: cint; elementSlot: cint)
  {.cdecl, importc: "wrenGetListElement", header: "wren.h".}

proc insertInList*(vm: ptr WrenVM; listSlot: cint; index: cint; elementSlot: cint)
  {.cdecl, importc: "wrenInsertInList", header: "wren.h".}

proc getVariable*(vm: ptr WrenVM; module: cstring; name: cstring; slot: cint)
  {.cdecl, importc: "wrenGetVariable", header: "wren.h".}

proc abortFiber*(vm: ptr WrenVM; slot: cint)
  {.cdecl, importc: "wrenAbortFiber", header: "wren.h".}

proc getUserData*(vm: ptr WrenVM): pointer
  {.cdecl, importc: "wrenGetUserData", header: "wren.h".}

proc setUserData*(vm: ptr WrenVM; userData: pointer)
  {.cdecl, importc: "wrenSetUserData", header: "wren.h".}
