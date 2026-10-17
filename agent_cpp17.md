# Rabbit Order: C++17 / Boost removal work record

This is the consolidated implementation and verification record for the work completed on 2026-10-17. All separate development notes, scripts, binaries, profiles, test outputs and downloaded graph/reference caches were removed at the user's request. This record preserves the important conclusions, methods and numeric results; the discarded raw observations cannot be reanalysed from this document.

## Final state and scope

- Branch at consolidation: `agent_cpp17`; HEAD: `ea57dbcbac1b4fdb1c29da7e551669585792ac76`. The commit title mentions "except boost::atomic", but the actual header at consolidation already contains the embedded Boost-free backend. Inspect the source rather than inferring its contents from the title.
- The requested outcome is a C++17 build without an installed Boost library. Existing GNU Make, OpenMP, GNU parallel algorithms/libstdc++, POSIX, NUMA and tcmalloc dependencies remain.
- The final `rabbit_order.hpp` defines its own `atomic<T>` using GCC/Clang `__atomic_*` compiler intrinsics. It uses no `std::atomic` and includes no Boost headers.
- The final approach preserves the original representation and generated code. Repairing the original C++ object-lifetime/aliasing/concurrency assumptions was explicitly outside the final objective.
- Production files retained: `rabbit_order.hpp`, existing demo sources/Makefile, README and original project license. The complete Boost license for the embedded code is included below; its separate file was removed and its references were redirected here.
- User-owned `AGENTS.md`, `.vscode/`, `demo/test/` and Git history were preserved. No commit or staging was performed during consolidation. A temporary switch to another branch was resolved before any cleanup or restoration occurred.

The byte-verified header SHA-256 was `1a20697bcadc9a6e519a0b1882609e3174ad96508938e42a34495412c9654477`. The final consolidated header SHA-256 is `57a6ed2620c7f1604e0740e84f68f6984ca406d20bb1ed22134550b6ba366c2a`. The only post-verification header edit changes the license-reference comment from `boost_atomic_license.txt` to `work_summary.md`; executable source statements and line count are unchanged. No new test or timing claim is made for unrelated branches or future edits.

## Baselines and mechanical migration

The original source baseline was `f67a79e`. The comparison snapshot `94c4747` contained the reviewed mechanical non-atomic migration while retaining Boost.Atomic 1.58. This historical snapshot identifier differs from the final branch tip after history changes; the commit object was still available when this record was written.

Mechanical changes replaced Boost algorithms/ranges/optional/helpers with C++17 standard-library equivalents and selected `-std=c++17` in the demo build. Explicit required headers were added. Integer-range assertions and loops were kept lazy: no extra materialized vector was introduced to compare against `0..n`, and independent assertions retained their evaluation order. The user reviewed the mechanical changes separately from atomic/concurrency changes.

Unnecessary changes were rolled back, including independent empty-input/mmap fixes, unrelated alignment spelling changes and assertion simplifications. Empty-input edge cases therefore remain outside the validation claims below. Existing non-Boost dependencies were deliberately retained.

## Why a literal standard-atomic replacement was not retained

The original `atomix<T>` union overlays an atomic representation and a raw `T`. Its outer `atom` contains nested `atomix<float>` and `atomix<vint>` members, and is not trivially copyable. The original code accesses subfields through the inactive raw union member and overlaps 64-bit whole-state and 32-bit subfield atomic operations.

Boost 1.58 also documents trivially-copyable payload requirements. Its acceptance of this source is not a C++/Boost correctness guarantee. These observations do not show that the intended graph algorithm was wrong on the tested x86 environment; the tested original produced compatible outputs. They explain why a conforming `std::atomic<atom>` migration required a different representation/protocol rather than a simple textual substitution.

The initial conforming implementation used a trivial `{float strength, uint32_t child}` payload and whole-state CAS loops to update strength. That introduced different instructions and sometimes slower timing estimates. The user ultimately requested preservation of Boost's behavior/code generation, without `std::atomic`, rather than a language-model correctness redesign.

## Embedded atomic implementation

Both apt compilers actually selected Boost 1.58's **`gcc_atomic` backend**. Preprocessing `#include <boost/atomic.hpp>` with each compiler and examining `BOOST_ATOMIC_DETAIL_PLATFORM` confirmed this. An earlier explanation based on `ops_gcc_x86.hpp` inline assembly inspected an unselected backend and was incorrect for these builds. The final implementation uses the selected intrinsic backend; it contains no newly introduced inline assembly.

