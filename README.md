# FoundationBenchmarks

Simple benchmarks for Foundation, mostly for testing [swift-corelibs-foundation](https://github.com/apple/swift-corelibs-foundation).

Currently has tests for Base64 Encoding and Decoding.



```
$ swift run FoundationBenchmarks   -h
OVERVIEW: A utility for benchmarking swift-corelibs-foundation in different Swift toolchains.

USAGE: foundation-benchmarks <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  benchmark               Run the benchmarks and show the results.
  show                    Show the results.
  list                    List the available toolchains in the results file.
  rename                  Rename a toolchain in the results file.
  delete                  Delete a toolchain from the results file.
```

The benchmarks can be run as normal tests using:

`swift test -c release`

To test multiple toolchains, list the base directories of the individual
toolchains as command arguments. The toolchains are checked to see if
'usr/bin/swift' exists inside the specified directory. To include the default
toolchain which is in the `$PATH` use the toolchain name `default`:

`swift run foundation-benchmarks benchmark default ~/swift-5.2-RELEASE-ubuntu18.04 ~/swift-5.3-DEVELOPMENT-SNAPSHOT-2020-05-04-a-ubuntu18.04 ~/local-swift-test`

The tests will be run for each toolchain using `swift test -c release` and the
results collected into `benchmarks.sqlite3`. Once all of the benchmarks have run
a table of results will be shown comparing a toolchain to the preceeding
toolchain, and the final column will show the comparison between the first and
last toolchains.

To show just the results table again without running the tests, use the `show` command, optionally listing the toolchains to display

`swift run FoundationBenchmarks show`

Example output:
```
$ swift run FoundationBenchmarks show swift-test-master swift-encode3

| Base64Tests.base64EncodeShortSpeed        | swift-test-master | swift-encode3 | difference |  pct  |
|-------------------------------------------|-------------------|---------------|------------|-------|
| NSData.base64EncodedString - No options   |           1910 ms |       1648 ms |    -262 ms |  -14% |
| NSData.base64EncodedString - Length64     |           2064 ms |       1814 ms |    -250 ms |  -12% |
| NSData.base64EncodedString - Length64CR   |           2059 ms |       1797 ms |    -262 ms |  -13% |
| NSData.base64EncodedString - Length64LF   |           2058 ms |       1803 ms |    -255 ms |  -12% |
| NSData.base64EncodedString - Length64CRLF |           2065 ms |       1817 ms |    -248 ms |  -12% |
| NSData.base64EncodedString - Length76     |           2054 ms |       1807 ms |    -247 ms |  -12% |
| NSData.base64EncodedString - Length76CR   |           2054 ms |       1798 ms |    -256 ms |  -12% |
| NSData.base64EncodedString - Length76LF   |           2052 ms |       1797 ms |    -255 ms |  -12% |
| NSData.base64EncodedString - Length76CRLF |           2063 ms |       1811 ms |    -252 ms |  -12% |
| NSData.base64EncodedData - No options     |           1838 ms |       1688 ms |    -150 ms |   -8% |
| NSData.base64EncodedData - Length64       |           1991 ms |       1858 ms |    -133 ms |   -7% |
| NSData.base64EncodedData - Length64CR     |           1984 ms |       1844 ms |    -140 ms |   -7% |
| NSData.base64EncodedData - Length64LF     |           1980 ms |       1847 ms |    -133 ms |   -7% |
| NSData.base64EncodedData - Length64CRLF   |           1982 ms |       1851 ms |    -131 ms |   -7% |
| NSData.base64EncodedData - Length76       |           1981 ms |       1860 ms |    -121 ms |   -6% |
| NSData.base64EncodedData - Length76CR     |           1987 ms |       1842 ms |    -145 ms |   -7% |
| NSData.base64EncodedData - Length76LF     |           1986 ms |       1845 ms |    -141 ms |   -7% |
| NSData.base64EncodedData - Length76CRLF   |           1983 ms |       1852 ms |    -131 ms |   -7% |
| Data.base64EncodedString - No options     |           2548 ms |       1545 ms |   -1003 ms |  -39% |
| Data.base64EncodedString - Length64       |           2700 ms |       1697 ms |   -1003 ms |  -37% |
| Data.base64EncodedString - Length64CR     |           2713 ms |       1685 ms |   -1028 ms |  -38% |
| Data.base64EncodedString - Length64LF     |           2686 ms |       1690 ms |    -996 ms |  -37% |
| Data.base64EncodedString - Length64CRLF   |           2689 ms |       1699 ms |    -990 ms |  -37% |
| Data.base64EncodedString - Length76       |           2700 ms |       1701 ms |    -999 ms |  -37% |
| Data.base64EncodedString - Length76CR     |           2688 ms |       1686 ms |   -1002 ms |  -37% |
| Data.base64EncodedString - Length76LF     |           2694 ms |       1689 ms |   -1005 ms |  -37% |
| Data.base64EncodedString - Length76CRLF   |           2687 ms |       1703 ms |    -984 ms |  -37% |
| Data.base64EncodedData - No options       |           2466 ms |       1501 ms |    -965 ms |  -39% |
| Data.base64EncodedData - Length64         |           2645 ms |       1659 ms |    -986 ms |  -37% |
| Data.base64EncodedData - Length64CR       |           2642 ms |       1649 ms |    -993 ms |  -38% |
| Data.base64EncodedData - Length64LF       |           2638 ms |       1651 ms |    -987 ms |  -37% |
| Data.base64EncodedData - Length64CRLF     |           2647 ms |       1656 ms |    -991 ms |  -37% |
| Data.base64EncodedData - Length76         |           2625 ms |       1661 ms |    -964 ms |  -37% |
| Data.base64EncodedData - Length76CR       |           2636 ms |       1647 ms |    -989 ms |  -38% |
| Data.base64EncodedData - Length76LF       |           2631 ms |       1651 ms |    -980 ms |  -37% |
| Data.base64EncodedData - Length76CRLF     |           2631 ms |       1654 ms |    -977 ms |  -37% |
| Base64Kit                                 |          12235 ms |      12033 ms |    -202 ms |   -2% |
| Foundation - 0 bytes                      |            172 ms |         31 ms |    -141 ms |  -82% |
| Foundation - 1 byte                       |            850 ms |        292 ms |    -558 ms |  -66% |
| Foundation - 2 bytes                      |            815 ms |        292 ms |    -523 ms |  -64% |
| Foundation - 3 bytes                      |            831 ms |        294 ms |    -537 ms |  -65% |
| Base64Kit - 0 bytes                       |            456 ms |        479 ms |      23 ms |   +5% |
| Base64Kit - 1 byte                        |            985 ms |        941 ms |     -44 ms |   -4% |
| Base64Kit - 2 bytes                       |           1088 ms |       1035 ms |     -53 ms |   -5% |
| Base64Kit - 3 bytes                       |           1203 ms |       1153 ms |     -50 ms |   -4% |

| Base64Tests.base64EncodeLongSpeed         | swift-test-master | swift-encode3 | difference |  pct  |
|-------------------------------------------|-------------------|---------------|------------|-------|
| NSData.base64EncodedString - No options   |           2883 ms |       2589 ms |    -294 ms |  -10% |
| NSData.base64EncodedString - Length64     |           3217 ms |       2930 ms |    -287 ms |   -9% |
| NSData.base64EncodedString - Length64CR   |           3199 ms |       2899 ms |    -300 ms |   -9% |
| NSData.base64EncodedString - Length64LF   |           3198 ms |       2903 ms |    -295 ms |   -9% |
| NSData.base64EncodedString - Length64CRLF |           3222 ms |       2927 ms |    -295 ms |   -9% |
| NSData.base64EncodedString - Length76     |           3207 ms |       2918 ms |    -289 ms |   -9% |
| NSData.base64EncodedString - Length76CR   |           3194 ms |       2906 ms |    -288 ms |   -9% |
| NSData.base64EncodedString - Length76LF   |           3196 ms |       2896 ms |    -300 ms |   -9% |
| NSData.base64EncodedString - Length76CRLF |           3217 ms |       2917 ms |    -300 ms |   -9% |
| NSData.base64EncodedData - No options     |           2413 ms |       2113 ms |    -300 ms |  -12% |
| NSData.base64EncodedData - Length64       |           2740 ms |       2445 ms |    -295 ms |  -11% |
| NSData.base64EncodedData - Length64CR     |           2729 ms |       2428 ms |    -301 ms |  -11% |
| NSData.base64EncodedData - Length64LF     |           2731 ms |       2423 ms |    -308 ms |  -11% |
| NSData.base64EncodedData - Length64CRLF   |           2739 ms |       2442 ms |    -297 ms |  -11% |
| NSData.base64EncodedData - Length76       |           2733 ms |       2433 ms |    -300 ms |  -11% |
| NSData.base64EncodedData - Length76CR     |           2725 ms |       2420 ms |    -305 ms |  -11% |
| NSData.base64EncodedData - Length76LF     |           2750 ms |       2419 ms |    -331 ms |  -12% |
| NSData.base64EncodedData - Length76CRLF   |           2732 ms |       2459 ms |    -273 ms |  -10% |
| Data.base64EncodedString - No options     |           2881 ms |       2581 ms |    -300 ms |  -10% |
| Data.base64EncodedString - Length64       |           3226 ms |       2932 ms |    -294 ms |   -9% |
| Data.base64EncodedString - Length64CR     |           3303 ms |       2903 ms |    -400 ms |  -12% |
| Data.base64EncodedString - Length64LF     |           3205 ms |       2905 ms |    -300 ms |   -9% |
| Data.base64EncodedString - Length64CRLF   |           3222 ms |       2927 ms |    -295 ms |   -9% |
| Data.base64EncodedString - Length76       |           3217 ms |       2918 ms |    -299 ms |   -9% |
| Data.base64EncodedString - Length76CR     |           3199 ms |       2902 ms |    -297 ms |   -9% |
| Data.base64EncodedString - Length76LF     |           3200 ms |       2919 ms |    -281 ms |   -9% |
| Data.base64EncodedString - Length76CRLF   |           3308 ms |       2921 ms |    -387 ms |  -12% |
| Data.base64EncodedData - No options       |           2413 ms |       2121 ms |    -292 ms |  -12% |
| Data.base64EncodedData - Length64         |           2740 ms |       2444 ms |    -296 ms |  -11% |
| Data.base64EncodedData - Length64CR       |           2863 ms |       2427 ms |    -436 ms |  -15% |
| Data.base64EncodedData - Length64LF       |           2729 ms |       2426 ms |    -303 ms |  -11% |
| Data.base64EncodedData - Length64CRLF     |           2739 ms |       2447 ms |    -292 ms |  -11% |
| Data.base64EncodedData - Length76         |           2733 ms |       2444 ms |    -289 ms |  -11% |
| Data.base64EncodedData - Length76CR       |           2725 ms |       2436 ms |    -289 ms |  -11% |
| Data.base64EncodedData - Length76LF       |           2729 ms |       2423 ms |    -306 ms |  -11% |
| Data.base64EncodedData - Length76CRLF     |           2733 ms |       2445 ms |    -288 ms |  -11% |
| Base64Kit                                 |          24493 ms |      23955 ms |    -538 ms |   -2% |

| Base64Tests.base64DecodeShortSpeed        | swift-test-master | swift-encode3 | difference |  pct  |
|-------------------------------------------|-------------------|---------------|------------|-------|
| NSData-decodeString                       |          24253 ms |      24133 ms |    -120 ms |    0% |
| NSData-decodeString - Ignore Unknown      |          24165 ms |      24147 ms |     -18 ms |    0% |
| NSData-decodeData                         |          37576 ms |      37359 ms |    -217 ms |   -1% |
| NSData-decodeData - Ignore Unknown        |          37437 ms |      37753 ms |     316 ms |   +1% |
| Data-decodeString                         |          24729 ms |      24816 ms |      87 ms |   +0% |
| Data-decodeString - Ignore Unknown        |          24694 ms |      24945 ms |     251 ms |   +1% |
| Data-decodeData                           |          38127 ms |      38394 ms |     267 ms |   +1% |
| Data-decodeData - Ignore Unknown          |          38127 ms |      38229 ms |     102 ms |   +0% |
| Base64kit                                 |           3132 ms |       3331 ms |     199 ms |   +6% |

| Base64Tests.base64DecodeLongSpeed         | swift-test-master | swift-encode3 | difference |  pct  |
|-------------------------------------------|-------------------|---------------|------------|-------|
| nsdata-decodeString                       |          58316 ms |      58423 ms |     107 ms |   +0% |
| nsdata-decodeString - Ignore Unknown      |          58302 ms |      58316 ms |      14 ms |   +0% |
| nsdata-decodeData                         |          84788 ms |      83033 ms |   -1755 ms |   -2% |
| nsdata-decodeData - Ignore Unknown        |          84522 ms |      84205 ms |    -317 ms |    0% |
| data-decodeString                         |          58427 ms |      58641 ms |     214 ms |   +0% |
| data-decodeString - Ignore Unknown        |          58438 ms |      58496 ms |      58 ms |   +0% |
| data-decodeData                           |          83235 ms |      82725 ms |    -510 ms |   -1% |
| data-decodeData - Ignore Unknown          |          83534 ms |      82679 ms |    -855 ms |   -1% |
| Base64kit                                 |           6029 ms |       6317 ms |     288 ms |   +5% |

```
