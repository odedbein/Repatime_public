#! /bin/bash

# Beta version of a script to preprocess SMS-EPI data from the Prisma scanner
# Written by Michael Waskom | Last updated June 15, 2017

if [ "$#" -ne 3 ]; then
    echo '

USAGE: prisma_preproc.sh <se> <se_rev> <wd>

Parameter Information:
  
  se : 4D spin echo EPI image with phase encoding corresponding to timeseries
  se_rev : 4D spin echo EPI image with reversed phase encoding
  wd : working directory for writing intermediate outputs
  
Notes:

- Assumes that the anatomical data for subject <subj> have been processed with
  recon-all and that $SUBJECTS_DIR is set correctly
- Assumes that phase encoding was performed in either the AP or PA direction
- Does not currently write files anywhere other than <wd>


'
    exit 1
fi

# Don't continue past errors
set -e

# Process command line arguments
se=$1
se_rev=$2
wd=$3

# Ensure working directory is exists
mkdir -p $wd

# --- Warpfield estimation using TOPUP

# Create a phase encoding parameters file to use

se_params=$wd/se_params.txt

if [ -e $se_params ]; then
    rm $se_params
fi

se_frames=`fslval $se dim4`

for i in $(seq 1 $se_frames); do
    echo "0 1 0 1" >> $se_params
done
for i in $(seq 1 $se_frames); do
    echo "0 -1 0 1" >> $se_params
done

# Concatenate the pair of spin-echo scans

se_pair=$wd/se_pair.nii.gz
fslmerge -t $se_pair $se $se_rev


# Run topup to estimate the distortions

topup --imain=$se_pair \
      --datain=$se_params \
      --config=b02b0.cnf \
      --out=$wd/topup \
      --iout=$wd/se_pair_unwarped \
      --dfout=$wd/topup_warp \
      --rbmout=$wd/topup_xfm \
      --verbose
