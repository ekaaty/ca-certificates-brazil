cmake_minimum_required(VERSION 3.16)

project(ca-certificates-brazil)
set(HASH_FILE "hashsha512.txt")

execute_process(
  COMMAND bash -c 
    "date +%Y.%m.%d \
      -d \"$( \
      curl -ksI $(grep ${HASH_FILE} ${CMAKE_SOURCE_DIR}/sources) \
        | grep -iPo '^Last-Modified: \\K[\\S ]*'
      )\"
    "
  OUTPUT_VARIABLE PROJECT_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
  COMMAND echo ${PROJECT_VERSION}
  OUTPUT_FILE ${CMAKE_BINARY_DIR}/version
)

set(SourceFiles 
  "${CMAKE_SOURCE_DIR}/cmake"
  "${CMAKE_SOURCE_DIR}/CMakeLists.txt"
  "${CMAKE_SOURCE_DIR}/CPackLists.txt"
  "${CMAKE_SOURCE_DIR}/sources"
)

include(CPackLists.txt)

add_custom_target(clear-cache
  COMMAND rm -rf cache/
)

add_custom_target(clear-certs
  COMMAND rm -rf certs/
)

add_custom_target(clear-anchors
  COMMAND rm -rf pki/
)

add_custom_target(clear-docs
  COMMAND rm -rf docs/
)

add_custom_target(clear-all
  DEPENDS
    clear-anchors
    clear-cache
    clear-certs
    clear-docs
)

add_custom_target(sources
  COMMAND xargs -n1
    curl
      --create-dirs
      --output-dir cache
      -ksO < ${CMAKE_CURRENT_SOURCE_DIR}/sources
  DEPENDS
    clear-cache
)

add_custom_target(certs
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/utils/cert-tool extract
    && ${CMAKE_CURRENT_SOURCE_DIR}/utils/cert-tool classify
  DEPENDS
    clear-certs
    sources
)

add_custom_target(anchors ALL
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/utils/cert-tool anchors
  DEPENDS
    clear-anchors
    certs
)

add_custom_target(docs ALL
  COMMAND mkdir docs
    && cp cache/*.pdf docs/
  DEPENDS
    clear-docs
    sources
)

# Checks for OpeSSL utility
find_program(OPENSSL
  NAMES openssl openssl3
  REQUIRED
)
message("-- Check for OpenSSL utility: ${OPENSSL}")

# Checks which tool is used to update certificate keyring
find_program(UPDATE_CACERTS_TOOL
  NAMES
    update-ca-certificates
    update-ca-trust
  REQUIRED
)
message("-- Check for CA certificates update tool: ${UPDATE_CACERTS_TOOL}")
string(REGEX MATCH "update-ca-trust" P11KIT UPDATE_CACERTS_TOOL)
string(REGEX MATCH "update-ca-certificates" LEGACY UPDATE_CACERTS_TOOL)

# Set install destination directory according the used tool
if(DEFINED P11KIT)
  set(CACERT_INSTALL_DIR "share/pki/ca-trust-source/anchors")
else()
  set(CACERT_INSTALL_DIR "share/ca-certificates/extra")
endif()
message("-- Set install path to CA certificates: ${CACERT_INSTALL_DIR}")

install(
  DIRECTORY 
    ${CMAKE_CURRENT_BINARY_DIR}/pki/ca-trust-source/anchors/.
  DESTINATION
    ${CMAKE_INSTALL_PREFIX}/${CACERT_INSTALL_DIR}
  FILES_MATCHING
    PATTERN "*.crt"
)

set(DOCS_INSTALL_DIR "share/doc/${PROJECT_NAME}")
install(
  FILES
  ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE
    ${CMAKE_CURRENT_SOURCE_DIR}/README.md
    ${CMAKE_CURRENT_BINARY_DIR}/docs/cpsrootca.pdf
    ${CMAKE_CURRENT_BINARY_DIR}/docs/DPCacraiz.pdf
    ${CMAKE_CURRENT_BINARY_DIR}/docs/PSacraiz.pdf
  DESTINATION
    ${CMAKE_INSTALL_PREFIX}/${DOCS_INSTALL_DIR}
)

# vim: ts=2:sw=2:sts=2:et
