#! /bin/bash

Help()
{
	echo "Manage Selinux easier"
	echo "IMPORTANT: Run as root user using sudo"
}

if [ ! $# -eq 0 ] && [ $1 = "--help" ]; then
	Help
	exit 0
fi

if ! [ $EUID -eq 0 ]; then
	echo "Run as root user using sudo"
	exit 2
fi

line_with_config=$(sestatus | grep root)
del_config_position=$(expr index "$line_with_config" :)

if ! [ $del_config_position -gt 0 ]; then
	echo "sestatus does not include config path"
	exit 1
fi

config_path=${line_with_config:del_config_position}/config
selinux_status=$(cat $config_path | grep "^[^#;]" | grep -w SELINUX)
del_status_position=$(expr index "$selinux_status" =)

if ! [ $del_status_position -gt 0 ]; then
	echo "config does not inlude correct status"
	exit 1
fi

se_status=${selinux_status:del_status_position}

enforce=$(getenforce)

echo "---"
echo "Status of SELINUX: $enforce"
echo "Status of SELINUX in config: $se_status"
echo "---"

# terminal
if [ $enforce = "Enforcing" ]; then
	echo "Disable SELINUX? [y/n]"
else
	echo "Enable SELINUX? [y/n]"
fi

read selinux_active

while [ $selinux_active != "y" ] && [ $selinux_active != "n" ]; do
	if [ $enforce = "Enforcing" ]; then
		echo "Disable SELINUX? [y/n]"
	else
		echo "Enable SELINUX? [y/n]"
	fi
	read selinux_active
done

if [ $enforce = "Enforcing" ] && [ $selinux_active = "y" ]; then
	setenforce 0
	echo "Now selinux is disabled"
fi

if [ $enforce = "Permissive" ] && [ $selinux_active = "y" ]; then
	setenforce 1
	echo "Now selinux is enabled"
fi

# config
if [ $se_status = "enforcing" ]; then
	echo "Disable SELINUX in config? [y/n]. After this action you must reboot system to see changes."
else
	echo "Enable SELINUX in config? [y/n] After this action you must reboot system to see changes."
fi

read config_selinux_active

while [ $config_selinux_active != "y" ] && [ $config_selinux_active != "n" ]; do
	if [ $se_status = "enforcing" ]; then
		echo "Disable SELINUX in config? [y/n]. After this action you must reboot system to see changes."
	else
		echo "Enable SELINUX in config? [y/n] After this action you must reboot system to see changes."
	fi
	read config_selinux_active
done

if [ $se_status = "enforcing" ] && [ $config_selinux_active = "y" ]; then
	sed -i "s/^SELINUX=enforcing/SELINUX=permissive/" $config_path
	echo "Now selinux in config is disabled. Please reboot system."
fi

if [ $se_status = "permissive" ] && [ $config_selinux_active = "y" ]; then
	sed -i "s/^SELINUX=permissive/SELINUX=enforcing/" $config_path
	echo "Now selinux in config is ebanbled. Please reboot system."
fi

