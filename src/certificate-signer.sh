#!/usr/bin/env bash

typeset -A config
config=(
  [DEFAULT_C]=""
  [DEFAULT_ST]=""
  [DEFAULT_L]=""
  [DEFAULT_O]=""
  [DEFAULT_OU]=""
  [DEFAULT_EMAIL_ADDRESS]=""
  [DEFAULT_CN]=""
  [DEFAULT_ALT_NAMES]=""
  [GEN_FOLDER]="generated"
  [TMP_CSR_FILENAME]="tmp_server.csr.cnf"
  [TMP_V3_FILENAME]="tmp_v3.ext"
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
# Collecting information about the certificate (using defaults, if present)
if [ -z "${config[DEFAULT_C]}" ]; then
  read -rp "Country Name (2 letter code) [NO]: " dnC
  dnC=${dnC:-"NO"}
else
  dnC=${config[DEFAULT_C]}
fi

if [ -z "${config[DEFAULT_ST]}" ]; then
  read -rp "ST (State or Province) [Some State]: " dnST
  dnST=${dnST:-"Some State"}
else
  dnST=${config[DEFAULT_ST]}
fi

if [ -z "${config[DEFAULT_L]}" ]; then
  read -rp "L (Locality (City)) [Some City]: " dnL
  dnL=${dnL:-"Some City"}
else
  dnL=${config[DEFAULT_L]}
fi

if [ -z "${config[DEFAULT_O]}" ]; then
  read -rp "O (Organization) [Some Organization]: " dnO
  dnO=${dnO:-"Some Organization"}
else
  dnO=${config[DEFAULT_O]}
fi

if [ -z "${config[DEFAULT_OU]}" ]; then
  read -rp "OU (Organizational Unit) [Some Organizational Unit]: " dnOU
  dnOU=${dnOU:-"Some Organizational Unit"}
else
  dnOU=${config[DEFAULT_OU]}
fi

if [ -z "${config[DEFAULT_EMAIL_ADDRESS]}" ]; then
  read -rp "Email Address [someone@somewhere.local]: " dnEmailAddress
    dnEmailAddress=${dnEmailAddress:-"someone@somewhere.local"}
else
  dnEmailAddress=${config[DEFAULT_EMAIL_ADDRESS]}
fi

if [ -z "${config[DEFAULT_CN]}" ]; then
  while [ -z "$dnCN" ]
  do
    read -rp "CN (Common Name): " dnCN
  done
else
  dnCN=${config[DEFAULT_CN]}
fi

if [ -z "${config[DEFAULT_ALT_NAMES]}" ]; then
  IFS=',' read -r -a subjectAltNames -p "Subject Alt Names (additional domains, comma separated list): "
else
  IFS=',' read -r -a subjectAltNames <<< "${config[DEFAULT_ALT_NAMES]}"
fi


#=============================================================================

#=============================================================================
# Writing temporary files
cat <<EOT  > "${config[GEN_FOLDER]}"/"${config[TMP_CSR_FILENAME]}"
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=$dnC
ST=$dnST
L=$dnL
O=$dnO
OU=$dnOU
emailAddress=$dnEmailAddress
CN = $dnCN
EOT

cat <<EOT  > "${config[GEN_FOLDER]}"/"${config[TMP_V3_FILENAME]}"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $dnCN
EOT
#=============================================================================


#=============================================================================
# Adding subject alt names
i=2

for an in "${subjectAltNames[@]}"
do
	echo DNS."$i" = "$an" | xargs >> "${config[GEN_FOLDER]}"/"${config[TMP_V3_FILENAME]}"
	((i=i+1))
done
#=============================================================================

#=============================================================================
# Name of the .key and .pem files for the generated certificate
read -rp "Certificate file name (defaults to Common Name): " certFileName
certFileName=${certFileName:-${dnCN}}
#=============================================================================



#=============================================================================
# Generating
openssl req -new -sha256 -nodes -out "${config[GEN_FOLDER]}"/"$certFileName"-selfsigned.csr -newkey rsa:2048 -keyout "${config[GEN_FOLDER]}"/"$certFileName"-selfsigned.key -config <( cat "${config[GEN_FOLDER]}"/"${config[TMP_CSR_FILENAME]}" )
openssl x509 -req -in "${config[GEN_FOLDER]}"/"$certFileName"-selfsigned.csr -CA "${config[GEN_FOLDER]}"/"$rootCertName".pem -CAkey "${config[GEN_FOLDER]}"/"$rootCertName".key -CAcreateserial -out "${config[GEN_FOLDER]}"/"$certFileName"-selfsigned.crt -days 500 -sha256 -extfile "${config[GEN_FOLDER]}"/"${config[TMP_V3_FILENAME]}"
#=============================================================================



#=============================================================================
# Removing temporary files
rm -f "${config[GEN_FOLDER]}"/"${config[TMP_CSR_FILENAME]}"
rm -f "${config[GEN_FOLDER]}"/"${config[TMP_V3_FILENAME]}"
#=============================================================================
