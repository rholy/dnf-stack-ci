Feature: Test upgrading installonly packages


Background:
  Given I use repository "dnf-ci-fedora"


@dnf5
@bz1668256 @bz1616191 @bz1639429
Scenario: Install multiple versions of an installonly package with a limit of 2
  Given I set config option "installonly_limit" to "2"
   When I execute dnf with args "install kernel-core"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.18.16-300.fc29.x86_64 |
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
   When I execute dnf with args "upgrade kernel-core"
   Then the exit code is 0
   Then stderr does not contain "cannot install both"
    And Transaction is empty
  Given I use repository "dnf-ci-fedora-updates-testing"
   When I execute dnf with args "upgrade"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.20.6-300.fc29.x86_64  |
        | unchanged     | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | remove        | kernel-core-0:4.18.16-300.fc29.x86_64 |
    And package state is
        | package                             | reason | from_repo                     |
        | kernel-core-4.19.15-300.fc29.x86_64 | User   | dnf-ci-fedora-updates         |
        | kernel-core-4.20.6-300.fc29.x86_64  | User   | dnf-ci-fedora-updates-testing |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason | repository                    |
        | Install | kernel-core-0:4.20.6-300.fc29.x86_64  | User   | dnf-ci-fedora-updates-testing |
        | Remove  | kernel-core-0:4.18.16-300.fc29.x86_64 | User   | @System                       |

@dnf5
Scenario: Install and remove multiple versions of an installonly package
  Given I set config option "installonly_limit" to "2"
   When I execute dnf with args "install kernel-core"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.18.16-300.fc29.x86_64 |
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
    And package state is
        | package                             | reason | from_repo             |
        | kernel-core-4.18.16-300.fc29.x86_64 | User   | dnf-ci-fedora         |
        | kernel-core-4.19.15-300.fc29.x86_64 | User   | dnf-ci-fedora-updates |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason | repository            |
        | Install | kernel-core-0:4.19.15-300.fc29.x86_64 | User   | dnf-ci-fedora-updates |
   When I execute dnf with args "remove kernel-core"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | remove        | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | remove        | kernel-core-0:4.18.16-300.fc29.x86_64 |
    And package state is
        | package | reason | from_repo |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason | repository |
        | Remove  | kernel-core-0:4.18.16-300.fc29.x86_64 | User   | @System    |
        | Remove  | kernel-core-0:4.19.15-300.fc29.x86_64 | User   | @System    |

@dnf5
@bz1769788
Scenario: Install multiple versions of an installonly package and keep reason
   When I execute dnf with args "install kernel-core"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.18.16-300.fc29.x86_64 |
    And package state is
        | package                             | reason | from_repo             |
        | kernel-core-4.18.16-300.fc29.x86_64 | User   | dnf-ci-fedora         |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason | repository    |
        | Install | kernel-core-0:4.18.16-300.fc29.x86_64 | User   | dnf-ci-fedora |
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade --no-best"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
    And package state is
        | package                             | reason | from_repo             |
        | kernel-core-4.18.16-300.fc29.x86_64 | User   | dnf-ci-fedora         |
        | kernel-core-4.19.15-300.fc29.x86_64 | User   | dnf-ci-fedora-updates |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason | repository            |
        | Install | kernel-core-0:4.19.15-300.fc29.x86_64 | User   | dnf-ci-fedora-updates |
   When I execute dnf with args "autoremove"
   Then the exit code is 0
    And Transaction is empty

# @dnf5
# TODO(nsella) Unknown argument "--oldinstallonly" for command "remove"
@bz1774670
Scenario: Remove all installonly packages but keep the latest
   When I execute dnf with args "install kernel-core"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.18.16-300.fc29.x86_64 |
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
  Given I use repository "dnf-ci-fedora-updates-testing"
   When I execute dnf with args "upgrade"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                  |
        | install       | kernel-core-0:4.20.6-300.fc29.x86_64     |
        | unchanged     | kernel-core-0:4.19.15-300.fc29.x86_64    |
        | unchanged        | kernel-core-0:4.18.16-300.fc29.x86_64 |
   When I execute dnf with args "remove --oldinstallonly"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                  |
        | unchanged       | kernel-core-0:4.20.6-300.fc29.x86_64   |
        | remove        | kernel-core-0:4.19.15-300.fc29.x86_64    |
        | remove        | kernel-core-0:4.18.16-300.fc29.x86_64    |

