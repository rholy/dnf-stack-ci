@not.with_dnf=4
@dnf5
Feature: Tests for actions plugin

Background:
  Given I enable plugin "actions"
    And I configure dnf with
      | key            | value                                              |
      | pluginconfpath | {context.dnf.installroot}/etc/dnf/libdnf5-plugins  |
    And I create and substitute file "/etc/dnf/libdnf5-plugins/actions.conf" with
    """
    [main]
    enabled = 1
    """
    And I use repository "dnf-ci-fedora"


Scenario: Test substitutions and settings of libdnf variables, configuration options and actions plugin temporary variables
  Given I create and substitute file "/etc/dnf/libdnf5-plugins/actions.d/test.actions" with
    """
    # Print the value of the configuration option "defaultyes"
    pre_base_setup:::/bin/sh -c echo\ 'pre_base_setup:\ conf.defaultyes=${{conf.defaultyes}}'\ >>\ {context.dnf.installroot}/actions.log

    # A substitution will take place. The resulting action is the same as the previous one, it is filtered out.
    pre_base_setup:::/bin/sh -c echo\ 'pre_base_setup:\ conf.defaultyes=${{conf.defaultyes}}'\ >>\ {context.dnf.installroot}/actions.log

    # Create libdnf variable "test1" with value "Value1",
    # set configuration option "defaultyes" to 'true',
    # create temporary actions plugin variable "test_variable" with value "Value2"
    pre_base_setup:::/bin/sh -c echo\ -e\ "var.test1=Value1\\nconf.defaultyes=true\\ntmp.test_variable=Value2"

    # Print value of: libdnf variable "test1", configuration option "defaultyes", plugin temporary variable "test_variable"
    post_base_setup:::/bin/sh -c echo\ 'post_base_setup:\ var.test1=${{var.test1}}\ conf.defaultyes=${{conf.defaultyes}}\ tmp.test_variable=${{tmp.test_variable}}'\ >>\ {context.dnf.installroot}/actions.log

    # Delete temporary plugin variable "test_variable"
    post_base_setup:::/bin/sh -c echo\ -e\ "tmp.test_variable"

    # Nothing will be done. We cannot print the value of the plugin's temporary variable "test_variable" because it does not exist - it was deleted by a previous action.
    post_base_setup:::/bin/sh -c echo\ 'post_base_setup:\ tmp.test_variable=${{tmp.test_variable}}'\ >>\ {context.dnf.installroot}/actions.log

    # Print the value of the libdnf variable "releasever"
    post_base_setup:::/bin/sh -c echo\ 'post_base_setup:\ var.releasever=${{var.releasever}}'\ >>\ {context.dnf.installroot}/actions.log

    # Create temporary actions plugin variable "test_variable" with value "Value_set_in_pre_transaction"
    pre_transaction:::/bin/sh -c echo\ -e\ "tmp.test_variable=Value_set_in_pre_transaction"

    # Print a line for each package in the transaction - before executing the transaction
    pre_transaction:*::/bin/sh -c echo\ 'pre_transaction:\ ${{pkg.action}}\ ${{pkg.name}}-${{pkg.epoch}}:${{pkg.version}}-${{pkg.release}}.${{pkg.arch}}\ repo\ ${{pkg.repo_id}}'\ >>\ {context.dnf.installroot}/actions.log

    # Print a line for each package in the transaction - after the transaction
    post_transaction:*::/bin/sh -c echo\ 'post_transaction:\ ${{pkg.action}}\ ${{pkg.full_nevra}}\ repo\ ${{pkg.repo_id}}'\ >>\ {context.dnf.installroot}/actions.log

    # Print value of the temporary plugin variable "test_variable"
    post_transaction:::/bin/sh -c echo\ 'post_transaction:\ tmp.test_variable=${{tmp.test_variable}}'\ >>\ {context.dnf.installroot}/actions.log
    """
   When I execute dnf with args "install setup"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                               |
        | install       | setup-0:2.12.1-1.fc29.noarch          |
    And file "/actions.log" contents is
    """
    pre_base_setup: conf.defaultyes=0
    post_base_setup: var.test1=Value1 conf.defaultyes=1 tmp.test_variable=Value2
    post_base_setup: var.releasever=29
    pre_transaction: I setup-0:2.12.1-1.fc29.noarch repo dnf-ci-fedora
    post_transaction: I setup-0:2.12.1-1.fc29.noarch repo dnf-ci-fedora
    post_transaction: tmp.test_variable=Value_set_in_pre_transaction
    """


