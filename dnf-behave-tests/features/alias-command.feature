# Aliases config path cannot be changed, so it cannot be taken from installroot
@no_installroot
Feature: Test for alias command

Background:
  Given I delete directory "/etc/dnf/aliases.d/"
    And I delete file "/etc/yum.repos.d/*.repo" with globs


Scenario: Add alias
   When I execute dnf with args "alias add inthrone=install"
   Then the exit code is 0
    And stdout is
        """
        Aliases added: inthrone
        """


@bz1666325
Scenario: List aliases
   When I execute dnf with args "alias add inthrone=install"
   Then the exit code is 0
   When I execute dnf with args "alias list"
   Then the exit code is 0
    And stdout is
        """
        Alias inthrone='install'
        """


@bz1680488
Scenario: List aliases with trivial infinite recursion
 When I execute dnf with args "alias add install='install dnf-ci-packageA'"
 Then the exit code is 0
  And stdout is
      """
      Aliases added: install
      """
   When I execute dnf with args "alias list"
   Then the exit code is 0
    And stderr is
        """
        Aliases contain infinite recursion, alias install="install dnf-ci-packageA"
        """
  Given I use repository "alias-command"
   When I execute dnf with args "install dnf-ci-packageB"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | dnf-ci-packageB-0:1.0-1.x86_64        |
    And stderr contains "Aliases contain infinite recursion, using original arguments."
  Given I successfully execute dnf with args "remove dnf-ci-packageB"


@bz1680488
Scenario: List aliases with non-trivial infinite recursion
 When I execute dnf with args "alias add install='inthrone dnf-ci-packageA' inthrone=install"
 Then the exit code is 0
  And stdout is
      """
      Aliases added: install, inthrone
      """
   When I execute dnf with args "alias list"
   Then the exit code is 0
    And stderr is
        """
        Aliases contain infinite recursion, alias install="inthrone dnf-ci-packageA"
        Aliases contain infinite recursion, alias inthrone="install"
        """
  Given I use repository "alias-command"
   When I execute dnf with args "install dnf-ci-packageB"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | dnf-ci-packageB-0:1.0-1.x86_64        |
    And stderr contains "Aliases contain infinite recursion, using original arguments."
  Given I successfully execute dnf with args "remove dnf-ci-packageB"


Scenario: Use alias
   When I execute dnf with args "alias add inthrone=install"
   Then the exit code is 0
  Given I use repository "alias-command"
   When I execute dnf with args "inthrone dnf-ci-packageA"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | dnf-ci-packageA-0:1.0-1.x86_64        |
  Given I successfully execute dnf with args "remove dnf-ci-packageA"


Scenario: Delete alias
   When I execute dnf with args "alias add inthrone=install"
   Then the exit code is 0
   When I execute dnf with args "alias delete inthrone"
   Then the exit code is 0
    And stdout is
        """
        Aliases deleted: inthrone
        """
   When I execute dnf with args "alias list"
   Then the exit code is 0
    And stdout is
        """
        No aliases defined.
        """
  Given I use repository "alias-command"
   When I execute dnf with args "inthrone dnf-ci-package"
   Then the exit code is 1
    And stderr contains "No such command: inthrone"
  Given I successfully execute dnf with args "remove dnf-ci-package"


@bz1680489
Scenario: Aliases conflicts: USER.conf has the highest priority, then alphabetical ordering is used
      # Multiple config files to decrease the randomness aspect
  Given I create file "/etc/dnf/aliases.d/A.conf" with
        """
        [aliases]
        test0 = commandA
        test1 = commandA
        test2 = commandA
        test3 = commandA
        test4 = commandA
        """
    And I create file "/etc/dnf/aliases.d/Z.conf" with
        """
        [aliases]
        test0 = commandZ
        test1 = commandZ
        """
    And I create file "/etc/dnf/aliases.d/B.conf" with
        """
        [aliases]
        test0 = commandB
        test1 = commandB
        test2 = commandB
        test3 = commandB
        """
    And I create file "/etc/dnf/aliases.d/USER.conf" with
        """
        [aliases]
        test0 = commandU
        """
    And I create file "/etc/dnf/aliases.d/C.conf" with
        """
        [aliases]
        test0 = commandC
        test1 = commandC
        test2 = commandC
        """
   When I execute dnf with args "alias"
   Then stdout is
        """
        Alias test0='commandU'
        Alias test1='commandZ'
        Alias test2='commandC'
        Alias test3='commandB'
        Alias test4='commandA'
        """
