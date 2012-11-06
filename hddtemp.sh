#/!bin/sh
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <pantu39@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Pantu
# ----------------------------------------------------------------------------
#

# Check if we are root
if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
exit 1
fi

# Check if smartctl exists on the system
command -v smartctl >/dev/null  || { echo "smartctl not found. (install sysutils/smartmontools)"; exit 1; }


# Colors
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
OFF="\033[0m"

# Get all attached devices (one per line)
DEVLIST=`sysctl kern.disks | awk '{$1=""; ;print $0}' | awk 'gsub(" ", "\n")' | tail -n500 -r`

# Loop through all lines
for dev in $DEVLIST
do
        size=`diskinfo -v /dev/${dev} | grep bytes | awk '{printf "%.2f\n",($1/(1024*1024*1024))}'`
        bus=`cat /var/run/dmesg.boot | grep "${dev} at" |grep target | awk '{print $3}'`
        # get names via dmesg instead of camcontrol and also include firmware revision
                name=`cat /var/run/dmesg.boot |grep ${dev}: | grep "<"|grep ">"  | awk 'gsub(/<|>/, "\n");' | awk 'NR==2'`
                #name=`camcontrol identify /dev/${dev} | grep "device model" | awk '{ $1=$2=""; print $0}'`
        temp=`smartctl -d atacam -A /dev/${dev} | grep Temperature_Celsius | awk '{print $10}'`

        case $temp in
                ''|*[!0-9]*)
                                        temp="n.a."
                                        ;;
                *)
                                        if [ $temp -gt 40 ]; then
                                                temp="${RED}${temp} C${OFF}"
                                        elif [ $temp -gt 30 ]; then
                                                temp="${YELLOW}${temp} C${OFF}"
                                        else

                                                temp="${GREEN}${temp} C${OFF}"
                                        fi
                                        ;;
        esac

        echo -e "$temp\t${bus}:${dev}\t${name} (${size}G)"
done

