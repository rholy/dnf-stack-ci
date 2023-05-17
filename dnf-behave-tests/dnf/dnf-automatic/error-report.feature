@no_installroot
Feature: dnf-automatic reports an error when transaction failed


# We are not running in installroot with dnf-automatic,
# so we need to prepare a clean environment.
Background:
Given I delete file "/etc/yum.repos.d/*.repo" with globs
  And I create file "/etc/dnf/dnf.conf" with
    """
    [main]
    plugins=0
    """


# First, install the "test-1.0" package, which should proceed successfully. 
# Then, attempt to update to "test-1.1", which contains a broken scriptlet.
# An error should be reported during the installation of the update.
@bz2170093
Scenario: dnf-automatic reports an error when package installation failed
  Given I use repository "dnf-ci-automatic-update"
    And I successfully execute dnf with args "install test-1.0"
   When I execute dnf-automatic with args "--installupdates"
   Then the exit code is 1
    And Transaction is empty
    And stderr is
    """
    Error in PREIN scriptlet in rpm package test
    Error: Transaction failed
    """
