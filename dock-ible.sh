#!/bin/bash

set -e

export ANSIBLE_CONFIG=.ansible.cfg

containers=(test1 test2 test3 test4)

# delete all, if any, currently existing containers that we are going to configure from scratch
delete () {
	printf "deleting currently running containers\n"
	for container in ${containers[@]}; do
		docker rm -f $container && printf "deleted $container\n" || continue
	done
}

# start all containers in a loop and configure a bare minimum with the cloud-init.yaml file
launch () {
	printf "\nstarting docker containers\n"
	for container in ${containers[@]}; do
		docker run -d --name $container atlassian/ssh-ubuntu:0.2.2 #sleep 100000
	done
}

# create a fresh hosts file so you don't need to edit the ip addresses manually
list () {
	printf "\nupdating the hosts file\n"
	> hosts
	for container in ${containers[@]}; do
		docker inspect $container | grep -w IPAddress | awk -F'"' 'NR==1 { print $4 }' >> hosts
	done
}

# finally run ansible and configure the containers
ansible () {
	printf "\nrunning ansible\n"
	ansible-playbook -i hosts --private-key ssh_key main.yml
}

case $1 in

	all)
		delete
		launch
		list
		ansible
	;;

	purge)
		delete
	;;

	launch)
		delete
		launch
		list
	;;

	ansible)
		ansible
	;;

	*)
		echo "Command '$1' not recognized"
		echo "Valid commands"
		echo "all"
		echo "purge"
		echo "launch"
		echo "ansible"
		exit
	;;
esac
