#!/bin/bash

out=${1}
mkdir -p $(dirname ${out})
shift

in=''
for c in ${*}; do
  echo "+ Loading CA certificate: ${c}";
  in="${in} -certfile ${c}";
done;

openssl crl2pkcs7 -nocrl ${in} \
  | openssl pkcs7 -print_certs -out ${out}
