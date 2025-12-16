#!/bin/bash
#
# JP 11/03/25 04:57 PM - Created to define all pairings of Re and AOA in one txt file
#
# SK 12/03/25 12:00 PM - Modified to generate basic test cases, added necessary permissions
#
# generate_matrix.sh
# Usage: chmod +x gen_test_mat.sh
#        ./gen_test_mat.sh > test_matrix.txt

# Define Reynolds numbers
RE_VALUES=(100 1000)

# Define Meshes 
MESHES=(mesh00.re2 mesh02.re2 mesh04.re2 mesh06.re2 mesh08.re2 mesh10.re2 mesh12.re2)

# Generate all combinations (15*13=195)
for Re in "${RE_VALUES[@]}"; do
  for mesh in "${MESHES[@]}"; do
    echo "$Re $mesh"
  done
done
