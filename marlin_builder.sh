#!/bin/bash

flags=""
build_env="FF_F407ZG"
project_dir="Marlin"
fw_path=$project_dir"/.pio/build/"$build_env
fw_tool_dir="flashforge_firmware_tool"
build_silent="--silent"
SIZE=arm-none-eabi-size

function usage()
{
   cat << usage_info

   Usage: $(basename $0) -m <machine> [-s] [-l]

   arguments:
     -h           show this help message and exit
     -m           machine name ( nx/dreamer/inventor )
     -s           swap extruders ( for dreamer and inventor machines )
     -l           enable linear advance ( pressure control algo )
     -u           old style GUI
     -v           verbose build
     
   example:
     $(basename $0) -m dreamer -s -l
usage_info
}

if ! hash -r python3; then
   echo "python3 is not installed"
   exit
fi

if ! hash -r platformio; then
   echo "platformio is not installed"
   exit
fi

if [ ! -x $fw_tool_dir/ff_fw_tool ]
then
   echo "Build FF FW tool..."
   gcc $fw_tool_dir/main.c -o $fw_tool_dir/ff_fw_tool
   if [[ $? -eq 0 ]]
   then
    echo "done"
   else
    echo "failed"
    exit
   fi
fi

while getopts "m:slhvu" opt
do
   case "$opt" in
      m ) machine="$OPTARG" ;;
      s ) flags+="-DFF_EXTRUDER_SWAP " ;;
      l ) flags+="-DLIN_ADVANCE " ;;
      u ) flags+="-DUSE_OLD_MARLIN_UI " ;;
      v ) build_silent="" ;;
      ? | h ) usage; exit ;;
   esac
done

if [[ "$machine" == "nx" ]]
then
   flags+="-DFF_DREAMER_NX_MACHINE"
elif [[ "$machine" == "dreamer" ]]
then
   flags+="-DFF_DREAMER_MACHINE"
elif [[ "$machine" == "inventor" ]]
then
   flags+="-DFF_INVENTOR_MACHINE"
else
   usage
   exit
fi

PLATFORMIO_BUILD_FLAGS="$flags"
export PLATFORMIO_BUILD_FLAGS
echo "Flags: " $PLATFORMIO_BUILD_FLAGS
echo "Clean..."
platformio run --project-dir $project_dir --target clean -e $build_env $build_silent
echo "Build..."
platformio run --project-dir $project_dir -e $build_env $build_silent

if [[ $? -eq 0 ]]
then
   echo -e "Build OK\nEncode firmware..."
   if hash -r $SIZE; then
      $SIZE --format=berkeley $fw_path/firmware.elf
   fi
   mkdir -p $machine"_build"
   $(pwd)/$fw_tool_dir/ff_fw_tool -e -i $fw_path/firmware.bin -o $machine"_build/fw_"$machine"_"`date +"%m_%d_%Y"`".bin"
else
   echo "Build failed"
fi



