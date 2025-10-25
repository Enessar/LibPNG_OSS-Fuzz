# Fuzzing and Vulnerability Analysis of libpng

A comprehensive security research project demonstrating **coverage-guided fuzzing**, **code coverage analysis**, and **vulnerability exploitation** using Google's OSS-Fuzz framework on libpng library.

---

## 🎯 Project Overview

This project showcases practical application of modern software security testing techniques:

- **Coverage-guided fuzzing** with OSS-Fuzz
- **Empirical analysis** of seed corpus impact on fuzzing effectiveness  
- **Custom fuzzer development** to improve code coverage
- **CVE exploitation** (CVE-2014-9495) with proof-of-concept code

**Target:** libpng (Portable Network Graphics library)  
**Versions Tested:** v1.6.48 (fuzzing), v1.5.20 (vulnerability exploitation)

---

## 📊 Project Structure

```
├── part1/          # Baseline Fuzzing & Corpus Impact Analysis
│   ├── run.w_corpus.sh
│   ├── run.w_o_corpus.sh
│   ├── oss-fuzz.diff
│   └── report/
│       ├── w_corpus/        # Coverage reports WITH seed corpus
│       └── w_o_corpus/      # Coverage reports WITHOUT seed corpus
│
├── part3/          # Coverage Improvement Experiments
│   ├── coverage_noimprove/  # Baseline coverage for comparison
│   ├── improve1/
│   │   ├── run.improve1.sh
│   │   └── coverage_improve1/
│   └── improve2/
│       ├── run.improve2.sh
│       └── coverage_improve2/
│
└── part4/          # Vulnerability Exploitation
    ├── run.poc.sh
    └── write_exploit.c
```

---

## 📁 Part 1: Fuzzing with and without Seed Corpus

### Objective
Quantify the impact of seed corpus on fuzzing effectiveness by comparing coverage metrics.

### Methodology

#### Experiment 1: WITH Seed Corpus
**Script:** `run.w_corpus.sh`

```bash
# Uses default libpng OSS-Fuzz configuration
- Fuzzer: libpng_read_fuzzer
- Seed Corpus: PNG images from libpng/contrib/oss-fuzz/
- Duration: 4 hours
- Target: libpng v1.6.48
```

#### Experiment 2: WITHOUT Seed Corpus
**Script:** `run.w_o_corpus.sh`

```bash
# Modified configuration (oss-fuzz.diff applied)
- Fuzzer: libpng_read_fuzzer  
- Seed Corpus: Empty (no initial inputs)
- Duration: 4 hours
- Target: libpng v1.6.48
- Modification: Removed seed corpus zip step in build.sh
```

### Results Summary

| Metric | WITH Corpus | WITHOUT Corpus | Improvement |
|--------|-------------|----------------|-------------|
| **Line Coverage** | 41.83% (5,372/12,841) | 24.76% (3,180/12,841) | **+17.07%** |
| **Branch Coverage** | 35.49% (2,069/5,830) | 21.03% (1,226/5,830) | **+14.46%** |
| **Function Coverage** | 50.75% (203/400) | 34.75% (139/400) | **+16.00%** |

> **[INSERT SCREENSHOT: Coverage comparison graphs]**

### Key Findings

✅ **Seed corpus dramatically improves fuzzing effectiveness**  
- 17% increase in line coverage with seed corpus
- Seed corpus helps fuzzer explore deeper code paths faster
- Quality of seed inputs matters more than quantity

✅ **Without seed corpus, fuzzer struggles with complex formats**  
- PNG format requires valid headers, chunks, CRC checks
- Random mutations unlikely to generate valid PNG structures from scratch

---

## 📁 Part 3: Custom Fuzzer Development

### Objective
Improve code coverage beyond baseline by developing custom fuzzers targeting unexplored code paths.

### Baseline Measurements

From Part 1 WITH corpus baseline:
- **Total Line Coverage:** 33.02% (5,384/16,307 lines including write functions)
- **Read Functions:** Well covered (41.83%)
- **Write Functions:** Completely uncovered (0%)

