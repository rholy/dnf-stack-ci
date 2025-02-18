#!/bin/bash
set -xe

DIR=$(dirname "$(readlink -f "$0")")
REPODIR="$DIR/../repos"
SPECS="$DIR/../specs"

rm -r "${DIR}/keys" || true
mkdir "${DIR}/keys"

KEYSPECS=$(ls "${DIR}/keyspecs")
for KEY_NAME in $KEYSPECS; do
    # kill gpg-agent because path to gpg keys changes in each iteration
    gpgconf --kill gpg-agent

    # set defaults
    USE_SIGN_SUBKEY=0
    USE_NOEOF_KEYS=0
    USE_EXPIRATION_DATE=0

    # read config file for key
    if [ -f "${DIR}/keyspecs/${KEY_NAME}/config" ]; then
        # shellcheck source=dnf-behave-tests/fixtures/gpgkeys/keyspecs/dnf-ci-gpg/config
        . "${DIR}/keyspecs/${KEY_NAME}/config"
    fi

    KEY_DIR="${DIR}/keys/${KEY_NAME}"
    mkdir "${KEY_DIR}"

    # workaround for gpgme unable to handle long paths
    # * create a temp directory /tmp/<tempdir>
    # * symlink key directory -> /tmp/<tempdir>/gpghome
    #
    # gpg usually works as stated in https://bugzilla.redhat.com/show_bug.cgi?id=1813705#c3
    # but sometimes (in containers without running systemd) /run/user/$UID doesn't exist
    # and that's why this workaround is needed
    TMP_DIR=$(mktemp -d)
    TMP_KEY_DIR="${TMP_DIR}/gpghome"
    ln -s "${KEY_DIR}" "${TMP_KEY_DIR}"

    # keys are without expiration date by default
    # if expiration is requested, set it to 1 year from now
    EXPIRY_DATE=0
    if [ "${USE_EXPIRATION_DATE}" = "1" ]; then
        EXPIRY_DATE=$(date -d "+1 year" +%Y-%m-%d)
    fi

    # create key (without password)
    HOME=${TMP_KEY_DIR} gpg2 --batch --passphrase '' --quick-gen-key "${KEY_NAME}" default default "${EXPIRY_DATE}"

    if [ "${USE_SIGN_SUBKEY}" = "1" ]; then
        # add sign subkey
        KEY_ID=$(HOME=${TMP_KEY_DIR} gpg2 --list-keys --with-colons "${KEY_NAME}"  | grep '^fpr:' | head -n 1 | cut -d : -f 10)
        HOME=${TMP_KEY_DIR} gpg2 --batch --passphrase '' --quick-add-key "${KEY_ID}" default sign 0
    fi

    # export public and private key
    HOME=${TMP_KEY_DIR} gpg2 --export -a "${KEY_NAME}" > "${TMP_KEY_DIR}/${KEY_NAME}-public"
    HOME=${TMP_KEY_DIR} gpg2 --export-secret-keys -a "${KEY_NAME}" > "${TMP_KEY_DIR}/${KEY_NAME}-private"

    if [ "${USE_NOEOF_KEYS}" = "1" ]; then
      # remove EOF from keyfiles
      truncate -s -1 "${TMP_KEY_DIR}/${KEY_NAME}-public"
      truncate -s -1 "${TMP_KEY_DIR}/${KEY_NAME}-private"
    fi

    # create .rpmmacros
    cat > "${TMP_KEY_DIR}/.rpmmacros" <<EOF
%_signature gpg
%_gpg_name ${KEY_NAME}
EOF

    # sign packages
    while IFS= read -r package || [ -n "$package" ]; do
        HOME=${TMP_KEY_DIR} rpm --addsign "${REPODIR}/${package}"
    done < "${DIR}/keyspecs/${KEY_NAME}/packages"

    rm -rf "${TMP_DIR}"
done

