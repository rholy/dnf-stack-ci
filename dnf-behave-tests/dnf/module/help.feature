Feature: Module usage help

Scenario: I can print help using dnf module --help
 When I execute dnf with args "module --help"
 Then stdout contains "usage: .+ module \[-c CONFIG_FILE\]"

Scenario: I can print help using dnf module -h
 When I execute dnf with args "module -h"
 Then stdout contains "usage: .+ module \[-c CONFIG_FILE\]"
