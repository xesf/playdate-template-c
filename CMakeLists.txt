cmake_minimum_required(VERSION 3.14)
set(CMAKE_C_STANDARD 11)

set(ENVSDK $ENV{PLAYDATE_SDK_PATH})

if (NOT ${ENVSDK} STREQUAL "")
    # Convert path from Windows
    file(TO_CMAKE_PATH ${ENVSDK} SDK)
else()
    execute_process(
        COMMAND bash -c "egrep '^\\s*SDKRoot' $HOME/.Playdate/config"
        COMMAND head -n 1
        COMMAND cut -c9-
        OUTPUT_VARIABLE SDK
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif()

if (NOT EXISTS ${SDK})
    message(FATAL_ERROR "SDK Path not found; set ENV value PLAYDATE_SDK_PATH")
    return()
endif()

set(CMAKE_CONFIGURATION_TYPES "Debug;Release")
set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

set(PLAYDATE_GAME_NAME template)
set(PLAYDATE_GAME_DEVICE template)

# Set to ON to build a demo version
option(DEMO "Build demo version" OFF)

project(${PLAYDATE_GAME_NAME} C ASM)

set(SOURCE_FILES
        src/main.c
)

# Track resource files so changes trigger rebuild
set(RESOURCE_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/Source/pdxinfo
)

# Mark resource files as "header" files so they don't get compiled but are tracked
set_source_files_properties(${RESOURCE_FILES} PROPERTIES HEADER_FILE_ONLY TRUE)

file(GLOB IMAGES
	"Source/images/*"
)

# --- Auto-increment version on each build ---
add_custom_target(bump_version
        COMMAND ${CMAKE_COMMAND}
                -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
                -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/bump_version.cmake
        COMMENT "Bumping patch version and buildNumber"
)

if (TOOLCHAIN STREQUAL "armgcc")
        add_executable(${PLAYDATE_GAME_DEVICE} ${SOURCE_FILES} ${RESOURCE_FILES})
        add_dependencies(${PLAYDATE_GAME_DEVICE} bump_version)
        if (DEMO)
                target_compile_definitions(${PLAYDATE_GAME_DEVICE} PRIVATE DEMO)
        endif()
else()
        add_library(${PLAYDATE_GAME_NAME} SHARED ${SOURCE_FILES} ${IMAGES} ${RESOURCE_FILES})
        add_dependencies(${PLAYDATE_GAME_NAME} bump_version)
        if (DEMO)
                target_compile_definitions(${PLAYDATE_GAME_NAME} PRIVATE DEMO)
        endif()
endif()

# Custom target to re-run pdc when resources change
if (DEMO)
    add_custom_target(bundle_resources ALL
            COMMAND ${SDK}/bin/pdc -sdkpath ${SDK} ${CMAKE_CURRENT_SOURCE_DIR}/Source ${CMAKE_CURRENT_SOURCE_DIR}/${PLAYDATE_GAME_NAME}.pdx
            COMMAND sed -i '' "s/name=.*/name=Template Demo/" ${CMAKE_CURRENT_SOURCE_DIR}/${PLAYDATE_GAME_NAME}.pdx/pdxinfo
            COMMAND sed -i '' "s/bundleID=\(.*\)/bundleID=\1-demo/" ${CMAKE_CURRENT_SOURCE_DIR}/${PLAYDATE_GAME_NAME}.pdx/pdxinfo
            DEPENDS ${RESOURCE_FILES}
            COMMENT "Bundling resources with pdc (demo)"
    )
else()
    add_custom_target(bundle_resources ALL
            COMMAND ${SDK}/bin/pdc -sdkpath ${SDK} ${CMAKE_CURRENT_SOURCE_DIR}/Source ${CMAKE_CURRENT_SOURCE_DIR}/${PLAYDATE_GAME_NAME}.pdx
            DEPENDS ${RESOURCE_FILES}
            COMMENT "Bundling resources with pdc"
    )
endif()
if (TOOLCHAIN STREQUAL "armgcc")
        add_dependencies(bundle_resources ${PLAYDATE_GAME_DEVICE})
else()
        add_dependencies(bundle_resources ${PLAYDATE_GAME_NAME})
endif()

# Package device build to releases folder
if (TOOLCHAIN STREQUAL "armgcc")
        set(RELEASE_SUFFIX "")
        if (DEMO)
                set(RELEASE_SUFFIX "-demo")
        endif()
        add_custom_target(package_device
                COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_SOURCE_DIR}/releases
                COMMAND ${CMAKE_COMMAND}
                        -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
                        -DGAME_NAME=${PLAYDATE_GAME_NAME}
                        -DRELEASE_SUFFIX=${RELEASE_SUFFIX}
                        -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/package_release.cmake
                DEPENDS bundle_resources
                COMMENT "Packaging device build to releases folder"
        )
endif()

include(${SDK}/C_API/buildsupport/playdate_game.cmake)
