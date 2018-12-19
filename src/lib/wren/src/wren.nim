
import ./wren/libwren

export libwren


# custom helpers

proc emptyConfig*: ptr WrenConfiguration =
  result = addr new(WrenConfiguration)[]
  result.initConfiguration()


# stuff for a usable default config

import tables

type
  ForeignMethodTable = Table[string, WrenForeignMethodFn]

var vmModules = initTable[ptr WrenVM, ForeignMethodTable]()



proc procString (className, signature: string): string =
  return $className & "." & $signature


proc register* (vm: ptr WrenVM, className, signature: string, fn: WrenForeignMethodFn) =
  if not vmModules.hasKey(vm):
    vmModules[vm] = initTable[string, WrenForeignMethodFn]()

  vmModules[vm][procString(className, signature)] = fn


proc defaultConfig*: ptr WrenConfiguration =
  result = emptyConfig()

  result.reallocateFn = proc (
    memory: pointer; newSize: csize
  ): pointer {.cdecl.} =
    # later use dealloc(a)  ??
    # might need to used shared mem (allocShared ?)
    var a = realloc(memory, newSize)
    return a

  result.writeFn = proc (vm: ptr WrenVM, s: cstring) {.cdecl.} =
    if s != "\n":
      echo "[echo]  \"", s, "\""
  
  result.loadModuleFn = proc (vm: ptr WrenVM, name: cstring): cstring {.cdecl.} =
    let path = "./" & $name & ".wren"
    echo "[load]  loading module: ", path, "..."
    var code = readFile(path).cstring
    echo "[load]  done "
    return code

  result.errorFn = proc (
    vm: ptr WrenVM, 
    errorType: WrenErrorType,
    module: cstring,
    line: cint,
    message: cstring
  ) {.cdecl.} =
    let msg = if message == nil: "*no message*" else: $message
    let mo = if module == nil: "anon" else: $module
    echo "[" & $line & "] " & mo & " ->  " & msg

  result.bindForeignMethodFn = proc (
    vm: ptr WrenVM, 
    module: cstring, 
    className: cstring, 
    isStatic: bool, 
    signature: cstring
  ): WrenForeignMethodFn {.cdecl.} =
    let ps = procString($className, $signature)

    if not vmModules.hasKey(vm):
      echo "No foreign methods registered for this VM. Module (" & $module & ") Looking for: ", ps
      return nil

    if not vmModules[vm].hasKey(ps):
      echo "No foreign method registered. Module (" & $module & ") Looking for: ", ps
      return nil

    return vmModules[vm][ps]


proc runScript* (vm: ptr WrenVM, path: string) =
  let script = readFile(path)
  let result = interpret(vm, script)
  if result != WREN_RESULT_SUCCESS: quit "[!!!!]  Script failed to compile"
