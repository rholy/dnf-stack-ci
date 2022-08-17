Feature: --security upgrades


Scenario: --security upgrade with advisories with pkgs of different arches
Given I use repository "security-upgrade"
  And I execute dnf with args "install json-c-1-1 bind-libs-lite-1-1"
 When I execute dnf with args "upgrade --security"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                     |
      | upgrade       | bind-libs-lite-0:2-2.x86_64 |
      | upgrade       | json-c-0:2-2.x86_64         |