| Boost 1.58 source component | Local equivalent |
| --- | --- |
| `boost/memory_order.hpp` | Same order enum values and conversion to `__ATOMIC_*` constants |
| `atomic/detail/casts.hpp` | `memcpy_cast`: initialize wrapper member, copy representation, return member |
| `atomic/detail/ops_gcc_atomic.hpp` | `builtin_operations<T>` with the same volatile references and intrinsic arguments |
| `atomic/detail/storage_type.hpp` | Standard 32/64-bit signed/unsigned integer types |
| `base_atomic<T,int>` / `base_atomic<T,void>` | `atomic_base<T,true>` / `atomic_base<T,false>` |
| `atomics::atomic<T>` | Local `atomic<T>` constructor/inheritance layer |
| Boost configuration macros | Expanded attributes, C++17 keywords and standard traits |

Only needed constructors/copy restrictions, load, store, exchange, integral fetch-add, weak CAS and lock-freedom query remain. Unused pointer/flag/bool/128-bit interfaces, additional arithmetic/bitwise methods, platform discovery and fallback machinery were omitted. Lock-free 32/64-bit storage is checked; no new `libatomic` link dependency was introduced.

Maintain the volatile storage references, order conversion, by-value overload forwarding and member-return copy boundaries when editing this code. Replacing them with apparently equivalent constructs can change optimization and caller inlining. Keep the original `atomix`/`atom` representation and algorithm call sites for correspondence. The algorithm section from `Miscellaneous definitions` onward matched the reviewed `94c4747` snapshot byte-for-byte as source.

Upstream copyright notices remain in the embedded source. The code is derived from Boost 1.58 and is subject to the Boost Software License reproduced at the end of this file; the original project remains subject to its own `license.txt`.

## Toolchain, build and exact executable identity

Compilers used:

- `g++ (Ubuntu 15.2.0-16ubuntu1) 15.2.0`
- `Ubuntu clang version 21.1.8 (6ubuntu1)`

Ordinary build commands are `make -C demo -B CXX=g++` and `make -C demo -B CXX=clang++`. GNU Make and the existing development dependencies are needed; Clang uses libomp and the existing GNU C++ library facilities. No Boost installation is required for the migrated build. The tested optimization flags were `-std=c++17 -O3 -DNDEBUG -fopenmp -mcx16`, with the Makefile's warning flags and `-ltcmalloc_minimal -lnuma` linking.

For byte comparison, original and migrated real demo trees were built with identical relative paths (`demo/reorder.cc`, `../rabbit_order.hpp` as included from the demo), compiler flags and linking. Only the reference build received the Boost 1.58 include path. Matching paths matter for `__FILE__` strings. The reference was the C++17 mechanical snapshot, not the unmodified C++14 full-Boost source.

**Complete release ELF executables matched byte-for-byte within each compiler pair**, including actual inlined callers, all code/data sections and metadata/build IDs. No address normalization was used for this result.

| Compiler | SHA-256 of both Boost and local executable | `.text` bytes |
| --- | --- | ---: |
| g++ | `af799e274f77c71ff2684357905707a0d32f26cb237d196434a1c5f8c63fe32e` | 104245 |
| clang++ | `c0f9af0e66ffb10384b65b7e0ec32456daa63bff737c41aac96abd68ee8592b2` | 108531 |

To repeat this verification later, obtain the old snapshot/reference headers, build matching relative demo trees with the same toolchain/flags, and compare full files with `cmp` and `sha256sum`. `objcopy --dump-section .text=...` and `objdump -d` can localize any mismatch. The reference Boost archive URL is https://archives.boost.io/release/1.58.0/source/boost_1_58_0.tar.bz2 . Other compiler versions, flags, target architectures and debug configurations are not asserted bit-identical.

## Inlining investigation and rejected alternatives

Initial instruction comparisons used small noinline **probe functions**. `atomic` operations were inlined into those probes, but the probes did not capture all surrounding algorithm/caller optimization. A subsequent comparison compiled the actual linked demo without adding noinline probes and retained full function bodies, compiler inline diagnostics and source locations.

