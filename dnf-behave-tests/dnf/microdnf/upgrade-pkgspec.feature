Feature: Upgrade RPMs by pkgspec


Background: Install glibc
  Given I use repository "dnf-ci-fedora"
    # "/usr" directory is needed to load rpm database (to overcome bad heuristics in libdnf created by Colin Walters)
    And I create directory "/usr"
   When I execute microdnf with args "install glibc"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | install       | glibc-0:2.28-9.fc29.x86_64                |
        | install-dep   | setup-0:2.12.1-1.fc29.noarch              |
        | install-dep   | filesystem-0:3.9-2.fc29.x86_64            |
        | install-dep   | basesystem-0:11-6.fc29.noarch             |
        | install-dep   | glibc-common-0:2.28-9.fc29.x86_64         |
        | install-dep   | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |

@bz1905471
Scenario Outline: Upgrade an RPM by <pkgspec-type>
  Given I use repository "dnf-ci-fedora-updates"
   When I execute microdnf with args "upgrade <pkgspec>"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | upgrade       | glibc-0:2.28-26.fc29.x86_64               |
        | upgraded      | glibc-0:2.28-9.fc29.x86_64                |
        | upgrade       | glibc-common-0:2.28-26.fc29.x86_64        |
        | upgraded      | glibc-common-0:2.28-9.fc29.x86_64         |
        | upgrade       | glibc-all-langpacks-0:2.28-26.fc29.x86_64 |
        | upgraded      | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |


@tier1
Examples: Name
  | pkgspec-type                    | pkgspec                       |
  | name                            | glibc                         |

Examples: Other pkgspecs
  | pkgspec-type                    | pkgspec                       |
  | name-version                    | glibc-2.28                    |
  | name-version-release            | glibc-2.28-26.fc29            |
  | name-version-release.arch       | glibc-2.28-26.fc29.x86_64     |
  | name-epoch:version-release.arch | glibc-0:2.28-26.fc29.x86_64   |
  | name.arch                       | glibc.x86_64                  |

@bz1905471
Scenario: Upgrade an RPM by name containing dashes
  Given I use repository "dnf-ci-fedora-updates"
   When I execute microdnf with args "upgrade glibc-common"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | upgrade       | glibc-0:2.28-26.fc29.x86_64               |
        | upgraded      | glibc-0:2.28-9.fc29.x86_64                |
        | upgrade       | glibc-common-0:2.28-26.fc29.x86_64        |
        | upgraded      | glibc-common-0:2.28-9.fc29.x86_64         |
        | upgrade       | glibc-all-langpacks-0:2.28-26.fc29.x86_64 |
        | upgraded      | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |

@bz1905471
Scenario: Upgrade an RPM by pkgspec contining wildcards
  Given I use repository "dnf-ci-fedora-updates"
   When I execute microdnf with args "upgrade glibc-*.x86_64"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | upgrade       | glibc-0:2.28-26.fc29.x86_64               |
        | upgraded      | glibc-0:2.28-9.fc29.x86_64                |
        | upgrade       | glibc-common-0:2.28-26.fc29.x86_64        |
        | upgraded      | glibc-common-0:2.28-9.fc29.x86_64         |
        | upgrade       | glibc-all-langpacks-0:2.28-26.fc29.x86_64 |
        | upgraded      | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |
