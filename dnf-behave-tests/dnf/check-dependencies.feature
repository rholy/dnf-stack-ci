Feature: Check when there is a package with missing dependency


Scenario Outline: Check <option>
   When I execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/dnf-ci-fedora/x86_64/filesystem-3.9-2.fc29.x86_64.rpm"
   Then the exit code is 0
   When I execute dnf with args "check <option>"
   Then the exit code is 1
    And stdout contains "filesystem-3.9-2.fc29.x86_64 has missing requires of setup"
    And stderr is
        """
        Error: Check discovered 1 problem(s)
        """

Examples:
        | option             |
        # no option defaults to "all"
        |                    |
        | all                |
        | --dependencies     |


Scenario Outline: Check <option>
   When I execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/dnf-ci-fedora/x86_64/filesystem-3.9-2.fc29.x86_64.rpm"
   Then the exit code is 0
   When I execute dnf with args "check <option>"
   Then the exit code is 0
    And stdout is empty
    And stderr is empty

Examples:
        | option             |
        | --duplicates       |
        | --obsoleted        |
        | --provides         |


@bz1543449
Scenario: Removed scriptlet pre and post dependencies are not reported as missing
  Given I use repository "dnf-ci-check-dependencies"
    And I successfully execute dnf with args "install package-requires-all-scriptlets"
    And I successfully execute dnf with args "remove dependency-1 dependency-2"
   When I execute dnf with args "check --dependencies"
   Then the exit code is 0
    And stdout is empty
    And stderr is empty


Scenario: Removed requires(pre) dependency is reported if it is also requires
  Given I use repository "dnf-ci-check-dependencies"
    And I successfully execute dnf with args "install package-requires-and-requires-pre"
    And I successfully execute rpm with args "--erase --nodeps dependency-1"
   When I execute dnf with args "check --dependencies"
   Then the exit code is 1
    And stdout is
    """
    package-requires-and-requires-pre-1.0-1.x86_64 has missing requires of dependency-1
    """
    And stderr is
    """
    Error: Check discovered 1 problem(s)
    """


Scenario: Removed requires(pre) dependency is reported if it is also requires(preun)
  Given I use repository "dnf-ci-check-dependencies"
    And I successfully execute dnf with args "install package-requires-pre-and-requires-preun"
    And I successfully execute rpm with args "--erase --nodeps dependency-1"
   When I execute dnf with args "check --dependencies"
   Then the exit code is 1
    And stdout is
    """
    package-requires-pre-and-requires-preun-1.0-1.x86_64 has missing requires of dependency-1
    """
    And stderr is
    """
    Error: Check discovered 1 problem(s)
    """


Scenario: Removed scriptlet preun and postun dependencies are reported as missing
  Given I use repository "dnf-ci-check-dependencies"
    And I successfully execute dnf with args "install package-requires-all-scriptlets"
    And I successfully execute rpm with args "--erase --nodeps dependency-3 dependency-4"
   When I execute dnf with args "check --dependencies"
   Then the exit code is 1
    And stdout is
    """
    package-requires-all-scriptlets-1.0-1.x86_64 has missing requires of dependency-3
    package-requires-all-scriptlets-1.0-1.x86_64 has missing requires of dependency-4
    """
    And stderr is
    """
    Error: Check discovered 2 problem(s)
    """