The intermediate unsafe standard-word adapter matched five of six probes in both compilers. GCC's unmatched CAS differed mainly in stack slots (33 normal-path instructions, 20 stack references in each probe). Clang reduced the probe from 26 instructions / 16 stack references to 11 / 0. This was insufficient evidence of caller equivalence: in the real Clang demo, `merge` shrank from 138 to 106 instructions, making some calls inline into the OpenMP worker. The worker grew from 1,377 instructions / 6,453 bytes to 2,799 / 13,332. The compiler reported merge cost 635 vs threshold 525 for the original and cost 390 for the adapter. These are intermediate-adapter results, not final implementation results. The final intrinsic extraction instead achieved full ELF identity.

Four earlier standard-conforming optimization candidates passed their applicable correctness checks but were rejected for lack of demonstrated primary speed gain. The primary condition was DBLP four-thread reordering, 30 paired blocks. Ratios below compare each candidate to the initial standard-CAS implementation in that candidate's experiment; they cannot be compared as if from one combined trial.

| Candidate | GCC mean ratio (95% exploratory interval) | Clang mean ratio (interval) |
| --- | --- | --- |
| Owned-lock release store | 1.0096 [0.9769, 1.0422] | 0.9916 [0.9491, 1.0389] |
| Exchange acquisition | 1.0221 [0.9858, 1.0598] | 1.0629 [1.0279, 1.0964] |
| Per-thread analysis counters | 0.9853 [0.9516, 1.0222] | 0.9933 [0.9646, 1.0230] |
| Parent path halving | 1.0335 [0.9928, 1.0712] | 1.0208 [0.9874, 1.0563] |

Only the store-only experiment completed all controls; the others stopped after the primary condition did not justify adoption. Restores occurred only about 0.6% as often as acquisitions in the primary workload, limiting their opportunity. The GCC single-thread counter variant also regressed in its control. No candidate was retained in the final Boost-compatible implementation.

Hardware `perf` events worked without container permission changes. A separate profile of 20 cached-input Clang reorders showed substantial cycles in the edge lambda/parent chase, merging, sorting and OpenMP runtime. Unknown runtime symbols were not evidence of a specific spin-wait mechanism; whole-process profiles and event skid prevented precise attribution to individual atomic operations. Profile timings were not used as latency comparisons. No permission blocker remained unresolved.

## Correctness validation

- Both apt compilers built the final implementation through the existing GNU Make rules. Include-dependency traces contained no Boost headers; production code used neither `std::atomic` nor `<atomic>`.
- Assertions-enabled contention and weighted/random graph tests passed at 1/2/4/8 threads with both compilers. The contention test raced whole-state positive CAS updates against the original 32-bit strength exchange/restore protocol, checking child/strength correspondence.
- Both final compiler pairs matched original sequential output and printed modularity on 30 seeded nonempty graphs in both modes (seed 20261017).
- All 80 real-graph checks passed: baseline/new sequential equality per compiler; new implementations at 1/2/4 threads, both modes, all five graphs. Independent checks validated a permutation of all vertex IDs, valid self-rooted community representatives and independently recomputed modularity (absolute tolerance 5e-6).
- Earlier ASan/UBSan and Valgrind results applied to earlier migration candidates, not an additional certification of the final unsafe representation. Original empty-input cases were excluded from the claimed core coverage. These tests do not prove all concurrency executions or language-model correctness.

## Real-world datasets and normalization

Datasets were selected from SNAP, which the repository recommends. They provide collaboration, email, road and Web structures. They are **not claimed to be the exact benchmark suite in the 2016 Rabbit Order paper**: that paper's full benchmark table was not verified during this work.

Reference paper: Arai, J., Shiokawa, H., Yamamuro, T., Onizuka, M., and Iwamura, S. (2016). Rabbit Order: Just-in-time Parallel Reordering for Fast Graph Analysis. IPDPS, pp. 22-31.

| Graph | Vertices in input | Preserved input rows | Download |
| --- | ---: | ---: | --- |
| ca-GrQc | 5,242 | 28,980 | https://snap.stanford.edu/data/ca-GrQc.txt.gz |
| email-Enron | 36,692 | 367,662 | https://snap.stanford.edu/data/email-Enron.txt.gz |
| com-DBLP | 317,080 | 1,049,866 | https://snap.stanford.edu/data/bigdata/communities/com-dblp.ungraph.txt.gz |
| roadNet-PA | 1,088,092 | 3,083,796 | https://snap.stanford.edu/data/roadNet-PA.txt.gz |
| web-Google | 875,713 | 5,105,039 | https://snap.stanford.edu/data/web-Google.txt.gz |

