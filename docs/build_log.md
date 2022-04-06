# Winot - Putting the IoT in Wine
## Balena Residency Project

This document is a chapter in the Winot project documentation. To see it in context, open the project [README](README.md).

---

# Build Log

With enough design down on paper to see how all the pieces will fit together, it's time to chase out the design flaws by putting some pieces together!


## Table of Contents

-   [Learning balena](#learning-balena)
-   [Designing the API](#designing-the-api)
-   [Designing the UI](#designing-the-ui)
    -   [Creating a Qt App](#creating-a-qt-app)
    -   [Porting to the target](#porting-to-the-target)
        -   [Native ARM compilation of Qt](#native-arm-compilation-of-qt)
        -   [Cross-compiling Qt](#cross-compiling-qt)
        -   [Complete cross-compilation attempt](#complete-cross-compilation-attempt)
    -   [Status Stocktake](#status-stocktake)
        -   [Native compilation with Docker](#native-compilation-with-docker)
    -   [Development workflow](#development-workflow)
-   [Back to deployment workflow](#back-to-deployment-workflow)
-   [On the home stretch](#on-the-home-stretch)



## Learning balena

With the BOM ordered and parts trickling in, I turned to software development. To make sure I was taking advantage of the balena platform, I ran through the [getting-started](https://www.balena.io/docs/learn/getting-started/raspberrypi3/nodejs/) tutorial and later realised you can choose your own adventure by language and platform like [this](https://www.balena.io/docs/learn/getting-started/raspberry-pi2/haskell/)! I followed that with the guides on [local mode](https://www.balena.io/docs/learn/develop/local-mode) and [multiple containers](https://www.balena.io/docs/learn/develop/multicontainer).

That gave me a great grasp of how balenaCloud was going to power my application, but I was still reaching for some sort of guidance on a dev environment that would give me the GPIO twiddling power I craved without putting barriers in place when I want to add a HTTP API interface layer to leverage the *services* model that balena empowers. I've spent decades in C based IDEs writing firmware for microcontrollers, cut Python on SBCs to do physical computing, dabbled in Node.js et al for simple user front ends, and consumed a new programming language every couple of years. But I now realise that coming from an embedded background, this is still new territory: specifically, how to transition to what is well encapsulated by the nebulous term, *edge computing*. How do I apply my hardware-centric perspective to a world of containerised apps that drive hardware from a webapp-centric perspective?

Eventually I stumbled on [this](https://www.balena.io/blog/interfacing-balena-edge-devices-with-adafruitio/) and the pieces started to fall together. For better or worse, the marvellous glue language, Python, is the defacto tool for bridging the physical device with the ephemeral cloud. Seeing that a fellow balenista had a (not necessarily ideal) path to success gave me the gumption to bury my reservations about using a dynamic, jack-of-all-trades scripting language for *work*, and just get on with it. Extolling the virtues of a Better Way can wait until I get some damn LEDs flashing! Perhaps at that point it may not seem so important.

Now to get started... I realise I've started with the wrong repo template. I'm now creating an app, so I need whatever is required for `balena push` to work. But it's not clear to me how `balena push` turns into something that fires up docker on the device. Maybe `balena push` uploads the entire working folder somewhere and then calls `docker build` on that folder. That would mean two things:

1. managing git is entirely separate. That is, `balena push` and `git push` are unrelated and can operate in different cycles.
2. the entire working copy is acted upon, so anything is fair game, including using `.dockerignore` to limit what `docker build` uses.

Oh great, this is almost exactly what [this](https://www.balena.io/docs/learn/deploy/deployment/) says. Oh that page answers allll my questions. Required reading methinks!

Finally, I'm ready to create a starting repo. What would be really awesome is a document pointing out the purpose of every possible file in a balena app repo skeleton. Just enough to know who it is for, so the reader can then use existing knowledge or additional docs to piece the whole thing together.

Alright, got a hello world repo going from the ground up! Now we're underway.

## Designing the API

Thinking about a suitable API for `led-strip-driver`. What have others done? `esp8266-fastled-webserver` is a popular example. But the API doesn't appear to be documented! Reading [esp8266-fastled-webserver.ino](https://github.com/jasoncoon/esp8266-fastled-webserver/blob/1b8929c86eb7d42233ff48b41c7c7d516ac8213f/esp8266-fastled-webserver/esp8266-fastled-webserver.ino) suggests it's quite complicated and not very generic:

- GET all|product|info|fieldValue|etc
- POST fieldValue|power|cooing|sparking|speed|etc...

Reminds me of the [RGB](https://twitter.com/newieventures/status/1041910957524566016) [LED](https://github.com/NewieVentures/Obelisk) [Obelisk](https://www.tulipnetwork.org/post/tulip-blooms-in-lake-macquarie) we did! Defining "patterns" is complex.

Although it's not as powerful, I think I just want an `off` and `setLED` API for now. That is, just the ability to turn individual pixels to a certain colour.

Eh, so little guidance out there on a suitable API for what is essentially an array of ints (LED RGB values). REST is really designed for CRUD, and adaptations to plain old get/set operations are a wide variety of commonly accepted bastardisations of the verbs. Here's the [standard](https://restfulapi.net/rest-put-vs-post/) purpose of PUT and POST, but the world has realised that there's lots more use cases than that and the extensions are common and fractured.

Best options:

1. Copy `esp8266-fastled-webserver`. Way too hard for now.
2. Use the LED position as the resource id, and limit to Read and Update operations on either all or one LED. Eg. `GET /leds` , `GET /leds/{id}`, `PUT /leds` and `PUT /leds/{id}`.
3. Specify the LED position as an option parameter with the default being all, and use the common bastardisation of comma delimited multiple parameter values. Eg. `GET /leds`, `PUT /leds?pos=5,6,7,8&colour=#336699`.

On reflection, #3 doesn't provide enough power to warrant the non-standardness. Instead, starting with #2 is simple, easy to understand and will provide a certain amount of functionality. It can then be extended with specific functions that provide more powerful functionality, until it's eventually `esp8266-fastled-webserver` compatible.

Oh [rpi-ws2812-server](https://github.com/tom-2015/rpi-ws2812-server) is an impressive feature rich web server for controlling ws2812 and similar LED arrays. Keep in mind.

Eh, Flask [auto-converts](https://flask.palletsprojects.com/en/2.0.x/api/#flask.Flask.make_response) the `dict` *response* you provide into JSON (it jsonifies it). Doesn't say what it does to a `list`. Also, JSON can only support strings as keys, and list, dictionary, string, integer, float, boolean or Null as values (eg. no tuples). Only decimal integers are supported.

To make life as easy as possible, we could pick `0xWWRRGGBB`, which matched the [Arduino NeoPixel lib](https://github.com/adafruit/Adafruit_NeoPixel/blob/master/Adafruit_NeoPixel.h#L352).

Getting started with `rpi-ws281x-python`:

```
$ python
import rpi_ws281x
strip = rpi_ws281x.PixelStrip(5, 21)
strip.begin()
strip.setPixelColor(1, rpi_ws281x.Color(255,0,0))
strip.show()
```

And fancier (a selection from [strandtest.py](https://github.com/rpi-ws281x/rpi-ws281x-python/blob/master/examples/strandtest.py)):

```
import time
from rpi_ws281x import Color

def wheel(pos):
    """Generate rainbow colors across 0-255 positions."""
    if pos < 85:
        return Color(pos * 3, 255 - pos * 3, 0)
    elif pos < 170:
        pos -= 85
        return Color(255 - pos * 3, 0, pos * 3)
    else:
        pos -= 170
        return Color(0, pos * 3, 255 - pos * 3)

def theaterChaseRainbow(strip, wait_ms=50):
    """Rainbow movie theater light style chaser animation."""
    for j in range(256):
        for q in range(3):
            for i in range(0, strip.numPixels(), 3):
                strip.setPixelColor(i + q, wheel((i + j) % 255))
            strip.show()
            time.sleep(wait_ms / 1000.0)
            for i in range(0, strip.numPixels(), 3):
                strip.setPixelColor(i + q, 0)

theaterChaseRainbow(strip)
```

I wanted to auto-document the API and got the hot tip from a colleague that fastapi >> Flask for that and other RESTful things. Do I really want to abandon Flask at this stage? Well, the Internet strongly agrees:

- Old [hotness](https://stackoverflow.com/questions/14295322/what-tools-are-available-to-auto-produce-documentation-for-a-rest-api-written-in)
- New [hotness](https://stackoverflow.com/questions/67849806/flask-how-to-automate-openapi-v3-documentation)

So I bit the bullet and ported it over. Muuuuch better.

- [Swagger UI](https://5fba0b0e46ba6ea4f1cfb5e40f3183a7.balena-devices.com/docs)
- [ReDoc](https://5fba0b0e46ba6ea4f1cfb5e40f3183a7.balena-devices.com/redoc)
- And now, best of both with [redoc try](https://5fba0b0e46ba6ea4f1cfb5e40f3183a7.balena-devices.com/redoc-try)

`led-strip-driver` is done! Does all I need at the moment. On to the "app" that provides the user interface.

## Designing the UI

Obvious choice is a web app, as outlined in the [Software Architecture](README.md#software-architecture) diagram. First step - what's the kiosk going to be? Posed this question on Flowdock:

---
I’m looking for guidance on a starting point to create a kiosk app on the Raspberry Pi 7” Touchscreen.

Pre-balena I’ve done this a few times with a minimal window manager, chromium and a startup script with a bunch of options to make it kiosky and do power management. Now I want to go non-DIY and leverage the balena-verse. I’m not even wedded to a browser and happy to write my UI in just about anything, provided I can show a few buttons, a hideable on-screen keyboard, and a webview.

So far I’ve seen:

- [balenalabs/balena-dash](https://github.com/balenalabs/balena-dash)
- [Igalia/balena-wpe](https://github.com/Igalia/balena-wpe)
- [balenalabs-incubator/balena-wpe](https://github.com/balenalabs-incubator/balena-wpe)
- [balenablocks/electron](https://github.com/balenablocks/electron)
- [jayatvars/balena-chromium-kiosk](https://github.com/jayatvars/balena-chromium-kiosk)
- [balenablocks/browser](https://github.com/balenablocks/browser)
- [mir-kiosk](https://snapcraft.io/blog/mir-kiosk-uses-mir)

and am having a hard time figuring out how to avoid deep exploratory rabbit holes.

---

Responses indicate `balenablocks/browser` will do just fine, which makes sense. Feel like I'm missing out on wpe/electron/mir, but maybe they're just distractions.

With the client sorted, on to the app itself. Oh boy. Do I want a web app, a Progressive Web App or a Single Page App? Do I get with the times and use JavaScript + React. Or get ahead of the curve with TypeScript and Svelte? Or do just stick with Python + Django or my mate Flask? What about vanilla JS or even something I actually enjoy, like Ruby on Rails?

After *much* Googling and hand-wringing, decided that *if* I was to do a web app, it would be a PWA in Vanilla JS, adding frameworks and tools as I felt the need for them. [This](https://medium.com/james-johnson/a-simple-progressive-web-app-tutorial-f9708e5f2605) would be the starting point.

But then... why do a web app at all? There's so much infrastructure (eg. the server and the client), the landscape is a hot mess, I'm not utilising of any of the advantages, the learning curve is steep and bumpy, none of my preferred languages are well supported, and besides, aren't I contributing to the downfall of modern society by using web technologies when native will do?

What if I did a native app? The options are really:

- C++ and Qt (either QWidgets or QML and Qt Quick)
- Perl/Ruby/Python/C++ and wxWidgets
- Python/C/C++/Rust and GtK
- Python and Tkinter
- Python and Kivy
- Java and Swing/JavaFX
- Pascal and Lazarus (Delphi clone)

The choice is pretty clear to me, given I have some familiarity with everyone of those. Time to fire up **Qt Creator**!

### Creating a Qt App

I hate that the first step is always "name your new project". Naming is hard - particularly as the first step! What do you name the app/main/ui service? After some [research](https://twitter.com/HeathRaftery/status/1501907650363080704?s=20&t=V60iMK8w2BqdVIR4NBnILQ) I see:

- match the fleet name (eg. `inkyshot`)
- `frontend` / `backend`
- `eink`

So am still a bit undecided. Nearly went with `app` to match the Software Architecture diagram, but that term has meaning in the balenaverse. So let's go with... `winot-gui`. Well scoped, nicely descriptive and hints that there should be some separation of concerns, even if nearly all functionality will be in the user interface service to begin with.

Phew, done. Man, that app was *hard*. Everytime I go to do UI I feel like I'm reinventing the wheel, designing buttons and setting spacing and establishing UX. Is this frustration a product of growing up with the Apple HIG, with graphical UI toolboxes like Interface Builder and ResEdit? Twas a much simpler and prettier world back then...

Anyway, after a big slog, a complete V1 of the UI is done. Was brutal getting screens, tables, webviews and other pedestrian crap going. But would have only been worse as a web app, I think. So now ready to draw a line in the sand, and work on integration - getting `winot-gui` off the desktop, and building, deploying and running on balenaOS. Then we get to hook up the UI to the LED driver!

### Porting to the target

Okay, now to port to Raspberry Pi. Here goes. Hmm, looks like there's no shrinkwrapped Qt 6 deployment environment for Linux.

Difficult to find guidance which isn't either Qt 5 or RPi 4 specific. It doesn't help that both 64-bit Raspberry Pi OS and Qt 6 are both relatively new. Found two decent guides:

- [Impressive code and guide from Vikto Petersson, CEO of Screenly.io](https://www.docker.com/blog/compiling-qt-with-docker-multi-stage-and-multi-platform/)
- [TalOrg - Building Qt 6.2 on Raspberry Pi OS](https://www.tal.org/tutorials/building-qt-62-raspberry-pi)

Cross-compilation is definitely the *right* way, but I'm going to try building on ARM first. It simplifies a complex problem a lot, and the balena ARM builders may be okay anyway.

#### Native ARM compilation of Qt

First attempt:

```
apt update
apt install build-essential cmake ninja-build libfontconfig1-dev libdbus-1-dev libfreetype6-dev libicu-dev libinput-dev libxkbcommon-dev libssl-dev libpng-dev libjpeg-dev libglib2.0-dev
apt install libgles2-mesa-dev libgbm-dev libdrm-dev
apt install libx11-dev libxcb1-dev libxext-dev libxi-dev libxcomposite-dev libxcursor-dev libxtst-dev libxrandr-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libxcb-xinput-dev
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtbase-everywhere-src-6.2.3.tar.xz
tar xf qtbase-everywhere-src-6.2.3.tar.xz
```

The guide then says this, but I'm getting nowhere with that, even "fixing" it to the second version:

```
mkdir qtbasebuild && cd qtbasebuild
/opt/cmake/bin/cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/Qt/6.2.3-armv7l -DQT_FEATURE_opengles2=ON -DQT_FEATURE_opengles3=ON -DCMAKE_TOOLCHAIN_FILE=tc.cmake -DQT_AVOID_CMAKE_ARCHIVING_API=ON ../qtbase-everywhere-src-6.2.3
/usr/bin/cmake -G Ninja -DCMAKE_MAKE_PROGRAM=/usr/bin/cmake -DCMAKE_INSTALL_PREFIX=/opt/Qt/6.2.3-armv7l -DQT_FEATURE_opengles2=ON -DQT_FEATURE_opengles3=ON -DCMAKE_TOOLCHAIN_FILE=tc.cmake -DQT_AVOID_CMAKE_ARCHIVING_API=ON ../qtbase-everywhere-src-6.2.3
```

So instead, try to get a vanilla build going first:

```
cd qtbase-everywhere-src-6.2.3
sudo dphys-swapfile swapoff
sudo vi /etc/dphys-swapfile # change CONF_SWAPSIZE to 1024
sudo dphys-swapfile swapon
./configure 
cmake --build . --parallel
```

Key notes at this point:

- Qt embedded existed in Qt 4, but is now obsolete. I think that goes for OpenGL ES (GLES - OpenGL for Embedded System) too.
- As of Qt 5.0, Qt no longer has its own window system (QWS) implementation. For single-process use cases, the Qt Platform Abstraction is a superior solution; multi-process use cases are supported through Wayland.
- EGLFS is a platform plugin for running Qt applications on top of EGL and OpenGL ES 2.0, without an actual windowing system like X11 or Wayland. It is the recommended plugin for modern Embedded Linux devices that include a GPU.
- *Qt for Device Creation* is a **commercial offering** that provides the Qt development framework for embedded Linux and Real Time Operating Systems (RTOS).
	- Yocto tools and recipes, plus embedded Linux cross-compilation environments for reference devices.
- [Configure an Embedded Linux Device](https://doc.qt.io/qt-6/configure-linux-device.html) is the official place to start.
	- And these are the [configure options](https://doc.qt.io/qt-6/configure-options.html) in general.

Given Qt for Device Creation is commercial, I have a feeling the embedded route might be *too hard* and I'm better off pursuing execution on top of Raspberry Pi OS / X11.

#### Cross-compiling Qt

Trying cross-compiling on a DigitalOcean beast. Start with host build:

```
ssh root@188.166.216.202
apt update
apt upgrade
apt install build-essential cmake ninja-build libfontconfig1-dev libdbus-1-dev libfreetype6-dev libicu-dev libinput-dev libxkbcommon-dev libssl-dev libpng-dev libjpeg-dev libglib2.0-dev
apt install libgles2-mesa-dev libgbm-dev libdrm-dev
apt install libx11-dev libxcb1-dev libxext-dev libxi-dev libxcomposite-dev libxcursor-dev libxtst-dev libxrandr-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libxcb-xinput-dev
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtbase-everywhere-src-6.2.3.tar.xz
tar xf qtbase-everywhere-src-6.2.3.tar.xz 
cd qtbase-everywhere-src-6.2.3/
./configure
cmake --build . --parallel
cmake --install .
```

Easy. But useless on its own. Now will it cross compile? Using variations on [this guide](https://wiki.qt.io/Raspberry_Pi_Beginners_Guide) for Qt 5.

```
cd
wget https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2022-01-28/2022-01-28-raspios-bullseye-arm64.zip
apt install unzip
unzip raspios_arm64-2022-01-28/2022-01-28-raspios-bullseye-arm64.zip
mkdir /mnt/rasp-pi-rootfs
fdisk -l 2022-01-28-raspios-bullseye-arm64.img # note "Start" of Linux partition. Let offset = Start * sector size.
mount -o loop,offset=272629760 2022-01-28-raspios-bullseye-arm64.img /mnt/rasp-pi-rootfs
apt install gcc make gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu
rm -R qtbase-everywhere-src-6.2.3
tar xf qtbase-everywhere-src-6.2.3.tar.xz 
```

Okay, how to configure...

See [mkspecs/devices](https://code.qt.io/cgit/qt/qtbase.git/tree/mkspecs/devices) for `-device`. `linux-rasp-pi3-g++` is obvious choice, avoiding `vc4`/`mesa` for now. Bugger - according to [this](https://doc-snapshots.qt.io/qt6-dev/configure-linux-device.html#toolchain-files-versus-device-makespecs), the device makespec approach is "no longer sufficient". Crap - "cross-compiling Qt requires a host build of Qt being available". Shouldn't have deleted it!

Let's try again.

```
./configure -prefix /opt/qt-host
cmake --build . --parallel
cmake --install .
cd ..
mv qtbase-everywhere-src-6.2.3 qtbase-everywhere-src-6.2.3-host
tar xf qtbase-everywhere-src-6.2.3.tar.xz 
mv qtbase-everywhere-src-6.2.3 qtbase-everywhere-src-6.2.3-cross
mkdir qtbasebuild && cd qtbasebuild
vi ../qtbase-everywhere-src-6.2.3-cross/toolchain.cmake # contents below
../qtbase-cross/configure -nomake examples -nomake tests -qt-host-path ../qtbase-host -prefix /usr/local/qt6 -- -DCMAKE_TOOLCHAIN_FILE=../qtbase-cross/toolchain.cmake -DQT_BUILD_TOOLS_WHEN_CROSSCOMPILING=ON
```

Contents of `toolchain.cmake`:

```
cmake_minimum_required(VERSION 3.16)
include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(TARGET_SYSROOT /mnt/rasp-pi-rootfs)
set(CROSS_COMPILER /usr/bin)

set(CMAKE_SYSROOT ${TARGET_SYSROOT})

set(ENV{PKG_CONFIG_PATH} "")
set(ENV{PKG_CONFIG_LIBDIR} ${CMAKE_SYSROOT}/usr/lib/pkgconfig:${CMAKE_SYSROOT}/usr/share/pkgconfig)
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT})

set(CMAKE_C_COMPILER ${CROSS_COMPILER}/aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER ${CROSS_COMPILER}/aarch64-linux-gnu-g++)

set(QT_COMPILER_FLAGS "-march=armv8-a+crc -mtune=cortex-a53 -ftree-vectorize")
set(QT_COMPILER_FLAGS_RELEASE "-O2 -pipe")
set(QT_LINKER_FLAGS "-Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

include(CMakeInitializeConfigs)

function(cmake_initialize_per_config_variable _PREFIX _DOCSTRING)
  if (_PREFIX MATCHES "CMAKE_(C|CXX|ASM)_FLAGS")
    set(CMAKE_${CMAKE_MATCH_1}_FLAGS_INIT "${QT_COMPILER_FLAGS}")

    foreach (config DEBUG RELEASE MINSIZEREL RELWITHDEBINFO)
      if (DEFINED QT_COMPILER_FLAGS_${config})
        set(CMAKE_${CMAKE_MATCH_1}_FLAGS_${config}_INIT "${QT_COMPILER_FLAGS_${config}}")
      endif()
    endforeach()
  endif()

  if (_PREFIX MATCHES "CMAKE_(SHARED|MODULE|EXE)_LINKER_FLAGS")
    foreach (config SHARED MODULE EXE)
      set(CMAKE_${config}_LINKER_FLAGS_INIT "${QT_LINKER_FLAGS}")
    endforeach()
  endif()

  _cmake_initialize_per_config_variable(${ARGV})
endfunction()
```

Failed on OpenGL. Want to use OpenGL Desktop but haven't found the flag. Tried `-opengl es2` which failed with same error. Hmm, seems it's because the `sysroot` has none of the required libaries. How best to install libaries into `sysroot`? [Seems](https://stackoverflow.com/questions/39731894/cross-compile-with-dependencies-how-to-get-target-dependencies-on-host) [to](https://stackoverflow.com/questions/41568496/trying-to-cross-compile-qtwebengine-for-arm7) [be](https://stackoverflow.com/questions/69024955/how-to-deal-with-dependencies-when-cross-compiling) [a](https://stackoverflow.com/questions/67552467/is-there-a-way-to-cross-compile-a-library-without-having-to-manually-compile-eve) [FAQ](https://stackoverflow.com/questions/11796127/how-to-cross-compile-c-library-with-dependencies) [with](https://stackoverflow.com/questions/34040363/how-to-add-library-to-cross-compile-toolchain) [few](https://stackoverflow.com/questions/54870687/build-library-in-target-for-cross-compile-in-host) [solutions](https://stackoverflow.com/questions/18900855/how-to-work-with-external-libraries-when-cross-compiling). One question I came across (and can't find now) even desperately asked "there must be an easy way to do this", and the single answer was effectively "yes, of course" and then trailled off into gate-keeping obscurity, a characteristic you often see in technical circles when pride exceeds knowledge. In my mind, the feasible methods are:

1. Copy them from a Raspberry Pi.
	- Can be sure they're installed correctly, but tricky to ensure you have all the right files and all the paths are intact.
2. Download a binary distribution.
	- Great if it exists...
3. Cross-compile them.
	- A lot of work. Although, the [tttapa/RPi-Cpp-Toolchain](https://tttapa.github.io/Pages/Raspberry-Pi/C++-Development/index.html) repo and docker container makes it as easy as possible. Lots of great work there, which means there's a learning curve just to take advantage of it!
4. Add `dpkg` to the cross-compiling toolchain, as described for [LFS](http://www.linuxfromscratch.org/hints/downloads/files/ATTACHMENTS/dpkg/status)
	- Sounds a bit fanciful, but I don't know much about LFS (Linux From Scratch) or BLFS (Beyond LFS).
5. Use `qemu-debootstrap` to get an emulated [shell](https://stackoverflow.com/a/58422339/3697870).
	- Veeery interesting. Potentially represents the best of all the previous options?

Nearly posted this:

> Hey @team , I’m about to go down a rabbit hole and know a lot of you have seen further than I have. I’m making good progress on a build process for Qt apps on RPi3, but it’s not easy. Which makes me wonder whether I can zoom out and solve the essence of the problem, instead of just the instance. I’m starting to see balena as this sort of translation layer between non-embedded and embedded software development, and wonder whether the pain of porting software that runs on the Desktop or the cloud to a physical (probably-ARM) device is one balena ought to ease.

> So I’m putting my misspent youth, getting Open Source software to run on the evil Darwin OS, to use.

Until I realised I don't know what balena really provides out of the box in terms of qemu and cross-compilation, or even native compilation on arm hardware??

Argh, went down rabbit hole of:

- `qemu-debootstrap` actually creates all new Debian/Ubuntu userspace, instead of "adopting" the Raspberry Pi OS I have.
- So what about emulating a Pi, and using the OS image? Well, [rabbit holes](https://azeria-labs.com/emulate-raspberry-pi-with-qemu/) in [rabbit holes](https://github.com/dhruvvyas90/qemu-rpi-kernel).
- Basically, anything is possible, but you're on your own with the latest 64-bit OS and RPi3, which feels like no-man's land.

After a long battle, and compiling QEMU 6.2.0 from source, I tried:

```
mount -o offset=4194304,sizelimit=268435456 -t vfat 2022-01-28-raspios-bullseye-arm64.img /mnt/rasp-pi-rootfs/boot
cp /mnt/rasp-pi-rootfs/boot/kernel8.img ./
cp /mnt/rasp-pi-rootfs/boot/bcm2710-rpi-3-b-plus.dtb ./
umount /mnt/rasp-pi-rootfs/boot
umount /mnt/rasp-pi-rootfs
qemu-img resize -f raw 2022-01-28-raspios-bullseye-arm64.img 4G
qemu-6.2.0/build/qemu-system-aarch64 -m 1024 -M raspi3b -kernel kernel8.img -dtb bcm2710-rpi-3-b-plus.dtb -drive file=2022-01-28-raspios-bullseye-arm64.img,if=sd,format=raw -append "console=ttyAMA0 root=/dev/mmcblk0p2 rw rootwait rootfstype=ext4" -nographic -device usb-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::5555-:22
```

And it booted!

Successful boot [console log](successful_qemu_boot_console_log.txt). 


So I did

```
sudo apt update
sudo apt remove chromium-browser
sudo apt upgrade # took ages! And kills network on reboot...
sudo apt install build-essential cmake ninja-build libfontconfig1-dev libdbus-1-dev libfreetype6-dev libicu-dev libinput-dev libxkbcommon-dev libssl-dev libpng-dev libjpeg-dev libglib2.0-dev zlib1g-dev
sudo apt install libgles2-mesa-dev libgbm-dev libdrm-dev
sudo apt install libx11-dev libxcb1-dev libxext-dev libxi-dev libxcomposite-dev libxcursor-dev libxtst-dev libxrandr-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libxcb-xinput-dev
sudo raspi-config # Advanced -> graphics driver -> change to GL (Full KMS).
sudo apt install mesa-utils # maybe, maybe bad
exit
```

Now when running configure, OpenGL is found:

```
-- Found OpenGL: /mnt/rasp-pi-rootfs/usr/lib/aarch64-linux-gnu/libOpenGL.so   
-- Found WrapOpenGL: TRUE  
-- Performing Test HAVE_GLESv2
-- Performing Test HAVE_GLESv2 - Success
-- Found GLESv2: /mnt/rasp-pi-rootfs/usr/include  
```

But I realise now I need `qttools` installed. So `rm` all the `-host` dirs. Download the extra submodules:

```
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qttools-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtdeclarative-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtvirtualkeyboard-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtwebsockets-everywhere-src-6.2.3.tar.xz
wget https://download.qt.io/official_releases/qt/6.2/6.2.3/submodules/qtwebview-everywhere-src-6.2.3.tar.xz
```

Un-tar them, mv to `-host` suffixes, then `cd qtbase-host` again. Do plain `./configure`, but this time to `cmake --build . --parallel` and `cmake --install .`. Now `cd` to `qttools-host` and run:

```
/usr/local/Qt-6.2.3/bin/qt-configure-module .
cmake --build . --parallel
cmake --install .
```

Finally:

```
cd ../qtbasebuild
rm -R *
../qtbase-cross/configure -nomake examples -nomake tests -qt-host-path /usr/local/Qt-6.2.3 -prefix /usr/local/qt6 -- -DCMAKE_TOOLCHAIN_FILE=../qtbase-cross/toolchain.cmake
cmake --build . --parallel
```

Oh no, now all the `.so` library symlinks have incorrect paths. Fixed 3 of them manually, and... **boom**, turns out `gcc-aarch64-linux-gnu` is [broken](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=100985). Sigh. Looks like the fixed version is in hirsute (21.04) and impish (21.10). Back to the start, and here we go again...

#### Complete cross-compilation attempt

```
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
```

Build complete! Now to test.

Useful [clarification](https://forums.raspberrypi.com/viewtopic.php?t=260994) on the devilishly complex naming in `vc4-fkms-v3d`/`vc4-kms-v3d`

### Status Stocktake

- qtbase
	- [X] x86_64 compile (relatively easy)
	- [X] arm64 compile
	- [X] target compile (a few hours maybe)
	- [X] cross-compile (runs hello-world-gui successfully)
- qtwebview
	- [X] x86_64 compile
	- [X] arm64 compile (weirdly, requires `libre2-9` and `minizip` on target)
	- [ ] target compile (exhausts 16GB SD card after ~6 hours)
	- [ ] Cross-compile (builds but still have undefined reference / GLIBC_2.34 not found issues at runtime)
- qtwebengine
	- [X] x86_64 compile (about an hour, needs lots of cores, lots of RAM)
	- [X] arm64 compile (need to restart after crash 1000 times, but builds in ~10 hours)
	- [ ] target compile (not a chance)
	- [ ] Cross-compile (can't find `fontconfig` during cross build)
- Docker
	- used for arm64 builds on macOS
	- FROM scratch, COPY bullseye root extracted from img
	- `exec it` then manually run build
	- `docker cp` to extract build, then runs on target
	- `docker commit` fails "no space left on device". Appears to be 10GB limit, so have no way to create image.

Halelujah, a Qt 6 app, built and running on the RPi 3 running a 64-bit OS. [Where's my t-shirt?](https://twitter.com/HeathRaftery/status/1503934255570690048). But webview and webengine are a much tougher nut to crack.

So cross-compilation is getting there, but painfully. With a big clean up of the cross-compilation environment, taking in the lessons from the last big ditch effort, there's every chance of success. But the clock's ticking and after reviewing the strongest horses in that stocktake and where the current project needs to get to, it's time to back the Docker build to try to bring it home.

#### Native compilation with Docker

Okay, the Docker build is going well. With every iteration the `Dockerfile` gets simpler, as I figure out what's not important. It's now kinda embarassingly simple, a mere shadow of the hours and hours and hours that went into it. Some key points:

- Have abandoned the source submodules as a build strategy and am just building from the unified source.
	- Submodules were useful for learning, but the dependencies between them (discovered organically, but actually documented well [here](https://www.tal.org/tutorials/building-qt-62-raspberry-pi)) are complicated and end up meaning you're building many submodules to get a few any way.
	- Plus the build process is just far simpler - instead of building each submodule, you just exclude the ones you don't want by passing `-skip` to `configure`.
	- The drawback is the source tarball is 650MB, but that's an easier pill to swallow than having to incrementally add big submodules instead.
- Have switched to `debian:bullseye` as the base image for now. My cross-compiling experiments with Ubuntu demonstrated that having the same distro and version as the target is more important than having the Raspberry Pi OS itself. The `debian:bullseye` image happens to be official and easy to get. So if it works, it'll do just fine.
	- Have some lingering doubts about whether this will result in optimal support for the Pi's GPU, but at this stage I'm not experiencing any issues.
- Have dropped `qtwebengine` from the build. It adds significant complexity to the process, which actually turns out to be fairly straight-forward without it. There was some doubt about whether `qtwebview` had dependencies on `qtwebengine`, but I've proven by way of a running GUI on the Raspberry Pi 3B+ plus 7" Touchscreen, in X, VNC and bare console forms, that `qtwebengine` is not required.
	- Still including `qtwebengine`'s dependencies, because the impact is fairly negligable and removing them could have unintended consequences.
	- TODO: I think I can substitute this with `balenalib/%%BALENA_MACHINE_NAME%%-debian:bullseye`. I don't know the implications. This is one of the investigations necessary to balena-ify.
	- UPDATE: I was [wrong](https://forum.qt.io/topic/135256/no-webview-plug-in-found-with-qt-6-2-3-on-linux).
- If it turns out there are no runtime issues, this "native compiling in Docker on arm64" could turn out to be far more worthwhile than promoting cross-compilation. It can be done on the Desktop with a Mac M1, and in the cloud on balena's ARM builders. You can't just spin up 16 x86 cores and 128GB of RAM in the cloud and go to town on the build, but in both cases you're still looking at a long build (in ideal circumstances, maybe 30 mins on a maxed out x86 and 45 mins on a M1 Pro, and in non-ideal circumstances they're both going to take hours). So the simplicity of native and of local building is probably worth it.
	- This is not true if `qtwebengine` is added. At that point, more cores and buckets of RAM make a world of difference.
- Biggest issue at the moment is Docker running out of disk space! The more I use Docker the more I realise its slick vaneer covers a rollicking mess below. Still trying to figure out the best hoops to convince Docker to be a little more accommodating of Qt's girth.


Other [Qt 6.2 Configure Options](https://doc.qt.io/qt-6/configure-linux-device.html) to explore:

- `-optimize-size` - seems to be optimizing release builds in terms of resulting binaries size (by sacrificing build time)
- `-static` - see [At last, let's build Qt statically](https://decovar.dev/blog/2018/02/17/build-qt-statically/).
	- Update: requires newer version of CMake. Temporarily in the too hard basket.
- 



Reached a stable place with Docker. Now consists of a multi-stage build, that can start from `balenalib/raspberrypi3-64-debian:buster-build`, that can build Qt from source (excluding `qtwebwengine`), and finish with an *image* that can build Qt projects. Needs 70+GB and 45 mins to build, but resulting image is <2GB. Is a stable place because the path to balena-fication is now low risk. However, this does not appear to be a useful way to develop. So will shelve in a good place, do development using more direct means, and pick back up at the end.

For reference, commands to build and use the image:

```
$ docker build .
$ docker image ls
$ docker run -it <image ID> /bin/bash
$ docker cp src <container ID>:/src
```

Note:

- get <image ID> from the output of `docker image ls` and be wary that Docker's "Created" column is buggy.
- run the `docker cp` command in separate session, because the `docker run` session will be in the container.
- get <container ID> from the prompt that appears in the `docker run` session

Some ideas on how to distribute the image:

```
$ docker save <image> | bzip2 | pv | ssh user@host sudo docker load
```

### Development workflow

On the development front, after much hand-wringing, am satisfied with this workflow:

- extract Qt install from Docker image and copy to RPi
- develop on Desktop in Qt Creator
- sync (`rsync` perhaps) project source to Pi
	- This will do fine, run from the `winot-gui` directory on Desktop: `rsync -a --filter=".- ${HOME}/.gitignore" --filter='.- ../.gitignore' src/ pi@raspberrypi.local:~/Programming/winot/winot-gui/src-cmdline-build`
		- Note there's no automatic delete, because the target may have generated files it wants to keep.
		- [Ref](https://stackoverflow.com/a/63438492/3697870)
- build and test on target over ssh

Still can't understand why I'm the last hold-out in the world from doing dev with Docker. Though [this comment](https://stackoverflow.com/questions/27068596/how-to-include-files-outside-of-dockers-build-context#comment83524633_27068596) brings me some peace.

Okay, back to development. GUI is looking good on the desktop, let's clean it up on device.

First issue is rotation. Flat out doesn't work and it's a nasty thing to search for because it depends on:

- Raspberry Pi 3 or Raspberry Pi 4 (the latter uses a different display driver)
- Raspberry Pi OS Bullseye or Buster (it all changed in Bullseye)
- Date of advice (after Bullseye release, fixes were made around end of 2021 / start of 2022).
- HDMI or DSI
- Touch or just display (need to be rotated individually)
- 180° (inverted) compared to 90° (portrait). Eg. the former can be done with `lcd_rotate=2` but `lcd_rotate=1` doesn't result in the latter.
- Default window manager or different - many solutions are window manager specific.

Only reliable way to rotate screen so far is to use Screen Configuration tool in the RPiOS GUI. It rotates the display, but not the touch. Tracked down its behaviour to being that of `arandr` which is a GUI wrapper for `xrandr` that persists settings by [writing scripts](https://github.com/pimoroni/hyperpixel4/issues/53#issuecomment-567006223) such as `/usr/share/dispsetup.sh` to be executed on boot. Alas, `xrandr` is X only.

So running out of hope for a lower level method, that would work regardless of the user space application. Maybe worth investigating whether `eglfs` itself can rotate. If all else fails, will do it right at the top level in Qt itself, but that would suck.

Looks like setting the `QT_QPA_EGLFS_ROTATION=90` environment variable might be a winner. Bummer, it definitely *shifts* the display, but doesn't rotate it. Ah: "This variable does not apply to OpenGL-based windows, including Qt Quick.".

The trail runs cold in [2017](https://forum.qt.io/topic/76386/qml-rotation-for-scene-and-mouse).

Okay, by sheer determination (aka. trial and error), I have a working solution based on a QML transform. Specifically:

- declare `property bool onTarget: true` in root `Window` component so rotation can be turned off globally for use on desktop, and anticipating that this might not be the only setting that needs to be applied globally for switching between target and desktop.
- flip the root `Window`'s `width` and `height` based on `onTarget`.
- `Window` itself doesn't have a `transform` property, so apply a `Binding` to the `Stack` component, which is the only visual element in the `Window`. Use the `Binding` with a `when` of `onTarget` to set `transform` to `Rotation { origin.x: root.height/2; origin.y: root.height/2; angle: -90 }`. Note the funny origin to accommodate the coordinate space transform.
- Everything automagically works, including touch. Except `Webview`. Oddly, all `Webview`'s have to have their `width` and `height` swapped too.


Set the [barely documented](https://doc.qt.io/qt-6/inputs-linux-device.html) `QT_QPA_EGLFS_HIDECURSOR=1` environment variable to hide the cursor.

## Back to deployment workflow

Okay, am in a good place with the code, running natively on target. Back to running within Docker. Quick experiment installing Docker on native and just running the compiled binary - as expected, shared libraries are going to be a big hassle. Two options:

1. Run the binary from the same image it is built.
	- Pro: low risk - all the bits already exist.
	- Con: image is *chunky*. At the end of the day, what's 1.4GB between friends?
2. Build a static binary.
	- Pro: [finally](https://doc.qt.io/qt-6/linux-deployment.html#static-linking) some confirmation of my hunch - static is the "safest and easiest way to distribute on Unix".
	- Con: building Qt itself statically is currently in too hard basket.
		- Update: pulled it out of the basket. Qt build went fine (requires building CMake from source, but have already crossed bigger bridges than that), all looks in order. But alas, the build of the Qt project fails with the following error, and the trail runs cold. Back in the too hard basket.

```
/usr/bin/ld: /qt/./qml/QtQuick/Controls/Basic/objects-Release/qtquickcontrols2basicstyleplugin_qmlcache/.rcc/qmlcache/qtquickcontrols2basicstyleplugin_qmlcache_loader.cpp.o:(.data.rel.ro._ZN21QmlCacheGeneratedCode65_qt_0x2d_project_0x2e_org_imports_QtQuick_Controls_Basic_Dial_qmlL4unitE+0x0): undefined reference to `QmlCacheGeneratedCode::_qt_0x2d_project_0x2e_org_imports_QtQuick_Controls_Basic_Dial_qml::qmlData'
```

Method #1 works fine and encouraged by my balena guide, so will push ahead. Notes on running:

- Run docker: `docker run -it --priviledged --env UDEV=1 955f57a0613c bash`
	- Only `/dev/dri/card0` is required for the display, and the contents of `/dev/input/` should be enough for touch. Alas, touch still wont work unless `UDEV=1`. Which requires `--priviledged`. Yep, for a kernel-supported touch panel, 'cause Docker.
- Copy in src: `docker cp src 83695ec69017:/src`
- Build src: `cd src; qmake; make`
- Run: `QT_QPA_EGLFS_HIDECURSOR=1 ./winot-gui -platform eglfs`

Packaged it all up in a Dockerfile, including building and running the project source, sent to to the balena builders. Woke in the morning to a functional device! Voila!

Touchscreen looks good (albeit upside down - known issue) although WebView doesn't load...

Looked into WebView issue. Looks like the old "No WebView plug-in found!" issue, which I previously fixed by setting `QT_DEBUG_PLUGINS=1` watching the stdout when the WebView should appear. From memory that revealed a missing library, which was relatively easy to fix. Can't remember the details though, and appears to be the only issue amongst 70 trillion that I fixed, that I didn't document...

Bigger issues though - I set `QT_DEBUG_PLUGINS=1` and re-pushed. It takes 10 minutes just to load the image from cache, but when it ran next... touch no longer worked! What changed? Maybe:

- The addition of `QT_DEBUG_PLUGINS=1`.
- Launch on to an already running blank balenaOS vs pushing a new version.
- Flipping the GUI up the right way.
- Disabling `led-strip-driver` (which is in its own world of pain - a restart spin because "ws2811_init failed with code -3 (Hardware revision is not supported)".
- Putting the case on (and bumping cables).

Have tried toggling each of these potential confounding variables, to no avail.

So back to first principles: oh dear, I'm sure RPiOS was using `edt-ft5x06` as the driver. Turns out balenaOS has `raspberrypi-ts` instead... but that's actually correct! That's the one in the kernel, and Raspberry Pi switched to it back in rpi-5.0.y (which I think corresponds to kernel version 5.0, which was ages ago. RPiOS is 5.10. Certainly the [confirmation](https://github.com/raspberrypi/linux/issues/3412#issuecomment-576193691) was a couple of years ago. So maybe `edt-ft5x06` was never responsible in the first place. But is `raspberrypi-ts` sufficient? Certainly doesn't seem to be - `/dev/input` only have `event0` and I can't get any touch action. But what changed??? Surely it's a bumped cable / power on issue. Nope, still works if I flip back to RPiOS, and no change if I reboot / restart containers / power cycle / re-push / etc.

Basically [this issue](https://forums.raspberrypi.com/viewtopic.php?f=28&t=303680). No solution.

Went deeeep on balenaOS. Eventually found:

- balenaOS 2.65.0+rev1 : no screen
- balenaOS 2.80.3+rev1 : happy days
- balenaOS 2.94.4 : false sense of security

And added kernel version table to [Sheets](https://docs.google.com/spreadsheets/d/1Vril53xEtRFOpUpF5h6KM9TFz6D7Ar1aQKYEL28-_Lo/edit?usp=sharing).

So 2.80.3+rev1 seems to be going good. Right up until I rotate the display +90 instead of -90! Suddenly no touch! Couldn't possibly be software - why would the direction matter?

Except... oh dear, just found `cat /dev/input/event0` produces output with *either* rotation! But in one case they're not being registered. WTF??

Hmm, `evtest` (installed in `winot_gui` container) even reports correct coordinates.

Similar issues [here](https://forum.qt.io/topic/78340/screen-rotation-does-not-handle-mouse-clicks-properly/3). No solution.

Okay `rev9` is a clean build. `rev10` is `CMD /bin/bash`.

OMG. The "false sense of security” turns out to simply be a bad balena builder build.

- winot release [0.0.0-rev7](https://dashboard.balena-cloud.com/fleets/1918105/releases/2112182) was built largely from cache. The only code change was to rotate the GUI 90° instead of -90°, way up in the painting layer of QML. Build duration: 12:52.
  - Behaviour: no touch response. But `evtest` running in the gui container reports correct coordinates when touching the screen! Otherwise identical as far as I can see to rev9.
- winot release [0.0.0-rev9](https://dashboard.balena-cloud.com/fleets/1918105/releases/2112220) was built with cache disabled (`-c`), but otherwise **no** code change. Build duration: 37:14.
  - Behaviour: sweet as a button. No issues.

Back when I was on 2.94.4 the cache build *seemed* weird - a strange combination of re-build and cache pull and new layer generation. But I’m new and there was 70 zillion other potential causes, so I had to eliminate them first. Now looking back at the build log stored on the cloud, it doesn’t seem unusual, so I’m not sure what I saw.

So I don’t know what went wrong, but everything is hunky-dory now. I suggest that I can replace "false sense of security” in the 2.94.4 row above with "happy days", but given I’m now on 2.80.3+rev1, and this little detour has taken me about 12 hours, I’m not all that motivated to test it to make sure.

From internal conversation:

---

> if your app runs in newer balenaOS version where we have `vc4-kms-v3d` as default, your app might not work
> 
> you can enforce `vc4-fkms-v3d` by using a fleet/dev config variable, `BALENA_HOST_CONFIG_dtoverlay=vc4-fkms-v3d` 
> 
> you can add it to your app's `balena.yml`

Great summary, thank you. Two clarifications:

- I’m still unsure which is the “right” overlay for RPi3 - things seem to have changed in the last 6 months or so, and there’s [opinions](https://forums.raspberrypi.com/viewtopic.php?p=1866277#p1866277) and [suggestions](http://psychtoolbox.org/docs/RaspberryPiSetup) that `vc4-kms-v3d` is now preferred for the RPi3, but it’s pretty [wild](https://github.com/raspberrypi/linux/issues/4516) out there.

Why the build went bad is still a open sore, but now I can separate it from driver/overlay issues, progress is much easier.

> yeah `vc4-kms-v3d` is supposed to be the recommended one but it is not on par with the firmware driver which has more features. but kms is using open source drivers and the rpi foundation is pushing towards that, same with the camera library stack
> 
> fwiw, on RPiOS bullseye, `vc4-kms-v3d` is the default

---

Okay, on to the next issue: [No WebView plug-in found!](https://forum.qt.io/topic/135256/no-webview-plug-in-found-with-qt-6-2-3-on-linux).

Took the advice from that thread and kicked off a build including webengine. Sure enough, it crashed, no doubt due to OOM. So have kicked off another one that just retries 15 times. Has been running for several hours (gets really slow when near OOM) and making incremental progress, but looks like 15 times wont cut it. So can either brute force it:

```
for retry in {1..200}; do
	cmake --build . --parallel && break
done
```

Or back off and go slower:

```
cmake --build . --parallel || CMAKE_BUILD_PARALLEL_LEVEL=4 cmake --build . --parallel
```

Haven't tried either yet - it's a many hour process. In the meantime, managed to pull the compiled Qt tarball from the Macbook, `cp` it to the balena container, and confirm that yes indeed, having `webengine` fixes things. Perhaps I should just include the tarball in my context and abandon hope of building in the cloud?

Although note that because the balena container runs as root (there are no other users), and `webengine` thinks that's a bit much to be running a browser, you get this error: 

```
ERROR:zygote_host_impl_linux.cc(89)] Running as root without --no-sandbox is not supported. See https://crbug.com/638180.
```

The link is useless, but the error is self-explanatory. Unfortunately, I can't run `winot-gui` as non-root because it doesn't have permission to access `/dev/dri/core0` (which seems wrong), but fortunately passing the `--no-sandbox` flag does work. I'd prefer to run as non-root, but it looks like balena hasn't published [a](https://forums.balena.io/t/running-as-root-without-no-sandbox-is-not-supported/18845) [solution](https://forums.balena.io/t/create-a-non-root-user-on-x11-window-manager/63131).

So current avenues of pursuit:

1. WebView without WebEngine
	- **ABANDONED**. Assumed not possible on Linux.
1. Build WebEngine
	1. Brute force.
		- **TRIAL UNDERWAY**
	1. Back off on failure.
		- **NEXT TO TRIAL**
	1. Tarball in context + `ADD`.
		- Low risk backup plan.
1. WebView working on device.
	- **CONFIRMED** with MacBook build of webengine.
1. `led-strip-driver` hardware incompatibility issue.
	- **INVESTIGATION UNDERWAY** while the brute force trial runs in background.


On to the `led-strip-driver` hardware incompatibility issue.

> ws2811_init failed with code -3 (Hardware revision is not supported)

Will check source to see what the test is.

Found it. Guess what, another "fix it with privileged" issue... I've painstakingly documented why in the issue linked [here](https://stackoverflow.com/a/71602410/3697870).

## On the home stretch

Well that's the blockers unblocked. What's left to do?

1. RPi case.
2. Hooking up `winot-gui` to `led-strip-driver`.
3. Connecting LED strip to protoboard.
4. Snipping/soldering LED strip.
5. LED cases.
6. Procure a wine rack.
7. Assemble!

Update on "Brute force" avenue: abandoned after ~24 hours build time. Was still making progress, but that's too long not to be done. Always bogs down on tasks like: `CXX obj/third_party/blink/renderer/core/core/core_jumbo_17.o` where the two digits vary. Apparently "jumbo" is an innovation that dramatically speeds up the compilation time of Blink (the Chromium renderer), which was getting out of hand!

Moving on to "Back off on failure" avenue. Well that was inconclusive - it breezed through the whole thing in <2 hours with no crashes! Ah predicatability, how I miss thee.

Case is done. Very intricate, story to come.

Connecting LED strip to protoboard is done.

Snipping/soldering LED strip is done.

LED cases eliminated.

Wine rack procured.

Assembly done!

New todo list:

1. Hook up `winot-gui` to `led-strip-driver`.
2. Coil scanner cable.
3. Hack in a cellar tracker login. Virtual keyboard investigation is sucking up time. Might be best just to plug in a keyboard or print some barcodes and use the scanner!
4. Prevent "Login timed out after 60 seconds" from taking over display! Workaround is to wait and then reboot GUI.
5. Re-print case after correcting mount positions, radius and hole depth? A lot of work to re-assemble...
6. Generate some fake data.
7. Switch to WiFI.
8. Peel off screen film.
9. Create vid.

Working on #1.

Aaaaargh! How hard can it be? Looked like a walk in the park - QML supports `XMLHttpRequest`, so simply fire a few `PUT`'s in response to user action. But bloody 'ell. Turns out `XMLHttpRequest`, when asked to make the most basic of HTTP call (no HTTPS, no DNS, no body, no JSON, no frills), actually sends a unnecessarily complicated HTTP/2 upgrade request, which `uvicorn` borks at and it all falls down. Went down a rabbit hole of making `uvicorn` more robust only to discover it was a wild goose chase. Changing `XMLHttpRequest`'s behaviour was similarly frustrating, with lots of half baked ideas all over the web, none of which make a lick of difference.

Ended up abandoning `XMLHttpRequest` and calling out to a C++ class instead, which uses `QNetworkRequest`. Pulling on that thread let me to unravel `QNetworkAccessManager`, `QJsonDocument`, `QJsonValue`, and `QJsonArray`, none of which made the job of constructing a 7 element array of identical integers any easier, but could at least send a sane HTTP message over the LAN. Then I just needed to discover that `fastapi` chokes on empty bodies, and you have to explicitly specify that an empty body is okay, and all the Internet guidance on doing so is misleading, but with "modern programming practices" (copy and paste and hope and repeat until successful), I fixed it.

Easy. `winot-gui` and `led-strip-driver` are hooked up.

Todo's #2, #3, #4 I'll park for now, and just work on #5 tonight because then I can leave the printer running overnight.

Fixes on #5 worked! The screw tunnel is brilliant. Screw dropped in one end, and with a bit of a push from the driver, pops out neatly on the other end! Improvements for next time:

- Stupid [Internet](https://forums.raspberrypi.com/viewtopic.php?t=192936) was wrong again on the corner radius. Changing from 6mm to 6.5mm was not enough. Maybe 7 to 8mm would be better.
- Despite increasing the screw shelf height from 2mm to 2.8mm to compensate for removal of the washer the screw now pokes out a touch too far. Go to 3.8 or 4mm.

Now to #3 - thinking I might do it with keyboard first while I have the until disassembled and USB ports handy, but then just monitor what I'm doing and print barcodes to repeat it later when unit is assembled.

Family is not allowing computer time this arvo, so will do #2 in the meantime.

Task #2 was quite successful. On to #3. Done. Barcode method was easiest! Now GUI crashes occassionally with "Could not queue DRM page flip on screen DSI1 (Invalid argument)". Seems to be correlated with me trying to run the container with the `--privileged` flag to try to pick up the keyboard (which didn't work anyway, just have to make sure scanner and keyboard were plugged in before running the container). Hope that goes away.

Skip #4. #5 done. On to #6. Will get some real bottles to use as fake data.

By the way, the rsync method of rapid development needs some extra leaps because of course Docker makes everything harder. Now need to sync *from* the container to ensure the code ends up in the right spot, which means we lose the ability to filter based on gitignore. Oh well, nothing about this is ideal. This will do: `rsync -av --exclude='build*' liteyear@192.168.0.110:~/EmpiricalEE/Balena/repos/winot/winot-gui/src/ ./`.

Hmm, those DRM page flip crashes I was talking about happen whenever I show the webview, possible only when I input data with the scanner. Magically, setting `QT_QPA_EGLFS_ALWAYS_SET_MODE=1 QT_QPA_EGLFS_KMS_ATOMIC=1` seems to [fix things](https://stackoverflow.com/questions/64731435/problem-when-deploying-qt-app-on-raspberry-pi-4-could-not-queue-drm-page-flip-o). I don't know what makes this work, but just `QT_QPA_EGLFS_ALWAYS_SET_MODE` is not enough. Screen still goes blank (no idea why) but wakes up with a tap.

Demo Script:

1. PUT Barramundi Shariz in slot 5.
2. GET Feet on the ground from slot 2.
3. DRANK On the Grapevine.
4. RETURN Wiley Rooster into slot 2.

Phew, #6 done. Now #7.

WiFi was a matter of following the instructions! What a relief.

Time to bite the bullet and do #8. Film off!

And just a quick little #9 to finish off, right? Right? Oh my... 20 hours later, I've earned a deep appreciation for people that can make videos. </struggle-town>

At least I managed to find 1000 ways you can’t [record the screen of a eglfs app on Raspberry Pi](https://unix.stackexchange.com/questions/697188/how-to-record-screen-when-using-eglfs-on-broadcom-videocore-iv).

Finit.