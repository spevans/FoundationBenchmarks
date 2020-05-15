# FoundationBenchmarks

Simple benchmarks for Foundation, mostly for testing [swift-corelibs-foundation](https://github.com/apple/swift-corelibs-foundation).

Currently has tests for Base64 Encoding and Decoding.

The benchmarks can be run as normal tests using:

`swift test -c release`

To test multiple toolchains, list the base directories of the individual
toolchains as command arguments. The toolchains are checked to see if
'usr/bin/swift' exists inside the specified directory. To include the default
toolchain which is in the `$PATH` use the toolchain name `default`:

`swift run FoundationBenchmarks default ~/swift-5.2-RELEASE-ubuntu18.04 ~/swift-5.3-DEVELOPMENT-SNAPSHOT-2020-05-04-a-ubuntu18.04 ~/local-swift-test`

The tests will be run for each toolchain using `swift test -c release` and the
results collected into `benchmarks.sqlite3`. Once all of the benchmarks have run
a table of results will be shown comparing a toolchain to the preceeding
toolchain, and the final column will show the comparison between the first and
last toolchains.

To show just the results table again without running the tests, use the `--show` option:

`swift run FoundationBenchmarks --show`



Example output:

| Base64Tests.base64EncodeShortSpeed        | 5.3-DEVELOPMENT-SNAPSHOT-2020-05-04 | DEVELOPMENT-SNAPSHOT-2020-05-11 | difference |  pct  | test-decode-speedup1 | difference |  pct  | test-decode-speedup2 | difference |  pct  | First to Last |  pct  |
|-------------------------------------------|-------------------------------------|---------------------------------|------------|-------|----------------------|------------|-------|----------------------|------------|-------|---------------|-------|
| Foundation-nsdata-toString - No options   |                             3759 ms |                         3498 ms |    -261 ms |   -7% |              1234 ms |   -2264 ms |  -65% |              1476 ms |     242 ms |  +20% |      -2283 ms |  -61% |
| Foundation-nsdata-toString - Length64     |                             4121 ms |                         3753 ms |    -368 ms |   -9% |              1382 ms |   -2371 ms |  -63% |              1635 ms |     253 ms |  +18% |      -2486 ms |  -60% |
| Foundation-nsdata-toString - Length64CR   |                             3853 ms |                         3689 ms |    -164 ms |   -4% |              1361 ms |   -2328 ms |  -63% |              1632 ms |     271 ms |  +20% |      -2221 ms |  -58% |
| Foundation-nsdata-toString - Length64LF   |                             4006 ms |                         3656 ms |    -350 ms |   -9% |              1372 ms |   -2284 ms |  -62% |              1640 ms |     268 ms |  +20% |      -2366 ms |  -59% |
| Foundation-nsdata-toString - Length64CRLF |                             3852 ms |                         3727 ms |    -125 ms |   -3% |              1365 ms |   -2362 ms |  -63% |              1636 ms |     271 ms |  +20% |      -2216 ms |  -58% |
| Foundation-nsdata-toString - Length76     |                             4033 ms |                         3798 ms |    -235 ms |   -6% |              1368 ms |   -2430 ms |  -64% |              1631 ms |     263 ms |  +19% |      -2402 ms |  -60% |
| Foundation-nsdata-toString - Length76CR   |                             4033 ms |                         3786 ms |    -247 ms |   -6% |              1372 ms |   -2414 ms |  -64% |              1622 ms |     250 ms |  +18% |      -2411 ms |  -60% |
| Foundation-nsdata-toString - Length76LF   |                             4133 ms |                         3763 ms |    -370 ms |   -9% |              1364 ms |   -2399 ms |  -64% |              1626 ms |     262 ms |  +19% |      -2507 ms |  -61% |
| Foundation-nsdata-toString - Length76CRLF |                             4033 ms |                         3802 ms |    -231 ms |   -6% |              1369 ms |   -2433 ms |  -64% |              1627 ms |     258 ms |  +19% |      -2406 ms |  -60% |
| Foundation-nsdata-toData - No options     |                             2143 ms |                         2137 ms |      -6 ms |    0% |              1103 ms |   -1034 ms |  -48% |              1366 ms |     263 ms |  +24% |       -777 ms |  -36% |
| Foundation-nsdata-toData - Length64       |                             2370 ms |                         2368 ms |      -2 ms |    0% |              1216 ms |   -1152 ms |  -49% |              1505 ms |     289 ms |  +24% |       -865 ms |  -36% |
| Foundation-nsdata-toData - Length64CR     |                             2354 ms |                         2372 ms |      18 ms |   +1% |              1214 ms |   -1158 ms |  -49% |              1498 ms |     284 ms |  +23% |       -856 ms |  -36% |
| Foundation-nsdata-toData - Length64LF     |                             2355 ms |                         2345 ms |     -10 ms |    0% |              1211 ms |   -1134 ms |  -48% |              1508 ms |     297 ms |  +25% |       -847 ms |  -36% |
| Foundation-nsdata-toData - Length64CRLF   |                             2379 ms |                         2347 ms |     -32 ms |   -1% |              1221 ms |   -1126 ms |  -48% |              1507 ms |     286 ms |  +23% |       -872 ms |  -37% |
| Foundation-nsdata-toData - Length76       |                             2432 ms |                         2461 ms |      29 ms |   +1% |              1233 ms |   -1228 ms |  -50% |              1512 ms |     279 ms |  +23% |       -920 ms |  -38% |
| Foundation-nsdata-toData - Length76CR     |                             2463 ms |                         2441 ms |     -22 ms |   -1% |              1220 ms |   -1221 ms |  -50% |              1501 ms |     281 ms |  +23% |       -962 ms |  -39% |
| Foundation-nsdata-toData - Length76LF     |                             2434 ms |                         2436 ms |       2 ms |   +0% |              1233 ms |   -1203 ms |  -49% |              1496 ms |     263 ms |  +21% |       -938 ms |  -39% |
| Foundation-nsdata-toData - Length76CRLF   |                             2472 ms |                         2440 ms |     -32 ms |   -1% |              1217 ms |   -1223 ms |  -50% |              1491 ms |     274 ms |  +23% |       -981 ms |  -40% |
| Foundation-data-toString - No options     |                             4064 ms |                         3995 ms |     -69 ms |   -2% |              1175 ms |   -2820 ms |  -71% |              1410 ms |     235 ms |  +20% |      -2654 ms |  -65% |
| Foundation-data-toString - Length64       |                             4369 ms |                         4179 ms |    -190 ms |   -4% |              1343 ms |   -2836 ms |  -68% |              1581 ms |     238 ms |  +18% |      -2788 ms |  -64% |
| Foundation-data-toString - Length64CR     |                             4281 ms |                         4184 ms |     -97 ms |   -2% |              1322 ms |   -2862 ms |  -68% |              1571 ms |     249 ms |  +19% |      -2710 ms |  -63% |
| Foundation-data-toString - Length64LF     |                             4328 ms |                         4166 ms |    -162 ms |   -4% |              1323 ms |   -2843 ms |  -68% |              1594 ms |     271 ms |  +20% |      -2734 ms |  -63% |
| Foundation-data-toString - Length64CRLF   |                             4305 ms |                         4184 ms |    -121 ms |   -3% |              1323 ms |   -2861 ms |  -68% |              1588 ms |     265 ms |  +20% |      -2717 ms |  -63% |
| Foundation-data-toString - Length76       |                             4407 ms |                         4299 ms |    -108 ms |   -2% |              1316 ms |   -2983 ms |  -69% |              1568 ms |     252 ms |  +19% |      -2839 ms |  -64% |
| Foundation-data-toString - Length76CR     |                             4389 ms |                         4265 ms |    -124 ms |   -3% |              1300 ms |   -2965 ms |  -70% |              1564 ms |     264 ms |  +20% |      -2825 ms |  -64% |
| Foundation-data-toString - Length76LF     |                             4418 ms |                         4257 ms |    -161 ms |   -4% |              1298 ms |   -2959 ms |  -70% |              1573 ms |     275 ms |  +21% |      -2845 ms |  -64% |
| Foundation-data-toString - Length76CRLF   |                             4386 ms |                         4320 ms |     -66 ms |   -2% |              1326 ms |   -2994 ms |  -69% |              1581 ms |     255 ms |  +19% |      -2805 ms |  -64% |
| Foundation-data-toData - No options       |                             2656 ms |                         2615 ms |     -41 ms |   -2% |               992 ms |   -1623 ms |  -62% |              1251 ms |     259 ms |  +26% |      -1405 ms |  -53% |
| Foundation-data-toData - Length64         |                             2883 ms |                         2856 ms |     -27 ms |   -1% |              1112 ms |   -1744 ms |  -61% |              1397 ms |     285 ms |  +26% |      -1486 ms |  -52% |
| Foundation-data-toData - Length64CR       |                             2890 ms |                         2821 ms |     -69 ms |   -2% |              1100 ms |   -1721 ms |  -61% |              1398 ms |     298 ms |  +27% |      -1492 ms |  -52% |
| Foundation-data-toData - Length64LF       |                             2872 ms |                         2843 ms |     -29 ms |   -1% |              1113 ms |   -1730 ms |  -61% |              1407 ms |     294 ms |  +26% |      -1465 ms |  -51% |
| Foundation-data-toData - Length64CRLF     |                             2866 ms |                         2830 ms |     -36 ms |   -1% |              1107 ms |   -1723 ms |  -61% |              1385 ms |     278 ms |  +25% |      -1481 ms |  -52% |
| Foundation-data-toData - Length76         |                             2952 ms |                         2913 ms |     -39 ms |   -1% |              1115 ms |   -1798 ms |  -62% |              1386 ms |     271 ms |  +24% |      -1566 ms |  -53% |
| Foundation-data-toData - Length76CR       |                             2970 ms |                         2939 ms |     -31 ms |   -1% |              1102 ms |   -1837 ms |  -63% |              1385 ms |     283 ms |  +26% |      -1585 ms |  -53% |
| Foundation-data-toData - Length76LF       |                             2941 ms |                         2916 ms |     -25 ms |   -1% |              1107 ms |   -1809 ms |  -62% |              1398 ms |     291 ms |  +26% |      -1543 ms |  -52% |
| Foundation-data-toData - Length76CRLF     |                             2958 ms |                         2917 ms |     -41 ms |   -1% |              1111 ms |   -1806 ms |  -62% |              1386 ms |     275 ms |  +25% |      -1572 ms |  -53% |
| Base64Kit                                 |                            10617 ms |                         9230 ms |   -1387 ms |  -13% |              9224 ms |      -6 ms |    0% |              9494 ms |     270 ms |   +3% |      -1123 ms |  -11% |
| Foundation - 0 bytes                      |                              137 ms |                          139 ms |       2 ms |   +1% |                25 ms |    -114 ms |  -82% |                26 ms |       1 ms |   +4% |       -111 ms |  -81% |
| Foundation - 1 byte                       |                              994 ms |                          989 ms |      -5 ms |   -1% |               177 ms |    -812 ms |  -82% |               183 ms |       6 ms |   +3% |       -811 ms |  -82% |
| Foundation - 2 bytes                      |                              980 ms |                          953 ms |     -27 ms |   -3% |               190 ms |    -763 ms |  -80% |               185 ms |      -5 ms |   -3% |       -795 ms |  -81% |
| Foundation - 3 bytes                      |                              974 ms |                          951 ms |     -23 ms |   -2% |               180 ms |    -771 ms |  -81% |               193 ms |      13 ms |   +7% |       -781 ms |  -80% |
| Base64Kit - 0 bytes                       |                              318 ms |                          294 ms |     -24 ms |   -8% |               283 ms |     -11 ms |   -4% |               291 ms |       8 ms |   +3% |        -27 ms |   -8% |
| Base64Kit - 1 byte                        |                              702 ms |                          653 ms |     -49 ms |   -7% |               620 ms |     -33 ms |   -5% |               636 ms |      16 ms |   +3% |        -66 ms |   -9% |
| Base64Kit - 2 bytes                       |                              770 ms |                          742 ms |     -28 ms |   -4% |               698 ms |     -44 ms |   -6% |               719 ms |      21 ms |   +3% |        -51 ms |   -7% |
| Base64Kit - 3 bytes                       |                              854 ms |                          814 ms |     -40 ms |   -5% |               782 ms |     -32 ms |   -4% |               800 ms |      18 ms |   +2% |        -54 ms |   -6% |

| Base64Tests.base64EncodeLongSpeed         | 5.3-DEVELOPMENT-SNAPSHOT-2020-05-04 | DEVELOPMENT-SNAPSHOT-2020-05-11 | difference |  pct  | test-decode-speedup1 | difference |  pct  | test-decode-speedup2 | difference |  pct  | First to Last |  pct  |
|-------------------------------------------|-------------------------------------|---------------------------------|------------|-------|----------------------|------------|-------|----------------------|------------|-------|---------------|-------|
| Foundation-nsdata-toString - No options   |                             6296 ms |                         6116 ms |    -180 ms |   -3% |              1760 ms |   -4356 ms |  -71% |              2331 ms |     571 ms |  +32% |      -3965 ms |  -63% |
| Foundation-nsdata-toString - Length64     |                             7101 ms |                         6636 ms |    -465 ms |   -7% |              2045 ms |   -4591 ms |  -69% |              2682 ms |     637 ms |  +31% |      -4419 ms |  -62% |
| Foundation-nsdata-toString - Length64CR   |                             6929 ms |                         6565 ms |    -364 ms |   -5% |              2031 ms |   -4534 ms |  -69% |              2657 ms |     626 ms |  +31% |      -4272 ms |  -62% |
| Foundation-nsdata-toString - Length64LF   |                             6809 ms |                         6623 ms |    -186 ms |   -3% |              2021 ms |   -4602 ms |  -69% |              2666 ms |     645 ms |  +32% |      -4143 ms |  -61% |
| Foundation-nsdata-toString - Length64CRLF |                             7001 ms |                         6703 ms |    -298 ms |   -4% |              2056 ms |   -4647 ms |  -69% |              2645 ms |     589 ms |  +29% |      -4356 ms |  -62% |
| Foundation-nsdata-toString - Length76     |                             7168 ms |                         6825 ms |    -343 ms |   -5% |              2045 ms |   -4780 ms |  -70% |              2644 ms |     599 ms |  +29% |      -4524 ms |  -63% |
| Foundation-nsdata-toString - Length76CR   |                             7121 ms |                         6783 ms |    -338 ms |   -5% |              2031 ms |   -4752 ms |  -70% |              2620 ms |     589 ms |  +29% |      -4501 ms |  -63% |
| Foundation-nsdata-toString - Length76LF   |                             6997 ms |                         6850 ms |    -147 ms |   -2% |              2014 ms |   -4836 ms |  -71% |              2636 ms |     622 ms |  +31% |      -4361 ms |  -62% |
| Foundation-nsdata-toString - Length76CRLF |                             7034 ms |                         6841 ms |    -193 ms |   -3% |              2048 ms |   -4793 ms |  -70% |              2647 ms |     599 ms |  +29% |      -4387 ms |  -62% |
| Foundation-nsdata-toData - No options     |                             3112 ms |                         3086 ms |     -26 ms |   -1% |              1379 ms |   -1707 ms |  -55% |              1940 ms |     561 ms |  +41% |      -1172 ms |  -38% |
| Foundation-nsdata-toData - Length64       |                             3535 ms |                         3475 ms |     -60 ms |   -2% |              1656 ms |   -1819 ms |  -52% |              2237 ms |     581 ms |  +35% |      -1298 ms |  -37% |
| Foundation-nsdata-toData - Length64CR     |                             3508 ms |                         3466 ms |     -42 ms |   -1% |              1645 ms |   -1821 ms |  -53% |              2244 ms |     599 ms |  +36% |      -1264 ms |  -36% |
| Foundation-nsdata-toData - Length64LF     |                             3519 ms |                         3468 ms |     -51 ms |   -1% |              1642 ms |   -1826 ms |  -53% |              2228 ms |     586 ms |  +36% |      -1291 ms |  -37% |
| Foundation-nsdata-toData - Length64CRLF   |                             3529 ms |                         3481 ms |     -48 ms |   -1% |              1664 ms |   -1817 ms |  -52% |              2232 ms |     568 ms |  +34% |      -1297 ms |  -37% |
| Foundation-nsdata-toData - Length76       |                             3703 ms |                         3694 ms |      -9 ms |    0% |              1663 ms |   -2031 ms |  -55% |              2235 ms |     572 ms |  +34% |      -1468 ms |  -40% |
| Foundation-nsdata-toData - Length76CR     |                             3723 ms |                         3694 ms |     -29 ms |   -1% |              1642 ms |   -2052 ms |  -56% |              2237 ms |     595 ms |  +36% |      -1486 ms |  -40% |
| Foundation-nsdata-toData - Length76LF     |                             3717 ms |                         3717 ms |       0 ms |   +0% |              1637 ms |   -2080 ms |  -56% |              2221 ms |     584 ms |  +36% |      -1496 ms |  -40% |
| Foundation-nsdata-toData - Length76CRLF   |                             3730 ms |                         3710 ms |     -20 ms |   -1% |              1657 ms |   -2053 ms |  -55% |              2226 ms |     569 ms |  +34% |      -1504 ms |  -40% |
| Foundation-data-toString - No options     |                             3980 ms |                         3935 ms |     -45 ms |   -1% |              1764 ms |   -2171 ms |  -55% |              2358 ms |     594 ms |  +34% |      -1622 ms |  -41% |
| Foundation-data-toString - Length64       |                             6803 ms |                         6642 ms |    -161 ms |   -2% |              2063 ms |   -4579 ms |  -69% |              2646 ms |     583 ms |  +28% |      -4157 ms |  -61% |
| Foundation-data-toString - Length64CR     |                             6710 ms |                         6610 ms |    -100 ms |   -1% |              2030 ms |   -4580 ms |  -69% |              2641 ms |     611 ms |  +30% |      -4069 ms |  -61% |
| Foundation-data-toString - Length64LF     |                             6690 ms |                         6685 ms |      -5 ms |    0% |              2026 ms |   -4659 ms |  -70% |              2654 ms |     628 ms |  +31% |      -4036 ms |  -60% |
| Foundation-data-toString - Length64CRLF   |                             6775 ms |                         6734 ms |     -41 ms |   -1% |              2051 ms |   -4683 ms |  -70% |              2657 ms |     606 ms |  +30% |      -4118 ms |  -61% |
| Foundation-data-toString - Length76       |                             7025 ms |                         6952 ms |     -73 ms |   -1% |              2052 ms |   -4900 ms |  -70% |              2655 ms |     603 ms |  +29% |      -4370 ms |  -62% |
| Foundation-data-toString - Length76CR     |                             6977 ms |                         6901 ms |     -76 ms |   -1% |              2027 ms |   -4874 ms |  -71% |              2636 ms |     609 ms |  +30% |      -4341 ms |  -62% |
| Foundation-data-toString - Length76LF     |                             6957 ms |                         6915 ms |     -42 ms |   -1% |              2040 ms |   -4875 ms |  -70% |              2655 ms |     615 ms |  +30% |      -4302 ms |  -62% |
| Foundation-data-toString - Length76CRLF   |                             6994 ms |                         6858 ms |    -136 ms |   -2% |              2047 ms |   -4811 ms |  -70% |              2650 ms |     603 ms |  +29% |      -4344 ms |  -62% |
| Foundation-data-toData - No options       |                             3114 ms |                         3105 ms |      -9 ms |    0% |              1374 ms |   -1731 ms |  -56% |              1942 ms |     568 ms |  +41% |      -1172 ms |  -38% |
| Foundation-data-toData - Length64         |                             3509 ms |                         3551 ms |      42 ms |   +1% |              1674 ms |   -1877 ms |  -53% |              2237 ms |     563 ms |  +34% |      -1272 ms |  -36% |
| Foundation-data-toData - Length64CR       |                             3495 ms |                         3479 ms |     -16 ms |    0% |              1648 ms |   -1831 ms |  -53% |              2240 ms |     592 ms |  +36% |      -1255 ms |  -36% |
| Foundation-data-toData - Length64LF       |                             3485 ms |                         3474 ms |     -11 ms |    0% |              1654 ms |   -1820 ms |  -52% |              2239 ms |     585 ms |  +35% |      -1246 ms |  -36% |
| Foundation-data-toData - Length64CRLF     |                             3544 ms |                         3495 ms |     -49 ms |   -1% |              1687 ms |   -1808 ms |  -52% |              2252 ms |     565 ms |  +33% |      -1292 ms |  -36% |
| Foundation-data-toData - Length76         |                             3724 ms |                         3702 ms |     -22 ms |   -1% |              1654 ms |   -2048 ms |  -55% |              2260 ms |     606 ms |  +37% |      -1464 ms |  -39% |
| Foundation-data-toData - Length76CR       |                             3740 ms |                         3700 ms |     -40 ms |   -1% |              1641 ms |   -2059 ms |  -56% |              2249 ms |     608 ms |  +37% |      -1491 ms |  -40% |
| Foundation-data-toData - Length76LF       |                             3733 ms |                         3683 ms |     -50 ms |   -1% |              1644 ms |   -2039 ms |  -55% |              2260 ms |     616 ms |  +37% |      -1473 ms |  -39% |
| Foundation-data-toData - Length76CRLF     |                             3713 ms |                         3679 ms |     -34 ms |   -1% |              1654 ms |   -2025 ms |  -55% |              2243 ms |     589 ms |  +36% |      -1470 ms |  -40% |
| Base64Kit                                 |                            20710 ms |                        17832 ms |   -2878 ms |  -14% |             18059 ms |     227 ms |   +1% |             18282 ms |     223 ms |   +1% |      -2428 ms |  -12% |

| Base64Tests.base64DecodeShortSpeed        | 5.3-DEVELOPMENT-SNAPSHOT-2020-05-04 | DEVELOPMENT-SNAPSHOT-2020-05-11 | difference |  pct  | test-decode-speedup1 | difference |  pct  | test-decode-speedup2 | difference |  pct  | First to Last |  pct  |
|-------------------------------------------|-------------------------------------|---------------------------------|------------|-------|----------------------|------------|-------|----------------------|------------|-------|---------------|-------|
| nsdata-decodeString                       |                            13929 ms |                        13904 ms |     -25 ms |    0% |              5566 ms |   -8338 ms |  -60% |              2838 ms |   -2728 ms |  -49% |     -11091 ms |  -80% |
| nsdata-decodeString - Ignore Unknown      |                            13975 ms |                        13897 ms |     -78 ms |   -1% |              5692 ms |   -8205 ms |  -59% |              2834 ms |   -2858 ms |  -50% |     -11141 ms |  -80% |
| nsdata-decodeData                         |                            18347 ms |                        18170 ms |    -177 ms |   -1% |             14781 ms |   -3389 ms |  -19% |              2881 ms |  -11900 ms |  -81% |     -15466 ms |  -84% |
| nsdata-decodeData - Ignore Unknown        |                            18421 ms |                        18094 ms |    -327 ms |   -2% |             14876 ms |   -3218 ms |  -18% |              2870 ms |  -12006 ms |  -81% |     -15551 ms |  -84% |
| Base64kit                                 |                             2285 ms |                         2502 ms |     217 ms |   +9% |              2429 ms |     -73 ms |   -3% |              2419 ms |     -10 ms |    0% |        134 ms |   +6% |

| Base64Tests.base64DecodeLongSpeed         | 5.3-DEVELOPMENT-SNAPSHOT-2020-05-04 | DEVELOPMENT-SNAPSHOT-2020-05-11 | difference |  pct  | test-decode-speedup1 | difference |  pct  | test-decode-speedup2 | difference |  pct  | First to Last |  pct  |
|-------------------------------------------|-------------------------------------|---------------------------------|------------|-------|----------------------|------------|-------|----------------------|------------|-------|---------------|-------|
| nsdata-decodeString                       |                            34842 ms |                        34620 ms |    -222 ms |   -1% |             10640 ms |  -23980 ms |  -69% |              5037 ms |   -5603 ms |  -53% |     -29805 ms |  -86% |
| nsdata-decodeString - Ignore Unknown      |                            35483 ms |                        34668 ms |    -815 ms |   -2% |             10676 ms |  -23992 ms |  -69% |              5042 ms |   -5634 ms |  -53% |     -30441 ms |  -86% |
| nsdata-decodeData                         |                            34972 ms |                        34953 ms |     -19 ms |    0% |             29169 ms |   -5784 ms |  -17% |              5047 ms |  -24122 ms |  -83% |     -29925 ms |  -86% |
| nsdata-decodeData - Ignore Unknown        |                            35311 ms |                        34695 ms |    -616 ms |   -2% |             29175 ms |   -5520 ms |  -16% |              5045 ms |  -24130 ms |  -83% |     -30266 ms |  -86% |
| Base64kit                                 |                             4480 ms |                         4928 ms |     448 ms |  +10% |              4805 ms |    -123 ms |   -2% |              4790 ms |     -15 ms |    0% |        310 ms |   +7% |
