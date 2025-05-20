cmake_minimum_required(VERSION 3.16)

project(ca-certificates-brazil)
string(TIMESTAMP PROJECT_VERSION "%Y%m%d")

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
    isrg-root-x2.crt
    lets-encrypt-ca-bundle.crt
    icp-brasil-ca-bundle.crt
)

add_custom_target(certs
  COMMAND xargs -n1 
    curl 
      --create-dirs 
      --output-dir certs 
      -ksO < ${CMAKE_CURRENT_SOURCE_DIR}/sources
    && unzip -d certs certs/ACcompactado.zip
  DEPENDS
    clear-certs
)

add_custom_target(isrg-root-x2.crt
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/crt2bundle.sh 
    buildroot/share/pki/ca-trust-source/anchors/isrg-root-x2.crt
    certs/isrg-root-x2.pem
  DEPENDS
    certs
)

add_custom_target(lets-encrypt-ca-bundle.crt
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/crt2bundle.sh
    buildroot/share/pki/ca-trust-source/anchors/lets-encrypt-ca-bundle.crt
    certs/lets-encrypt-e1.pem
    certs/lets-encrypt-e2.pem
    certs/lets-encrypt-r3.pem
    certs/lets-encrypt-r4.pem
  DEPENDS
    certs
)

add_custom_target(icp-brasil-ca-bundle.crt
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/crt2bundle.sh
    buildroot/share/pki/ca-trust-source/anchors/icp-brasil-ca-bundle.crt
    certs/*.crt
  DEPENDS
    certs
)

add_custom_target(archors ALL
  DEPENDS
    isrg-root-x2.crt
    lets-encrypt-ca-bundle.crt
    icp-brasil-ca-bundle.crt
)

install(
  FILES
    ${CMAKE_CURRENT_BINARY_DIR}/buildroot/share/pki/ca-trust-source/anchors/isrg-root-x2.crt
    ${CMAKE_CURRENT_BINARY_DIR}/buildroot/share/pki/ca-trust-source/anchors/lets-encrypt-ca-bundle.crt
    ${CMAKE_CURRENT_BINARY_DIR}/buildroot/share/pki/ca-trust-source/anchors/icp-brasil-ca-bundle.crt
  DESTINATION
    ./share/pki/ca-trust-source/anchors
)

# vim: ts=2:sw=2:sts=2:et
