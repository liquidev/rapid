{.deadCodeElim: on.}
when defined(windows):
  const wrendll* = "libwren.dll"
elif defined(macosx):
  const wrendll* = "libwren.dylib"
else:
  const wrendll* = "libwren.so"


##  The Wren semantic version number components.
const
  WREN_VERSION_MAJOR* = 0
  WREN_VERSION_MINOR* = 1
  WREN_VERSION_PATCH* = 0
  
  ##  A human-friendly string representation of the version.
  WREN_VERSION_STRING* = "0.1.0"
  
  ##  A monotonically increasing numeric representation of the version number. Use
  ##  this if you want to do range checks over versions.
  WREN_VERSION_NUMBER* = (
    WREN_VERSION_MAJOR * 1000000 +
    WREN_VERSION_MINOR * 1000 +
    WREN_VERSION_PATCH)
  

type
  ##  Wren has no global state, so all state stored by a running interpreter lives
  ##  here.
  WrenVM* {.bycopy.} = object

  ##  A handle to a Wren object.
  ##  This lets code outside of the VM hold a persistent reference to an object.
  ##  After a handle is acquired, and until it is released, this ensures the
  ##  garbage collector will not reclaim the object it references.
  WrenHandle* {.bycopy.} = object
  
  WrenErrorType* {.size: sizeof(cint).} = enum
    WREN_ERROR_COMPILE,       ##  The error message for a runtime error.
    WREN_ERROR_RUNTIME,       ##  One entry of a runtime error's stack trace.
    WREN_ERROR_STACK_TRACE

  ##  A generic allocation function that handles all explicit memory management
  ##  used by Wren. It's used like so:
  ## 
  ##  - To allocate new memory, [memory] is NULL and [newSize] is the desired
  ##    size. It should return the allocated memory or NULL on failure.
  ## 
  ##  - To attempt to grow an existing allocation, [memory] is the memory, and
  ##    [newSize] is the desired size. It should return [memory] if it was able to
  ##    grow it in place, or a new pointer if it had to move it.
  ## 
  ##  - To shrink memory, [memory] and [newSize] are the same as above but it will
  ##    always return [memory].
  ## 
  ##  - To free memory, [memory] will be the memory to free and [newSize] will be
  ##    zero. It should return NULL.
  WrenReallocateFn* = proc (memory: pointer; newSize: csize): pointer {.cdecl.}

  ##  A function callable from Wren code, but implemented in C.
  WrenForeignMethodFn* = proc (vm: ptr WrenVM) {.cdecl.}

  ##  A finalizer function for freeing resources owned by an instance of a foreign
  ##  class. Unlike most foreign methods, finalizers do not have access to the VM
  ##  and should not interact with it since it's in the middle of a garbage
  ##  collection.
  WrenFinalizerFn* = proc (data: pointer) {.cdecl.}

  ##  Loads and returns the source code for the module [name].
  WrenLoadModuleFn* = proc (vm: ptr WrenVM; name: cstring): cstring {.cdecl.}

  ##  Returns a pointer to a foreign method on [className] in [module] with
  ##  [signature].
  WrenBindForeignMethodFn* = proc (
    vm: ptr WrenVM; module: cstring; className: cstring; isStatic: bool;
    signature: cstring): WrenForeignMethodFn {.cdecl.}

  ##  Displays a string of text to the user.
  WrenWriteFn* = proc (vm: ptr WrenVM; text: cstring) {.cdecl.}

  ##  Reports an error to the user.
  ##  An error detected during compile time is reported by calling this once with
  ##  `WREN_ERROR_COMPILE`, the name of the module and line where the error occurs,
  ##  and the compiler's error message.
  ##  A runtime error is reported by calling this once with `WREN_ERROR_RUNTIME`,
  ##  no module or line, and the runtime error's message. After that, a series of
  ##  `WREN_ERROR_STACK_TRACE` calls are made for each line in the stack trace.
  ##  Each of those has the module and line where the method or function is
  ##  defined and [message] is the name of the method or function.
  WrenErrorFn* = proc (
    vm: ptr WrenVM; `type`: WrenErrorType; module: cstring; line: cint;
    message: cstring) {.cdecl.}

  WrenForeignClassMethods* {.bycopy.} = object
    ##  The callback invoked when the foreign object is created.
    ##  This must be provided. Inside the body of this, it must call
    ##  [wrenSetSlotNewForeign()] exactly once.
    allocate*: WrenForeignMethodFn

    ##  The callback invoked when the garbage collector is about to collect a
    ##  foreign object's memory.
    ##  This may be `NULL` if the foreign class does not need to finalize.
    finalize*: WrenFinalizerFn


  ##  Returns a pair of pointers to the foreign methods used to allocate and
  ##  finalize the data for instances of [className] in [module].
  WrenBindForeignClassFn* = proc (
    vm: ptr WrenVM; module: cstring; className: cstring
  ): WrenForeignClassMethods {.cdecl.}

  WrenConfiguration* {.bycopy.} = object
    ##  The callback Wren will use to allocate, reallocate, and deallocate memory.
    ##  If `NULL`, defaults to a built-in function that uses `realloc` and `free`.
    reallocateFn*: WrenReallocateFn

    ##  The callback Wren uses to load a module.
    ## 
    ##  Since Wren does not talk directly to the file system, it relies on the
    ##  embedder to physically locate and read the source code for a module. The
    ##  first time an import appears, Wren will call this and pass in the name of
    ##  the module being imported. The VM should return the soure code for that
    ##  module. Memory for the source should be allocated using [reallocateFn] and
    ##  Wren will take ownership over it.
    ## 
    ##  This will only be called once for any given module name. Wren caches the
    ##  result internally so subsequent imports of the same module will use the
    ##  previous source and not call this.
    ## 
    ##  If a module with the given name could not be found by the embedder, it
    ##  should return NULL and Wren will report that as a runtime error.
    loadModuleFn*: WrenLoadModuleFn
    
    ##  The callback Wren uses to find a foreign method and bind it to a class.
    ## 
    ##  When a foreign method is declared in a class, this will be called with the
    ##  foreign method's module, class, and signature when the class body is
    ##  executed. It should return a pointer to the foreign function that will be
    ##  bound to that method.
    ## 
    ##  If the foreign function could not be found, this should return NULL and
    ##  Wren will report it as runtime error.
    bindForeignMethodFn*: WrenBindForeignMethodFn
    
    ##  The callback Wren uses to find a foreign class and get its foreign methods.
    ## 
    ##  When a foreign class is declared, this will be called with the class's
    ##  module and name when the class body is executed. It should return the
    ##  foreign functions uses to allocate and (optionally) finalize the bytes
    ##  stored in the foreign object when an instance is created.
    bindForeignClassFn*: WrenBindForeignClassFn
    
    ##  The callback Wren uses to display text when `System.print()` or the other
    ##  related functions are called.
    ## 
    ##  If this is `NULL`, Wren discards any printed text.
    writeFn*: WrenWriteFn
    
    ##  The callback Wren uses to report errors.
    ## 
    ##  When an error occurs, this will be called with the module name, line
    ##  number, and an error message. If this is `NULL`, Wren doesn't report any
    ##  errors.
    errorFn*: WrenErrorFn
    
    ##  The number of bytes Wren will allocate before triggering the first garbage
    ##  collection.
    ## 
    ##  If zero, defaults to 10MB.
    initialHeapSize*: csize
    
    ##  After a collection occurs, the threshold for the next collection is
    ##  determined based on the number of bytes remaining in use. This allows Wren
    ##  to shrink its memory usage automatically after reclaiming a large amount
    ##  of memory.
    ## 
    ##  This can be used to ensure that the heap does not get too small, which can
    ##  in turn lead to a large number of collections afterwards as the heap grows
    ##  back to a usable size.
    ## 
    ##  If zero, defaults to 1MB.
    minHeapSize*: csize
    
    ##  Wren will resize the heap automatically as the number of bytes
    ##  remaining in use after a collection changes. This number determines the
    ##  amount of additional memory Wren will use after a collection, as a
    ##  percentage of the current heap size.
    ## 
    ##  For example, say that this is 50. After a garbage collection, when there
    ##  are 400 bytes of memory still in use, the next collection will be triggered
    ##  after a total of 600 bytes are allocated (including the 400 already in use.)
    ## 
    ##  Setting this to a smaller number wastes less memory, but triggers more
    ##  frequent garbage collections.
    ## 
    ##  If zero, defaults to 50.
    heapGrowthPercent*: cint
    
    ##  User-defined data associated with the VM.
    userData*: pointer

  WrenInterpretResult* {.size: sizeof(cint).} = enum
    WREN_RESULT_SUCCESS,
    WREN_RESULT_COMPILE_ERROR,
    WREN_RESULT_RUNTIME_ERROR



  ##  The type of an object stored in a slot.
  ## 
  ##  This is not necessarily the object's *class*, but instead its low level
  ##  representation type.
  WrenType* {.size: sizeof(cint).} = enum
    WREN_TYPE_BOOL,
    WREN_TYPE_NUM,
    WREN_TYPE_FOREIGN,
    WREN_TYPE_LIST,
    WREN_TYPE_NULL,
    WREN_TYPE_STRING,
    WREN_TYPE_UNKNOWN  ##  The object is of a type that isn't accessible by the C API.


