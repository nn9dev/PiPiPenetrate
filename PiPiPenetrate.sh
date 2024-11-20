#!/bin/bash
# run_dmc.sh by goodafternoon 

cd "$HOME" || exit

# Options "header"

# FIRMWARE_VERSION: 7.00-11.00
# Be sure your stage 2 payload is compatible with your firmware!
FIRMWARE_VERSION=11.00

# DOWNLOAD_PAYLOAD: goldhen, ps4hen, none
# this will download the appropriate payload, or don't download one.
# see https://github.com/nn9dev/pppissed (not out yet lol)
DOWNLOAD_PAYLOAD=goldhen

# USE_SYSTEM_PCAP: yes, no
# if no, pcap will be built from source. you probably want 'yes'
USE_SYSTEM_PCAP=yes

# PPPWN_INTERFACE: eth0, eth1, etc.
# Set this as the interface for PPPwn to use.
PPPWN_INTERFACE=eth0

# BUILD_STAGE_1: yes, no
# if set to "yes", building stage1 will be skipped and you should provide your own at /boot/firmware/PPPwn/stage1.bin
# you probably don't want to change this.
SKIP_STAGE_1=no

# SKIP_OPTIONS: yes, no
# if set to "yes", the script will skip asking for any entries and proceed with the settings above.
SKIP_OPTIONS=no


# PPPwn options

# "-t --timeout: the timeout in seconds for ps4 response, 0 means always wait (default: 0)"
PPPWN_OPT_TIMEOUT=0

# "-wap --wait-after-pin: the waiting time in seconds after first round CPU pinning (default: 1)"
# "Accordinmg to a PR, setting this value to 20 helps to improve stability. This may not help your console."
PPPWN_OPT_WAITAFTERPIN=1

# "-gd --groom-delay: wait for 1ms every groom-delay rounds during Heap grooming (default: 4)"
# "You can set any value within 1-4097 (4097 is equivalent to not doing any wait).""
PPPWN_OPT_GROOMDELAY=4

# "-bs --buffer-size: PCAP buffer size in bytes, less than 100 indicates default value (usually 2MB) (default: 0)
# For --buffer-size, When running on low-end devices, this value can be set to reduce memory usage. 
# I tested that setting it to 10240 can run normally, and the memory usage is about 3MB. 
# (Note: A value that is too small may cause some packets to not be captured properly)"
PPPWN_OPT_BUFFERSIZE=0

# "--ipv6: Use your own ipv6. Doesn't check for correct formatting, use with caution. Can be useful for testing exploit parts or useful on difficult consoles."
PPPWN_OPT_IPV6=


# _NUM options, these will be passed as arguments to pppwn

# Default is no because this is an additional option, defaults get passed if no.
NUM_OPTIONS=no
# No clue what this one does tbh but if u make it hella low (like 0d1100) success rate goes hella up
PPPWN_OPT_SPRAY_NUM=0x1000
# PIN_NUM is how long to wait after sending packets (so we get the memory space we want)
PPPWN_OPT_PIN_NUM=0x1000
# CORRUPT_NUM is the amount of overflow packets sent to the PS4.
PPPWN_OPT_CORRUPT_NUM=0x1


# thank you Homebrew
abort() {
  printf "%s\n" "$@" >&2
  exit 1
}
# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
if [ -z "${BASH_VERSION:-}" ]
then
  abort "Bash is required to interpret this script."
fi

# echo a string in a given ANSI color
echoColor() {
  local text="$1"
  local color_code="$2"
  echo -e "\e[${color_code}m${text}\e[0m"
}

# uninstall: sudo rm -rf $HOME/PPPwn_cpp; sudo rm -rf /boot/firmware/PPPwn; sudo systemctl disable pppwn.service; sudo rm -f /etc/systemd/system/pppwn.service; sudo systemctl daemon-reload;

if [[ "$1" == "uninstall" ]]
then
  echoColor "Uninstalling pppwn..." 32
  sudo rm -rf $HOME/PPPwn_cpp; sudo rm -rf /boot/firmware/PPPwn; 
  sudo systemctl disable pppwn.service; 
  sudo rm -f /etc/systemd/system/pppwn.service; 
  sudo systemctl daemon-reload;
  echoColor "PPPwn uninstalled! Rebooting in 10."
  sleep 10
  sudo reboot
fi

