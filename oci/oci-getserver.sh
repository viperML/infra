#! /usr/bin/env bash
set -u -o pipefail

# https://hitrov.medium.com/resolving-oracle-cloud-out-of-capacity-issue-and-getting-free-vps-with-4-arm-cores-24gb-of-a3d7e6a027a8
MY_DIR="$(dirname ${BASH_SOURCE})"

OCI_AVAILABILITY_DOMAIN=vOMn:EU-MARSEILLE-1-AD-1
OCI_IMAGE_ID=ocid1.image.oc1.eu-marseille-1.aaaaaaaaifl7xffzp2d5i2vkr26rwh66wa2egimkbqs2zrihuinw5u2iqssa

echo "$(oci --version)"

result=$(oci compute instance launch \
 --availability-domain $OCI_AVAILABILITY_DOMAIN \
 --compartment-id $OCI_COMPARTMENT_ID \
 --shape VM.Standard.A1.Flex \
 --subnet-id $OCI_NETWORK_ID \
 --assign-private-dns-record true \
 --assign-public-ip false \
 --availability-config file://${MY_DIR}/availabilityConfig.json \
 --display-name nixos \
 --image-id $OCI_IMAGE_ID \
 --instance-options file://${MY_DIR}/instanceOptions.json \
 --shape-config file://${MY_DIR}/shapeConfig.json \
 --ssh-authorized-keys-file ${MY_DIR}/key.pub \
 --config-file $OCI_CONFIG \
 2>&1 >/dev/null)

success="$?"

if [ $success -ne 0 ]; then
    echo "Failed to launch instance"
    echo -e "$result"
    exit 0
fi

body="From: ${MAIL_FROM}
To: ${MAIL_TO}
Subject: sever-up

letsgo

$result"

curl \
    --url "smtps://${MAIL_SERVER}:465" \
    --ssl-reqd \
    --mail-from "${MAIL_FROM}" \
    --mail-rcpt "${MAIL_TO}" \
    --user "${MAIL_FROM}:${MAIL_PASSWORD}" \
    -T <(echo -e "$body")
