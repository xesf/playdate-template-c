# Playdate C Template

A starter template for developing Playdate games using C and CMake.
You will be able to build, debug and run your game on both the Playdate Simulator and the actual device.

![Playdate Simulator](Screenshots/simulator.png)

## Prerequisites

- [Playdate SDK](https://play.date/dev/)
- CMake 3.14 or later
- Make sure `PLAYDATE_SDK_PATH` is set in your environment, or `SDKRoot` is configured in `${userHome}/.Playdate/config`

## Resources

- [Playdate SDK Documentation](https://sdk.play.date/)
- [Inside Playdate C API](https://sdk.play.date/Inside%20Playdate%20with%20C.html)
- [Playdate Developer Forum](https://devforum.play.date/)

## Project Structure

```
template_c/
├── .vscode/         # VSCode configuration
├── src/
│   └── main.c       # Main game source code
├── Source/
│   ├── pdxinfo      # Game metadata
│   ├── images/      # Image assets
│   └── sounds/      # Sound assets
├── .gitignore       # Git ignore file
├── CMakeLists.txt   # CMake build configuration
├── LICENSE          # License file
└── README.md        # This README file
```

## Build Steps

Note, all these steps where made and tested on macOS. Adjust accordingly for other Linux or Windows operating systems.

Playdate SDK must be installed and expected under /Users/{username}/Developer and `PLAYDATE_SDK_PATH` environment variable set to the SDK location. If you have it in a different location, adjust the paths accordingly.

### VSCode

Use the VSCode debugger (F5) to launch the Playdate Simulator with the built `.pdx` file.


### Build for Simulator (CMake)

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug

cmake --build build
```

This will create a `template.pdx` folder that can be run in the Playdate Simulator.

### Build for Device (CMake)

```bash
cmake -B build-device -DCMAKE_BUILD_TYPE=Release -DTOOLCHAIN=armgcc --toolchain=$PLAYDATE_SDK_PATH/C_API/buildsupport/arm.cmake

cmake --build build-device
```

### Clean Build

```bash
rm -rf build build-device
```

## Run

### VSCode

Use the VSCode debugger (F5) to launch the Playdate Simulator with the built `.pdx` file. You can set breakpoints and step through your code.

### Simulator (Manual)

Open the Playdate Simulator and drag the `template.pdx` folder onto it, or:

```bash
open $PLAYDATE_SDK_PATH/bin/Playdate\ Simulator.app template.pdx
```

### Device

Connect your Playdate via USB and use the Simulator to sideload the `.pdx` file.

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

See LICENSE file for full details.