# @dnf5
# TODO(nsella) Unknown argument "--repofrompath=r,/opt/ci/dnf-behave-tests/fixtures/repos/dnf-ci-fedora" for command "install"
@bz1774670
@no_installroot
@destructive
Scenario: Remove all installonly packages but keep the latest and running kernel-core-0:4.18.16-300.fc29.x86_64
  Given I use repository "dnf-ci-fedora"
    And I fake kernel release to "4.18.16-300.fc29.x86_64"
   When I execute dnf with args "install kernel-core --repofrompath=r,{context.dnf.repos[dnf-ci-fedora].path} --repo=r --nogpgcheck"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.18.16-300.fc29.x86_64 |
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade --repofrompath=r,{context.dnf.repos[dnf-ci-fedora-updates].path} --repo=r --nogpgcheck kernel-core"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
  Given I use repository "dnf-ci-fedora-updates-testing"
   When I execute dnf with args "upgrade --repofrompath=r,{context.dnf.repos[dnf-ci-fedora-updates-testing].path} --repo=r --nogpgcheck kernel-core"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                  |
        | install       | kernel-core-0:4.20.6-300.fc29.x86_64     |
        | unchanged     | kernel-core-0:4.19.15-300.fc29.x86_64    |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64    |
   When I execute dnf with args "remove --oldinstallonly"
   Then the exit code is 0
    And Transaction is following
        | Action          | Package                                  |
        | unchanged       | kernel-core-0:4.20.6-300.fc29.x86_64     |
        | remove          | kernel-core-0:4.19.15-300.fc29.x86_64    |
        | unchanged       | kernel-core-0:4.18.16-300.fc29.x86_64   |


@dnf5
@bz1934499
@bz1921063
Scenario: Do not autoremove kernel after upgrade with --best
   When I execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/dnf-ci-fedora/x86_64/kernel-core-4.18.16-300.fc29.x86_64.rpm"
   Then package reasons are
        | Package                                | Reason          |
        | kernel-core-4.18.16-300.fc29.x86_64    | unknown         |
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade --best"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
  #  Also valid result can be unknown reason
    And package reasons are
        | Package                                | Reason          |
        | kernel-core-4.18.16-300.fc29.x86_64    | unknown         |
        | kernel-core-4.19.15-300.fc29.x86_64    | unknown         |
    And package state is
        | package                             | reason        | from_repo             |
        | kernel-core-4.19.15-300.fc29.x86_64 | External User | dnf-ci-fedora-updates |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason        | repository            |
        | Install | kernel-core-0:4.19.15-300.fc29.x86_64 | External User | dnf-ci-fedora-updates |
   When I execute dnf with args "autoremove"
   Then the exit code is 0
    And Transaction is empty


@dnf5
@bz1934499
@bz1921063
Scenario: Do not autoremove kernel after upgrade with --no-best
   When I execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/dnf-ci-fedora/x86_64/kernel-core-4.18.16-300.fc29.x86_64.rpm"
   Then package reasons are
        | Package                                | Reason          |
        | kernel-core-4.18.16-300.fc29.x86_64    | unknown         |
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade --no-best"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
  #  Also valid result can be unknown reason
    And package reasons are
        | Package                                | Reason          |
        | kernel-core-4.18.16-300.fc29.x86_64    | unknown         |
        | kernel-core-4.19.15-300.fc29.x86_64    | unknown         |
    And package state is
        | package                             | reason        | from_repo             |
        | kernel-core-4.19.15-300.fc29.x86_64 | External User | dnf-ci-fedora-updates |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason        | repository            |
        | Install | kernel-core-0:4.19.15-300.fc29.x86_64 | External User | dnf-ci-fedora-updates |
   When I execute dnf with args "autoremove"
   Then the exit code is 0
    And Transaction is empty


