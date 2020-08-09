# Set these variables accordingly before executing the script
#export VIVADO=/opt/Xilinx/Vivado/2018.2/bin/vivado
export VIVADO=/home/lsa/xilinx/2018.2/Vivado/2018.2/bin/vivado
export VIVADO_DESIGN_NAME=ps_hermes
export VIVADO_TOP_NAME=${VIVADO_DESIGN_NAME}_wrapper
export XIL_APP_NAME=dma_test

if [ -f $VIVADO ]; then
  echo "###################################"
  echo "### Creating the Vivado Project ###"
  echo "###################################"
  $VIVADO -mode batch -source build.tcl -notrace
  echo "#########################"
  echo "######## Synthesis ######"
  echo "#########################"
  $VIVADO -mode batch -source build_bitstream_export_sdk.tcl -notrace
  # count xml files to decide whether this project is a leaf custom IP or a design that uses custom IPs
  # For instance, considering this command executed in the project root dir:
  #$ find hw/ips/*/ -name *.xml
  # This is a typical output of a design that uses 3 custom IPs
  #hw/ips/hermes-router-axis-ip/hw/ips/hermes_router_axis_ip/component.xml
  #hw/ips/m-axis-dip-ip/hw/ips/m_axis_dip_ip/component.xml
  #hw/ips/s-axis-led-ip/hw/ips/s_axis_led_ip/component.xml
  # However, a leaf custom IP (i.e. and IP that does not use other custom IPs) would have this kind of file tree
  #hw/ips/axis_s_const/component.xml
  # In summary, if the component.xml is found 3 dir layers below the root dir, then this project is a leaf custom IP
  # if the component.xml is found in more than 3 dir layers, then this project uses custom IPs
  # Finally, there is no component.xml at all under hw/ips, then this project does not use any custom IP
  leafIPs=$(find hw/ips/*/ -maxdepth 1 -name *.xml | wc -l) 
  if [ "$leafIPs" -eq 0 ]; 
  then
    echo "#########################"
    echo "### Loading bitstream ###"
    echo "#########################"
    $VIVADO -mode batch -source download_bitstream.tcl -notrace
    echo "#########################"
    echo "### Bitstream loaded ####"
    echo "#########################"
  fi;
  # check whether there is any software to be compiled, i.e., if there is any dir inside src/
  list_dirs=`ls -d ./src/*/ 2> /dev/null`
  # build a bash list 
  has_software=($list_dirs)
  # check if len(list) > 0
  if [ "${#has_software[@]}" -gt 0 ]; 
  then
    echo "#########################"
    echo "### Compiling w SDK  ###"
    echo "#########################"
    xsct sdk.tcl
    echo "####################################"
    echo "### End of software compilation  ###"
    echo "####################################"
    echo "execute the following command to launch SDK GUI"
    echo "xsdk -workspace ./vivado/${VIVADO_DESIGN_NAME}/${VIVADO_DESIGN_NAME}.sdk/ -hwspec ./vivado/${VIVADO_DESIGN_NAME}/${VIVADO_DESIGN_NAME}.sdk/${VIVADO_DESIGN_NAME}.hdf"
    echo "#########################"
    echo "## Loading application ##"
    echo "#########################"
    xsct download_elf.tcl
    echo "#########################"
    echo "## Application loaded ###"
    echo "#########################"
  fi;
elif [ -f ~/.bash_aliases ]; then
  echo ""
  echo "###############################"
  echo "### Failed to locate Vivado ###"
  echo "###############################"
  echo ""
  echo "This script file 'build.sh' did not find Vivado installed in:"
  echo ""
  echo "    $VIVADO"
  echo ""
  echo "Fix the problem by doing one of the following:"
  echo ""
  echo " 1. If you do not have this version of Vivado installed,"
  echo "    please install it or download the project sources from"
  echo "    a commit of the Git repository that was intended for"
  echo "    your version of Vivado."
  echo ""
  echo " 2. If Vivado is installed in a different location on your"
  echo "    PC, please modify the first line of this batch file "
  echo "    to specify the correct location."
  echo ""
fi
