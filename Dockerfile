FROM shadowrobot/build-tools:xenial-kinetic-ide

LABEL Description="Furbinator arduino environment" Version="1.0"

ENV HOME_DIR=/home/user
ENV PROJECTS_WS=$HOME_DIR/projects/furbinator/catkin_ws
ENV remote_shell_script=bit.ly/tom_setup
ENV MY_USERNAME=user
USER $MY_USERNAME
ENV PATH="/home/user/arduino-1.8.9/bin:${PATH}"

RUN set +x && \
    \
    echo "Running tom_setup..." && \
    wget -O /tmp/tom_setup "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod +x /tmp/tom_setup && \
    bash -c "/tmp/tom_setup -s true -b true -t true" && \
    \
    echo "Creating and initialising the workspace..." && \
    mkdir -p $PROJECTS_WS && \
    sudo apt-get update && \
    # sudo apt-get install -y python-wstool python-rosdep ninja-build ros-kinetic-rosserial-arduino ros-kinetic-rosserial && \
    cd $PROJECTS_WS && \
    wstool init src && \
    wstool update -t src && \
    sudo rm -rf /etc/ros/rosdep/sources.list.d/20-default.list && \
    sudo rosdep init || exit 0 && \        
    rosdep update && \
    #rosdep install --from-paths src --ignore-src --rosdistro=${ROS_DISTRO} -y && \
    #source /opt/ros/kinetic/setup.bash && \
    #echo "source /opt/ros/kinetic/setup.bash" >> $HOME_DIR/.bashrc && \
    \
    echo "Adding user to dialout group..." && \
    sudo usermod -a -G dialout $MY_USERNAME && \      
    \
    echo "Fetching arduino-1.8.9, extracting & installing..." && \  
    cd ~/ && wget https://downloads.arduino.cc/arduino-1.8.9-linux64.tar.xz && \
    tar -xJf arduino-1.8.9-linux64.tar.xz && \
    rm arduino-1.8.9-linux64.tar.xz && \
    cd arduino-1.8.9 && \	
    sudo ./install.sh && \
    \
    echo "Installing arduino-cli..." && \  
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh && \
    \
    # echo "Adding nucleo-F446RE to boards list & installing..." && \  
    # touch $HOME_DIR/arduino-1.8.9/bin/arduino-cli.yaml && \
    # echo -e "board_manager:\n additional_urls:\n   - https://github.com/stm32duino/BoardManagerFiles/raw/master/STM32/package_stm_index.json" >> $HOME_DIR/arduino-1.8.9/bin/arduino-cli.yaml && \
    cd $HOME_DIR/arduino-1.8.9/bin/ && \
    arduino-cli core update-index && \
    # arduino-cli core install STM32:stm32 && \
    \
    echo "Fetching arduino library list" && \
    mkdir -p ~/Arduino/libraries && \
    cd ~/Arduino/libraries && \
    libraries=$(curl -L https://raw.githubusercontent.com/carebare47/furbinator/master/libraries) && \
    \
    echo "Installing the following libraries:" && \
    echo "$libraries" && \
    for library in $libraries; do git clone "$library"; done && \    
    arduino-cli lib install "MPU6050" && \
    \
    echo "Cloning and checking out latest branch of furbinator..." && \
    git clone https://github.com/carebare47/ez-arduino-spidey /home/user/Arduino/furbinator && \ 
    cd /home/user/Arduino/furbinator && \
    latest_branch=$(git for-each-ref --count=30 --sort=-committerdate refs/remotes/ | head -n 1 | sed 's;.*/;;g') && \
    git checkout $latest_branch && \
    \
    echo "Updating arduino preferences..." && \
    wget -O /home/user/.arduino15/preferences.txt https://raw.githubusercontent.com/carebare47/furbinator/master/preferences.txt


USER root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
