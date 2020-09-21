#!/bin/bash


# Adapted from
# https://github.com/stnava/ANTs/blob/51b08bb5ab03275df81f6c7047ab7d2d59705c8a/Scripts/antsRegistrationSyNQuick.sh
# https://github.com/stnava/ANTs/blob/51b08bb5ab03275df81f6c7047ab7d2d59705c8a/Scripts/antsBrainExtraction.sh


VERSION="0.0.0 test"


echo "---------------------  Running `basename $0` on `hostname`  ---------------------"


function setPath {
    cat <<SETPATH

--------------------------------------------------------------------------------------
Error locating ANTS
--------------------------------------------------------------------------------------
It seems that the ANTSPATH environment variable is not set. Please add the ANTSPATH
variable. This can be achieved by editing the .bash_profile in the home directory.
Add:

ANTSPATH=/home/yourname/bin/ants/

Or the correct location of the ANTS binaries.

Alternatively, edit this script ( `basename $0` ) to set up this parameter correctly.

SETPATH
    exit 1
}

# Uncomment the line below in case you have not set the ANTSPATH variable in your environment.
# export ANTSPATH=${ANTSPATH:="$HOME/bin/ants/"} # EDIT THIS

#ANTSPATH=YOURANTSPATH
if [[ ${#ANTSPATH} -le 3 ]];
  then
    setPath >&2
  fi


ANTS=${ANTSPATH}/antsRegistration
N4=${ANTSPATH}/N4BiasFieldCorrection


if [[ ! -s ${ANTS} ]];
  then
    echo "antsRegistration program can't be found. Please (re)define \$ANTSPATH in your environment."
    exit
  fi

if [[ ! -s ${N4} ]];
  then
    echo we cant find the N4 program -- does not seem to exist.  please \(re\)define \$ANTSPATH in your environment.
    exit
  fi


function Help {
    cat <<HELP

Usage:

`basename $0` -f FixedImage -l List -i Index -x FixedMask -o OutputFile


Compulsory arguments:

     -f:  Fixed image or source image or reference image

     -o:  Output final warped file

     -x:  Mask for the fixed image space

     -i:  Input moving image to be processed

Optional arguments:

     -n:  Number of threads (default = 1)

     -t:  transform type (default = 's')
        t: translation
        r: rigid
        a: rigid + affine
        s: rigid + affine + deformable syn
        sr: rigid + deformable syn
        so: deformable syn only
        b: rigid + affine + deformable b-spline syn
        br: rigid + deformable b-spline syn
        bo: deformable b-spline syn only

--------------------------------------------------------------------------------------
Get the latest ANTs version at:
--------------------------------------------------------------------------------------
https://github.com/stnava/ANTs/

--------------------------------------------------------------------------------------
Read the ANTS documentation at:
--------------------------------------------------------------------------------------
http://stnava.github.io/ANTs/

--------------------------------------------------------------------------------------
ANTS was created by:
--------------------------------------------------------------------------------------
Brian B. Avants, Nick Tustison and Gang Song
Penn Image Computing And Science Laboratory
University of Pennsylvania

Relevent references for this script include:
   * http://www.ncbi.nlm.nih.gov/pubmed/20851191
   * http://www.frontiersin.org/Journal/10.3389/fninf.2013.00039/abstract
--------------------------------------------------------------------------------------
script by Nick Tustison
--------------------------------------------------------------------------------------

HELP
    exit 1
}

function reportMappingParameters {
    cat <<REPORTMAPPINGPARAMETERS

--------------------------------------------------------------------------------------
 Mapping parameters
--------------------------------------------------------------------------------------
 ANTSPATH is $ANTSPATH

 Dimensionality:           $DIM
 Temporary output files:   $OUTPUTNAME
 Output file:              $FINALFILE
 Fixed images:             ${FIXEDIMAGES[@]}
 List of images:           $LIST
 Index:                    $INDEX
 Moving images:            ${MOVINGIMAGES[@]}
 Number of threads:        $NUMBEROFTHREADS
 Spline distance:          $SPLINEDISTANCE
 Transform type:           $TRANSFORMTYPE
 MI histogram bins:        $NUMBEROFBINS
 Precision:                $PRECISIONTYPE
 Use histogram matching    $USEHISTOGRAMMATCHING
======================================================================================
REPORTMAPPINGPARAMETERS
}


# Provide output for Help
if [[ "$1" == "-h" || $# -eq 0 ]];
  then
    Help >&2
  fi




function cleanup() {
  cmd="rm -rfv $TMPDIR"
  echo "Cleanup: $cmd"
  $cmd
}


# Echos a command to stdout, then runs it
# Will immediately exit on error unless you set debug flag here
DEBUG_MODE=0

function logCmd() {

  time_start=$(date +%s)

  cmd="$*"
  echo "BEGIN >>>>>>>>>>>>>>>>>>>>"
  echo $cmd
  $cmd

  cmdExit=$?

  if [[ $cmdExit -gt 0 ]];
    then
      echo "ERROR: command exited with nonzero status $cmdExit"
      echo "Command: $cmd"
      echo
      if [[ ! $DEBUG_MODE -gt 0 ]];
        then
          cleanup
          exit 1
        fi
    fi

  echo "END   <<<<<<<<<<<<<<<<<<<<"

  time_end=$(date +%s)
  time_elapsed=$((time_end - time_start))

  echo " Done in  $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s"

  echo
  echo

  return $cmdExit
}




#################
#
# default values
#
#################

DIM=3
FIXEDIMAGES=()
MOVINGIMAGES=()
OUTPUTNAME=output
NUMBEROFTHREADS=1
SPLINEDISTANCE=26
TRANSFORMTYPE='s'
PRECISIONTYPE='d'
NUMBEROFBINS=32
MASK=0
USEHISTOGRAMMATCHING=0


N4_CONVERGENCE_1="[50x50x50x50,0.0000001]"
N4_SHRINK_FACTOR_1=4
N4_BSPLINE_PARAMS="[200]"


# reading command line arguments
while getopts "f:h:i:l:n:o:t:x:" OPT
  do
  case $OPT in
      h) #help
   Help
   exit 0
   ;;
      f)  # fixed image
   FIXEDIMAGES[${#FIXEDIMAGES[@]}]=$OPTARG
   ;;
      x)  # inclusive mask
   MASK=$OPTARG
   ;;
      n)  # number of threads
   NUMBEROFTHREADS=$OPTARG
   ;;
      o) #output file
   FINALFILE=$OPTARG
   ;;
      t)  # transform type
   TRANSFORMTYPE=$OPTARG
   ;;
      i)  # input file
   MOVINGIMAGES[0]=$OPTARG
   ;;
     \?) # getopts issues an error message
   echo "$USAGE" >&2
   exit 1
   ;;
  esac
