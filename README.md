#Nek5000 Airfoil Simulation Test Cases

This repository contains the necessary files to run a systematic study of an airfoil using the **Nek5000** incompressible Navier-Stokes solver. The workflow automates the generation of test cases, execution of the simulations, and post-processing of lift and drag coefficients.

##Simulation OverviewThe simulations are set up for **2D Incompressible Navier-Stokes with Heat Transfer** on an airfoil (likely a NACA 4-digit profile, such as the NACA 2412 indicated in `template.par`).

The test matrix explores a combination of:

* **Reynolds Numbers (Re)**: Defined in `gen_test_mat.sh` (e.g., 100, 1000).
* **Angles of Attack (\alpha)**: Determined by the provided mesh files (`mesh00.re2`, `mesh02.re2`, etc.).

##PrerequisitesTo run the simulations and analysis, you will need:

1. **Nek5000**: The Nek5000 solver must be installed and compiled, with its executables (`genmap`, `makenek`, `nekmpi`, `visnek`) accessible in your environment's `$PATH`.
2. **MPI**: An MPI environment (e.g., OpenMPI or MPICH) is required for parallel execution.
3. **Python 3**: With the following packages for post-processing:
```bash
pip install pandas matplotlib

```



##File Structure| File Name | Description |
| --- | --- |
| `run_cases_local.sh` | **Main execution script.** Reads `test_matrix.txt`, prepares case directories, modifies the `.par` file with correct Re and AoA, and executes `genmap`, `makenek`, and `nekmpi`. |
| `gen_test_mat.sh` | **Test matrix generator.** Shell script that prints a list of (Reynolds Number, Mesh File) pairs to standard output, which is typically piped to `test_matrix.txt`. |
| `test_matrix.txt` | Defines the specific combinations of Reynolds numbers and mesh files to be run by `run_cases_local.sh`. |
| `template.par` | **Nek5000 parameter file.** Contains the default simulation settings, including time stepping, problem type (`incompNS + heat`), and placeholders for Re/AoA which are updated by the run script. |
| `template.usr` | **Nek5000 user file (Fortran).** Contains user-defined routines for boundary conditions, body forces (e.g., buoyancy), and, critically, the routines (`set_obj`) to calculate lift and drag coefficients. |
| `SIZE` | **Nek5000 dimensioning file.** Defines array and grid sizes for the solver (e.g., 2D simulation, N_{GLL}=8). |
| `mesh##.re2` | Nek5000 geometry/mesh files. The `##` is interpreted by the run script to be the Angle of Attack (\alpha) in degrees. |
| `plot_data_summary.py` | **Post-processing script.** Reads the extracted drag/lift CSV files from the `results/` directory and generates summary plots. |

##WorkflowFollow these steps to generate and run the test matrix, and then visualize the results:

###1. Generate the Test MatrixThe `gen_test_mat.sh` script generates the list of cases to run.

```bash
# Ensure the script is executable
chmod +x gen_test_mat.sh

# Generate the matrix (this will overwrite the existing file)
./gen_test_mat.sh > test_matrix.txt

```

###2. Run the SimulationsThe `run_cases_local.sh` script will create a new subdirectory (`results/ReXX_AOAXX/`) for each case defined in `test_matrix.txt`, execute the simulation, and extract the coefficients.

**Note:** Ensure all template files (`.par`, `.usr`, `SIZE`, and all `.re2` meshes) are in the same directory as the script before running.

```bash
# Ensure the script is executable
chmod +x run_cases_local.sh

# Run the simulations
./run_cases_local.sh

```

###3. Analyze and Plot ResultsThe Python script reads the `.csv` output files generated during the simulation runs and creates summary plots. The plots will be saved in the `results/` directory.

```bash
python3 plot_data_summary.py

```

##ResultsAfter execution, the `results/` directory will contain:

* **Case Directories**: Subdirectories named `ReXXX_AOAXX` (e.g., `Re100_AOA00`, `Re1000_AOA12`), each containing the simulation files, log file, and coefficient CSVs (`drag_...csv`, `lift_...csv`).
* **Plot Images**: PNG files summarizing the study:
* `drag_coefficient_vs_aoa.png`
* `lift_coefficient_vs_aoa.png`
* `lift_to_drag_ratio_vs_aoa.png`
