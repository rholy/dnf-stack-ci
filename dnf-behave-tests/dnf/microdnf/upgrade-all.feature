Feature: Upgrade all RPMs


Background: Install some RPMs from one repository
  Given I use repository "dnf-ci-fedora"
    # "/usr" directory is needed to load rpm database (to overcome bad heuristics in libdnf created by Colin Walters)
    And I create directory "/usr"
   When I execute microdnf with args "install glibc flac wget"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | install       | glibc-0:2.28-9.fc29.x86_64                |
        | install       | flac-0:1.3.2-8.fc29.x86_64                |
        | install       | wget-0:1.19.5-5.fc29.x86_64               |
        | install-dep   | setup-0:2.12.1-1.fc29.noarch              |
        | install-dep   | filesystem-0:3.9-2.fc29.x86_64            |
        | install-dep   | basesystem-0:11-6.fc29.noarch             |
        | install-dep   | glibc-common-0:2.28-9.fc29.x86_64         |
        | install-dep   | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |

@bz1905471
Scenario: Upgrade all RPMs from one repository
  Given I use repository "dnf-ci-fedora-updates"
   When I execute microdnf with args "upgrade"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | upgrade       | glibc-0:2.28-26.fc29.x86_64               |
        | upgraded      | glibc-0:2.28-9.fc29.x86_64                |
        | upgrade       | glibc-common-0:2.28-26.fc29.x86_64        |
        | upgraded      | glibc-common-0:2.28-9.fc29.x86_64         |
        | upgrade       | glibc-all-langpacks-0:2.28-26.fc29.x86_64 |
        | upgraded      | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |
        | upgrade       | flac-0:1.3.3-3.fc29.x86_64                |
        | upgraded      | flac-0:1.3.2-8.fc29.x86_64                |
        | upgrade       | wget-0:1.19.6-5.fc29.x86_64               |
        | upgraded      | wget-0:1.19.5-5.fc29.x86_64               |

@bz1905471
Scenario: Upgrade all RPMs from one repository using '*'
  Given I use repository "dnf-ci-fedora-updates"
   When I execute microdnf with args "upgrade '*'"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | upgrade       | glibc-0:2.28-26.fc29.x86_64               |
        | upgraded      | glibc-0:2.28-9.fc29.x86_64                |
        | upgrade       | glibc-common-0:2.28-26.fc29.x86_64        |
        | upgraded      | glibc-common-0:2.28-9.fc29.x86_64         |
        | upgrade       | glibc-all-langpacks-0:2.28-26.fc29.x86_64 |
        | upgraded      | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |
        | upgrade       | flac-0:1.3.3-3.fc29.x86_64                |
        | upgraded      | flac-0:1.3.2-8.fc29.x86_64                |
        | upgrade       | wget-0:1.19.6-5.fc29.x86_64               |
        | upgraded      | wget-0:1.19.5-5.fc29.x86_64               |
