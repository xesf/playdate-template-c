# package_release.cmake
# Reads the current version from Source/pdxinfo and creates a versioned zip.

set(PDXINFO_FILE "${SOURCE_DIR}/Source/pdxinfo")

# Read version from pdxinfo
file(READ "${PDXINFO_FILE}" PDXINFO_CONTENT)
string(REGEX MATCH "version=([0-9]+\\.[0-9]+\\.[0-9]+)" _match "${PDXINFO_CONTENT}")
set(VERSION "${CMAKE_MATCH_1}")

string(REGEX MATCH "buildNumber=([0-9]+)" _match "${PDXINFO_CONTENT}")
set(BUILD_NUMBER "${CMAKE_MATCH_1}")

set(ZIP_NAME "${GAME_NAME}_v${VERSION}-${BUILD_NUMBER}${RELEASE_SUFFIX}.pdx.zip")

message(STATUS "Packaging ${ZIP_NAME}")

execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar "cfv"
        "${SOURCE_DIR}/releases/${ZIP_NAME}"
        --format=zip
        "${GAME_NAME}.pdx"
    WORKING_DIRECTORY "${SOURCE_DIR}"
)
