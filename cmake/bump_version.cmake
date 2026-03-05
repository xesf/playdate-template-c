# bump_version.cmake
# Automatically increments the buildNumber in Source/pdxinfo
#
# pdxinfo version field: X.Y.Z  (plain, no build suffix)
# pdxinfo buildNumber:   incremented each bump

set(PDXINFO_FILE "${SOURCE_DIR}/Source/pdxinfo")

# --- Read pdxinfo ---
file(READ "${PDXINFO_FILE}" PDXINFO_CONTENT)

# Extract current version (major.minor.patch)
string(REGEX MATCH "version=([0-9]+)\.([0-9]+)\.([0-9]+)" _match "${PDXINFO_CONTENT}")
set(VERSION_MAJOR "${CMAKE_MATCH_1}")
set(VERSION_MINOR "${CMAKE_MATCH_2}")
set(VERSION_PATCH "${CMAKE_MATCH_3}")

# Extract current buildNumber
string(REGEX MATCH "buildNumber=([0-9]+)" _match "${PDXINFO_CONTENT}")
set(BUILD_NUMBER "${CMAKE_MATCH_1}")

# --- Increment ---
math(EXPR NEW_BUILD "${BUILD_NUMBER} + 1")

set(BASE_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

message(STATUS "Version: ${BASE_VERSION} (unchanged)")
message(STATUS "Bumping buildNumber: ${BUILD_NUMBER} -> ${NEW_BUILD}")

# --- Update pdxinfo ---
# version stays as plain X.Y.Z (no build suffix)
string(REGEX REPLACE
    "version=[0-9]+\\.[0-9]+\\.[0-9]+"
    "version=${BASE_VERSION}"
    PDXINFO_CONTENT "${PDXINFO_CONTENT}"
)
string(REGEX REPLACE
    "buildNumber=[0-9]+"
    "buildNumber=${NEW_BUILD}"
    PDXINFO_CONTENT "${PDXINFO_CONTENT}"
)
file(WRITE "${PDXINFO_FILE}" "${PDXINFO_CONTENT}")

message(STATUS "Version updated: pdxinfo=${BASE_VERSION}, build=${NEW_BUILD}")
