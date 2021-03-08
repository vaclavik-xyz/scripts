#!/bin/bash

# Test to see if user is running with root privileges.
if [[ "${UID}" -ne 0 ]]
then
    echo 'Must execute with sudo or root' >&2
    exit 1
fi

killswitch='/root/killswitch.sh'
killswitch_rule='/etc/udev/rules.d/85-killswitch_rule.rules'

get_product(){
    echo ''
    echo 'Now remove inserted USB'
    echo ''
    PRODUCT=$(udevadm monitor --subsystem-match=usb --property --udev | grep -m 1 "PRODUCT" | sed 's:.*=::')
    echo 'ACTION=="remove", ENV{PRODUCT}=="'$PRODUCT'", RUN+="'$killswitch'"' > $killswitch_rule
    echo ''$PRODUCT' set as killswitch'
    udevadm control --reload-rules
    echo 'rules reloaded'

cat >$killswitch <<'EOF'
#!/bin/sh
killswitch_usage='/root/killswitch_usage'
t=$(date);
echo $t > $killswitch_usage 
#shutdown now
EOF

echo 'killswitch.sh written at '$killswitch''

chmod +x $killswitch

echo 'killswitch.sh made executable'

}
main() {
    INPUT=0
    echo ''
    echo 'Insert USB device you would like to use as killswitch and press enter'
    echo ''
    
    read -s -n 1 key
    if [[ $key = "" ]]; then
        get_product
    else 
        echo 'You pressed '$key', press enter'
    fi
}
main
