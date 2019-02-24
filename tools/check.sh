#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -e

cd $(dirname "$0")
cd "$(git rev-parse --show-toplevel)"

source "tools/utils.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function on_failure {
    echo >&2
    echo -e "${RED}Whoopsie-daisy: something failed!$NC" >&2
}

# `cargo-deadlinks` does not work on windows.
test "$(os)" = windows || assert_installed "cargo-deadlinks"
assert_installed "cargo-fmt"
assert_installed "cargo-miri"

trap on_failure ERR

cargo build --features fatal-warnings --all-targets
cargo test  --features fatal-warnings
cargo doc   --features fatal-warnings

# Tests for memory safety and memory leaks with miri.
cargo +nightly miri test

# `cargo-deadlinks` does not work on windows.
test "$TRAVIS_OS_NAME" = windows || cargo deadlinks

cargo package --allow-dirty
cargo fmt -- --check
./tools/update-readme.sh --check

echo
echo -e "${GREEN}Everything looks lovely!$NC"

exit 0