Original numeric IDs were sorted and mapped bijectively to contiguous `[0,n)` IDs. Input row order, multiplicities, directions and loops were preserved. The inverse ID file listed one original ID per normalized vertex, ascending. Output edges were decimal `u v\n` lines. The demo then symmetrizes, aggregates duplicate edges and removes loops as in the original program. This applies to web-Google's directed hyperlinks as well.

ca-GrQc has 28,980 input rows, 14,484 distinct non-loop undirected pairs and 12 loop rows; its published edge count is 14,496. Enron has 367,662 rows representing 183,831 pairs in both directions. DBLP has 1,049,866 rows/pairs. roadNet-PA has 3,083,796 rows representing 1,541,898 undirected edges. These row counts should not be confused with the symmetrized/aggregated algorithm graph's counts.

Dataset SHA-256 checksums (gzip source, normalized edge file, inverse ID mapping):

- **ca-GrQc**

  ```text
  gzip:  a254442cdf5d684712578b630c2e0d7543518ab154ef2341cabb607572ce7230
  edges: dc9c030b1cadc5e4e1da19c839a3507cff992152f771d9207d13ba2dcfde3c91
  ids:   ad11b44f6b08e1a57559c6b611def07b20751a1def01413b7daecb5c5d85e815
  ```

- **email-Enron**

  ```text
  gzip:  55cfead79b1f0161786179a48796c2a119bd7026a246238b257b6be9d8b69b68
  edges: 939316e543379a8b4e85d61015c19acb0cd60f3655bfae40fd1b0ca0ca30d215
  ids:   f6ffde1712680fe80fb6ad7c20c62371847c8aa22003a9b2fce5e5f4204c5ad9
  ```

- **com-DBLP**

  ```text
  gzip:  9eb0bd30312ddd04e2624f7c36c0983a2e99b116f0385be5a7fce6d6170f4cb3
  edges: 30163339a7623d7e8a74cbef5b7100bda30fe08c45cba9999b3dda420f8839a5
  ids:   a919195bbbc9a3d8ddc5383e7de05b171241a9c707b234ac1822d14f76e17e25
  ```

- **roadNet-PA**

  ```text
  gzip:  450b8733635d887466a2b96b26411f6e62caf7006f8a264f59cf9b5d75cdf549
  edges: e3855da4df16eca137168eca2491a9b3624794547d1c274ad793b08ceb977bb0
  ids:   0578d1bd6afa5c2d5c9fdd54bfe189cba29d4a0432ca7b7f0b03b509ac71ca6f
  ```

- **web-Google**

  ```text
  gzip:  bcac0af0471d749f4a8c010bca92b61cf2868a0570741de06892fc062f265ea6
  edges: 31f9a7fa3d51874c5b27feef8db5a3b6e3981d71d845989f2c751bc82c964601
  ids:   a1da45d0e666717a7f11d5230554d6cfb830fced7b23d3a870957f43624281a6
  ```

## Performance history and interpretation

The initial concern was Clang DBLP four-thread reordering: five interleaved samples gave medians 90.6365 ms (original) and 102.056 ms (standard migration), +12.6%. Original samples were [103.526, 85.7332, 86.6668, 90.6365, 98.4375] ms; migrated samples were [101.003, 114.602, 103.568, 98.8193, 102.056] ms. This was not safely dismissible as noise: four of five paired blocks were slower. That experiment also compared the C++14 original against C++17 and had less explicit affinity control. Subsequent experiments changed conditions; non-reproduction does not prove the old result was measurement error.

A later matched C++17 baseline rerun gave Clang DBLP four-thread means 100.888 -> 103.561 ms (+2.65%, ratio interval [0.9918, 1.0673]); that still did not establish equivalence. A broader bounded standard-atomic campaign gave Clang four-thread reordering +0.99% DBLP, +6.58% roads and +5.32% Web. Those observations motivated the final representation-preserving approach. That campaign had only two passes/two blocks and 1/8 runtime-stability successes; its last configuration was rewarmed/repeated after a deadline interruption, with partial observations superseded. It must not be treated as a precise universal regression estimate.

### Final byte-identical performance recheck