##  Initializes [configuration] with all of its default values.
## 
##  Call this before setting the particular fields you care about.
proc initConfiguration*(configuration: ptr WrenConfiguration)
  {.cdecl, importc: "wrenInitConfiguration", dynlib: wrendll.}

##  Creates a new Wren virtual machine using the given [configuration]. Wren
##  will copy the configuration data, so the argument passed to this can be
##  freed after calling this. If [configuration] is `NULL`, uses a default
##  configuration.
proc newVM*(configuration: ptr WrenConfiguration): ptr WrenVM
  {.cdecl, importc: "wrenNewVM", dynlib: wrendll.}

##  Disposes of all resources is use by [vm], which was previously created by a
##  call to [wrenNewVM].
proc freeVM*(vm: ptr WrenVM) {.cdecl, importc: "wrenFreeVM", dynlib: wrendll.}

##  Immediately run the garbage collector to free unused memory.
proc collectGarbage*(vm: ptr WrenVM)
  {.cdecl, importc: "wrenCollectGarbage", dynlib: wrendll.}

##  Runs [source], a string of Wren source code in a new fiber in [vm].
proc interpret*(vm: ptr WrenVM; source: cstring): WrenInterpretResult
  {.cdecl, importc: "wrenInterpret", dynlib: wrendll.}

