@use.with_os=fedora__ge__31
Feature: Test the system-upgrade plugin

Background:
Given I enable plugin "system_upgrade"
  # Install the initial package versions first, then set the (target)
  # releasever and switch the repositories to http (so that system-upgrade
  # actually downloads the packages instead of using the local path). It is not
  # possible to set up an http server for a repository with two different
  # releasever variations.
  And I use repository "system-upgrade-f$releasever" with configuration
      | key         | value |
      | priority    | 1     |
  And I use repository "system-upgrade-2-f$releasever" with configuration
      | key         | value |
      | priority    | 2     |
  And I successfully execute dnf with args "install pkg-a pkg-b pkg-both"
  And I set releasever to "30"
  And I use repository "system-upgrade-f$releasever" as http
  And I use repository "system-upgrade-2-f$releasever" as http
  And I set environment variable "DNF_SYSTEM_UPGRADE_NO_REBOOT" to "1"


Scenario: Test system-upgrade when reboot wasn't performed
 When I execute dnf with args "system-upgrade download"
 Then the exit code is 0
  And DNF Transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
      | downgrade     | pkg-b-1.0-1.noarch    |
  And stdout contains lines
      """
      Download complete! Use 'dnf system-upgrade reboot' to start the upgrade.
      To remove cached metadata and transaction use 'dnf system-upgrade clean'
      The downloaded packages were saved in cache until the next successful transaction.
      You can remove cached packages by executing 'dnf clean packages'.
      """
 When I execute dnf with args "system-upgrade upgrade"
 Then the exit code is 0
  And stdout is
      """
      trigger file does not exist. exiting quietly.
      """


Scenario: Test system-upgrade basic functionality
 When I execute dnf with args "system-upgrade download"
 Then the exit code is 0
  And DNF Transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
      | downgrade     | pkg-b-1.0-1.noarch    |
  And stdout contains lines
      """
      Download complete! Use 'dnf system-upgrade reboot' to start the upgrade.
      To remove cached metadata and transaction use 'dnf system-upgrade clean'
      The downloaded packages were saved in cache until the next successful transaction.
      You can remove cached packages by executing 'dnf clean packages'.
      """
Given I successfully execute dnf with args "system-upgrade reboot"
  And I stop http server for repository "system-upgrade-f$releasever"
  And I stop http server for repository "system-upgrade-2-f$releasever"
 When I execute dnf with args "system-upgrade upgrade"
 Then the exit code is 0
  And transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
      | downgrade     | pkg-b-1.0-1.noarch    |


Scenario: Test system-upgrade with --destdir
 When I execute dnf with args "system-upgrade download --destdir={context.dnf.tempdir}/destdir"
 Then the exit code is 0
  And DNF Transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
      | downgrade     | pkg-b-1.0-1.noarch    |
  And stdout contains lines
      """
      Download complete! Use 'dnf system-upgrade reboot' to start the upgrade.
      To remove cached metadata and transaction use 'dnf system-upgrade clean'
      The downloaded packages were saved in cache until the next successful transaction.
      You can remove cached packages by executing 'dnf clean packages'.
      """
Given I successfully execute dnf with args "system-upgrade reboot"
  And I stop http server for repository "system-upgrade-f$releasever"
  And I stop http server for repository "system-upgrade-2-f$releasever"
 When I execute dnf with args "system-upgrade upgrade"
 Then the exit code is 0
  And transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
      | downgrade     | pkg-b-1.0-1.noarch    |


Scenario: Test system-upgrade with --no-downgrade
 When I execute dnf with args "system-upgrade download --no-downgrade"
 Then the exit code is 0
  And DNF Transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
  And stdout contains lines
      """
      Download complete! Use 'dnf system-upgrade reboot' to start the upgrade.
      To remove cached metadata and transaction use 'dnf system-upgrade clean'
      The downloaded packages were saved in cache until the next successful transaction.
      You can remove cached packages by executing 'dnf clean packages'.
      """
Given I successfully execute dnf with args "system-upgrade reboot"
  And I stop http server for repository "system-upgrade-f$releasever"
  And I stop http server for repository "system-upgrade-2-f$releasever"
 When I execute dnf with args "system-upgrade upgrade"
 Then the exit code is 0
  And transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |


Scenario: Test system-upgrade transaction file not found
 When I execute dnf with args "system-upgrade download"
 Then the exit code is 0
  And DNF Transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
      | downgrade     | pkg-b-1.0-1.noarch    |
  And stdout contains lines
      """
      Download complete! Use 'dnf system-upgrade reboot' to start the upgrade.
      To remove cached metadata and transaction use 'dnf system-upgrade clean'
      The downloaded packages were saved in cache until the next successful transaction.
      You can remove cached packages by executing 'dnf clean packages'.
      """
Given I successfully execute dnf with args "system-upgrade reboot"
  And I delete file "/var/lib/dnf/system-upgrade/system-upgrade-transaction.json"
 When I execute dnf with args "system-upgrade upgrade"
 Then the exit code is 1
  And stderr is
      """
      [Errno 2] No such file or directory: '{context.dnf.installroot}/var/lib/dnf/system-upgrade/system-upgrade-transaction.json'
      """


Scenario: Test system-upgrade downloading a package from a different repo
 When I execute dnf with args "system-upgrade download"
 Then the exit code is 0
  And DNF Transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
      | downgrade     | pkg-b-1.0-1.noarch    |
  And stdout contains lines
      """
      Download complete! Use 'dnf system-upgrade reboot' to start the upgrade.
      To remove cached metadata and transaction use 'dnf system-upgrade clean'
      The downloaded packages were saved in cache until the next successful transaction.
      You can remove cached packages by executing 'dnf clean packages'.
      """
Given I successfully execute dnf with args "system-upgrade reboot"
# Swap the priorities, so that dnf attempts to install the package from the other repo
  And I configure repository "system-upgrade-f$releasever" with
      | key         | value |
      | priority    | 2     |
  And I configure repository "system-upgrade-2-f$releasever" with
      | key         | value |
      | priority    | 1     |
  And I stop http server for repository "system-upgrade-f$releasever"
  And I stop http server for repository "system-upgrade-2-f$releasever"
 When I execute dnf with args "system-upgrade upgrade"
 Then the exit code is 0
  And transaction is following
      | Action        | Package               |
      | upgrade       | pkg-a-2.0-1.noarch    |
      | upgrade       | pkg-both-2.0-1.noarch |
      | downgrade     | pkg-b-1.0-1.noarch    |
