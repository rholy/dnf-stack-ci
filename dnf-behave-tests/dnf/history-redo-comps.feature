Feature: Transaction history redo - comps


Background:
  Given I use repository "dnf-ci-fedora"
    And I use repository "dnf-ci-thirdparty"
    And I successfully execute dnf with args "group install DNF-CI-Testgroup"
   Then Transaction is following
        | Action        | Package                           |
        | group-install | DNF-CI-Testgroup                  |
        | install-group | filesystem-0:3.9-2.fc29.x86_64    |
        | install-group | lame-0:3.100-4.fc29.x86_64        |
        | install-dep   | setup-0:2.12.1-1.fc29.noarch      |
        | install-dep   | lame-libs-0:3.100-4.fc29.x86_64   |
    And History is following
        | Id     | Command                               | Action        | Altered   |
        | 1      | group install DNF-CI-Testgroup        | Install       | 5         |


Scenario: Redo a transaction that installed a group
  Given I successfully execute dnf with args "remove lame"
   When I execute dnf with args "history redo 1"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                           |
        | group-install | DNF-CI-Testgroup                  |
        | install-group | lame-0:3.100-4.fc29.x86_64        |
        | install-dep   | lame-libs-0:3.100-4.fc29.x86_64   |
    And History is following
        | Id     | Command                               | Action        | Altered   |
        | 3      | history redo 1                        | Install       | 3         |
        | 2      | remove lame                           | Removed       | 2         |
        | 1      | group install DNF-CI-Testgroup        | Install       | 5         |


Scenario: Redo a transaction that removed a group
  Given I successfully execute dnf with args "group remove DNF-CI-Testgroup"
    And I successfully execute dnf with args "install lame"
   When I execute dnf with args "history redo 2"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                           |
        | remove        | lame-0:3.100-4.fc29.x86_64        |
        | remove-unused | lame-libs-0:3.100-4.fc29.x86_64   |
    And History is following
        | Id     | Command                               | Action        | Altered   |
        | 4      | history redo 2                        | Removed       | 2         |
        | 3      | install lame                          | Install       | 2         |
        | 2      | group remove DNF-CI-Testgroup         | Removed       | 5         |
        | 1      | group install DNF-CI-Testgroup        | Install       | 5         |


Scenario: Redo a transaction with a missing group
  Given I drop repository "dnf-ci-thirdparty"
   When I execute dnf with args "history redo 1"
   Then the exit code is 1
    And stderr is
    """
    Error: The following problems occurred while running a transaction:
      Group id 'dnf-ci-testgroup' is not available.
    """


Scenario: Redo a transaction that removed a group and the group is was removed from the system already
  Given I successfully execute dnf with args "group remove DNF-CI-Testgroup"
   When I execute dnf with args "history redo last"
   Then the exit code is 0
    And Transaction is empty


# TODO(dmach): group operations should be closer to rpm operations; install should be no-op in this case, upgrade would install the latest group from repo
Scenario: Redo a transaction that installed a group and the group is still on the system
   When I execute dnf with args "history redo last"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                           |
        | group-install | DNF-CI-Testgroup                  |
    And History is following
        | Id     | Command                               | Action        | Altered   |
        | 2      | history redo last                     | Install       | 1         |
        | 1      | group install DNF-CI-Testgroup        | Install       | 5         |
    And Transaction is empty