The last measurement compares complete **identical ELF files**, labelled Boost and local but stored at separate paths. It is an A/A measurement control, not a comparison with the discarded standard-atomic implementation. Differences cannot be caused by changed algorithm instructions. Scheduling, ASLR, executable/page-cache placement, host drift and systematic measurement effects remain possible explanations. Timing data alone do not identify which effect dominates.

- Machine: Ryzen 7 PRO 7840U under WSL2, 16 guest CPUs, guest-reported two threads/core. Guest CPU pinning is not a guarantee of exclusive physical host cores.
- Matrix: five graphs x 1/2/4/8 threads x reorder/community x GCC/Clang x Boost/local; two passes and two measured balanced blocks per configuration/pass. This produced 640 measured runs and 80 compiler/configuration summaries, four observations per implementation/configuration.
- Seed: 20261018. Within each adjacent block pair, seed-based compiler/variant order was complemented by reversing the next block's order. Thread groups and graph/mode order were randomized by pass.
- A complete calibration pass chose the uniform even repetition count from elapsed process costs and the remaining 30-minute budget, before using measured speed ratios. No value-based sample deletion or favorable-result stopping occurred.
- Both implementations/compilers received continuous 45-second preconditioning per thread group/pass using the largest input (at least six complete blocks; checked at block boundaries), and one workload-specific warm-up block before measurement.
- `OMP_DYNAMIC=FALSE`, `OMP_PROC_BIND=close`, `OMP_WAIT_POLICY=ACTIVE`; explicit `OMP_PLACES` and affinity CPUs 0/2/4/6/... (one per guest-reported core). KMP/GOMP affinity overrides were cleared.
- Kernel time came from the **unmodified** program's `system_clock`, including aggregation plus permutation generation or final community extraction. Input/adjacency construction and stdout were excluded; modularity computation was also outside the community kernel. External `perf_counter` measured the entire process, including input, discarded stdout and modularity.
- No concurrent agent builds, downloads, functional campaigns or profiling during timing. The user was notified to stop heavy work and notified at completion. Execution, status monitoring and report generation were scripted; no manual per-configuration intervention.
- No power-plan, governor, boost or thermal-protection settings changed. The user selected warm-up instead. CPUFreq/CPU temperature/powercap interfaces were unavailable in the guest; hwmon exposed AC/battery devices. Unlimited container CPU quota and absence of cgroup throttle events did not rule out physical throttling or host scheduling interference.
- The runtime-stability proxy (three consecutive nonoverlapping two-block medians per binary within 3%) passed in **0/8** periods. Sustained warm-up was performed; stable temperature/frequency was not established.
- Hierarchical bootstrap: 5,000 resamples of passes and adjacent complementary-order block pairs. There were only two passes with few independent units, no verified pass independence and no multiple-comparison correction. Intervals are exploratory; intervals excluding 1 for identical binaries demonstrate that these assumptions/sample counts do not support strong causal performance claims.
- Measured campaign elapsed: 1,240.505 seconds (20 minutes 41 seconds). All samples/summary data were saved before a report-rendering integer/string-key error; only the renderer was fixed and rerun. There was **no measurement rerun** in the final campaign.

Four-thread reordering results (local / Boost):

| Graph | Compiler | Boost mean ms | Local mean ms | Change | Exploratory ratio interval |
| --- | --- | ---: | ---: | ---: | --- |
| ca-GrQc | clang | 1.307 | 1.252 | -4.25% | [0.9130, 1.0021] |
| ca-GrQc | gcc | 1.202 | 1.111 | -7.51% | [0.8593, 1.0094] |
| com-DBLP | clang | 100.275 | 103.534 | +3.25% | [0.9889, 1.0762] |
| com-DBLP | gcc | 100.927 | 96.534 | -4.35% | [0.9280, 0.9830] |
| email-Enron | clang | 10.246 | 10.034 | -2.08% | [0.9266, 1.0361] |
| email-Enron | gcc | 9.372 | 9.790 | +4.46% | [1.0189, 1.0731] |
| roadNet-PA | clang | 212.785 | 217.046 | +2.00% | [1.0068, 1.0335] |
| roadNet-PA | gcc | 203.751 | 191.812 | -5.86% | [0.8400, 1.0615] |
| web-Google | clang | 396.130 | 401.925 | +1.46% | [0.9806, 1.0502] |
| web-Google | gcc | 402.179 | 370.762 | -7.81% | [0.8860, 0.9600] |

