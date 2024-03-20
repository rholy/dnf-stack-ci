Feature: Mark command


@dnf5
Scenario Outline: Marking non-existent package as <type> fails
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "mark <type> nosuchpkg"
   Then the exit code is 1
    And stderr contains lines
    """
    Failed to resolve the transaction:
    No match for argument: nosuchpkg
    """

Examples:
        | type        |
        | user        |
        | dependency  |
        | weak        |


@dnf5
Scenario: Marking as group for non-existent package or non-existent group fails
  Given I use repository "dnf-ci-thirdparty"
    And I use repository "dnf-ci-fedora"
   When I execute dnf with args "mark group dnf-ci-testgroup nosuchpkg"
   Then the exit code is 1
    And stderr contains lines
    """
    Failed to resolve the transaction:
    No match for argument: nosuchpkg
    """
   When I execute dnf with args "install lame"
    And I execute dnf with args "mark group nosuchgrp lame"
   Then the exit code is 1
    And stderr contains lines
    """
    Group state for "nosuchgrp" not found.
    """


@dnf5
Scenario: Marking available but not installed package fails
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "mark user lame"
   Then the exit code is 1
    And stderr contains lines
    """
    Failed to resolve the transaction:
    No match for argument: lame
    """


@dnf5
Scenario: Marking as dependency a list of pkgs when one of them is not available fails 
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install lame"
    And I execute dnf with args "mark dependency lame nosuchpkg"
   Then the exit code is 1
    And package reasons are
        | Package                      | Reason  |
        | lame-3.100-4.fc29.x86_64     | user    |
    And stderr contains lines
    """
    Failed to resolve the transaction:
    No match for argument: nosuchpkg
    """


@dnf5
Scenario: Marking as dependency a list of pkgs when one of them is not available passes with --skip-unavailable
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install lame"
    And I execute dnf with args "mark --skip-unavailable dependency lame nosuchpkg"
   Then the exit code is 0
    And package reasons are
        | Package                      | Reason        |
        | lame-3.100-4.fc29.x86_64     | dependency    |
    And stderr is
    """
    No match for argument: nosuchpkg
    """


@dnf5
Scenario Outline: Mark user installed package as <type>
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install lame"
   Then the exit code is 0
   When I execute dnf with args "mark <type> lame"
   Then the exit code is 0
    And package reasons are
        | Package                      | Reason    |
        | lame-3.100-4.fc29.x86_64     | <type>    |

Examples:
        | type        |
        | dependency  |
        | weak        |


@dnf5
Scenario Outline: Mark package installed as dependency as <type>
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install filesystem"
   Then the exit code is 0
    And package reasons are
        | Package                        | Reason     |
        | filesystem-0:3.9-2.fc29.x86_64 | user       |
        | setup-0:2.12.1-1.fc29.noarch   | dependency |
   When I execute dnf with args "mark <type> setup"
   Then the exit code is 0
    And package reasons are
        | Package                        | Reason |
        | setup-0:2.12.1-1.fc29.noarch   | <type> |

Examples:
        | type        |
        | user        |
        | weak        |


@dnf5
Scenario: Mark package as the same reason it currently has
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install lame"
   Then the exit code is 0
    And package reasons are
        | Package                      | Reason    |
        | lame-3.100-4.fc29.x86_64     | user      |
   When I execute dnf with args "mark user lame"
   Then the exit code is 0
    And stdout is
    """
    <REPOSYNC>
    Nothing to do.
    """
    And stderr is
    """
    Package "lame-3.100-4.fc29.x86_64" is already installed with reason "User".
    """


@dnf5
Scenario: Mark user installed package as group
  Given I use repository "dnf-ci-thirdparty"
    And I use repository "dnf-ci-fedora"
   When I execute dnf with args "install lame"
    And I execute dnf with args "group install dnf-ci-testgroup"
   Then the exit code is 0
    And package reasons are
        | Package                        | Reason |
        | lame-3.100-4.fc29.x86_64       | user   |
   When I execute dnf with args "mark group dnf-ci-testgroup lame"
   Then the exit code is 0
    And package reasons are
        | Package                        | Reason |
        | lame-3.100-4.fc29.x86_64       | group  |


#@dnf5 currently fails, see:
# https://github.com/rpm-software-management/dnf5/issues/935
# TODO (emrakova): update the scenario when the issue is fixed
Scenario: Mark group installed package as user and back again
  Given I use repository "dnf-ci-thirdparty"
    And I use repository "dnf-ci-fedora"
    And I execute dnf with args "group install dnf-ci-testgroup"
   Then the exit code is 0
    And package reasons are
        | Package                        | Reason |
        | lame-3.100-4.fc29.x86_64       | group  |
   When I execute dnf with args "mark user lame"
   Then the exit code is 0
    And package reasons are
        | Package                        | Reason |
        | lame-3.100-4.fc29.x86_64       | user   |
   When I execute dnf with args "mark group dnf-ci-testgroup lame"
   Then the exit code is 0
    And package reasons are
        | Package                        | Reason |
        | lame-3.100-4.fc29.x86_64       | group  |
   When I execute dnf with args "mark group dnf-ci-testgroup lame"
   Then the exit code is 0
    And stdout does not contain "User -> Group"
    And stderr is
    """
    Package "lame-3.100-4.fc29.x86_64" is already installed with reason "Group".
    """


@dnf5
Scenario: Marking dependency as user-installed should not remove it automatically
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install filesystem"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | install       | filesystem-0:3.9-2.fc29.x86_64            |
        | install-dep   | setup-0:2.12.1-1.fc29.noarch              |
   When I execute dnf with args "mark user setup"
   Then the exit code is 0
   When I execute dnf with args "remove filesystem"
   Then the exit code is 0
   And Transaction is following
        | Action        | Package                                   |
        | remove        | filesystem-0:3.9-2.fc29.x86_64            |
        | unchanged     | setup-0:2.12.1-1.fc29.noarch              |
   When I execute dnf with args "remove setup"
   Then the exit code is 0
   And Transaction is following
        | Action        | Package                                   |
        | remove        | setup-0:2.12.1-1.fc29.noarch              |


@dnf5
@bz2046581
Scenario: Marking installed package when history DB is not on the system (deleted or not created yet)
   When I execute rpm with args "-i {context.dnf.fixturesdir}/repos/dnf-ci-fedora-updates/x86_64/wget-1.19.6-5.fc29.x86_64.rpm"
   Then the exit code is 0
    And package reasons are
        | Package                      | Reason         |
        | wget-1.19.6-5.fc29.x86_64    | unknown        |
   When I execute dnf with args "mark user wget"
   Then the exit code is 0
    And package reasons are
        | Package                      | Reason        |
        | wget-1.19.6-5.fc29.x86_64    | user          |


@dnf5
Scenario: Marking toplevel package as dependency should not remove shared dependencies on autoremove
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install nss_hesiod libnsl"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | install       | libnsl-0:2.28-9.fc29.x86_64               |
        | install       | nss_hesiod-0:2.28-9.fc29.x86_64           |
        | install-dep   | setup-0:2.12.1-1.fc29.noarch              |
        | install-dep   | filesystem-0:3.9-2.fc29.x86_64            |
        | install-dep   | basesystem-0:11-6.fc29.noarch             |
        | install-dep   | glibc-0:2.28-9.fc29.x86_64                |
        | install-dep   | glibc-common-0:2.28-9.fc29.x86_64         |
        | install-dep   | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |
   When I execute dnf with args "mark dependency libnsl"
   Then the exit code is 0
   When I execute dnf with args "autoremove"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | remove        | libnsl-0:2.28-9.fc29.x86_64               |