done


# Extract moving image from list and index
#SED_INDEX=$(($INDEX + 1))
#MOVINGIMAGES[0]=$(sed -n "${SED_INDEX}{p;q}" "${LIST}")

# Define temporary dir and files
NAME=$(basename ${MOVINGIMAGES[0]} | sed -e s,.nii$,, -e s,.nii.gz$,,)
TMPDIR=$(mktemp -d)'/'
OUTPUTNAME=$TMPDIR$NAME
WARPEDFILE=${OUTPUTNAME}'_Warped.nii.gz'
BRAINFILE=${OUTPUTNAME}'_Brain.nii.gz'

# Define output file
#FINALFILE=$OUTPUTDIR'/'$NAME'-Processed-.nii.gz'

if [[ -f ${FINALFILE} ]]; then
    #echo "Output file already exists: $FINALFILE"
    #exit 0
    rm "$FINALFILE"
fi

# Create directories
cleanup
logCmd mkdir -pv $TMPDIR
#logCmd mkdir -pv $OUTPUTDIR



###############################
#
# Check inputs
#
###############################
if [[ ${#FIXEDIMAGES[@]} -ne ${#MOVINGIMAGES[@]} ]];
  then
    echo "Number of fixed images is not equal to the number of moving images."
    exit 1
  fi

for(( i=0; i<${#FIXEDIMAGES[@]}; i++ ))
  do
    if [[ ! -f "${FIXEDIMAGES[$i]}" ]];
      then
        echo "Fixed image '${FIXEDIMAGES[$i]}' does not exist.  See usage: '$0 -h 1'"
        exit 1
      fi
    if [[ ! -f "${MOVINGIMAGES[$i]}" ]];
      then
        echo "Moving image '${MOVINGIMAGES[$i]}' does not exist.  See usage: '$0 -h 1'"
        exit 1
      fi
  done

###############################
#
# Set number of threads
#
###############################

ORIGINALNUMBEROFTHREADS=${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS}
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NUMBEROFTHREADS
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

##############################
#
# Print out options
#
##############################

reportMappingParameters




##############################
#
# N4 Bias Correction
#
##############################

echo
echo "--------------------------------------------------------------------------------------"
echo " Bias correction of anatomical images (pre brain extraction)"
echo "   1) pre-process by truncating the image intensities"
echo "   2) run N4"
echo "--------------------------------------------------------------------------------------"
echo

N4_TRUNCATED_IMAGE=${OUTPUTNAME}'_N4Truncated.nii.gz'
N4_CORRECTED_IMAGE=${OUTPUTNAME}'_N4Corrected.nii.gz'

logCmd ${ANTSPATH}/ImageMath ${DIM} ${N4_TRUNCATED_IMAGE} TruncateImageIntensity ${MOVINGIMAGES[0]} 0.01 0.999 256

exe_n4_correction="${N4} -d ${DIM} -i ${N4_TRUNCATED_IMAGE} -s ${N4_SHRINK_FACTOR_1} -c ${N4_CONVERGENCE_1} -b ${N4_BSPLINE_PARAMS} -o ${N4_CORRECTED_IMAGE}"
logCmd $exe_n4_correction


MOVINGIMAGES[0]=$N4_CORRECTED_IMAGE



##############################
#
# Infer the number of levels based on
# the size of the input fixed image.
#
##############################

ISLARGEIMAGE=0

SIZESTRING=$( ${ANTSPATH}/PrintHeader ${FIXEDIMAGES[0]} 2 )
SIZESTRING="${SIZESTRING%\\n}"
SIZE=( `echo $SIZESTRING | tr 'x' ' '` )

for (( i=0; i<${#SIZE[@]}; i++ ))
  do
    if [[ ${SIZE[$i]} -gt 256 ]];
      then
        ISLARGEIMAGE=1
        break
      fi
  done

##############################
#
# Construct mapping stages
#
##############################

RIGIDCONVERGENCE="[1000x500x250x0,1e-6,10]"
RIGIDSHRINKFACTORS="8x4x2x1"
RIGIDSMOOTHINGSIGMAS="3x2x1x0vox"

AFFINECONVERGENCE="[1000x500x250x0,1e-6,10]"
AFFINESHRINKFACTORS="8x4x2x1"
AFFINESMOOTHINGSIGMAS="3x2x1x0vox"

SYNCONVERGENCE="[100x70x50x0,1e-6,10]"
SYNSHRINKFACTORS="8x4x2x1"
SYNSMOOTHINGSIGMAS="3x2x1x0vox"

if [[ $ISLARGEIMAGE -eq 1 ]];
  then
    RIGIDCONVERGENCE="[1000x500x250x0,1e-6,10]"
    RIGIDSHRINKFACTORS="12x8x4x2"
    RIGIDSMOOTHINGSIGMAS="4x3x2x1vox"

    AFFINECONVERGENCE="[1000x500x250x0,1e-6,10]"
    AFFINESHRINKFACTORS="12x8x4x2"
    AFFINESMOOTHINGSIGMAS="4x3x2x1vox"

    SYNCONVERGENCE="[100x100x70x50x0,1e-6,10]"
    SYNSHRINKFACTORS="10x6x4x2x1"
    SYNSMOOTHINGSIGMAS="5x3x2x1x0vox"
  fi

tx=Rigid
if [[ $TRANSFORMTYPE == 't' ]] ; then
  tx=Translation
fi

INITIALSTAGE="--initial-moving-transform [${FIXEDIMAGES[0]},${MOVINGIMAGES[0]},1]"

RIGIDSTAGE="--transform ${tx}[0.1] \
            --metric MI[${FIXEDIMAGES[0]},${MOVINGIMAGES[0]},1,32,Regular,0.25] \
            --convergence $RIGIDCONVERGENCE \
            --shrink-factors $RIGIDSHRINKFACTORS \
            --smoothing-sigmas $RIGIDSMOOTHINGSIGMAS"

AFFINESTAGE="--transform Affine[0.1] \
             --metric MI[${FIXEDIMAGES[0]},${MOVINGIMAGES[0]},1,32,Regular,0.25] \
             --convergence $AFFINECONVERGENCE \
             --shrink-factors $AFFINESHRINKFACTORS \
             --smoothing-sigmas $AFFINESMOOTHINGSIGMAS"

SYNMETRICS=''
for(( i=0; i<${#FIXEDIMAGES[@]}; i++ ))
  do
    SYNMETRICS="$SYNMETRICS --metric MI[${FIXEDIMAGES[$i]},${MOVINGIMAGES[$i]},1,${NUMBEROFBINS}]"
  done

SYNSTAGE="${SYNMETRICS} \
          --convergence $SYNCONVERGENCE \
          --shrink-factors $SYNSHRINKFACTORS \
          --smoothing-sigmas $SYNSMOOTHINGSIGMAS"

if [[ $TRANSFORMTYPE == 'sr' ]] || [[ $TRANSFORMTYPE == 'br' ]];
  then
    SYNCONVERGENCE="[50x0,1e-6,10]"
    SYNSHRINKFACTORS="2x1"
    SYNSMOOTHINGSIGMAS="1x0vox"
          SYNSTAGE="${SYNMETRICS} \
          --convergence $SYNCONVERGENCE \
          --shrink-factors $SYNSHRINKFACTORS \
          --smoothing-sigmas $SYNSMOOTHINGSIGMAS"
  fi

if [[ $TRANSFORMTYPE == 'b' ]] || [[ $TRANSFORMTYPE == 'br' ]] || [[ $TRANSFORMTYPE == 'bo' ]];
  then
    SYNSTAGE="--transform BSplineSyN[0.1,${SPLINEDISTANCE},0,3] \
             $SYNSTAGE"
  fi

if [[ $TRANSFORMTYPE == 's' ]] || [[ $TRANSFORMTYPE == 'sr' ]] || [[ $TRANSFORMTYPE == 'so' ]];
  then
    SYNSTAGE="--transform SyN[0.1,3,0] \
             $SYNSTAGE"
  fi

STAGES=''
case "$TRANSFORMTYPE" in
"r" | "t")
  STAGES="$INITIALSTAGE $RIGIDSTAGE"
  ;;
"a")
  STAGES="$INITIALSTAGE $RIGIDSTAGE $AFFINESTAGE"
  ;;
"b" | "s")
  STAGES="$INITIALSTAGE $RIGIDSTAGE $AFFINESTAGE $SYNSTAGE"
  ;;
"br" | "sr")
  STAGES="$INITIALSTAGE $RIGIDSTAGE  $SYNSTAGE"
  ;;
"bo" | "so")
  STAGES="$INITIALSTAGE $SYNSTAGE"
  ;;
*)
  echo "Transform type '$TRANSFORMTYPE' is not an option.  See usage: '$0 -h 1'"
  exit
  ;;
esac

PRECISION=''
case "$PRECISIONTYPE" in
"f")
  PRECISION="--float 1"
  ;;
"d")
  PRECISION="--float 0"
  ;;
*)
  echo "Precision type '$PRECISIONTYPE' is not an option.  See usage: '$0 -h 1'"
  exit
  ;;
esac


if [[ ${#MASK} -lt 3 ]] ; then
  echo "Mask must be specified.  See usage: '$0 -h 1'"
  exit
fi


COMMAND="${ANTS} \
                 --dimensionality $DIM $PRECISION \
                 --output [$OUTPUTNAME,$WARPEDFILE] \
                 --interpolation Linear \
                 --use-histogram-matching ${USEHISTOGRAMMATCHING} \
                 --winsorize-image-intensities [0.005,0.995] \
                 $STAGES"

echo " antsRegistration call"
echo "--------------------------------------------------------------------------------------"


# Run registration
logCmd $COMMAND



###############################
#
# Extract brain from warped MRI
#
###############################

logCmd ${ANTSPATH}/MultiplyImages ${DIM} ${WARPEDFILE} ${MASK} ${BRAINFILE}



###############################
#
# Normalize intensities
#
###############################

logCmd ${ANTSPATH}/ImageMath ${DIM} ${FINALFILE} Normalize ${BRAINFILE}




###############################
#
# Clean up
#
###############################

cleanup




###############################
#
# Restore original number of threads
#
###############################

ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$ORIGINALNUMBEROFTHREADS
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS




###############################
#
# End of main routine
#
###############################

echo
echo "Success"

exit 0