# Read in options
if [[ "${SKIP_OPTIONS}" != "yes" ]] # if it's NOT "yes", then skip this block
then
  read -r -p "Enter your firmware version (ex: 9.50, 11.00, etc.) -> " FIRMWARE_VERSION
  echo 
  echoColor "If you choose to download a stage2 payload, the appropriate payload will be downloaded and placed at /boot/firmware/PPPwn/stage2.bin." 36
  echoColor "If you enter "none", no payload will be downloaded and you should provide your own at /boot/firmware/PPPwn/stage2.bin." 32
  read -r -p "Download which payload? (goldhen, ps4hen, none) -> " DOWNLOAD_PAYLOAD
  echo

  echoColor "You may need to change the PPPwn interface if you are using an external ethernet adapter." 36
  echoColor "If you are using an external ethernet adapter, plug it in now." 36
  echoColor "The default interface is 'eth0'." 32
  read -r -p "Change PPPwn interface? ([y]es/[n]o) -> " CHANGE_INTERFACE
  CHANGE_INTERFACE=$(echo "${CHANGE_INTERFACE}" | tr '[:upper:]' '[:lower:]') #convert answer to lowercase
  if [ "${CHANGE_INTERFACE}" == "y" ] || [ "${CHANGE_INTERFACE}" == "yes" ]
  then
    #echo -e "\e[31m!!!PAY ATTENTION!!!\e[0m"
    #echo -e "\e[31m!!!You will be asked to select a network interface when pppwn has finished building!!!\e[0m"
    echoColor "Please choose one of the interfaces in the 'Iface' column below." 33
    echo  
    netstat -i
    echo  
    # Ask to SELECT INTERFACE
    if [ "${CHANGE_INTERFACE}" == "y" ] || [ "${CHANGE_INTERFACE}" == "yes" ]
    then
      echo 
      #echo -e "\e[31m!Select your PPPwn interface!\e[0m"
      echo -e "\e[33mIf you have NO external adapter plugged in, you likely want eth0. Otherwise, choose one of the options above.\e[0m"
      read -r -p "Choose PPPwn interface (eth0, eth0, etc.) -> " PPPWN_INTERFACE
    fi
  fi
  echo

  echoColor "Setting the _NUM options can increase stability. If you have values in mind, this is where you enter them." 36
  echoColor "Otherwise, you likely want to leave these as default." 32
  read -r -p "Set CORRUPT_NUM, PIN_NUM, SPRAY NUM? ([y]es/[n]o) -> " NUM_OPTIONS
  NUM_OPTIONS=$(echo "${NUM_OPTIONS}" | tr '[:upper:]' '[:lower:]') #convert answer to lowercase
  if [ "${NUM_OPTIONS}" == "y" ] || [ "${NUM_OPTIONS}" == "yes" ]
  then
    read -r -p "SPRAY_NUM? (Default: 4096 or 0x1000) -> " PPPWN_OPT_SPRAY_NUM
    read -r -p "PIN_NUM? (Default: 4096 or 0x1000 ) -> " PPPWN_OPT_PIN_NUM
    read -r -p "CORRUPT_NUM? (Default: 1 or 0x1) -> " PPPWN_OPT_CORRUPT_NUM
  fi
  # set defaults if any are empty
  if [ "${PPPWN_OPT_SPRAY_NUM}" == "" ]; then PPPWN_OPT_SPRAY_NUM=0x1000; fi;
  if [ "${PPPWN_OPT_PIN_NUM}" == "" ]; then PPPWN_OPT_PIN_NUM=0x1000; fi;
  if [ "${PPPWN_OPT_CORRUPT_NUM}" == "" ]; then PPPWN_OPT_CORRUPT_NUM=0x1; fi;

  echoColor "Using a custom IPv6 can make some edge case consoles work better." 36
  echoColor "Before entering a value here, make sure you have one in mind." 36
  echoColor "It's reccomended to NOT enter one unless you've tried everything else." 32
  read -r -p "Use old IPv6? ([y]es/[n]o) -> " USE_OLD_IPV6
  USE_OLD_IPV6=$(echo "${USE_OLD_IPV6}" | tr '[:upper:]' '[:lower:]') #convert answer to lowercase
  if [ "${USE_OLD_IPV6}" == "y" ] || [ "${USE_OLD_IPV6}" == "yes" ]
  then
    read -r -p "Enter an IPv6 to use in the format of 9f9f:41ff:9f9f:41ff -> " PPPWN_OPT_IPV6
    PPPWN_OPT_IPV6="--ipv6 $PPPWN_OPT_IPV6"
  else
    PPPWN_OPT_IPV6=""
  fi
fi

echo

# Make sure none of our important options are blank. If any are, exit.
if [ "${FIRMWARE_VERSION}" == "" ] || [ "${DOWNLOAD_PAYLOAD}" == "" ] || [ "${PPPWN_INTERFACE}" == "" ] || [ "${SKIP_STAGE_1}" == "" ]
then
  echo -e "\e[31mOne or more options not configured! Exiting...\e[0m"
  exit
