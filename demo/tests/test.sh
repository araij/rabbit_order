#!/usr/bin/env bash
# Compare against master with the same compiler; run from any directory.
# Requires curl, gzip, Python 3 and the demo's build dependencies.
set -euo pipefail
cd "$(dirname "$0")"
root=$(git rev-parse --show-toplevel)
cxx=${CXX:-g++}
threads=${TEST_THREADS:-4}
work=$(mktemp -d)
trap 'status=$?; if (( status )); then cat "$work/"*.log >&2; fi; rm -rf "$work"' EXIT

# Master needs its historical Boost.Atomic backend; current Boost rejects its payload.
if [[ ! -d boost_1_58_0/boost ]]; then
    curl --fail --location --retry 3 \
        https://archives.boost.io/release/1.58.0/source/boost_1_58_0.tar.bz2 \
        -o "$work/boost.tar.bz2"
    python3 - "$work/boost.tar.bz2" <<'PYTHON'
import sys
import tarfile
with tarfile.open(sys.argv[1]) as archive:
    members = [m for m in archive if m.name.startswith("boost_1_58_0/boost/")
               or m.name == "boost_1_58_0/LICENSE_1_0.txt"]
    archive.extractall(members=members, filter="data")
PYTHON
fi
export CPPFLAGS="-I$PWD/boost_1_58_0 ${CPPFLAGS:-}"

# These SNAP graphs also appear in the human migration's dataset selection.
for name in web-NotreDame cit-Patents; do
    if [[ ! -f $name.txt ]]; then
        curl --fail --location --retry 3 "https://snap.stanford.edu/data/$name.txt.gz" \
            -o "$work/graph.gz"
        gzip -dc "$work/graph.gz" > "$name.txt.tmp"
        mv "$name.txt.tmp" "$name.txt"
    fi
done

mkdir "$work/master" "$work/current"
git -C "$root" archive master | tar -x -C "$work/master"
cp "$root/rabbit_order.hpp" "$work/current/"
mkdir "$work/current/demo"
cp "$root/demo/Makefile" "$root/demo/"*.cc "$root/demo/"*.hpp "$work/current/demo/"
# Both compilations use the same relative source paths (including __FILE__).
for version in master current; do
    make -C "$work/$version/demo" -B CXX="$cxx"
done

for name in web-NotreDame cit-Patents; do
    graph="$PWD/$name.txt"
    for mode in reorder community; do
        args=()
        [[ $mode == reorder ]] || args=(-c)
        for version in master current; do
            OMP_NUM_THREADS=1 OMP_DYNAMIC=FALSE "$work/$version/demo/reorder" \
                "${args[@]}" "$graph" > "$work/$version.out" 2> "$work/$version.log"
        done
        cmp "$work/master.out" "$work/current.out"
        if [[ $mode == community ]]; then
            reference_q=$(awk '/^Modularity:/ {print $2}' "$work/master.log")
        fi
        OMP_NUM_THREADS="$threads" OMP_DYNAMIC=FALSE "$work/current/demo/reorder" \
            "${args[@]}" "$graph" > /dev/null 2> "$work/parallel.log"
    done
    # Community labels/order can vary across threads. Allow an absolute quality
    # change of 0.02 from master's sequential modularity, and reject NaN/Inf.
    parallel_q=$(awk '/^Modularity:/ {print $2}' "$work/parallel.log")
    python3 - "$reference_q" "$parallel_q" <<'PY'
import math
import sys
reference, actual = map(float, sys.argv[1:])
assert all(map(math.isfinite, (reference, actual)))
assert abs(actual - reference) <= 0.02, (reference, actual)
print(f"Modularity: master={reference}, parallel={actual}")
PY
    echo "PASS: $name ($cxx, 1/$threads threads, both modes)"
done
