Feature: Install an obsoleted RPM


Scenario: Install an obsoleted RPM
  Given I use repository "dnf-ci-thirdparty"
   When I execute dnf with args "install glibc-profile"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | install       | glibc-profile-0:2.3.1-10.x86_64           |


Scenario: Install an obsoleted RPM when the obsoleting RPM is available
  Given I use repository "dnf-ci-fedora"
    And I use repository "dnf-ci-thirdparty"
   When I execute dnf with args "install glibc-profile"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | install       | setup-0:2.12.1-1.fc29.noarch              |
        | install       | filesystem-0:3.9-2.fc29.x86_64            |
        | install       | basesystem-0:11-6.fc29.noarch             |
        | install       | glibc-0:2.28-9.fc29.x86_64                |
        | install       | glibc-common-0:2.28-9.fc29.x86_64         |
        | install       | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |


@bz1672618
@xfail
Scenario: Upgrading obsoleted package by its obsoleter keeps userinstalled=false (with --best)
  Given I use repository "dnf-ci-thirdparty"
   When I execute dnf with args "install glibc-profile"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | install       | glibc-profile-0:2.3.1-10.x86_64           |
   When I execute dnf with args "mark remove glibc-profile"
   Then the exit code is 0
   When I execute dnf with args "history userinstalled"
   Then the exit code is 1
    And stdout is empty
    And stderr is
        """
        Error: No packages to list
        """
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "upgrade --best"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | obsoleted     | glibc-profile-0:2.3.1-10.x86_64           |
        | install       | setup-0:2.12.1-1.fc29.noarch              |
        | install       | filesystem-0:3.9-2.fc29.x86_64            |
        | install       | basesystem-0:11-6.fc29.noarch             |
        | install       | glibc-0:2.28-9.fc29.x86_64                |
        | install       | glibc-common-0:2.28-9.fc29.x86_64         |
        | install       | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |
   When I execute dnf with args "history userinstalled"
   Then the exit code is 1
    And stdout is empty
    And stderr is
        """
        Error: No packages to list
        """


@bz1672618
Scenario: Upgrading obsoleted package by its obsoleter keeps userinstalled=false (with --nobest)
  Given I use repository "dnf-ci-thirdparty"
   When I execute dnf with args "install glibc-profile"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | install       | glibc-profile-0:2.3.1-10.x86_64           |
   When I execute dnf with args "mark remove glibc-profile"
   Then the exit code is 0
   When I execute dnf with args "history userinstalled"
   Then the exit code is 1
    And stdout is empty
    And stderr is
        """
        Error: No packages to list
        """
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "upgrade --nobest"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | obsoleted     | glibc-profile-0:2.3.1-10.x86_64           |
        | install       | setup-0:2.12.1-1.fc29.noarch              |
        | install       | filesystem-0:3.9-2.fc29.x86_64            |
        | install       | basesystem-0:11-6.fc29.noarch             |
        | install       | glibc-0:2.28-9.fc29.x86_64                |
        | install       | glibc-common-0:2.28-9.fc29.x86_64         |
        | install       | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |
   When I execute dnf with args "history userinstalled"
   Then the exit code is 1
    And stdout is empty
    And stderr is
        """
        Error: No packages to list
        """
