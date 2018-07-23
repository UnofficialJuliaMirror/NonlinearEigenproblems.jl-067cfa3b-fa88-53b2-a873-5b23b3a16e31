################################################################################
# Submits test coverage for relevant code to Coveralls and Codecov
################################################################################

using Coverage

# Add folders and jl files below if you want to exclude them from the test
# coverage reports. Folders are excluded recursively. All names are case
# insensitive, and relative to the src/ folder.
excluded_folders_and_files = map(f -> uppercase("src/" * f), [
    "bugs/",
    "extra_tests/",
    "tmp/",
    "trash/",
    "gallery_extra/waveguide/waveguide_debug.jl",   # Some code to make larger verifications agains MATLAB (development phase)
    ])

cd(Pkg.dir("NonlinearEigenproblems"))
coverage = process_folder()
unfiltered_count = length(coverage)

filter!(f -> !any(x -> startswith(uppercase(f.filename), x), excluded_folders_and_files), coverage)

covered_lines, total_lines = get_summary(coverage)
@printf("%d / %d lines covered by tests (%.2f %%), in %d source files (%d files excluded)\n",
    covered_lines, total_lines, covered_lines * 100.0 / total_lines, length(coverage), unfiltered_count - length(coverage))

Coveralls.submit(coverage)
Codecov.submit(coverage)