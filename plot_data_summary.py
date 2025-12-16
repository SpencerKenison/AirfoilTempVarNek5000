import pandas as pd
import matplotlib.pyplot as plt
import os
import re
import glob

# --- Configuration ---
input_dir = 'results'
output_dir = 'results'

summary_data = []
regex = re.compile(r'(drag|lift)_Re(\d+)_aoa(\d+)\.csv')

# Find all CSV files in the input directory
file_paths = glob.glob(os.path.join(input_dir, '*.csv'))

for file_path in file_paths:
    file_name = os.path.basename(file_path)
    match = regex.match(file_name)

    if match:
        coeff_type = match.group(1)
        reynolds = int(match.group(2))
        aoa = int(match.group(3))

        try:
            df = pd.read_csv(file_path, header=None)

            if df.shape[1] >= 3 and not df.empty:
                final_coeff = df.iloc[-1, 2]
                summary_data.append({
                    'Coefficient_Type': coeff_type,
                    'Re': reynolds,
                    'AoA': aoa,
                    'Final_Coefficient': final_coeff
                })
            else:
                print(f"Skipping file {file_name}: Empty or malformed (expected at least 3 columns).")

        except Exception as e:
            print(f"Error processing file {file_name}: {e}")

summary_df = pd.DataFrame(summary_data)

if summary_df.empty:
    print("\nERROR: No data was successfully processed. Check that:")
    print("1. Your input files are in the specified directory.")
    print("2. Filenames match '(drag|lift)_Re<number>_aoa<number>.csv'.")
    print("3. Files contain data with ≥3 columns.")
    exit()

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

summary_csv_path = os.path.join(output_dir, 'summary_coefficients_lift_drag.csv')
summary_df.to_csv(summary_csv_path, index=False)

# 1. Plot Cd
drag_df = summary_df[summary_df['Coefficient_Type'] == 'drag']

if not drag_df.empty:
    fig_drag, ax_drag = plt.subplots(figsize=(8, 6))
    for re_value in sorted(drag_df['Re'].unique()):
        subset = drag_df[drag_df['Re'] == re_value].sort_values(by='AoA')
        ax_drag.plot(subset['AoA'], subset['Final_Coefficient'], marker='o', linestyle='-', label=f'Re = {re_value}')
    ax_drag.set_xlabel('Angle of Attack, α (deg)', fontsize=14)
    ax_drag.set_ylabel('Drag Coefficient, Cd', fontsize=14)
    ax_drag.tick_params(axis='both', which='major', labelsize=12)
    ax_drag.legend(loc='best', fontsize=12, frameon=False)
    ax_drag.grid(False)
    fig_drag.tight_layout()
    fig_drag.savefig(os.path.join(output_dir, 'drag_coefficient_vs_aoa.png'))
    plt.close(fig_drag)

# 2. Plot Cl
lift_df = summary_df[summary_df['Coefficient_Type'] == 'lift']

if not lift_df.empty:
    fig_lift, ax_lift = plt.subplots(figsize=(8, 6))
    for re_value in sorted(lift_df['Re'].unique()):
        subset = lift_df[lift_df['Re'] == re_value].sort_values(by='AoA')
        ax_lift.plot(subset['AoA'], subset['Final_Coefficient'], marker='s', linestyle='-', label=f'Re = {re_value}')
    ax_lift.set_xlabel('Angle of Attack, α (deg)', fontsize=14)
    ax_lift.set_ylabel('Lift Coefficient, Cl', fontsize=14)
    ax_lift.tick_params(axis='both', which='major', labelsize=12)
    ax_lift.legend(loc='best', fontsize=12, frameon=False)
    ax_lift.grid(False)
    fig_lift.tight_layout()
    fig_lift.savefig(os.path.join(output_dir, 'lift_coefficient_vs_aoa.png'))
    plt.close(fig_lift)

# 3. L/D Plot 
# Merge lift and drag into one table per Re-AoA pair
lift_df_ren = lift_df.rename(columns={'Final_Coefficient': 'Cl'})
drag_df_ren = drag_df.rename(columns={'Final_Coefficient': 'Cd'})

merged = pd.merge(lift_df_ren[['Re','AoA','Cl']],
                  drag_df_ren[['Re','AoA','Cd']],
                  on=['Re','AoA'],
                  how='inner')

# Compute L/D
merged['L_over_D'] = merged['Cl'] / merged['Cd']

# Plot L/D vs AoA
if not merged.empty:
    fig_ld, ax_ld = plt.subplots(figsize=(8, 6))
    for re_value in sorted(merged['Re'].unique()):
        subset = merged[merged['Re'] == re_value].sort_values(by='AoA')
        ax_ld.plot(subset['AoA'], subset['L_over_D'], marker='^', linestyle='-', label=f'Re = {re_value}')
    ax_ld.set_xlabel('Angle of Attack, α (deg)', fontsize=14)
    ax_ld.set_ylabel('Lift-to-Drag Ratio, L/D', fontsize=14)
    ax_ld.tick_params(axis='both', which='major', labelsize=12)
    ax_ld.legend(loc='best', fontsize=12, frameon=False)
    ax_ld.grid(False)
    fig_ld.tight_layout()
    fig_ld.savefig(os.path.join(output_dir, 'LD_vs_aoa.png'))
    plt.close(fig_ld)

print(f"\nSummary data saved to: {summary_csv_path}")
print("C_L, C_D, and L/D plots saved results folder.")
print("Script execution completed successfully.")
