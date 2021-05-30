# Plot blood glucose level

import pandas as pd
import matplotlib.pyplot as plt
import argparse

parser = argparse.ArgumentParser()

parser.add_argument(
    "--data_file",
    type=str,
    required=True,
    help="Data file containing bgt data."
)

args = parser.parse_args()

file_name = args.data_file
df = pd.read_csv(file_name)
fig, ax = plt.subplots()
df.plot("Date", "BG", ax=ax, marker=".", grid=True, xlabel="Dates", ylabel="Blood Glucose Level")
fig.savefig("/tmp/bgt.pdf")