##  Creates a handle that can be used to invoke a method with [signature] on
##  using a receiver and arguments that are set up on the stack.
## 
##  This handle can be used repeatedly to directly invoke that method from C
##  code using [wrenCall].
## 
##  When you are done with this handle, it must be released using
##  [wrenReleaseHandle].
proc makeCallHandle*(vm: ptr WrenVM; signature: cstring): ptr WrenHandle
  {.cdecl, importc: "wrenMakeCallHandle", dynlib: wrendll.}

##  Calls [method], using the receiver and arguments previously set up on the
##  stack.
## 
##  [method] must have been created by a call to [wrenMakeCallHandle]. The
##  arguments to the method must be already on the stack. The receiver should be
##  in slot 0 with the remaining arguments following it, in order. It is an
##  error if the number of arguments provided does not match the method's
##  signature.
## 
##  After this returns, you can access the return value from slot 0 on the stack.
proc call*(vm: ptr WrenVM; `method`: ptr WrenHandle): WrenInterpretResult
  {.cdecl, importc: "wrenCall", dynlib: wrendll.}

##  Releases the reference stored in [handle]. After calling this, [handle] can
##  no longer be used.
proc releaseHandle*(vm: ptr WrenVM; handle: ptr WrenHandle)
  {.cdecl, importc: "wrenReleaseHandle", dynlib: wrendll.}

