function(ct_configure_compiler COMPILER_ID HARDENED SANITIZED)
  set(IS_GCC OFF)
  set(IS_CLANG OFF)

  if(COMPILER_ID STREQUAL "GNU")
    set(IS_GCC ON)
  elseif(COMPILER_ID MATCHES "Clang")
    set(IS_CLANG ON)
  endif()

  set(CT_COMPILER_FLAGS "")
  set(CT_LINKER_FLAGS "")

  if(IS_CLANG)
    set(CT_COMPILER_FLAGS "${CT_COMPILER_FLAGS} -stdlib=libc++")
    set(CT_LINKER_FLAGS "${CT_LINKER_FLAGS} -stdlib=libc++")
    message(STATUS "Using libc++ as a standard library")
  endif()

  if(HARDENED)
    if(IS_GCC)
      set(CT_COMPILER_FLAGS "${CT_COMPILER_FLAGS} -D_GLIBCXX_DEBUG")
      message(STATUS "Enabled debug mode for libstdc++")
    elseif(IS_CLANG)
      set(CT_COMPILER_FLAGS "${CT_COMPILER_FLAGS} -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG")
      message(STATUS "Enabled hardening mode for libc++")
    else()
      message(STATUS "Hardening is not supported for CXX compiler: '${COMPILER_ID}'")
    endif()
  endif()

  if(SANITIZED)
    if(IS_GCC OR IS_CLANG)
      set(CT_COMPILER_FLAGS "${CT_COMPILER_FLAGS} -fsanitize=undefined,address")
      set(CT_LINKER_FLAGS "${CT_LINKER_FLAGS} -fsanitize=undefined,address")
      string(JOIN " " CT_COMPILER_FLAGS
        "${CT_COMPILER_FLAGS}"
        "-fno-sanitize-recover=all"
        "-fno-optimize-sibling-calls"
        "-fno-omit-frame-pointer"
      )
      message(STATUS "Enabled UBSan and ASan")
    else()
      message(WARNING "Sanitized builds are not supported for CXX compiler: '${COMPILER_ID}'")
    endif()
  endif()

  message(STATUS "New compiler flags: ${CT_COMPILER_FLAGS}")
  message(STATUS "New linker flags: ${CT_LINKER_FLAGS}")

  set(CT_COMPILER_FLAGS ${CT_COMPILER_FLAGS} PARENT_SCOPE)
  set(CT_LINKER_FLAGS ${CT_LINKER_FLAGS} PARENT_SCOPE)
endfunction()