else
  echo -e "\e[38;5;200m"
  echo "----------------OPTIONS----------------"
  echo "FIRMWARE_VERSION: ${FIRMWARE_VERSION}"
  echo "DOWNLOAD_PAYLOAD: ${DOWNLOAD_PAYLOAD}"
  echo "USE_SYSTEM_PCAP: ${USE_SYSTEM_PCAP}"
  echo "PPPWN_INTERFACE: ${PPPWN_INTERFACE}"
  echo "SKIP_STAGE_1: ${SKIP_STAGE_1}"
  echo "SKIP_OPTIONS: ${SKIP_OPTIONS}"
  echo "CORRUPT_NUM: ${PPPWN_OPT_CORRUPT_NUM}"
  echo "PIN_NUM: ${PPPWN_OPT_PIN_NUM}"
  echo "SPRAY_NUM: ${PPPWN_OPT_SPRAY_NUM}"
  if [ "${PPPWN_OPT_IPV6}" != "" ]
  then echo "IPv6 : ${PPPWN_OPT_IPV6}"
  fi
  echo "---------------------------------------"
  echo -e "\e[0m"
fi

length=${#FIRMWARE_VERSION}
remove_pos=$((length - 3))
FW_ALSO="${FIRMWARE_VERSION:0:remove_pos}${FIRMWARE_VERSION:remove_pos+1}"


echo
echoColor "Proceeding to build, this may take several minutes..." 33
echo
sleep 3

# Check dependencies
# jq for json parse (get goldhen and ps4hen release)
# curl/wget/git/net-tools for networking
# gcc/g++/make/cmake for building
# libpcap-dev because pcap
# p7zip for goldhen
# nano because every system should have it
sudo apt update
sudo apt install jq curl wget git net-tools gcc g++ gcc-x86-64-linux-gnu binutils-x86-64-linux-gnu make cmake libpcap-dev p7zip nano -y
echo
echo


# Download PPPwn and compile it (or don't)
SYS_PCAP_ENTRY=""
if [[ ${USE_SYSTEM_PCAP} == "no" ]]
then
  echoColor "pcap will be built from source" "38;5;33"
  sleep 3
  SYS_PCAP_ENTRY="-DUSE_SYSTEM_PCAP=OFF"      # if Y is NOT pressed, so we DO NOT want to use it
  sudo apt install bison flex                 # required to build pcap for some reason
else
  echoColor "system pcap will be used" "38;5;33"
  sleep 3
fi
echo
echo

# Clone pppwn 
git clone --recursive https://github.com/nn9dev/PPPwn_cpp
cd PPPwn_cpp || exit

# Build pppwn
echo
echoColor "Building PPPwn_cpp..." "38;5;33"
echo

cmake -B build ${SYS_PCAP_ENTRY}
cmake --build build -j "$(nproc)" -t pppwn 
echo
echo
file build/pppwn

# Copy pppwn to a windows-accessible directory
mkdir /boot/firmware/PPPwn
chmod +x build/pppwn
cp build/pppwn /boot/firmware/PPPwn/pppwn


# Download GoldHEN or PS4-HEN-VTX
if [ ${DOWNLOAD_PAYLOAD} != "none" ]
then
  echo
  echoColor "Downloading ${DOWNLOAD_PAYLOAD}..." "38;5;226"
  echo

  if [[ ${DOWNLOAD_PAYLOAD} == "goldhen" ]]
  then
    # surely we won't need sistr0's custom stage 2 :clueless:
    # this downloads the TOP DISPLAYING release from the GoldHEN releases page
    wget "$(curl -s https://api.github.com/repos/GoldHEN/GoldHEN/releases | jq -r '.[0].assets[0].browser_download_url')" -O goldhen.7z
    sudo 7z x -ogoldhen goldhen.7z
    sudo chmod -R 777 goldhen/* #dude are you fucking serious
    #mkdir /boot/firmware/PPPwn/stage2
    # shellcheck disable=SC2164
    cd goldhen/pppnw_stage2/   #DUDE are you FUCKING serious??
    # shellcheck disable=SC2164
    cd goldhen/pppwn_stage2/   # just in case he fixes it...
    sudo 7z x "$(echo $(ls | grep .7z))"
    sudo chmod -R 777 * 
    echo
    echoColor "Copying stage2_${FIRMWARE_VERSION}.bin to /boot/firmware/PPPwn/stage2.bin" "38;5;33"
    cp stage2_${FIRMWARE_VERSION}.bin /boot/firmware/PPPwn/stage2.bin
    file /boot/firmware/PPPwn/stage2.bin
    cd ../..
    cd goldhen || exit  # end in ~/PPPwn_cpp/goldhen
  elif [[ ${DOWNLOAD_PAYLOAD} == "ps4hen" ]]
  then
    # this downloads the TOP DISPLAYING release from the ps4-hen-vtx releases page
    wget "$(curl -s https://api.github.com/repos/EchoStretch/ps4-hen-vtx/releases | jq -r '.[0].assets[0].browser_download_url')" -O ps4hen.zip
    7z x -ops4hen ps4hen.zip
    #sudo mkdir /boot/firmware/PPPwn/stage2
    #sudo cp ps4hen/stage2_${FIRMWARE_VERSION}.bin /boot/firmware/PPPwn/stage2/stage2.bin
    echo
    echoColor "Copying ps4hen/stage2_${FIRMWARE_VERSION}.bin to /boot/firmware/PPPwn/stage2.bin" "38;5;33"
    echo
    cp ps4hen/stage2_${FIRMWARE_VERSION}.bin /boot/firmware/PPPwn/stage2.bin
    file /boot/firmware/PPPwn/stage2.bin
    cd ps4hen || exit
  fi
  else
  echoColor "Invalid payload entered. Skipping payload download..." 31
fi


# Clone and build stage1 from PPPwn
if [[ ${SKIP_STAGE_1} != "yes" ]]
then
  echo
  echoColor "Cloning Stage 1..." "38;5;33"
  echo

  #this will be INSIDE the folder whatever payload you've just downloaded
  git clone --recursive -b goldhen https://github.com/SiSTR0/PPPwn
  #consider checking out a specific hash so that the below doesn't fucker up?
  cd PPPwn || exit
  cd stage1 || exit

  #patch Makefile because we cross compile stage1
  echoColor "Patching stage1 Makefile for cross compilation..." "38;5;33"
  sed -i 's/CC = gcc/CC = x86_64-linux-gnu-gcc/g' Makefile
  sed -i 's/OBJCOPY = objcopy/OBJCOPY = x86_64-linux-gnu-objcopy/g' Makefile
  cd .. 
  echo
  echoColor "Building Stage 1..." "38;5;33"
  echo

  make -C stage1 FW=${FW_ALSO} clean && make -C stage1 FW=${FW_ALSO}
  #sudo mkdir /boot/firmware/PPPwn/stage1
  #sudo cp stage1.bin /boot/firmware/PPPwn/stage1/stage1.bin
  cp stage1/stage1.bin /boot/firmware/PPPwn/stage1.bin
  file /boot/firmware/PPPwn/stage2.bin
fi

# generate run script (this will be run as root)
echo
echoColor "Generating run.sh at /boot/firmware/run.sh" "38;5;202"

echo "#!/bin/bash
/boot/firmware/PPPwn/pppwn --interface ${PPPWN_INTERFACE} --fw ${FW_ALSO} --stage1 "stage1.bin" --stage2 "stage2.bin" -t ${PPPWN_OPT_TIMEOUT} -wap ${PPPWN_OPT_WAITAFTERPIN} -gd ${PPPWN_OPT_GROOMDELAY} -bs ${PPPWN_OPT_BUFFERSIZE} -cn ${PPPWN_OPT_CORRUPT_NUM} -pn ${PPPWN_OPT_PIN_NUM} -sn ${PPPWN_OPT_SPRAY_NUM} ${PPPWN_OPT_IPV6} --auto-retry 

" >run.sh

# shutdown -h now #(move this up 3 lines)
#cat run.sh    # comment out for smoothness
chmod +x run.sh
cp run.sh /boot/firmware/PPPwn/run.sh
mv run.sh run.sh.copy


# set up service
echo
echoColor "Generating pppwn.service at /etc/systemd/system/pppwn.service" "38;5;202"
echo

echo "[Unit] 
Description=pppwn service
After=network.target

[Service]
User=root
Group=root
Type=forking
WorkingDirectory=/boot/firmware/PPPwn/
ExecStart=/boot/firmware/PPPwn/run.sh
TimeoutSec=300

[Install]
WantedBy=multi-user.target
" >pppwn.service
#cat pppwn.service    # comment out for smoothness
cp pppwn.service /boot/firmware/PPPwn/pppwn.service.copy
sudo cp pppwn.service /etc/systemd/system/pppwn.service #copy to /etc/systemd/system/

# enable service
sudo chmod -R 755 /boot/firmware/PPPwn
sudo systemctl enable pppwn
sudo systemctl daemon-reload
#sudo systemctl status pppwn

echo
echoColor "Installation complete! The system will restart in eight seconds." "38;5;226"
sleep 8
reboot


