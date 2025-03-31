function(ct_configure_target TARGET)
  include(ConfigureCompiler)
  ct_configure_compiler("${CMAKE_CXX_COMPILER_ID}" "${CT_HARDENED}" "${CT_SANITIZED}")

  separate_arguments(CT_COMPILER_FLAGS)
  separate_arguments(CT_LINKER_FLAGS)

  target_compile_options("${TARGET}" PRIVATE ${CT_COMPILER_FLAGS})
  target_link_options("${TARGET}" PRIVATE ${CT_LINKER_FLAGS})
endfunction()