Scenario Outline: I can filter on package or file: "<filter>"
  Given I create and substitute file "/etc/dnf/libdnf5-plugins/actions.d/test.actions" with
    """
    pre_transaction:<filter>::/bin/sh -c echo\ '${{pkg.action}}\ ${{pkg.full_nevra}}\ repo\ ${{pkg.repo_id}}'\ >>\ {context.dnf.installroot}/actions.log
    """
   When I execute dnf with args "install glibc"
   Then the exit code is 0
    And Transaction is following
       | Action        | Package                                   |
       | install       | glibc-0:2.28-9.fc29.x86_64                |
       | install-dep   | setup-0:2.12.1-1.fc29.noarch              |
       | install-dep   | glibc-all-langpacks-0:2.28-9.fc29.x86_64  |
       | install-dep   | glibc-common-0:2.28-9.fc29.x86_64         |
       | install-dep   | filesystem-0:3.9-2.fc29.x86_64            |
       | install-dep   | basesystem-0:11-6.fc29.noarch             |
    And file "/actions.log" contents is
    """
    I glibc-0:2.28-9.fc29.x86_64 repo dnf-ci-fedora
    """

Examples:
    | filter            |
    | /etc/ld.so.conf   |
    | /etc/ld*conf      |
    | glibc             |
    | g*c               |


Scenario Outline: I can filter on transaction direction - inbound/outbound
  Given I create and substitute file "/etc/dnf/libdnf5-plugins/actions.d/test.actions" with
    """
    post_transaction:*:<direction>:/bin/sh -c echo\ '${{pkg.action}}\ ${{pkg.name}}'\ >>\ {context.dnf.installroot}/actions.log
    """
    And I create file "/actions.log" with
    """
    """
   When I execute dnf with args "install setup"
   Then the exit code is 0
    And file "/actions.log" contents is
    """
    <output>
    """

Examples:
    | direction | output      |
    |           | I setup     |
    | in        | I setup     |
    | out       |             |


Scenario: Reason change is in transaction
  Given I create and substitute file "/etc/dnf/libdnf5-plugins/actions.d/test.actions" with
    """
    pre_transaction:*::/bin/sh -c echo\ '${{pkg.action}}\ ${{pkg.full_nevra}}\ repo\ ${{pkg.repo_id}}'\ >>\ {context.dnf.installroot}/actions.log
    """
    And I use repository "installonly"
    And I configure dnf with
        | key                          | value         |
        | installonlypkgs              | installonlyA  |
        | installonly_limit            | 2             |
   When I execute dnf with args "install installonlyA-1.0"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                         |
        | install       | installonlyA-1.0-1.x86_64       |
    And file "/actions.log" contents is
    """
    I installonlyA-0:1.0-1.x86_64 repo installonly
    """
   Given I delete file "/actions.log"
    And I execute dnf with args "install installonlyA-2.0"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                         |
        | install       | installonlyA-2.0-1.x86_64       |
    And file "/actions.log" contents is
    """
    I installonlyA-0:2.0-1.x86_64 repo installonly
    """
   Given I delete file "/actions.log"
    And I execute dnf with args "install installonlyA-2.2"
   Then the exit code is 0
    And Transaction is following
        | Action        | Package                         |
        | install       | installonlyA-2.2-1.x86_64       |
        | remove        | installonlyA-1.0-1.x86_64       |
    And file "/actions.log" contains lines
    """
    E installonlyA-0:1.0-1.x86_64 repo @System
    \? installonlyA-0:2.0-1.x86_64 repo @System
    I installonlyA-0:2.2-1.x86_64 repo installonly
    """