@dnf5
@bz1934499
@bz1921063
Scenario: Do not remove or change reason after remove of one of installonly packages
   When I execute dnf with args "install kernel-core"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.18.16-300.fc29.x86_64 |
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
   When I execute dnf with args "upgrade kernel-core"
   Then the exit code is 0
    And package reasons are
        | Package                                | Reason          |
        | kernel-core-4.18.16-300.fc29.x86_64    | user            |
        | kernel-core-4.19.15-300.fc29.x86_64    | user            |
    And package state is
        | package                             | reason | from_repo             |
        | kernel-core-4.18.16-300.fc29.x86_64 | User   | dnf-ci-fedora         |
        | kernel-core-4.19.15-300.fc29.x86_64 | User   | dnf-ci-fedora-updates |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason | repository            |
        | Install | kernel-core-0:4.19.15-300.fc29.x86_64 | User   | dnf-ci-fedora-updates |
   When I execute dnf with args "remove kernel-core-0:4.19.15-300.fc29.x86_64"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | remove        | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
    And package reasons are
        | Package                                | Reason          |
        | kernel-core-4.18.16-300.fc29.x86_64    | user            |
    And package state is
        | package                             | reason | from_repo             |
        | kernel-core-4.18.16-300.fc29.x86_64 | User   | dnf-ci-fedora         |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason | repository |
        | Remove  | kernel-core-0:4.19.15-300.fc29.x86_64 | User   | @System    |


@dnf5
@bz1934499
@bz1921063
Scenario: Keep reason for installonly packages
   When I execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/dnf-ci-fedora/x86_64/kernel-core-4.18.16-300.fc29.x86_64.rpm {context.dnf.fixturesdir}/repos/dnf-ci-fedora-updates/x86_64/kernel-core-4.19.15-300.fc29.x86_64.rpm"
   Then the exit code is 0

    And package reasons are
        | Package                                | Reason          |
        | kernel-core-4.18.16-300.fc29.x86_64    | unknown         |
        | kernel-core-4.19.15-300.fc29.x86_64    | unknown         |
  When I execute dnf with args "remove kernel-core-0:4.19.15-300.fc29.x86_64"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | remove        | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |
    And package reasons are
        | Package                                | Reason          |
        | kernel-core-4.18.16-300.fc29.x86_64    | unknown         |
    And package state is
        | package | reason | from_repo |
    And dnf5 transaction items for transaction "last" are
        | action  | package                               | reason | repository |
        | Remove  | kernel-core-0:4.19.15-300.fc29.x86_64 | User   | @System    |
   When I execute dnf with args "autoremove"
   Then the exit code is 0
    And Transaction is empty

# @dnf5
# TODO(nsella) different exit code
@bz1926261
Scenario: Value 1 of installonly_limit config option is not allowed
  Given I configure dnf with
        | key               | value     |
        | installonly_limit | 1         |
   When I execute dnf with args " "
   Then the exit code is 0
    And stderr matches line by line
    """
    Invalid configuration value: installonly_limit=1 in .*/etc/dnf/dnf.conf; value 1 is not allowed
    """

# TODO(lukash) dnf5 doesn't seem to implement the limit lower bound and accepts installonly_limit = 1
# also, the rpmdb check seems to not work correctly for this case, since it's passing without an
# error even if the older version is being removed
@bz1926261
Scenario: Kernel upgrade does not fail when installonly_limit=1 (default value is used instead of invalid 1)
  Given I configure dnf with
        | key               | value     |
        | installonly_limit | 1         |
    And I successfully execute dnf with args "install kernel-core"
    And I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "upgrade"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
        | unchanged     | kernel-core-0:4.18.16-300.fc29.x86_64 |

@dnf5
@bz2221308 @gh_dnf5_720
Scenario Outline: Dnf can downgrade kernel using "<command>" command.
  Given I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "install kernel-core-4.19.15-300.fc29.x86_64"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.19.15-300.fc29.x86_64 |
   When I execute dnf with args "<command> <args>"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | kernel-core-0:4.18.16-300.fc29.x86_64 |

Examples:
    | command       | args                                  |
    | downgrade     | kernel-core                           |
    | install       | kernel-core-4.18.16-300.fc29.x86_64   |
