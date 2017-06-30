Feature: Test for main repoquery functionality
  for options --requires, --provides, --conflicts, --obsoletes,
  --whatrequires, --whatprovides, --whatconflicts, --whatobsoletes

  @setup
  Scenario: Feature Setup
      Given repository "base" with packages
        | Package | Tag       | Value |
        | TestA   | Requires  | TestB |
        |         | Provides  | TestC |
        |         | Conflicts | TestD |
        |         | Obsoletes | TestE |

  Scenario: repoquery --requires
       When I save rpmdb
        And I enable repository "base"
        And I run "dnf repoquery --requires TestA"
       Then the command stdout should match regexp "TestB"

  Scenario: repoquery --provides
       When I save rpmdb
        And I enable repository "base"
        And I run "dnf repoquery --provides TestA"
       Then the command stdout should match regexp "TestC"

  Scenario: repoquery --conflicts
       When I save rpmdb
        And I enable repository "base"
        And I run "dnf repoquery --conflicts TestA"
       Then the command stdout should match regexp "TestD"

  Scenario: repoquery --obsoletes
       When I save rpmdb
        And I enable repository "base"
        And I run "dnf repoquery --obsoletes TestA"
       Then the command stdout should match regexp "TestE"

  Scenario: repoquery --whatrequires
       When I save rpmdb
        And I enable repository "base"
        And I run "dnf repoquery --whatrequires TestB"
       Then the command stdout should match regexp "TestA"

  Scenario: repoquery --whatprovides
       When I save rpmdb
        And I enable repository "base"
        And I run "dnf repoquery --whatprovides TestC"
       Then the command stdout should match regexp "TestA"

  Scenario: repoquery --whatconflicts
       When I save rpmdb
        And I enable repository "base"
        And I run "dnf repoquery --whatconflicts TestD"
       Then the command stdout should match regexp "TestA"

  Scenario: repoquery --whatobsoletes
       When I save rpmdb
        And I enable repository "base"
        And I run "dnf repoquery --whatobsoletes TestE"
       Then the command stdout should match regexp "TestA"
