Feature: Help command

Scenario: General help (dnf)
  Given I set dnf command to "dnf"
   When I execute dnf with args "--help"
   Then the exit code is 0
    And stdout contains "List of Main Commands"
   When I execute dnf with args "--unknown-option"
   Then the exit code is 0
    And stdout contains "List of Main Commands"
   When I execute dnf with args "help"
   Then the exit code is 0
    And stdout contains "List of Main Commands"
   When I execute dnf with args "unknown-command"
   Then the exit code is 1
    And stderr is
   """
   No such command: unknown-command. Please use /usr/bin/dnf --help
   It could be a DNF plugin command, try: "dnf install 'dnf-command(unknown-command)'"
   """

Scenario: General help (yum)
  Given I set dnf command to "yum"
   When I execute dnf with args "--help"
   Then the exit code is 0
    And stdout contains "List of Main Commands"
   When I execute dnf with args "--unknown-option"
   Then the exit code is 0
    And stdout contains "List of Main Commands"
   When I execute dnf with args "help"
   Then the exit code is 0
    And stdout contains "List of Main Commands"
   When I execute dnf with args "unknown-command"
   Then the exit code is 1
    And stderr is
   """
   No such command: unknown-command. Please use /usr/bin/yum --help
   It could be a YUM plugin command, try: "yum install 'dnf-command(unknown-command)'"
   """

Scenario: Command help
   When I execute dnf with args "help install"
   Then the exit code is 0
   And stdout contains "usage: .+ install"
   When I execute dnf with args "install --help"
   Then the exit code is 0
    And stdout contains "usage: .+ install"
   When I execute dnf with args "install --unknown-option"
   Then the exit code is 2
   And stderr contains ".+ install: err"

@bz1746474
@use.with_os=rhel__ge__8
@use.with_os=centos__ge__8
@use.with_os=fedora__ge__30
@use.with_os=fedora__lt__30
Scenario Outline: Help should refer to yum/dnf depending on what command was used
   When I execute "<command> <args>"
   Then the exit code is 0
    And stdout contains "usage: <help>"

Examples:
        | command  | args      |  help     |
        | dnf      | help      |  dnf \[options] COMMAND   |
        | dnf      | --help    |  dnf \[options] COMMAND   |
        | dnf-3    | help      |  dnf \[options] COMMAND   |
        | dnf-3    | --help    |  dnf \[options] COMMAND   |
        | yum      | help      |  yum \[options] COMMAND   |
        | yum      | --help    |  yum \[options] COMMAND   |
        | yum-builddep | --help    |  dnf builddep \[-c CONFIG_FILE] \[-q] \[-v] \[--version] |
        | yum shell    | --help    |  yum shell \[-c CONFIG_FILE] \[-q] \[-v] \[--version]    |

@bz1746474
@use.with_os=rhel__ge__8
@use.with_os=centos__ge__8
@use.with_os=fedora__ge__30
@use.with_os=fedora__lt__30
Scenario Outline: Help should refer to yum/dnf depending on what command was used
   When I execute "<command> <args>"
   Then the exit code is 0
    And stdout contains "<help>"

Examples:
        | command  | args      |  help     |
        | dnf builddep | --help    |  General DNF options:   |
        | yum builddep | --help    |  General YUM options:   |
        | yum-builddep | --help    |  General DNF options:   |
        | yum shell    | --help    |  run an interactive YUM shell  |
        | dnf shell    | --help    |  run an interactive DNF shell  |
        | yum alias    | --help    |  show YUM version and exit     |
        | dnf alias    | --help    |  show DNF version and exit     |
        | yum alias    | --help    |  enables yum's obsoletes processing logic for upgrade     |
        | dnf alias    | --help    |  enables dnf's obsoletes processing logic for upgrade     |
        | yum deplist    | --help    |  Display only packages that can be removed by "yum     |
        | dnf deplist    | --help    |  Display only packages that can be removed by "dnf     |
        | yum repoquery  | --help    |  Display only packages that can be removed by "yum     |
        | dnf repoquery  | --help    |  Display only packages that can be removed by "dnf     |
        | yum swap  | --help    |  run an interactive YUM mod for remove and install one spec    |
        | dnf swap  | --help    |  run an interactive DNF mod for remove and install one spe     |
        | yum config-manager  | --help    |  manage yum configuration options and repositories   |
        | dnf config-manager  | --help    |  manage dnf configuration options and repositories   |

@use.with_os=rhel__eq__7
@use.with_os=centos__eq__7
@xfail
Scenario Outline: Help should refer to yum4/dnf depending on what command was used
   When I execute "<command> <args>"
   Then the exit code is 0
    And stdout contains "usage: <command>"

Examples:
        | command  | args      |
        | dnf      | help      |
        | dnf      | --help    |
        | dnf-2    | help      |
        | dnf-2    | --help    |
        | yum4     | help      |
        | yum4     | --help    |
