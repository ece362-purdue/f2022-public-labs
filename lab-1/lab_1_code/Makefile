PREFIX := $${HOME}/Desktop/FVP_Linux/gcc-linaro-4.9.4-2017.01-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
CC := $(PREFIX)gcc
CFLAGS := -std=c99 -g3
INC := ./inc
EXE := lab

HOSTNAME := root@localhost
FVP_DIR := $${HOME}/Desktop/FVP_Linux

.PHONY: ssh
.PHONY: connect
.PHONY: gdbserver
.PHONY: launch_fvp
.PHONY: help

lab: lab*.S autograder-FVP-Linux.o
	@$(CC) -o $(EXE) $^ -I$(INC) $(CFLAGS)

connect:
	@telnet localhost `sed -n '3 p' port.env`

ssh:
	@ssh -p `sed -n '1 p' port.env` $(HOSTNAME)

launch_fvp:
# Assign unused ports on host for ssh, gdbserver, and serial port to avoid collision
	@ruby -e 'require "socket"; puts Addrinfo.tcp("", 0).bind {|s| s.local_address.ip_port }' > ./port.env
	@ruby -e 'require "socket"; puts Addrinfo.tcp("", 0).bind {|s| s.local_address.ip_port }' >> ./port.env
	@ruby -e 'require "socket"; puts Addrinfo.tcp("", 0).bind {|s| s.local_address.ip_port }' >> ./port.env
# Create gdbinit script with the right port
	@echo "target remote localhost:`sed -n '2 p' port.env`" > ./.gdbinit
# Read the assigned port and launch the run script
	bash -c "export NAT_SSH_PORT=`sed -n '1 p' port.env` && export NAT_GDBSERVER_PORT=`sed -n '2 p' port.env` && export SERIAL_PORT=`sed -n '3 p' port.env` && cd $(FVP_DIR) \
		&& source ./setup.sh && cd ./Linaro_Linux && ./run_model.sh"

stop_fvp:
	@ssh -p `sed -n '1 p' port.env` $(HOSTNAME) "halt"
	
upload: lab
	@ssh -p `sed -n '1 p' port.env` $(HOSTNAME) "rm -f $(EXE)"
	@scp -qP `sed -n '1 p' port.env` ./$(EXE) $(HOSTNAME):~
	@echo "Uploaded $^ to FVP home directory"  

just_run: lab
	@ssh -p `sed -n '1 p' port.env` $(HOSTNAME) "./$(EXE)"

gdbserver:
	-@ssh -p `sed -n '1 p' port.env` $(HOSTNAME) "killall -q gdbserver"
	@ssh -p `sed -n '1 p' port.env` $(HOSTNAME) "gdbserver localhost:1234 $(EXE)"

help:
	@echo "-----------------------------------------------------"
	@echo "| Help section for ECE 362 ARM FVP                  |"
	@echo "-----------------------------------------------------"
	@echo "| make lab: build the lab executable using arm      |"
	@echo "|           compiler                                |"
	@echo "|                                                   |"
	@echo "| make connect: connect to FVP Linux shell via      |"
	@echo "|               telnet, exit by 'CTRL+]',           |"
	@echo "|               follow with 'quit'                  |"
	@echo "|                                                   |"
	@echo "| make ssh: ssh into FVP Linux shell, exit by       |"
	@echo "|           'logout' command                        |"
	@echo "|                                                   |"
	@echo "| make upload: upload executable to FVP, will call  |"
	@echo "|              'make lab' if source files changed   |"
	@echo "|                                                   |"
	@echo "| make just_run: just run the uploaded executable   |"
	@echo "|                                                   |"
	@echo "| make launch_fvp: launch fvp model and linux       |"
	@echo "|                  Will assign a pair of unused     |"
	@echo "|                  ports to ssh and gdbserver       |"
	@echo "|                                                   |"
	@echo "| make stop_fvp: shut down the fvp and linux safely |"
	@echo "|                                                   |"
	@echo "| make gdbserver: start a gdbserver on FVP          |"
	@echo "|                 must run before debugging         |"
	@echo "|                 Or you could run on FVP directly  |"
	@echo "|                 using gdbserver :1234 lab         |"
	@echo "|                                                   |"
	@echo "-----------------------------------------------------"