#!/usr/bin/env bash

typeset -A config
config=(
  [DEFAULT_ROOT_CA_NAME]=""
  [GEN_FOLDER]="generated"
  [TMP_CSR_FILENAME]="tmp_server.csr.cnf"
)

if [ ! -f generator.conf ]; then
  cp generator.conf.dist generator.conf
fi


#=============================================================================
# Fetching config from generator.conf
while read -r line
do
  if echo "$line" | grep -F = &>/dev/null
  then
    varName=$(echo "$line" | cut -d '=' -f 1)
    config[$varName]=$(echo "$line" | cut -d '=' -f 2-)
  fi
done < generator.conf
#=============================================================================

#=============================================================================
# Name of the .key and .pem files for the root CA
if [ -z "${config[DEFAULT_ROOT_CA_NAME]}" ]; then
  read -rp "Key name [rootCA]: " rootCertName
  rootCertName=${rootCertName:-rootCA}
else
  rootCertName=${config[DEFAULT_ROOT_CA_NAME]}
fi
#=============================================================================

#=============================================================================
# Generating
echo "Generating key..."
openssl genrsa -des3 -out "${config[GEN_FOLDER]}"/"$keyName".key 2048
echo "Generating certificate..."
openssl req -x509 -new -nodes -key "${config[GEN_FOLDER]}"/"$keyName".key -sha256 -days 1024 -out "${config[GEN_FOLDER]}"/"$keyName".pem
#=============================================================================
