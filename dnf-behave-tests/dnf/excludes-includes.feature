Feature: Test config options includepkgs and excludepkgs


Scenario: Install RPMs that are in includepkgs in main conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=includepkgs=flac-libs,setup"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                          |
        | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |


Scenario: Install RPMs that are in includepkgs in repo conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=dnf-ci-fedora.includepkgs=flac-libs,setup"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                          |
        | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |


Scenario: Fail to install RPMs when some RPM is NOT in includepkgs in main conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac flac-libs --setopt=includepkgs=flac-libs,setup"
   Then the exit code is 1
    And Transaction is empty


Scenario: Fail to install RPMs when some RPM is NOT in includepkgs in repo conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac flac-libs --setopt=dnf-ci-fedora.includepkgs=flac-libs,setup"
   Then the exit code is 1
    And Transaction is empty


Scenario: Install RPMs that are NOT in excludepkgs in main conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=excludepkgs=flac,glibc"
   Then the exit code is 0
    And Transaction is following
       | Action        | Package                          |
       | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |


Scenario: Install RPMs that are NOT in excludepkgs in repo conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=dnf-ci-fedora.excludepkgs=flac,glibc"
   Then the exit code is 0
    And Transaction is following
       | Action        | Package                          |
       | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |


Scenario: Fail to install RPMs when some RPM is in excludepkgs in main conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac flac-libs --setopt=excludepkgs=flac,flac-libs,glibc"
   Then the exit code is 1
    And Transaction is empty


Scenario: Fail to install RPMs when some RPM is in excludepkgs in repo conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac flac-libs --setopt=dnf-ci-fedora.excludepkgs=flac,flac-libs,glibc"
   Then the exit code is 1
    And Transaction is empty


Scenario: Install RPMs that are in includepkgs and NOT in excludepkgs in main conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=includepkgs=flac,flac-libs,setup  --setopt=excludepkgs=flac,glibc"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                          |
        | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |


Scenario: Install RPMs that are in includepkgs and NOT in excludepkgs in repo conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=dnf-ci-fedora.includepkgs=flac,flac-libs,setup  --setopt=excludepkgs=flac,glibc"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                          |
        | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |


Scenario: Fail to install RPMs when there is a non-existent RPM in includedpkgs in main conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=includepkgs=non-existent-pkg"
   Then the exit code is 1
    And Transaction is empty


Scenario: Fail to install RPMs when there is a non-existent RPM in includedpkgs in repo conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=dnf-ci-fedora.includepkgs=non-existent-pkg"
   Then the exit code is 1
    And Transaction is empty


Scenario: Install RPMs when there is a non-existent RPM in excludepkgs in main conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=excludepkgs=non-existent-pkg"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                          |
        | install       | flac-0:1.3.2-8.fc29.x86_64       |
        | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |


Scenario: Install RPMs when there is a non-existent RPM in excludepkgs in repo conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=dnf-ci-fedora.excludepkgs=non-existent-pkg"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                          |
        | install       | flac-0:1.3.2-8.fc29.x86_64       |
        | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |


Scenario: Install RPMs that are in includepkgs in main conf and NOT in excludepkgs in repo conf
  Given I use repository "dnf-ci-fedora"
   When I execute dnf with args "install flac* --setopt=includepkgs=flac,flac-libs,setup  --setopt=excludepkgs=flac,glibc"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                          |
        | install       | flac-libs-0:1.3.2-8.fc29.x86_64  |
