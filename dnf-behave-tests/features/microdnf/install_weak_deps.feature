@no_installroot
# There is logical bug in libdnf and the test is not correct.
# Disable test until it will be fixed.
@xfail
Feature: Tests --setopt=install_weak_deps=


Background: Prepare environment
  Given I delete file "/etc/dnf/dnf.conf"
    And I delete file "/etc/yum.repos.d/*.repo" with globs
    And I delete directory "/var/lib/dnf/modulefailsafe/"
    And I execute microdnf with args "remove abcde flac"
    And I use repository "dnf-ci-fedora"


Scenario: Install "abcde" without weak dependencies
   When I execute microdnf with args "install --setopt=install_weak_deps=0 abcde"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | install       | abcde-0:2.9.2-1.fc29.noarch               |


Scenario: Install "abcde" with weak dependencies
   When I execute microdnf with args "install --setopt=install_weak_deps=1 abcde"
   Then the exit code is 0
    And microdnf transaction is
        | Action        | Package                                   |
        | install       | abcde-0:2.9.2-1.fc29.noarch               |
        | install       | flac-0:1.3.2-8.fc29.x86_64                |