##  The following functions are intended to be called from foreign methods or
##  finalizers. The interface Wren provides to a foreign method is like a
##  register machine: you are given a numbered array of slots that values can be
##  read from and written to. Values always live in a slot (unless explicitly
##  captured using wrenGetSlotHandle(), which ensures the garbage collector can
##  find them.
## 
##  When your foreign function is called, you are given one slot for the receiver
##  and each argument to the method. The receiver is in slot 0 and the arguments
##  are in increasingly numbered slots after that. You are free to read and
##  write to those slots as you want. If you want more slots to use as scratch
##  space, you can call wrenEnsureSlots() to add more.
## 
##  When your function returns, every slot except slot zero is discarded and the
##  value in slot zero is used as the return value of the method. If you don't
##  store a return value in that slot yourself, it will retain its previous
##  value, the receiver.
## 
##  While Wren is dynamically typed, C is not. This means the C interface has to
##  support the various types of primitive values a Wren variable can hold: bool,
##  double, string, etc. If we supported this for every operation in the C API,
##  there would be a combinatorial explosion of functions, like "get a
##  double-valued element from a list", "insert a string key and double value
##  into a map", etc.
## 
##  To avoid that, the only way to convert to and from a raw C value is by going
##  into and out of a slot. All other functions work with values already in a
##  slot. So, to add an element to a list, you put the list in one slot, and the
##  element in another. Then there is a single API function wrenInsertInList()
##  that takes the element out of that slot and puts it into the list.
## 
##  The goal of this API is to be easy to use while not compromising performance.
##  The latter means it does not do type or bounds checking at runtime except
##  using assertions which are generally removed from release builds. C is an
##  unsafe language, so it's up to you to be careful to use it correctly. In
##  return, you get a very fast FFI.
##  Returns the number of slots available to the current foreign method.
proc getSlotCount*(vm: ptr WrenVM): cint
  {.cdecl, importc: "wrenGetSlotCount", dynlib: wrendll.}

##  Ensures that the foreign method stack has at least [numSlots] available for
##  use, growing the stack if needed.
## 
##  Does not shrink the stack if it has more than enough slots.
## 
##  It is an error to call this from a finalizer.
proc ensureSlots*(vm: ptr WrenVM; numSlots: cint)
  {.cdecl, importc: "wrenEnsureSlots", dynlib: wrendll.}

##  Gets the type of the object in [slot].
proc getSlotType*(vm: ptr WrenVM; slot: cint): WrenType
  {.cdecl, importc: "wrenGetSlotType", dynlib: wrendll.}

##  Reads a boolean value from [slot].
## 
##  It is an error to call this if the slot does not contain a boolean value.
proc getSlotBool*(vm: ptr WrenVM; slot: cint): bool
  {.cdecl, importc: "wrenGetSlotBool", dynlib: wrendll.}

##  Reads a byte array from [slot].
## 
##  The memory for the returned string is owned by Wren. You can inspect it
##  while in your foreign method, but cannot keep a pointer to it after the
##  function returns, since the garbage collector may reclaim it.
## 
##  Returns a pointer to the first byte of the array and fill [length] with the
##  number of bytes in the array.
## 
##  It is an error to call this if the slot does not contain a string.
proc getSlotBytes*(vm: ptr WrenVM; slot: cint; length: ptr cint): cstring
  {.cdecl, importc: "wrenGetSlotBytes", dynlib: wrendll.}

##  Reads a number from [slot].
## 
##  It is an error to call this if the slot does not contain a number.
proc getSlotDouble*(vm: ptr WrenVM; slot: cint): cdouble
  {.cdecl, importc: "wrenGetSlotDouble", dynlib: wrendll.}

##  Reads a foreign object from [slot] and returns a pointer to the foreign data
##  stored with it.
## 
##  It is an error to call this if the slot does not contain an instance of a
##  foreign class.
proc getSlotForeign*(vm: ptr WrenVM; slot: cint): pointer
  {.cdecl, importc: "wrenGetSlotForeign", dynlib: wrendll.}

##  Reads a string from [slot].
## 
##  The memory for the returned string is owned by Wren. You can inspect it
##  while in your foreign method, but cannot keep a pointer to it after the
##  function returns, since the garbage collector may reclaim it.
## 
##  It is an error to call this if the slot does not contain a string.
proc getSlotString*(vm: ptr WrenVM; slot: cint): cstring
  {.cdecl, importc: "wrenGetSlotString", dynlib: wrendll.}

##  Creates a handle for the value stored in [slot].
## 
##  This will prevent the object that is referred to from being garbage collected
##  until the handle is released by calling [wrenReleaseHandle()].
proc getSlotHandle*(vm: ptr WrenVM; slot: cint): ptr WrenHandle
  {.cdecl, importc: "wrenGetSlotHandle", dynlib: wrendll.}

##  Stores the boolean [value] in [slot].
proc setSlotBool*(vm: ptr WrenVM; slot: cint; value: bool)
  {.cdecl, importc: "wrenSetSlotBool", dynlib: wrendll.}

