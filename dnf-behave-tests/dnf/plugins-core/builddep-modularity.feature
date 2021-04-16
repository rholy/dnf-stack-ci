Feature: Tests for builddep command on modular system

Background: Enable builddep plugin
  Given I enable plugin "builddep"
    And I use repository "dnf-ci-fedora"

# dnf-ci-fedora-modular repo:
#   module ninja:master [d] contains ninja-build-0:1.8.2-4.module_1991+4e5efe2f.x86_64
#   ninja:legacy contains ninja-build-0:1.5.2-1.module_1991+4e5efe2f.x86_64
#   ninja:development contans ninja-build-1.9.2-1.module_1991+4e5efe2f.x86_64
# dnf-ci-fedora repo (non-modular):
#   ninja-build-0:1.8.2-5.fc29.x86_64

Scenario: Builddep installs non-modular build requirements
   When I execute dnf with args "builddep {context.dnf.fixturesdir}/repos/dnf-ci-builddep/src/build-requires-ninja-build-1.0-1.src.rpm"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | ninja-build-0:1.8.2-5.fc29.x86_64     |


@bz1677583
Scenario: Builddep preferes default stream over other streams / non-modular content even though the version is older
  Given I use repository "dnf-ci-fedora-modular"
   When I execute dnf with args "builddep {context.dnf.fixturesdir}/repos/dnf-ci-builddep/src/build-requires-ninja-build-1.0-1.src.rpm"
   Then the exit code is 0
    And Transaction contains
        | Action                | Package                                           |
        | install               | ninja-build-0:1.8.2-4.module_1991+4e5efe2f.x86_64 |
        | module-stream-enable  | ninja:master                                      |


@bz1677583
Scenario: Builddep preferes enabled stream over other streams / non-modular content even though the version is older
  Given I use repository "dnf-ci-fedora-modular"
   When I execute dnf with args "module enable ninja:legacy"
   Then the exit code is 0
   When I execute dnf with args "builddep {context.dnf.fixturesdir}/repos/dnf-ci-builddep/src/build-requires-ninja-build-1.0-1.src.rpm"
   Then the exit code is 0
    And Transaction contains
        | Action                | Package                                           |
        | install               | ninja-build-0:1.5.2-1.module_1991+4e5efe2f.x86_64 |


# build-requires-ninja-build-0.5-1.src.rpm build requires ninja-build < 1.8
@1677583
Scenario: Builddep reports error where required package is available only in non-enabled non-default stream
  Given I use repository "dnf-ci-fedora-modular"
   When I execute dnf with args "builddep {context.dnf.fixturesdir}/repos/dnf-ci-builddep/src/build-requires-ninja-build-0.5-1.src.rpm"
   Then the exit code is 1
    And stderr is
    """
    Error: 
     Problem: conflicting requests
      - package ninja-build-1.5.2-1.module_1991+4e5efe2f.x86_64 is filtered out by modular filtering
    """


# dnf-ci-fedora-modular: nodejs-1:8.11.4-1.module_2030+42747d40.x86_64
# dnf-ci-fedora-modular-hotfix: nodejs-1:8.11.5-1.module_2030+42747d40.x86_64
@bz1677583
Scenario: Builddep preferes hotfix repo over the default stream
  Given I use repository "dnf-ci-fedora-modular"
    And I use repository "dnf-ci-fedora-modular-hotfix" with configuration
        | key                 | value |
        | module_hotfixes     | 1     |
   When I execute dnf with args "builddep {context.dnf.fixturesdir}/repos/dnf-ci-builddep/src/build-requires-ninja-build-nodejs-1.0-1.src.rpm"
   Then the exit code is 0
    And Transaction contains
        | Action                | Package                                           |
        | install               | ninja-build-0:1.8.2-4.module_1991+4e5efe2f.x86_64 |
        | install               | nodejs-1:8.11.5-1.module_2030+42747d40.x86_64     |
        | module-stream-enable  | ninja:master                                      |


@bz1677583
Scenario: Builddep preferes hotfix repo over the enabled stream
  Given I use repository "dnf-ci-fedora-modular"
    And I use repository "dnf-ci-fedora-modular-hotfix" with configuration
        | key                 | value |
        | module_hotfixes     | 1     |
   When I execute dnf with args "module enable nodejs:8"
   Then the exit code is 0
   When I execute dnf with args "builddep {context.dnf.fixturesdir}/repos/dnf-ci-builddep/src/build-requires-ninja-build-nodejs-1.0-1.src.rpm"
   Then the exit code is 0
    And Transaction contains
        | Action                | Package                                           |
        | install               | ninja-build-0:1.8.2-4.module_1991+4e5efe2f.x86_64 |
        | install               | nodejs-1:8.11.5-1.module_2030+42747d40.x86_64     |
        | module-stream-enable  | ninja:master                                      |
