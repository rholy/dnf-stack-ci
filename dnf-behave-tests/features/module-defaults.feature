Feature: Modulemd defaults are followed by dnf module commands

Background:
  Given I use repository "dnf-ci-fedora-modular"
    And I use repository "dnf-ci-fedora"


Scenario: The default stream is used when enabling a module
   When I execute dnf with args "module enable nodejs"
   Then the exit code is 0
    And modules state is following
        | Module    | State     | Stream    | Profiles  |
        | nodejs    | enabled   | 8         |           |


@bz1629702
Scenario: The default streams are identified in the output of module list
   When I execute dnf with args "module list nodejs"
   Then the exit code is 0
    And module list is
        | Repository            | Name      | Stream    | Profiles     |
        | dnf-ci-fedora-modular | nodejs    | 5         | development, minimal, default |
        | dnf-ci-fedora-modular | nodejs    | 8 [d]     | development, minimal, default [d] |
        | dnf-ci-fedora-modular | nodejs    | 10        | development, minimal, default [d] |
        | dnf-ci-fedora-modular | nodejs    | 11        | development, minimal, default |


@bz1618553
Scenario: Default profiles are identified in the output of dnf info
   When I execute dnf with args "module info nodejs"
   Then the exit code is 0
    And stdout contains "Default profiles : default"


Scenario: Default stream and profile are used when installing a module with no enabled profile
   When I execute dnf with args "module install nodejs"
   Then the exit code is 0
    And modules state is following
        | Module    | State     | Stream    | Profiles  |
        | nodejs    | enabled   | 8         | default   |


@bz1582450
Scenario: Default profile(s) is used when installing a module with enabled stream
   When I execute dnf with args "module enable nodejs:10"
   Then the exit code is 0
    And modules state is following
        | Module    | State     | Stream    | Profiles  |
        | nodejs    | enabled   | 10        |           |
   When I execute dnf with args "module install nodejs"
   Then the exit code is 0
    And modules state is following
        | Module    | State     | Stream    | Profiles  |
        | nodejs    | enabled   | 10        | default   |


Scenario: Default profile is installed when installing a non-default stream with dnf module install module:stream
   When I execute dnf with args "module install nodejs:10"
   Then the exit code is 0
    And modules state is following
        | Module    | State     | Stream    | Profiles  |
        | nodejs    | enabled   | 10        | default   |