##  Stores the array [length] of [bytes] in [slot].
## 
##  The bytes are copied to a new string within Wren's heap, so you can free
##  memory used by them after this is called.
proc setSlotBytes*(vm: ptr WrenVM; slot: cint; bytes: cstring; length: csize)
  {.cdecl, importc: "wrenSetSlotBytes", dynlib: wrendll.}

##  Stores the numeric [value] in [slot].
proc setSlotDouble*(vm: ptr WrenVM; slot: cint; value: cdouble)
  {.cdecl, importc: "wrenSetSlotDouble", dynlib: wrendll.}

##  Creates a new instance of the foreign class stored in [classSlot] with [size]
##  bytes of raw storage and places the resulting object in [slot].
## 
##  This does not invoke the foreign class's constructor on the new instance. If
##  you need that to happen, call the constructor from Wren, which will then
##  call the allocator foreign method. In there, call this to create the object
##  and then the constructor will be invoked when the allocator returns.
## 
##  Returns a pointer to the foreign object's data.
proc setSlotNewForeign*(vm: ptr WrenVM; slot: cint; classSlot: cint; size: csize): pointer
  {.cdecl, importc: "wrenSetSlotNewForeign", dynlib: wrendll.}

##  Stores a new empty list in [slot].
proc setSlotNewList*(vm: ptr WrenVM; slot: cint)
  {.cdecl, importc: "wrenSetSlotNewList", dynlib: wrendll.}

##  Stores null in [slot].
proc setSlotNull*(vm: ptr WrenVM; slot: cint)
  {.cdecl, importc: "wrenSetSlotNull", dynlib: wrendll.}

##  Stores the string [text] in [slot].
## 
##  The [text] is copied to a new string within Wren's heap, so you can free
##  memory used by it after this is called. The length is calculated using
##  [strlen()]. If the string may contain any null bytes in the middle, then you
##  should use [wrenSetSlotBytes()] instead.
proc setSlotString*(vm: ptr WrenVM; slot: cint; text: cstring)
  {.cdecl, importc: "wrenSetSlotString", dynlib: wrendll.}

##  Stores the value captured in [handle] in [slot].
## 
##  This does not release the handle for the value.
proc setSlotHandle*(vm: ptr WrenVM; slot: cint; handle: ptr WrenHandle)
  {.cdecl, importc: "wrenSetSlotHandle", dynlib: wrendll.}

##  Returns the number of elements in the list stored in [slot].
proc getListCount*(vm: ptr WrenVM; slot: cint): cint
  {.cdecl, importc: "wrenGetListCount", dynlib: wrendll.}

##  Reads element [index] from the list in [listSlot] and stores it in
##  [elementSlot].
proc getListElement*(vm: ptr WrenVM; listSlot: cint; index: cint; elementSlot: cint)
  {.cdecl, importc: "wrenGetListElement", dynlib: wrendll.}

##  Takes the value stored at [elementSlot] and inserts it into the list stored
##  at [listSlot] at [index].
## 
##  As in Wren, negative indexes can be used to insert from the end. To append
##  an element, use `-1` for the index.
proc insertInList*(vm: ptr WrenVM; listSlot: cint; index: cint; elementSlot: cint)
  {.cdecl, importc: "wrenInsertInList", dynlib: wrendll.}

##  Looks up the top level variable with [name] in [module] and stores it in
##  [slot].
proc getVariable*(vm: ptr WrenVM; module: cstring; name: cstring; slot: cint)
  {.cdecl, importc: "wrenGetVariable", dynlib: wrendll.}

##  Sets the current fiber to be aborted, and uses the value in [slot] as the
##  runtime error object.
proc abortFiber*(vm: ptr WrenVM; slot: cint)
  {.cdecl, importc: "wrenAbortFiber", dynlib: wrendll.}

##  Returns the user data associated with the WrenVM.
proc getUserData*(vm: ptr WrenVM): pointer
  {.cdecl, importc: "wrenGetUserData", dynlib: wrendll.}

##  Sets user data associated with the WrenVM.
proc setUserData*(vm: ptr WrenVM; userData: pointer)
  {.cdecl, importc: "wrenSetUserData", dynlib: wrendll.}
