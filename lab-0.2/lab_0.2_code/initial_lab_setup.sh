#! /bin/bash

# Copy FVP to desktop and install extensions for vscode
cp -r /local/scratch/a/FVP_Linux ~/Desktop/
code --install-extension dan-c-underwood.arm
code --install-extension ms-vscode.cpptools
code --install-extension webfreak.debug