The final Clang points were +3.25% DBLP, +2.00% roads and +1.46% Web. They are smaller than earlier estimates, but different protocols and implementations prevent treating that as a controlled before/after speedup. Full executable identity is the direct code-generation evidence. Short graphs can show much larger relative timing outliers.

<details>
<summary>All final performance conditions</summary>

| Graph | Threads | Mode | Compiler | Boost ms | Local ms | Change | Pass 1 ratio | Pass 2 ratio |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| ca-GrQc | 1 | community | clang | 2.280 | 2.436 | +6.86% | 0.9673 | 1.1749 |
| ca-GrQc | 1 | community | gcc | 2.277 | 2.295 | +0.79% | 0.8767 | 1.1500 |
| ca-GrQc | 1 | reorder | clang | 2.312 | 2.387 | +3.28% | 1.0261 | 1.0397 |
| ca-GrQc | 1 | reorder | gcc | 2.160 | 2.203 | +1.99% | 1.0269 | 1.0122 |
| ca-GrQc | 2 | community | clang | 1.845 | 1.799 | -2.53% | 0.9411 | 1.0120 |
| ca-GrQc | 2 | community | gcc | 1.709 | 1.713 | +0.22% | 1.1771 | 0.8573 |
| ca-GrQc | 2 | reorder | clang | 1.775 | 1.982 | +11.66% | 1.1052 | 1.1292 |
| ca-GrQc | 2 | reorder | gcc | 1.509 | 1.483 | -1.73% | 0.9689 | 0.9975 |
| ca-GrQc | 4 | community | clang | 1.341 | 1.237 | -7.73% | 0.8985 | 0.9511 |
| ca-GrQc | 4 | community | gcc | 1.086 | 1.030 | -5.18% | 1.0095 | 0.8839 |
| ca-GrQc | 4 | reorder | clang | 1.307 | 1.252 | -4.25% | 1.0021 | 0.9130 |
| ca-GrQc | 4 | reorder | gcc | 1.202 | 1.111 | -7.51% | 0.8593 | 1.0094 |
| ca-GrQc | 8 | community | clang | 0.887 | 0.972 | +9.65% | 1.1526 | 1.0379 |
| ca-GrQc | 8 | community | gcc | 0.798 | 0.798 | +0.02% | 1.0252 | 0.9766 |
| ca-GrQc | 8 | reorder | clang | 0.987 | 0.944 | -4.33% | 0.9522 | 0.9608 |
| ca-GrQc | 8 | reorder | gcc | 0.896 | 1.308 | +45.88% | 1.7801 | 1.1030 |
| com-DBLP | 1 | community | clang | 312.595 | 296.117 | -5.27% | 0.9257 | 0.9693 |
| com-DBLP | 1 | community | gcc | 277.819 | 271.966 | -2.11% | 0.9951 | 0.9627 |
| com-DBLP | 1 | reorder | clang | 330.867 | 310.878 | -6.04% | 0.9308 | 0.9485 |
| com-DBLP | 1 | reorder | gcc | 283.918 | 273.414 | -3.70% | 0.9716 | 0.9546 |
| com-DBLP | 2 | community | clang | 169.993 | 176.133 | +3.61% | 1.0492 | 1.0241 |
| com-DBLP | 2 | community | gcc | 148.547 | 160.042 | +7.74% | 1.1345 | 1.0207 |
| com-DBLP | 2 | reorder | clang | 174.454 | 180.856 | +3.67% | 0.9845 | 1.0893 |
| com-DBLP | 2 | reorder | gcc | 163.164 | 160.118 | -1.87% | 1.0167 | 0.9509 |
| com-DBLP | 4 | community | clang | 106.248 | 100.609 | -5.31% | 0.9267 | 0.9660 |
| com-DBLP | 4 | community | gcc | 92.522 | 102.058 | +10.31% | 1.1956 | 1.0280 |
| com-DBLP | 4 | reorder | clang | 100.275 | 103.534 | +3.25% | 1.0762 | 0.9889 |
| com-DBLP | 4 | reorder | gcc | 100.927 | 96.534 | -4.35% | 0.9830 | 0.9280 |
| com-DBLP | 8 | community | clang | 57.258 | 54.962 | -4.01% | 0.9136 | 1.0082 |
| com-DBLP | 8 | community | gcc | 55.761 | 54.465 | -2.32% | 1.0344 | 0.9252 |
| com-DBLP | 8 | reorder | clang | 59.811 | 56.163 | -6.10% | 0.9782 | 0.9018 |
| com-DBLP | 8 | reorder | gcc | 66.600 | 57.823 | -13.18% | 0.7374 | 1.0319 |
| email-Enron | 1 | community | clang | 28.545 | 26.565 | -6.94% | 1.0133 | 0.8578 |
| email-Enron | 1 | community | gcc | 23.764 | 24.269 | +2.12% | 0.9872 | 1.0578 |
| email-Enron | 1 | reorder | clang | 26.964 | 25.951 | -3.76% | 0.9386 | 0.9873 |
| email-Enron | 1 | reorder | gcc | 26.261 | 24.713 | -5.89% | 0.9439 | 0.9383 |
| email-Enron | 2 | community | clang | 16.130 | 16.477 | +2.15% | 1.1030 | 0.9417 |
| email-Enron | 2 | community | gcc | 15.054 | 15.445 | +2.60% | 1.0861 | 0.9648 |
| email-Enron | 2 | reorder | clang | 16.069 | 15.731 | -2.10% | 0.9696 | 0.9878 |
| email-Enron | 2 | reorder | gcc | 14.403 | 15.273 | +6.04% | 1.0093 | 1.1167 |
| email-Enron | 4 | community | clang | 10.195 | 10.254 | +0.58% | 1.0053 | 1.0062 |
| email-Enron | 4 | community | gcc | 10.056 | 9.847 | -2.08% | 1.0187 | 0.9419 |
| email-Enron | 4 | reorder | clang | 10.246 | 10.034 | -2.08% | 1.0361 | 0.9266 |
| email-Enron | 4 | reorder | gcc | 9.372 | 9.790 | +4.46% | 1.0189 | 1.0731 |
| email-Enron | 8 | community | clang | 6.311 | 6.458 | +2.33% | 0.9523 | 1.0926 |
| email-Enron | 8 | community | gcc | 5.573 | 5.847 | +4.93% | 1.1217 | 0.9763 |
| email-Enron | 8 | reorder | clang | 6.683 | 6.217 | -6.96% | 0.9826 | 0.8825 |
| email-Enron | 8 | reorder | gcc | 6.222 | 5.968 | -4.08% | 0.9419 | 0.9765 |
| roadNet-PA | 1 | community | clang | 548.535 | 541.566 | -1.27% | 1.0057 | 0.9691 |
| roadNet-PA | 1 | community | gcc | 474.176 | 472.199 | -0.42% | 1.0016 | 0.9902 |
| roadNet-PA | 1 | reorder | clang | 567.924 | 566.693 | -0.22% | 0.9882 | 1.0077 |
| roadNet-PA | 1 | reorder | gcc | 510.648 | 497.738 | -2.53% | 0.9677 | 0.9817 |
| roadNet-PA | 2 | community | clang | 342.185 | 330.103 | -3.53% | 0.9647 | 0.9647 |
| roadNet-PA | 2 | community | gcc | 295.238 | 302.599 | +2.49% | 0.9949 | 1.0535 |
| roadNet-PA | 2 | reorder | clang | 345.698 | 357.773 | +3.49% | 1.0414 | 1.0288 |
| roadNet-PA | 2 | reorder | gcc | 318.107 | 321.365 | +1.02% | 1.1038 | 0.9249 |
| roadNet-PA | 4 | community | clang | 209.500 | 210.085 | +0.28% | 1.0527 | 0.9572 |
| roadNet-PA | 4 | community | gcc | 194.531 | 194.349 | -0.09% | 1.0313 | 0.9671 |
| roadNet-PA | 4 | reorder | clang | 212.785 | 217.046 | +2.00% | 1.0068 | 1.0335 |
| roadNet-PA | 4 | reorder | gcc | 203.751 | 191.812 | -5.86% | 0.8400 | 1.0615 |
| roadNet-PA | 8 | community | clang | 131.907 | 134.139 | +1.69% | 1.0066 | 1.0269 |
| roadNet-PA | 8 | community | gcc | 119.313 | 122.807 | +2.93% | 0.9449 | 1.1223 |
| roadNet-PA | 8 | reorder | clang | 134.402 | 152.574 | +13.52% | 1.1086 | 1.1601 |
| roadNet-PA | 8 | reorder | gcc | 152.889 | 147.436 | -3.57% | 0.8737 | 1.0702 |
| web-Google | 1 | community | clang | 1272.190 | 1261.977 | -0.80% | 0.9576 | 1.0277 |
| web-Google | 1 | community | gcc | 1092.592 | 1113.763 | +1.94% | 1.0435 | 0.9958 |
| web-Google | 1 | reorder | clang | 1370.653 | 1357.487 | -0.96% | 0.9948 | 0.9860 |
| web-Google | 1 | reorder | gcc | 1208.168 | 1228.500 | +1.68% | 1.0046 | 1.0288 |
| web-Google | 2 | community | clang | 670.939 | 688.814 | +2.66% | 1.0298 | 1.0236 |
| web-Google | 2 | community | gcc | 607.121 | 629.745 | +3.73% | 1.0426 | 1.0320 |
| web-Google | 2 | reorder | clang | 707.173 | 709.023 | +0.26% | 1.0302 | 0.9762 |
| web-Google | 2 | reorder | gcc | 657.623 | 643.868 | -2.09% | 0.9419 | 1.0190 |
| web-Google | 4 | community | clang | 376.027 | 385.344 | +2.48% | 1.0317 | 1.0181 |
| web-Google | 4 | community | gcc | 364.867 | 375.457 | +2.90% | 1.0371 | 1.0211 |
| web-Google | 4 | reorder | clang | 396.130 | 401.925 | +1.46% | 0.9806 | 1.0502 |
| web-Google | 4 | reorder | gcc | 402.179 | 370.762 | -7.81% | 0.8860 | 0.9600 |
| web-Google | 8 | community | clang | 204.730 | 203.136 | -0.78% | 0.9629 | 1.0223 |
| web-Google | 8 | community | gcc | 193.907 | 200.617 | +3.46% | 1.0583 | 1.0120 |
| web-Google | 8 | reorder | clang | 210.532 | 213.607 | +1.46% | 1.0056 | 1.0236 |
| web-Google | 8 | reorder | gcc | 212.996 | 206.415 | -3.09% | 1.0064 | 0.9329 |

