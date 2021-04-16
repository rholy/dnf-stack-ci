Feature: Reinstall


Background: Install CQRlib-devel and CQRlib
  Given I use repository "dnf-ci-fedora"
    And I use repository "dnf-ci-fedora-updates"
   When I execute dnf with args "install CQRlib-devel"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | install       | CQRlib-devel-0:1.1.2-16.fc29.x86_64       |
        | install-dep   | CQRlib-0:1.1.2-16.fc29.x86_64             |


Scenario: Reinstall an RPM from the same repository
   When I execute dnf with args "reinstall CQRlib"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | reinstall     | CQRlib-0:1.1.2-16.fc29.x86_64             |


Scenario: Reinstall an RPM from different repository
  Given I use repository "dnf-ci-fedora-updates-testing"
   When I execute dnf with args "reinstall CQRlib"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                                   |
        | reinstall     | CQRlib-0:1.1.2-16.fc29.x86_64             |


Scenario: Reinstall an RPM that is not available
  Given I drop repository "dnf-ci-fedora-updates"
   When I execute dnf with args "reinstall CQRlib"
   Then the exit code is 1
