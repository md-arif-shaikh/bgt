# Plot blood glucose level
# This part of the Emacs package `bgt`
# Copyright (C) 2021  Md Arif Shaikh
# Author: Md Arif Shaikh
# Email: arifshaikh.astro@gmail.com
# Version: 0.1.0

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import pandas as pd
import matplotlib.pyplot as plt
import argparse
from datetime import datetime

parser = argparse.ArgumentParser()

parser.add_argument(
    "--data_file",
    type=str,
    required=True,
    help="Data file containing bgt data."
)
parser.add_argument(
    "--plot_file",
    type=str,
    required=True,
    help="file name for plot."
)
parser.add_argument(
    "--start_date",
    type=str,
    required=True,
    help="Start date for range of plot."
)
parser.add_argument(
    "--end_date",
    type=str,
    required=True,
    help="End date for range of plot."
)

args = parser.parse_args()

data_file = args.data_file
plot_file = args.plot_file
start_date = args.start_date
end_date = args.end_date

df = pd.read_csv(data_file)
start_date = datetime.strptime(start_date, "%Y-%m-%d")
end_date = datetime.strptime(end_date, "%Y-%m-%d")

df["date"] = [datetime.strptime(date[:10], "%Y-%m-%d") for date in df.Date]
df_fasting = df.loc[(df.Category == "Fasting")
                    & ((df.date >= start_date) & (df.date <= end_date))]
df_random = df.loc[(df.Category == "Random")
                   & ((df.date >= start_date) & (df.date <= end_date))]
df_pp = df.loc[(df.Category == "Post-prandial")
               & ((df.date >= start_date) & (df.date <= end_date))]

fig, ax = plt.subplots(figsize=(6, 4))
ax.plot(df_fasting["date"], df_fasting["BG"], marker=".", label="Fasting")
ax.plot(df_random["date"], df_random["BG"], marker=".", label="Random")
ax.plot(df_pp["date"], df_pp["BG"], marker=".", label="PP")
ax.legend()
ax.grid(ls="--")
ax.axhline(130, c="tab:blue", alpha=0.5)
ax.axhline(180, c="tab:green", alpha=0.5)
ax.set_ylabel("Glucose level")
ax.set_xlabel("Dates")
plt.xticks(rotation=45)
plt.subplots_adjust(bottom=0.25, top=0.95, right=0.95)

fig.savefig(plot_file)
