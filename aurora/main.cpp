#include <flutter/flutter_aurora.h>
#include <flutter/flutter_compatibility_qt.h>

int main(int argc, char* argv[]) {
    aurora::Initialize(argc, argv);
    
    aurora::EnableQtCompatibility();
    
    aurora::Launch();
    
    return 0;
}