</details>

Raw final-event file SHA-256 before deletion: `c623d6a6803b32ef8ac510d2f2f8a3eebb1236234390ee7b1c248eaa3f311877`. Final summary JSON SHA-256 before deletion: `7085466c9dbc7123fe66843e34f64397031609ca07e2f9766dbeebc9e154a8e3`. These are provenance identifiers, not substitutes for the removed raw observations. The initial measurement script hash was `e5eb3d47c772be7ca05c1e1210aa7cbceb10bb735168361c5b18c7f178d45380`; the report-key fix changed it to `96001ed0dc1dd0c9033c202908da09284955af36cee78cf855d761c864019df1` without changing or rerunning measurements.

## Future review and reproduction checklist

1. Keep the final dependency-removal objective distinct from standard-conforming concurrency redesign. A future redesign needs its own protocol proof and benchmark.
2. Verify which backend old Boost actually selects before transplanting it. Preserve volatile access and nontrivial-copy boundaries, not only the final hardware CAS instruction.
3. Compare whole real linked executables or actual inlined caller functions. Standalone probes alone cannot establish the caller's behavior or inlining decisions.
4. For a byte comparison, align reference source revision, C++ language mode, compiler/runtime/linker versions, flags and relative build paths. The quoted full-file hashes apply only to this exact release configuration.
5. Re-download datasets from the URLs above, reproduce numeric ID normalization and verify hashes before testing. Treat the demo's symmetrization/multiplicities consistently.
6. Notify users before new performance campaigns. Use an automated bounded script, warm both labels equally, balance order, preserve raw samples and predeclare budget/primary condition. More sequential repetitions do not fix systematic host or thermal bias.
7. Do not interpret a confidence interval containing 1 as equivalence, or a small-sample interval excluding 1 as a source-level regression when the compared binaries are identical. Agree a practical regression margin before a future acceptance test.

The complete embedded implementation is retained in `rabbit_order.hpp` and the final Git commit identified above. No separate patch, benchmark script, test executable, profile, downloaded graph/reference archive or progress log is retained from this session. Existing user-owned files and installed apt toolchains/libraries are not removed as part of artifact cleanup.

## Boost Software License

The following complete license applies to the Boost-derived atomic portion of `rabbit_order.hpp`. Upstream copyright notices are retained in that source. This does not replace the original project's separate license.

```text
Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```