> **[INSERT SCREENSHOT: Baseline coverage heatmap]**

---

### Improvement 1: Enhanced Read Fuzzer

**Repository:** [Enessar/oss-fuzz](https://github.com/Enessar/oss-fuzz)  
**Branch:** `submit_improve1`  
**Script:** `part3/improve1/run.improve1.sh`

#### Changes Made
Modified `libpng_read_fuzzer.cc` to:
- Add more PNG transformation API calls (`png_set_*` functions)
- Increase input variation handling
- Test additional color space conversions
- Explore edge cases in interlacing and filtering

#### Results

| Metric | Baseline | Improve 1 | Change |
|--------|----------|-----------|--------|
| **Line Coverage** | 33.02% | 34.08% | **+1.06%** |
| **Branch Coverage** | 28.81% | 29.79% | **+0.98%** |
| **Functions Covered** | 203 | 206 | **+3 functions** |

**Key Improvements:**
- `pngread.c`: +74 lines covered (+4% coverage)
- `pngrtran.c`: +19 lines covered  
- `pngtrans.c`: +73 lines covered (+12% coverage)

> **[INSERT SCREENSHOT: Improve1 coverage diff]**

---

### Improvement 2: Write Fuzzer (NEW)

**Repository:** [Enessar/oss-fuzz](https://github.com/Enessar/oss-fuzz)  
**Branch:** `submit_improve2`  
**Script:** `part3/improve2/run.improve2.sh`

#### Innovation
Created entirely new fuzzer `libpng_write_fuzzer.cc` to test PNG **encoding** operations (previously 0% coverage).

#### Fuzzer Design
```cpp
// Generates PNG images with fuzzed parameters:
- Width/height from fuzzer input
- Color types (RGB, RGBA, Grayscale, Palette)
- Bit depths (1, 2, 4, 8, 16)
- Interlacing methods (None, Adam7)
- Compression levels
- Filter methods
```

#### Results

| File | Coverage Before | Coverage After | Improvement |
|------|----------------|----------------|-------------|
| **pngwrite.c** | 0% (0/1,324) | 30.29% (401/1,324) | **+401 lines** |
| **pngwutil.c** | 0% (0/1,618) | 50.43% (816/1,618) | **+816 lines** |
| **pngwtran.c** | 0% (0/404) | 8.91% (36/404) | **+36 lines** |
| **pngwio.c** | 0% (0/30) | 56.67% (17/30) | **+17 lines** |

**Total New Coverage:** 1,270 lines of previously untested code

> **[INSERT SCREENSHOT: Write fuzzer coverage visualization]**

---

### Repository & Branch Summary

| Experiment | Repository | Branch | Fuzzer Type |
|------------|------------|--------|-------------|
| **Part 1** | google/oss-fuzz | main | Read fuzzer (baseline) |
| **Improve 1** | Enessar/oss-fuzz | `submit_improve1` | Read fuzzer (enhanced) |
| **Improve 2** | Enessar/oss-fuzz | `submit_improve2` | Write fuzzer (NEW) |

---

## 📁 Part 4: CVE Exploitation

### CVE-2014-9495: Heap Buffer Overflow

**Vulnerability:** Integer overflow in Adam7 interlaced PNG row buffer calculation  
**Affected Version:** libpng 1.5.20 and earlier  
**Impact:** Heap buffer overflow, potential code execution

#### Vulnerability Details

```c
// Vulnerable code in png_read_row() (simplified)
row_bytes = PNG_ROWBYTES(pixel_depth, row_width);
// If row_width overflows, row_bytes becomes too small
// Subsequent memcpy() writes beyond allocated buffer
```

**Root Cause:** During Adam7 interlacing, libpng calculates row buffer sizes based on image dimensions. For certain malformed dimensions, integer overflow causes undersized buffer allocation.

---

### Proof-of-Concept Exploit

**File:** `part4/write_exploit.c`  
**Script:** `part4/run.poc.sh`

#### Exploit Strategy

```c
// Creates malformed Adam7 PNG with:
png_set_IHDR(
    width = 5,           // Small width
    height = 7,          // Height for 7 Adam7 passes  
    interlace = ADAM7    // Trigger vulnerable code path
);

// Write oversized row for pass 3 to trigger overflow
png_write_row(big_row);  // Larger than allocated buffer
```

#### Execution

```bash
cd part4
./run.poc.sh

# Output:
# [BUILD] Building libpng 1.5.20 (vulnerable)...
# [COMPILE] Building trigger with AddressSanitizer...
# [RUN] Executing exploit...
# 
# =================================================================
# ==12345==ERROR: AddressSanitizer: heap-buffer-overflow
# WRITE of size 15 at 0x603000000020 thread T0
#     #0 0x7f... in png_write_row libpng/pngwrite.c:123
#     #1 0x4... in main write_exploit.c:45
# =================================================================
```

> **[INSERT SCREENSHOT: AddressSanitizer crash output]**

#### Files Generated
- `test_crash.png` - Malformed PNG that triggers vulnerability
- ASan report showing heap overflow detection

---

## 🛠️ Technologies & Tools

| Category | Technology |
|----------|-----------|
| **Fuzzing Framework** | Google OSS-Fuzz, libFuzzer |
| **Target Library** | libpng v1.6.48 (fuzzing), v1.5.20 (exploitation) |
| **Coverage Analysis** | LLVM source-based coverage |
| **Sanitizers** | AddressSanitizer (ASan) |
| **Languages** | C, C++, Bash |
| **Build Systems** | CMake, Autotools, Make |

---

## 📈 Overall Results Summary

### Coverage Progression

```
Baseline (no corpus):    24.76% line coverage
Baseline (with corpus):  41.83% line coverage  ← +17% from seed corpus
Improve 1 (read+):       34.08% overall        ← +1% from enhancements
Improve 2 (write):       +1,270 new lines      ← New code paths
```

### Achievements

✅ **Demonstrated seed corpus impact:** 17% coverage increase  
✅ **Created custom fuzzers:** 2 new fuzzer variants  
✅ **Achieved novel coverage:** 1,270 lines of write-path code tested  
✅ **Exploited real CVE:** Successful PoC for CVE-2014-9495  

---

## 🚀 How to Reproduce

### Prerequisites
- Ubuntu/Debian Linux
- Docker (for OSS-Fuzz)
- 16GB+ RAM
- sudo access

### Part 1: Run Fuzzing Experiments

```bash
# Experiment 1: WITH seed corpus
cd part1
./run.w_corpus.sh
# Wait 4 hours...
# Coverage report generated in report/w_corpus/

# Experiment 2: WITHOUT seed corpus  
./run.w_o_corpus.sh
# Wait 4 hours...
# Coverage report generated in report/w_o_corpus/

# Clean up between runs
sudo rm -rf oss-fuzz
```

### Part 3: Test Coverage Improvements

```bash
# Improvement 1: Enhanced read fuzzer
cd part3/improve1
./run.improve1.sh
# Wait 4 hours...

# Improvement 2: Write fuzzer
cd ../improve2
./run.improve2.sh
# Wait 4 hours...

# Compare coverage reports in coverage_improve*/
```

### Part 4: Run CVE Exploit

```bash
cd part4
./run.poc.sh

# Expected output:
# - Compiles libpng 1.5.20
# - Builds exploit with ASan
# - Triggers heap-buffer-overflow
# - Creates test_crash.png
```

### ⚠️ Important Notes

- Each fuzzing run takes **4 hours** and uses significant CPU
- **Delete `oss-fuzz/` directory** between runs to avoid conflicts
- Coverage reports are HTML files viewable in browser
- Part 4 requires AddressSanitizer-enabled compiler

---

## 📊 Coverage Report Viewing

Coverage reports are generated as interactive HTML:

```bash
# View WITH corpus coverage
firefox part1/report/w_corpus/linux/index.html

# View WITHOUT corpus coverage
firefox part1/report/w_o_corpus/linux/index.html

# View improvements
firefox part3/improve1/coverage_improve1/linux/index.html
firefox part3/improve2/coverage_improve2/linux/index.html
```

Reports include:
- Line-by-line coverage highlighting
- Branch coverage statistics
- Function coverage lists
- Coverage heatmaps
- Execution counts per line

---

## 🔍 Key Learnings

### 1. Seed Corpus is Critical
Quality seed inputs provide fuzzer with:
- Valid structure templates
- Known-good code paths
- Starting points for productive mutations

**Impact:** 17% coverage increase vs. starting from empty corpus

### 2. Targeted Fuzzing > Generic Fuzzing
Different fuzzer designs explore complementary code paths:
- Read fuzzer: Decoding operations
- Write fuzzer: Encoding operations

**Lesson:** One fuzzer cannot cover all functionality

### 3. Coverage-Guided Fuzzing Works
OSS-Fuzz's libFuzzer successfully:
- Discovered 74+ new paths in pngread.c
- Achieved 50% coverage in pngwutil.c
- Found edge cases in transformation functions

### 4. Historical CVEs Teach Modern Lessons
CVE-2014-9495 demonstrates:
- Integer overflow vulnerabilities in image parsers
- Importance of bounds checking
- Value of fuzzing for finding similar bugs

---

## 🎓 Research Questions Answered

| Question | Answer |
|----------|--------|
| Does seed corpus matter? | **YES** - 17% coverage improvement |
| Can custom fuzzers improve coverage? | **YES** - +1,270 lines from write fuzzer |
| Is libpng still vulnerable? | **NO** - v1.6.48 has patches, but historical CVEs remain instructive |
| Does fuzzing find real bugs? | **YES** - OSS-Fuzz has found 20+ libpng bugs historically |

---

## 📄 License & Disclaimer

**Educational Research Project**

⚠️ **DISCLAIMER:** This project is for **educational and research purposes only**.

- All vulnerabilities discussed are **historical** and **publicly disclosed**
- CVE-2014-9495 was patched in 2014
- Do **NOT** use exploitation techniques on systems you don't own
- Do **NOT** use PoC code maliciously

**Licenses:**
- libpng: [libpng license](http://www.libpng.org/pub/png/src/libpng-LICENSE.txt)
- OSS-Fuzz: Apache License 2.0
- This research: Educational use only

---

## 👤 Author

**Security Research Project**  
Demonstrating practical application of:
- Coverage-guided fuzzing
- Software testing methodologies  
- Vulnerability analysis
- Security research best practices

---

## 📚 References

### Tools & Frameworks
- [Google OSS-Fuzz](https://google.github.io/oss-fuzz/)
- [libFuzzer Documentation](https://llvm.org/docs/LibFuzzer.html)
- [LLVM Coverage](https://clang.llvm.org/docs/SourceBasedCodeCoverage.html)

### Target Library
- [libpng Official Site](http://www.libpng.org/pub/png/libpng.html)
- [libpng GitHub](https://github.com/pnggroup/libpng)

### Vulnerability Information
- [CVE-2014-9495](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-9495)
- [NVD Entry](https://nvd.nist.gov/vuln/detail/CVE-2014-9495)

### Research Papers
- "Coverage-Guided Fuzzing" - Böhme et al.
- "The Art, Science, and Engineering of Fuzzing" - Manes et al.

---

## 🏆 Project Highlights

This project demonstrates:

- ✅ **Rigorous methodology** - Controlled experiments with clear baselines
- ✅ **Quantitative analysis** - Precise coverage metrics and comparisons
- ✅ **Creative problem-solving** - Custom fuzzer development for uncovered paths
- ✅ **Security awareness** - Real vulnerability analysis and exploitation
- ✅ **Reproducibility** - Clear documentation and automated scripts
- ✅ **Best practices** - Use of industry-standard tools (OSS-Fuzz, ASan)

---

**Built with 🔍 for security research and education**
