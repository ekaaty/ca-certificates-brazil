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

add_custom_target(clear-certs
  COMMAND rm -rf 
    certs/
    pki/
)

add_custom_target(certs
  COMMAND xargs -n1 
    curl 
      --create-dirs 
      --output-dir certs 
      -ksO < ${CMAKE_CURRENT_SOURCE_DIR}/sources
    && cd certs
    && (sha512sum -c --quiet ${HASH_FILE} || exit -1)
    && unzip ACcompactado.zip
  DEPENDS
    clear-certs
)

add_custom_target(isrg-root-x2.crt
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/crt2bundle.sh 
    pki/ca-trust-source/anchors/isrg-root-x2.crt
    certs/isrg-root-x2.pem
  DEPENDS
    certs
)

add_custom_target(lets-encrypt-ca-bundle.crt
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/crt2bundle.sh
    pki/ca-trust-source/anchors/lets-encrypt-ca-bundle.crt
    certs/lets-encrypt-e1.pem
    certs/lets-encrypt-e2.pem
    certs/lets-encrypt-r3.pem
    certs/lets-encrypt-r4.pem
  DEPENDS
    certs
)

add_custom_target(icp-brasil-ca-bundle.crt
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/crt2bundle.sh
    pki/ca-trust-source/anchors/icp-brasil-ca-bundle.crt
    certs/*.crt
  DEPENDS
    certs
)

add_custom_target(anchors ALL
  DEPENDS
    isrg-root-x2.crt
    lets-encrypt-ca-bundle.crt
    icp-brasil-ca-bundle.crt
)

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
  FILES
    ${CMAKE_CURRENT_BINARY_DIR}/pki/ca-trust-source/anchors/isrg-root-x2.crt
    ${CMAKE_CURRENT_BINARY_DIR}/pki/ca-trust-source/anchors/lets-encrypt-ca-bundle.crt
    ${CMAKE_CURRENT_BINARY_DIR}/pki/ca-trust-source/anchors/icp-brasil-ca-bundle.crt
  DESTINATION
    ${CMAKE_INSTALL_PREFIX}/${CACERT_INSTALL_DIR}
)

# vim: ts=2:sw=2:sts=2:et
