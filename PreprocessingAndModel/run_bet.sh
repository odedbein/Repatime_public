#! /bin/bash -u
# Author: David Clewett, modified by Oded Bein
# Dave's version (from Avi) can be found in my folder "preprocessingAvi"


if [ $# -ne 2 ]; then
  echo "
usage: `basename $0` subj_anatomy_dir, image (t1/t2)

This script runs bet until you are happy with the reuslts
"
  exit
fi

root2=$1
image=$2

echo "running bet on $image"


answer="no"


# create while loop so that BET keeps being re-done until "yes" answer is typed
while [ "$answer" == "no" ]; do

	
	echo "Pulling up FSLEYES; please find center of brain and record the X, Y, and Z coordinates. When finished, close the FSLEYES window"
	fsleyes $root2/${image}.nii.gz
	
	answer_c="yes"
	while [ "$answer_c" == "yes" ]; do

	   echo "Please enter X coordinate: "
	   read X

	   echo "Please enter Y coordinate: "
	   read Y

	   echo "Please enter Z coordinate: "
	   read Z
	
		echo "Running BET now..."
	
		#run bet with parameters selected
		bet $root2/${image}.nii.gz $root2/${image}_brain.nii.gz -f 0.5 -g 0 -c $X $Y $Z
	
		echo "Pulling up FSLVIEW; examine the brain overlay. When finished checking, close the FSLVIEW window"
	
		#open the images to see how they look as an overlap
		fsleyes $root2/${image}.nii.gz -cm Greyscale $root2/${image}_brain.nii.gz -cm Hot
	
		#indicate whether the BET looks good
		echo "do you want to re-define the center? type yes or no"
		read answer_c
	done
	
	echo "Are you satisfied with this image?: type yes or no, if no, we'll continue"
	read answer4
	
	while [ "$answer4" == "no" ]; do
		
		echo "would you like to use the -B option? it takes time, consider re-defining your center"
		read answerB
		
		if [ "$answerB" != "no" ] && [ "$answerB" != "yes" ]; then
			echo "would you like to use the -B option? it takes time, consider re-defining your center"
			read answerB
		fi
		
		echo "would you like to use the -S option? it takes time, but may help to remove the optic nerves"
		read answerS
		
		if [ "$answerS" != "no" ] && [ "$answerS" != "yes" ]; then
			echo "would you like to use the -S option? it takes time, consider re-defining your center"
			read answerS
		fi
		
		echo "Please type new F parameter: Smaller values give larger brain outline estimates (less chopping). 0.5 is the default. Try going up or down by incremements of 0.1 depending on how large you want the whole brain to look; e.g., 0.6 would chop more of the brain and give it a smaller outline. Please type value:"
		read answerF
		
		echo "Please type new G parameter: Positive values give larger brain outline estimates at bottom, smaller at top. 0 is the default. Try going up or down by incremements of 0.05 depending on how much of the bottom/top you want to chop (negative values are ok); e.g., -0.05 would chop more of the brain at the bottom and give it a slightly larger outline on top. A value of -.10 would chop even more off the bottom. Please type value:"
		read answerG
		
		echo "Running new BET..."
		if [ "$answerB" == "no" ]; then
			if [ "$answerS" == "no" ]; then
				bet $root2/${image}.nii.gz $root2/${image}_brain.nii.gz -f $answerF -g $answerG -c $X $Y $Z
			else
				bet $root2/${image}.nii.gz $root2/${image}_brain.nii.gz -f $answerF -g $answerG -c $X $Y $Z -S
			fi
			
		else
			if [ "$answerS" == "no" ]; then
				bet $root2/${image}.nii.gz $root2/${image}_brain.nii.gz -f $answerF -g $answerG -c $X $Y $Z -B
			else
				bet $root2/${image}.nii.gz $root2/${image}_brain.nii.gz -f $answerF -g $answerG -c $X $Y $Z -B -S
			fi
		fi
	
		echo "Loading new brain...remember to close window when finished"
		fsleyes $root2/${image}.nii.gz -cm Greyscale $root2/${image}_brain.nii.gz -cm Hot
	
		echo "Are you satisfied with this image?: type yes or no"
		read answer4
	
	done
	
#Final indication of whether you like outcome. Otherwise, goes back to beginning
echo "Does BET look ok?: type yes or no"
read answer	

done
		
		
