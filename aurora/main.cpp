#include <flutter/flutter_aurora.h>
#include <flutter/flutter_compatibility_qt.h>  // <- Add for Qt
#include "generated_plugin_registrant.h"

int main(int argc, char* argv[]) {
    aurora::FlutterApp app(argc, argv);
    aurora::EnableQtCompatibility();                              // Enable Qt
    return app.exec();
}
