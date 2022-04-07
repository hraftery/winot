ssh root@128.199.97.210
apt update
apt upgrade
apt install build-essential cmake ninja-build libfontconfig1-dev libdbus-1-dev libfreetype6-dev libicu-dev libinput-dev libxkbcommon-dev libssl-dev libpng-dev libjpeg-dev libglib2.0-dev
apt install libgles2-mesa-dev libgbm-dev libdrm-dev
apt install libx11-dev libxcb1-dev libxext-dev libxi-dev libxcomposite-dev libxcursor-dev libxtst-dev libxrandr-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libxcb-xinput-dev
apt install unzip gcc make gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu
apt install qemu qemu-system-aarch64
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtbase-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtshadertools-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qttools-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtdeclarative-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtsvg-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtvirtualkeyboard-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtwebengine-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtwebsockets-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtwebview-everywhere-src-6.2.3.tar.xz
wget https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2022-01-28/2022-01-28-raspios-bullseye-arm64.zip


unzip 2022-01-28-raspios-bullseye-arm64.zip
mkdir /mnt/rasp-pi-rootfs
fdisk -l 2022-01-28-raspios-bullseye-arm64.img # note "Start" of Linux partition. Let offset = Start * sector size.
mount -o loop,offset=272629760 2022-01-28-raspios-bullseye-arm64.img /mnt/rasp-pi-rootfs
mount -o offset=4194304,sizelimit=268435456 -t vfat 2022-01-28-raspios-bullseye-arm64.img /mnt/rasp-pi-rootfs/boot
cp /mnt/rasp-pi-rootfs/boot/kernel8.img ./
cp /mnt/rasp-pi-rootfs/boot/bcm2710-rpi-3-b-plus.dtb ./
umount /mnt/rasp-pi-rootfs/boot
umount /mnt/rasp-pi-rootfs
qemu-img resize -f raw 2022-01-28-raspios-bullseye-arm64.img 4G
qemu-system-aarch64 -m 1024 -M raspi3b -kernel kernel8.img -dtb bcm2710-rpi-3-b-plus.dtb -drive file=2022-01-28-raspios-bullseye-arm64.img,if=sd,format=raw -append "console=ttyAMA0 root=/dev/mmcblk0p2 rw rootwait rootfstype=ext4" -nographic -device usb-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::5555-:22

#
# in qemu
#
sudo apt update
sudo apt remove chromium-browser
sudo apt autoremove
# sudo apt upgrade # took ages! And kills network on reboot... Fixed: copy the modified kernel file out of /boot again.
sudo apt install build-essential cmake ninja-build libfontconfig1-dev libdbus-1-dev libfreetype6-dev libicu-dev libinput-dev libxkbcommon-dev libssl-dev libpng-dev libjpeg-dev libglib2.0-dev zlib1g-dev
sudo apt install libgles2-mesa-dev libgbm-dev libdrm-dev
sudo apt install libx11-dev libxcb1-dev libxext-dev libxi-dev libxcomposite-dev libxcursor-dev libxtst-dev libxrandr-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libxcb-xinput-dev
sudo raspi-config # Advanced -> graphics driver -> change to GL (Full KMS). See https://forums.raspberrypi.com/viewtopic.php?t=317511
# sudo apt install mesa-utils # maybe good, maybe bad
exit


# Oh dear, qtwebview requires qtwebengine, which requires cmake 3.19 but impish only has 3.18.4.
apt purge cmake
wget https://github.com/Kitware/CMake/releases/download/v3.22.3/cmake-3.22.3.tar.gz
tar xf cmake-3.22.3.tar.gz
cd cmake
./bootstrap # takes ages
gmake -j$(nproc)
gmake install
cd ..

tar xf qtbase-everywhere-src-6.2.3.tar.xz
tar xf qtshadertools-everywhere-src-6.2.3.tar.xz
tar xf qttools-everywhere-src-6.2.3.tar.xz 
tar xf qtdeclarative-everywhere-src-6.2.3.tar.xz 
tar xf qtwebengine-everywhere-src-6.2.3.tar.xz 
tar xf qtwebsockets-everywhere-src-6.2.3.tar.xz 
tar xf qtwebview-everywhere-src-6.2.3.tar.xz 
tar xf qtsvg-everywhere-src-6.2.3.tar.xz
tar xf qtvirtualkeyboard-everywhere-src-6.2.3.tar.xz 

