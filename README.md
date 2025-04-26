# SCHIZONE


## Scientific Computing Homemade Implementation ZONE

DIY implementations of "scientific" computing algorithms. Educational videos attached. Everything provided AMDG.

The codebase below uses x86-64 assembly (see language breakdown on side panel). NASM is used as the assembler.

(see [aarch64](aarch64) directory for those episodes).

Topics include basic math, BSD/Linux, mechanical/aerospace engineering, home/garden, finance, and maybe some embedded stuff.

## Installation/Usage Instructions
```bash
git clone https://github.com/xmdi/SCHIZONE.git # clone this repo
cd SCHIZONE
./make_bins.sh # this generates some useful binaries (all written in asm)
cd ex/ex018_LU_decomposition/ex018d_plu_decomposition # try a random example
./run.sh # this assembles and runs the assembled binary
```

## Episodes
| DATE | TOPIC | VIDEO |
| :---: | :---: | :---: |
| JUN 02, 2023 | [A Minimal Executable](ex/ex001_minimal_executable) | [EP. 001](https://youtu.be/7NFOS9F1Afo) |
| JUN 09, 2023 | [Syscalls and Functions](ex/ex002_syscalls_and_functions) | [EP. 002](https://youtu.be/QDSzn43bq7E) |
| JUN 14, 2023 | [Command Line Args & Code Golf](ex/ex003_command_line_args_and_code_golf) | [EP. 003](https://youtu.be/zX0bcOVGjow) |
| JUN 16, 2023 | [Printing Strings](ex/ex004_printing_strings) | [EP. 004](https://youtu.be/ZUcCBNCcSz8) |
| JUN 23, 2023 | [Printing Integers](ex/ex005_printing_integers) | [EP. 005](https://youtu.be/_hbZN4khAyU) |
| JUN 30, 2023 | [User Input](ex/ex006_user_input) | [EP. 006](https://youtu.be/PXTgtQN2CMg) |
| JUL 07, 2023 | [Fractions](ex/ex007_fractions) | [EP. 007](https://youtu.be/MgbPiniv1g0) |
| JUL 14, 2023 | [Randomness](ex/ex008_randomness) | [EP. 008](https://youtu.be/oKt_r7PIBX0) |
| JUL 21, 2023 | [Timing](ex/ex009_timing) | [EP. 009](https://youtu.be/_Bo09H7EoHY) |
| JUL 28, 2023 | [Matrix Basics](ex/ex010_matrix_basics) | [EP. 010](https://youtu.be/gJ8e2tF2aPc) |
| AUG 09, 2023 | [Memory Allocation](ex/ex011_memory_allocation) | [EP. 011](https://youtu.be/oE80pvbapgI) |
| AUG 18, 2023 | [Bitmap Images](ex/ex012_bitmap_images) | [EP. 012](https://youtu.be/o7g5ttZPa-Q) |
| SEP 01, 2023 | [Floating Point I/O](ex/ex013_floating_point_io) | [EP. 013](https://youtu.be/JoYMVeNH4Ss) |
| SEP 15, 2023 | [Scatter Plots](ex/ex014_scatter_plots) | [EP. 014](https://youtu.be/ykPLQL1pC_4) |
| SEP 29, 2023 | [Data Reports](ex/ex015_data_reports) | [EP. 015](https://youtu.be/QRBNgs9ZZhY) |
| OCT 13, 2023 | [Trigonometry](ex/ex016_trigonometry) | [EP. 016](https://youtu.be/EfaJiAeHj7E) |
| OCT 20, 2023 | [Root Finding](ex/ex017_root_finding) | [EP. 017](https://youtu.be/TNmAOsaUJiQ) |
| NOV 03, 2023 | [LU Decomposition](ex/ex018_LU_decomposition) | [EP. 018](https://youtu.be/ApkJGn0Wiss) |
| NOV 10, 2023 | [Least Squares Regression](ex/ex019_least_squares_regression) | [EP. 019](https://youtu.be/ka0pG7-h-ig) |
| DEC 01, 2023 | [Framebuffer](ex/ex020_framebuffer) | [EP. 020](https://youtu.be/PvXeZidA82I) |
| DEC 08, 2023 | [Mouse Input](ex/ex021_mouse_input) | [EP. 021](https://youtu.be/M7ejglSgWtc) |
| JAN 05, 2024 | [3D Graphics](ex/ex022_3d_graphics) | [EP. 022](https://youtu.be/lTigI6C11IM) |
| JAN 19, 2024 | [Rendering Text](ex/ex023_rendering_text) | [EP. 023](https://youtu.be/aEcjIvD4hmU) |
| FEB 02, 2024 | [3D Graphics (cont)](ex/ex024_3d_graphics_cont) | [EP. 024](https://youtu.be/iXqQWcw6noQ) |
| FEB 16, 2024 | [STL Files](ex/ex025_stl_files) | [EP. 025](https://youtu.be/4G7QglTu1eM) |
| MAR 01, 2024 | [3D Frames FEA](ex/ex026_3d_frames_FEA) | [EP. 026](https://youtu.be/4mKymYT_kP8) |
| MAR 15, 2024 | [Integration](ex/ex027_integration) | [EP. 027](https://youtu.be/2txsBh5PPJk) |
| APR 19, 2024 | [Perspective Projections](ex/ex028_perspective_projections) | [EP. 028](https://youtu.be/IZUqEhRMaeg) |
| MAY 03, 2024 | [HUD Interface](ex/ex029_HUD_interface) | [EP. 029](https://youtu.be/gpkx3gd7ylM) |
| MAY 03, 2024 | [HUD Interface](ex/ex029_HUD_interface) | [EP. 029](https://youtu.be/gpkx3gd7ylM) |
| MAY 17, 2024 | [Postfix Notation](ex/ex030_postfix_notation) | [EP. 030](https://youtu.be/yO32l7OZ3tU) |
| JUL 01, 2024 | [Trig Algs Revisited](ex/ex031_trig_revisited) | [EP. 031](https://youtu.be/pbIhg0NF6pI) |
| AUG 03, 2024 | [3D Scatterplots](ex/ex032_3d_scatterplots) | [EP. 032](https://youtu.be/09L90wlvUrY) |
| AUG ??, 2024 | [In progress - 3D Curves and Surfaces](ex/ex033_3d_curves_and_surfaces) | [EP. 033](https://youtu.be/) |

## Labs
| DATE | TOPIC | VIDEO |
| :---: | :---: | :---: |
| AUG 11, 2023 | [Cramer's Rule](lab/lab001_cramers_rule) | [LAB 001](https://youtu.be/JyIpF5iBGxU) |
| OCT 27, 2023 | [Multiple Root Finding](lab/lab002_multiple_root_finding) | [LAB 002](https://youtu.be/KaKBrN7tHpA) |
| JAN 26, 2024 | [Password Generation](lab/lab003_password_generator) | [LAB 003](https://youtu.be/JJ1dbJ4a09k) |
| MAR 22, 2024 | [Countdown Timer](lab/lab004_countdown_timer) | [LAB 004](https://youtu.be/_ElYsWY4xss) |
| MAY 24, 2024 | [Binary Dump](lab/lab005_hexdump) | [LAB 005](https://youtu.be/6UT0XYfi610) |
| JUN 14, 2024 | [LS](lab/lab006_ls) | [LAB 006](https://youtu.be/GbsKzOtA7Lg) |

## Bonus
| DATE | TOPIC | VIDEO |
| :---: | :---: | :---: |
| JUN 06, 2024 | Debugging Tools/Strategies | [VIDEO ONLY](https://youtu.be/N3OMTrl4k-Q) |

### NOTE 0: 
As part of this project we created some DIY versions of common utilities (see [EP. 003](ex/ex003_command_line_args_and_code_golf)). Later examples use "SCHIZONE/bin/make_executable" in place of "chmod +x". You can generate these binaries by running "./make_bins.sh" in the root directory.

### NOTE 1:
This repository contains bash scripts to facilitate compilation, so BSD users will have to use a compatible shell. In addition, much of the graphics rendering leverages a framebuffer device that doesn't appear to be normally present on modern BSD.

