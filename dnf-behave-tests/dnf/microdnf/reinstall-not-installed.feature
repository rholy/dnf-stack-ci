@no_installroot
Feature: Reinstall


Background: Set up repositories
  Given I use repository "dnf-ci-fedora"
    And I use repository "dnf-ci-fedora-updates"


Scenario: Reinstall an RPM that is available, but not installed
   When I execute microdnf with args "reinstall CQRlib"
   Then the exit code is 1
    And RPMDB Transaction is empty
    And stdout is
        """
        No match for argument: CQRlib
        """