# now the order really matters...
# on the other hand, --parallel seems not to matter
cd qtbase-everywhere-src-6.2.3
./configure
cmake --build . --parallel
cmake --install .
cd ../qtshadertools-everywhere-src-6.2.3
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel
cmake --install .
cd ../qtdeclarative-everywhere-src-6.2.3
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel
cmake --install .
cd ../qtwebsockets-everywhere-src-6.2.3
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel
cmake --install .
cd ../qtwebengine-everywhere-src-6.2.3
apt install nodejs python gperf bison flex libnss3-dev libxshmfence-dev
apt install libxkbfile-dev # not checked by configure!
apt install libfontconfig1-dev libfreetype6-dev libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-xinerama0-dev libxkbcommon-dev libxkbcommon-x11-dev # still not enough...
apt install libevent-dev minizip libminizip-dev libre2-dev libwebp-dev liblcms2-dev libxml2-dev libxslt-dev libavcodec-dev libavformat-dev libopus-dev libharfbuzz-dev libsnappy-dev # maybe makes no difference. Deleting and untar-ing again worked instead.
apt purge libharfbuzz-dev # fails once you get to cross compiling!
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel # oh man, so many oom errors. 2GB per 8 processes: oom with 16GB RAM. Because DigitalOcean don't recommend swap on SSDs? Bit trigger-happy. Neither `--parallel 1` nor `-- -j 1` work, like they do on the Pi itself. Only solution so far is to keep re-starting. Maybe "echo 2 > /proc/sys/vm/overcommit_memory"? Bizarrely, "echo 1" is stable, "echo 2" is not... Still fragile though, so follow [this](https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-20-04) to create some swap.
cmake --install .
cd ../qtwebview-everywhere-src-6.2.3
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel
cmake --install .
cd ../qtsvg-everywhere-src-6.2.3
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel
cmake --install .
cd ../qtvirtualkeyboard-everywhere-src-6.2.3
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel
cmake --install .
cd ../qttools-everywhere-src-6.2.3
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel
cmake --install .


mv qtbase-everywhere-src-6.2.3 qtbase-everywhere-src-6.2.3-host
tar xf qtbase-everywhere-src-6.2.3.tar.xz
mv qtbase-everywhere-src-6.2.3 qtbase-cross
mkdir qtbasebuild
vi qtbase-cross/toolchain.cmake # as above
mount -o loop,offset=272629760 2022-01-28-raspios-bullseye-arm64.img /mnt/rasp-pi-rootfs
wget https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py # apparently the original, fixQualifiedLibraryPaths, is broken
chmod +x sysroot-relativelinks.py 
./sysroot-relativelinks.py /mnt/rasp-pi-rootfs
cd qtbasebuild/
../qtbase-cross/configure -nomake examples -nomake tests -qt-host-path /usr/local/Qt-6.2.3 -prefix /usr/local/qt6 -- -DCMAKE_TOOLCHAIN_FILE=../qtbase-cross/toolchain.cmake -DQT_BUILD_TOOLS_WHEN_CROSSCOMPILING=ON -DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined" # the last option prevents "/usr/lib/gcc-cross/aarch64-linux-gnu/11/../../../../aarch64-linux-gnu/bin/ld: /mnt/rasp-pi-rootfs/lib/aarch64-linux-gnu/libpthread.so.0: undefined reference to `__libc_dlopen_mode@GLIBC_PRIVATE'" compile errors
cmake --build . --parallel
cmake --install .

# wow. it worked. Now the other submodules

cd ..
mv qtshadertools-everywhere-src-6.2.3 qtshadertools-everywhere-src-6.2.3-host
tar xf qtshadertools-everywhere-src-6.2.3.tar.xz 
mv qtshadertools-everywhere-src-6.2.3 qtshadertools-cross
cd qtshadertools-cross/
/mnt/rasp-pi-rootfs/usr/local/qt6/bin/qt-configure-module . -- -DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined"
cmake --build . --parallel
cmake --install .
cd ..
mv qtdeclarative-everywhere-src-6.2.3 qtdeclarative-everywhere-src-6.2.3-host
tar xf qtdeclarative-everywhere-src-6.2.3.tar.xz 
mv qtdeclarative-everywhere-src-6.2.3 qtdeclarative-cross
cd qtdeclarative-cross/
/mnt/rasp-pi-rootfs/usr/local/qt6/bin/qt-configure-module . -- -DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined"
cmake --build . --parallel
cmake --install .
cd ..
mv qtwebsockets-everywhere-src-6.2.3 qtwebsockets-everywhere-src-6.2.3-host
tar xf qtwebsockets-everywhere-src-6.2.3.tar.xz 
mv qtwebsockets-everywhere-src-6.2.3 qtwebsockets-cross
cd qtwebsockets-cross/
/mnt/rasp-pi-rootfs/usr/local/qt6/bin/qt-configure-module . -- -DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined"
cmake --build . --parallel
cmake --install .
cd ..
mv qtwebengine-everywhere-src-6.2.3 qtwebengine-everywhere-src-6.2.3-host
tar xf qtwebengine-everywhere-src-6.2.3.tar.xz 
mv qtwebengine-everywhere-src-6.2.3 qtwebengine-cross
cd qtwebengine-cross/
/mnt/rasp-pi-rootfs/usr/local/qt6/bin/qt-configure-module . -- -DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined"
cmake --build . --parallel
cmake --install .
