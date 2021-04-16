Feature: Disabling module - error handling


Background:
  Given I use repository "dnf-ci-fedora-modular"
  Given I use repository "dnf-ci-fedora"


Scenario Outline: Disabling a module by referring the <spec> should fail
   When I execute dnf with args "module enable nodejs:8"
   Then the exit code is 0
   When I execute dnf with args "module disable <modulespec>"
   Then the exit code is 1
    And stderr contains lines
    """
    Unable to resolve argument <modulespec>
    Error: Problems in request:
    missing groups or modules: <modulespec>
    """

Examples:
    | spec              | modulespec                |
    | wrong version     | nodeje:8:999              |
    | wrong stream      | nodejs:_no_stream         |
    | wrong name        | nodejs_no_name            |
