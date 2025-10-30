# Test Suite CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

# Enable testing
enable_testing()

# ============================================================================
# End-to-End Test
# ============================================================================
set(CMAKE_AUTOMOC ON)

add_executable(test_e2e
    test_e2e.cpp
    ${CMAKE_SOURCE_DIR}/src/app/steganography.cpp
    ${CMAKE_SOURCE_DIR}/include/app/steganography.h
)

target_link_libraries(test_e2e
    PRIVATE
        Qt::Core
        Qt::Gui
        Qt::Qml
)

target_include_directories(test_e2e
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include/app
)

message(STATUS "End-to-end test configured")

# ============================================================================
# Debug LSB Logic Test
# ============================================================================
set(CMAKE_AUTOMOC ON)

add_executable(debug_lsb
    debug_lsb.cpp
)

target_link_libraries(debug_lsb
    PRIVATE
        Qt::Core
        Qt::Gui
)

message(STATUS "Debug LSB test configured")

# ============================================================================
# Simple Test (No Google Test dependency)
# ============================================================================
# Enable MOC for Qt meta-object compilation
set(CMAKE_AUTOMOC ON)

add_executable(simple_test
    simple_test.cpp
    ${CMAKE_SOURCE_DIR}/src/app/steganography.cpp
    ${CMAKE_SOURCE_DIR}/include/app/steganography.h
)

target_link_libraries(simple_test
    PRIVATE
        Qt::Core
        Qt::Gui
        Qt::Qml
)

target_include_directories(simple_test
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include/app
)

message(STATUS "Simple test executable configured")

# ============================================================================
# Full Test Suite (Requires Google Test)
# ============================================================================
find_package(GTest QUIET)

if(GTEST_FOUND)
    message(STATUS "Google Test found - building full test suite")
    include(GoogleTest)

    # Include directories
    include_directories(
        ${CMAKE_SOURCE_DIR}/include/app
        ${CMAKE_SOURCE_DIR}/include/opencv_player
        ${GTEST_INCLUDE_DIRS}
        ${OpenCV_INCLUDE_DIRS}
    )

    # Test utilities library
    add_library(test_utils STATIC
        test_utils.cpp
    )

    target_link_libraries(test_utils
        PUBLIC
            Qt::Core
            Qt::Gui
            ${OpenCV_LIBS}
    )

    # Unit Tests
    set(TEST_SOURCES
        unit/test_steganography.cpp
        unit/test_steganography_edge_cases.cpp
        unit/test_steganography_performance.cpp
    )

    add_executable(steganography_tests
        ${TEST_SOURCES}
        ${CMAKE_SOURCE_DIR}/src/app/steganography.cpp
    )

    target_link_libraries(steganography_tests
        PRIVATE
            GTest::GTest
            GTest::Main
            Qt::Core
            Qt::Gui
            Qt::Qml
            ${OpenCV_LIBS}
            test_utils
    )

    # Discover tests
    gtest_discover_tests(steganography_tests)
    
    # Extract Encoded Image Test (separate executable for focused testing)
    add_executable(test_extract_encoded_image
        unit/test_extract_encoded_image.cpp
        ${CMAKE_SOURCE_DIR}/src/app/steganography.cpp
        ${CMAKE_SOURCE_DIR}/include/app/steganography.h
    )
    
    set_target_properties(test_extract_encoded_image PROPERTIES
        AUTOMOC ON
    )

    target_link_libraries(test_extract_encoded_image
        PRIVATE
            GTest::GTest
            GTest::Main
            Qt::Core
            Qt::Gui
            Qt::Qml
            ${OpenCV_LIBS}
            test_utils
    )
    
    target_include_directories(test_extract_encoded_image
        PRIVATE
            ${CMAKE_SOURCE_DIR}/include/app
    )

    # Discover extract tests
    gtest_discover_tests(test_extract_encoded_image)

    # Full process end-to-end test
    add_executable(test_full_process_e2e
        test_full_process_e2e.cpp
        ${CMAKE_SOURCE_DIR}/src/app/steganography.cpp
        ${CMAKE_SOURCE_DIR}/include/app/steganography.h
    )
    
    set_target_properties(test_full_process_e2e PROPERTIES
        AUTOMOC ON
    )
    
    target_link_libraries(test_full_process_e2e
        PRIVATE
            GTest::gtest
            GTest::gtest_main
            Qt::Core
            Qt::Gui
            Qt::Qml
            opencv_core
            opencv_imgcodecs
            opencv_imgproc
            opencv_videoio
            test_utils
    )
    
    target_include_directories(test_full_process_e2e
        PRIVATE
            ${CMAKE_SOURCE_DIR}/include/app
            ${CMAKE_CURRENT_SOURCE_DIR}
    )

    # Discover full process e2e tests
    gtest_discover_tests(test_full_process_e2e)

    # Copy test data
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/data
         DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

    message(STATUS "Full test suite configured with Google Test")
else()
    message(STATUS "Google Test not found - only simple_test will be built")
    message(STATUS "To install Google Test: sudo apt-get install libgtest-dev")
endif()
