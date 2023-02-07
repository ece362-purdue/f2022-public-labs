# Introduction
In ECE362, students will learn fundamentals of microcontrollers, including their operation, and usage. In addition to the lecture portion of the course, students are expected to complete a series of lab experiments using a microcontroller platform and IDE. Computers and measurement equipment are provided in the course laboratory facilities to assist students in completing labs, however, the course has also been designed to allow students to perform experiment exercises on their own computers at home or elsewhere. Instructions provided in this lab document serves as a guide to setting up the microcontroller development environment used in ECE362 to provide a consistent user experience between home and the laboratory.
# Instructional Objectives
- To become familiar with the contents of the ECE 362 lab kit.
- To learn how to install the SystemWorkbench IDE on your personal computer
- To practice building a project, running a program on the microcontroller, and debugging execution

# Step 1: Place the Development Board on a Breadboard
Open your ECE 362 lab kit and find the STM32F091RCT microcontroller development board. It should look like the one in the image below. 

[devboard](img/img1.jpeg)

Your ECE Master/Mini kit has a large, four-panel breadboard similar to the one pictured below. Place the devboard so that it is on the bottom of the second panel, shown below:

[breadboard](img/img2.jpeg)

Typically, these will be a little hard to get in there, but you should not have to remove it once it's in there. To prevent damage to the board, press down on the buttons. Do not apply force to anything else, as parts of the board are delicate and may become damaged. When inserting, make sure there are two holes on either side of the development board to leave room to plug in peripherals.
Next, connect the USB programmer (shiny colored device with a light on it, pictured below) to the devboard.

[programmer](img/img9.jpeg)

It is important that this programmer only ever gets connected to the black header on the side of the devboard. If you manage to place it on the exposed pins on the long sides of the devboard, you will irreversably damage the development board.
After plugging in the programming side to the devboard , you should see a red and a green LED light up. If it does not light up, unplug the programmer and call over a TA so they can take a look at it.

# Step 2: Install the Development Software
For our course, the Eclipse IDE will be used, alongside of the SystemWorkbench for STM32 plugin. Eclipse is open source, so it may not seem like the most user-friendly when you are first using it. After extended use, you should be able to navigate it pretty well. Here are instructions on how to set it up on your machine, as well as on the lab computers.

# Step 2.1 Installation on the lab computers
Fortunately for you, one of the past instructors created a setup package that you can invoke to (msotly) take care of this for you. Open a terminal window, and invoke this line of code:
```bash
~ece362/bin/setup
```
After running this, you should see new icons appear on your desktop. One of them reruns the setup program, which you can use to update your configuration if any new applications are needed. Another icon is created for System Workbench, which is the main application that you will use.

# Step 2.2: Installation on a Linux system.
The version of Linux that this application is supported on is Ubuntu LTS. It might work on other distributions, or it might not. You can get the installation package [here](https://www.st.com/en/development-tools/sw4stm32.html#get-software). A couple of different ways to install it are located below:

```bash
bash install_sw4stm32_linux_64bits-latest.run
```
or
```bash
sudo apt install lib32ncurses5 make
```
or
```bash
sudo apt install libpython2.7:i386 libncurses5:i386 make
```

Pick the one that works best for your distribution, and keep track of where the installer puts the required folders. These will be important later. The installation script should set up a link on your desktop by which you can invoke System Workbench. If not, invoke it with 

```bash
[the path to the installation directory]/eclipse
```

# Step 2.3: Installation on a Windows System
Eclipse works on Windows 10 and 11. You can find the installation package [here](https://www.st.com/en/development-tools/sw4stm32.html#get-software). Once downloaded, run the installer. Keep track of where the installer puts the required folders. These will be important later. Sometimes Windows may require a driver for the STLink programming device. Download and install the driver, located [here](https://www.st.com/en/development-tools/stsw-link009.html).

# Step 3: Download and Install the Standard Peripheral Library
For this class, we will use the OpenSTM32 Standard Peripheral Library as the core of our work. In a sum, it's a script that starts the chip up, as well as a couple of other scripts that provide memory address acronyms. This is nice because you will not have to constantly look up the memory addresses for each part of the chip, which is a huge pain. You can find it [here](https://www.st.com/en/embedded-software/stsw-stm32048.html#get-software), or cached on the Brightspace.

Once downloaded, moved the zip file into the their repective directory. If you chose the default locations, typically they're located in:
```bash
.ac6/SW4STM32/firmwares.
```
for Linux, or
```bash
C:\Users\<username>\AppData\Roaming\Ac6\SW4STM32\firmwares
``` 
for Windows. 

For the lab machines, you need to enable the ability to view hidden files, as having the dot in front of ac6 makes it a hidden file. You can do this by selecting the view tab on the file explorer, and checking the box that says "show hidden files." 

Move the zip file into the firmwares directory, and unzip it inside of that location. None of use are really sure why, but Eclipse looks for both the zipped and unzipped version. They must have the same name, otherwise Eclipse will pretend like it's not there.

# Step 4: Configure SystemWorkbench
Now that the software is installed, we can begin configuration. Start this by selecting the "Window" dropdown at the top of the screen, and selecting the "Settings" option. As you're doing this, make sure that you're changing the settings highlighted with the red Xs.

# Step 4.1: General Workspace Preferences
Here, we configure the general workspace preferences. Open the "General" dropdown, and select "Workspace." Here, unselect "build automatically" and select "Save automatically before build." After, change your text file encoding to UTF-8, and new text file line delimiters to Unix. This helps standardize what you and the TAs look at, and enables a setting to build the correct version of your project, as Eclipse only builds the last-saved version. An example setting is shown below:

[workspace](img/img3.png)

# Step 4.2: General Text Editor Preferences
Next, drop down the "Editors" tab, and select "Text Editors." Check the "Show print margin" tab so you can see where the printer would stop in case your code ever needs to be printed out. An example setting is shown below:

[text editor](img/img4.png)

# Step 4.3: C/C++ indexer Preferences
Open the "C/C++" dropdown, and then select "Indexer." Make sure "Use active build configuration" is checked. An example setting is shown below:

[indexer](img/img5.png)

# Step 4.4: C/C++ Code Formatting Settings
Eclipse, like other IDEs, automatically formats code for you. However, it needs to be told to not use tabs. Open the "C/C++" dropdown, open the "Code Style" dropdown within it, and then select "Formatter." Select "New" to open a new template, and select "K&R C" as your base. Make sure to select "Spaces only" for your tab policy. Past that, you're free to format your code however you want. Make sure you save and apply after. An example setting is shown below:

[Formatter1](img/img6.png)

[Formatter2](img/img7.png)

# Step 4.5: Build Console Settings
Open the "C/C++" dropdown, then the "Build" dropdown within it. Then select the "Console" tab. In there, check "Bring console to top when building (if present) and "Wrap lines on the console." These make sure that the build console is present, as well as ensuring that the console is visible if you have it open. After, increase the number of lines to something larger. I typically use 5,000, as it's atypical for a program of our nature to print anything larger than that. An example setting is shown below:

[Build](img/img8.png)
