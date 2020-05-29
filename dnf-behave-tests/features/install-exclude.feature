Feature: Install RPMs with --exclude


Scenario: Install an RPM that is excluded
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install filesystem --exclude filesystem"
   Then the exit code is 1
    And Transaction is empty

@bz1756473
Scenario: Install an RPM that requires excluded RPM
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install filesystem --exclude setup"
   Then the exit code is 1
    And Transaction is empty
    And stderr is
    """
    Error: 
     Problem: package filesystem-3.9-2.fc29.x86_64 requires setup, but none of the providers can be installed
      - conflicting requests
      - package setup-2.12.1-1.fc29.noarch is filtered out by exclude filtering
    """


Scenario: Install RPMs while excluding part of them
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install setup filesystem --exclude filesystem"
   Then the exit code is 1
    And Transaction is empty


Scenario: Install RPMs while excluding part of them (strict=false)
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install setup filesystem --exclude filesystem --setopt=strict=false"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | setup-0:2.12.1-1.fc29.noarch          |


Scenario: Install RPMs while excluding another RPM
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install filesystem --exclude glibc"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | filesystem-0:3.9-2.fc29.x86_64        |
        | install-dep   | setup-0:2.12.1-1.fc29.noarch          |
