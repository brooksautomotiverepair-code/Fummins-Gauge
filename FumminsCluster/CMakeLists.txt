cmake_minimum_required(VERSION 3.16)

project(FumminsCluster VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appFumminsCluster
    main.cpp
)

qt_add_qml_module(appFumminsCluster
    URI FumminsCluster
    QML_FILES
        Main.qml
        QML_FILES SimData.qml
        QML_FILES GaugeNeedle.qml
    RESOURCES
        assets/needles/Needle4.png
        assets/needles/ned.png
        assets/needles/Needle2.png
        assets/needles/Needle21.png
        assets/icons/pto.png
        assets/icons/park_brake.png
        assets/icons/high_beam.png
        assets/icons/turn_right.png
        assets/icons/turn_left.png
        assets/icons/low_fuel.png
        assets/icons/cel.png
        assets/boot/boot_logo.png
        assets/boot/boot_logo.png


        QML_FILES GaugeFace.qml
        QML_FILES RoundGauge.qml
        QML_FILES LCDPlate.qml
        QML_FILES TelltaleIcon.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appFumminsCluster PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appFumminsCluster
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appFumminsCluster
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appFumminsCluster
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
