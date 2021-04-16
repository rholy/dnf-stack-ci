@use.with_os=fedora__ge__31
Feature: Test the system-upgrade plugin with comps


Background:
  Given I enable plugin "system_upgrade"
    And I use repository "system-upgrade-comps-f$releasever"


Scenario: Upgrade group when there are new package versions - upgrade packages
  Given I successfully execute dnf with args "group install A-group"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | upgrade       | A-mandatory-0:2.0-1.x86_64         |
        | upgrade       | A-default-0:2.0-1.x86_64           |
        | group-upgrade | A-group                            |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | upgrade       | A-mandatory-0:2.0-1.x86_64         |
        | upgrade       | A-default-0:2.0-1.x86_64           |
        | group-upgrade | A-group                            |


Scenario: Upgrade group when there are new packages - install new packages
  Given I successfully execute dnf with args "group install AB-group"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | upgrade       | A-mandatory-0:2.0-1.x86_64         |
        | upgrade       | A-default-0:2.0-1.x86_64           |
        | install-group | B-mandatory-0:1.0-1.x86_64         |
        | install-group | B-default-0:1.0-1.x86_64           |
        | group-upgrade | AB-group                           |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | upgrade       | A-mandatory-0:2.0-1.x86_64         |
        | upgrade       | A-default-0:2.0-1.x86_64           |
        | install-group | B-mandatory-0:1.0-1.x86_64         |
        | install-group | B-default-0:1.0-1.x86_64           |
        | group-upgrade | AB-group                           |


Scenario: Upgrade group when there were excluded packages during installation - don't install these packages
  Given I successfully execute dnf with args "group install A-group --exclude=A-mandatory,A-default,A-optional"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | group-upgrade | A-group                            |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | group-upgrade | A-group                            |


Scenario: Upgrade group when there were removed packages since installation - don't install these packages
  Given I successfully execute dnf with args "group install A-group"
    And I successfully execute dnf with args "remove A-mandatory A-default"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | group-upgrade | A-group                            |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | group-upgrade | A-group                            |


Scenario: Upgrade environment when there are new groups/packages - install new groups/packages
  Given I successfully execute dnf with args "group install AB-environment"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | upgrade       | A-mandatory-0:2.0-1.x86_64         |
        | upgrade       | A-default-0:2.0-1.x86_64           |
        | install-group | B-mandatory-0:1.0-1.x86_64         |
        | install-group | B-default-0:1.0-1.x86_64           |
        | group-install | B-group                            |
        | group-upgrade | A-group                            |
        | env-upgrade   | AB-environment                     |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | upgrade       | A-mandatory-0:2.0-1.x86_64         |
        | upgrade       | A-default-0:2.0-1.x86_64           |
        | install-group | B-mandatory-0:1.0-1.x86_64         |
        | install-group | B-default-0:1.0-1.x86_64           |
        | group-install | B-group                            |
        | group-upgrade | A-group                            |
        | env-upgrade   | AB-environment                     |


Scenario: Upgrade environment when there were excluded packages during installation - don't install these packages
  Given I execute dnf with args "group install A-environment --exclude=A-mandatory,A-default,A-optional"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                            |
        | group-upgrade | A-group                            |
        | env-upgrade   | A-environment                      |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | group-upgrade | A-group                            |
        | env-upgrade   | A-environment                      |


Scenario: Upgrade environment when there were removed packages since installation - don't install these packages
  Given I successfully execute dnf with args "group install A-environment"
    And I successfully execute dnf with args "remove A-mandatory A-default"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | group-upgrade | A-group                            |
        | env-upgrade   | A-environment                      |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | group-upgrade | A-group                            |
        | env-upgrade   | A-environment                      |


Scenario: Upgrade empty group
  Given I successfully execute dnf with args "group install empty-group"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | group-upgrade | empty-group                        |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | group-upgrade | empty-group                        |


Scenario: Upgrade empty environment
  Given I successfully execute dnf with args "group install empty-environment"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | env-upgrade   | empty-environment                  |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | env-upgrade   | empty-environment                  |


Scenario: Upgrade environment when all groups are removed
  Given I successfully execute dnf with args "group install A-environment"
    And I successfully execute dnf with args "group remove A-group"
    And I set releasever to "30"
    And I use repository "system-upgrade-comps-f$releasever" as http
    And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"
   When I execute dnf with args "system-upgrade download"
   Then the exit code is 0
    And DNF Transaction is following
        | Action        | Package                            |
        | env-upgrade   | A-environment                      |
  Given I successfully execute dnf with args "system-upgrade reboot"
    And I stop http server for repository "system-upgrade-comps-f$releasever"
   When I execute dnf with args "system-upgrade upgrade"
   Then the exit code is 0
    And transaction is following
        | Action        | Package                            |
        | env-upgrade   | A-environment                      |
