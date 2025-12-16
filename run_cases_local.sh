#!/bin/bash
############################# Usage ###########################
# Use generate_test_matrix to create a text file that contains the pairings for Re and AOA
# Navigate to main directory (script will create a results directory from your working directory)
# Move template .par, .usr, .re2, and SIZE files to working directory
# Note that script expects .re2 files to follow this naming convention:
#      mesh##.re2
#      ## - angle of attack of mesh
# Run script!
###############################################################

set -e

########## USER SETTINGS ##########
PAR="template.par"          # Template .par file
USR="template.usr"          # Template .usr file
SIZE='SIZE'                 # Template SIZE file
CWD=$(pwd)                     # Run script in current directory
MATRIX='test_matrix.txt'      # Test matrix of cases
NEK_EXEC='nek5000'
###################################


###################################
# SET UP JOB TRACKING
###################################
# Detect available cores (or use override)
# Choose ranks per job (4 or 8 preferred)
# Compute max parallel jobs

TOTAL_CORES=$(nproc)

if (( TOTAL_CORES >= 8 )); then
    RANKS_PER_JOB=8
# elif (( TOTAL_CORES >= 4 )); then
    # RANKS_PER_JOB=4
else
    RANKS_PER_JOB=2
fi

MAX_JOBS=$(( TOTAL_CORES / RANKS_PER_JOB ))
if (( MAX_JOBS < 1 )); then MAX_JOBS=1; fi

echo "Detected $TOTAL_CORES cores."
echo "Using $RANKS_PER_JOB MPI ranks per job."
echo "Max parallel jobs: $MAX_JOBS"

# Helper Function: Job limiter
running_jobs=0
wait_for_slot() {
    while (( running_jobs >= MAX_JOBS )); do
        wait -n
        ((running_jobs--))
    done
}



######################################
# SET UP RESULTS DIRECTORY AND SUMMARY
######################################
# Create results directory
# Create summary CSV and write first line

RES_D="${CWD}/results"
mkdir -p $RES_D

SUMMARY="${RES_D}/summary.csv"
echo "Re,AOA,WallTimeSeconds,Drag_Filepath,Lift_Filepath" > "$SUMMARY"



###################################
# MAIN SIMULATION LOOP
###################################
# Read test_matrix.txt
# Initialize parameter sweep loop

while read -r Re meshfile 0<&3; do
    # Parse Re and AOA from test_matrix.txt
    # Example: 100 mesh2.re2 → Re=100 AOA=2
    AOA=$(echo "$meshfile" | sed -E 's/^.*mesh([0-9]+)\.re2/\1/')
    case="Re${Re}_aoa${AOA}"

    echo "Preparing case: Re=$Re, AOA=$AOA → $case"

    # Make case directory and move files to it
    mkdir -p "$case"
    cp "$meshfile" "$case/$case.re2"
    cp "$PAR" "$case/$case.par"
    cp "$USR" "$case/$case.usr" 
    cp "$SIZE" "$case/$SIZE"

    ### EDIT .par FILE ###
    sed -i -E "s/^.*viscosity.*/viscosity = -$Re/" "$case/$case.par"
    sed -i -E "s/^.*userParam05.*/userParam05 = $AOA/" "$case/$case.par"

    (
        # Move to run directory and create result filenames
        cd "$case"
	LOG="logfile_$case.txt"
	DRAG="drag_$case.csv"
	LIFT="lift_$case.csv"
	
		### partition ###
		echo "Running genmap"
        genmap 0<&3 << EOF > /dev/null 2>&1
${case}
0.05
EOF

	# ### partition ###
    # # Use a subshell and pipe to provide input non-interactively
    # (echo "${case}"; echo "0.05") | genmap > genmap_log.txt 2>&1
        
		### compile ###
	echo "Running makenek"
	makenek $case > build.log
        
	### run ###
	start_time=$(date +%s)
	echo "Running Nek5000 for $case"
	nekmpi $case $RANKS_PER_JOB > $LOG 2>&1
	end_time=$(date +%s)
	wall=$(( end_time - start_time ))

	### Generate .nek5000 file for visualization ###
	echo "Running visnek $case"
	visnek $case > /dev/null 2>&1
        
	### Extract drag/lift ###
	awk '/dragx/ { printf("%d,%.12e,%.12e\n",$1,$2,$3) }' "$LOG" > "$DRAG"
	awk '/dragy/ { printf("%d,%.12e,%.12e\n",$1,$2,$3) }' "$LOG" > "$LIFT"
	
    # Copy the generated CSV files to the main results directory ($RES_D)
	cp "$DRAG" "$RES_D/$DRAG"
	cp "$LIFT" "$RES_D/$LIFT"

    ##### Record summary entry #####
	RUN_DIR=$(pwd)
	DRAGPATH="${RUN_DIR}/$DRAG"
	LIFTPATH="${RUN_DIR}/$LIFT"
        echo "$Re,$AOA,$wall,$DRAGPATH,$LIFTPATH" >> "$SUMMARY"

    ) 

done 3< "$MATRIX"

wait  # wait for all jobs to finish
echo "All Nek5000 runs complete."

#echo "Running post-processing..."
#python3 "$PY_POST" summary.csv
#echo "Post-processing complete."

