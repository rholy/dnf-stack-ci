@no_installroot
Feature: Test exception when dnf tries to do a transaction resolved but not valid anymore

Background: setup repository
  Given I use repository "miscellaneous"
    And I use repository "utility-plugins"
    And I configure dnf with
        | key          | value        |
        | pluginpath   | /dnf-plugins |
    And I do not disable plugins


@bz1815327
@bz1887293
@bz1909845
Scenario: Dnf fails to update a plugin if it does not exist after resolving the transaction
  Given I successfully execute dnf with args "install dummy"
    And I successfully execute dnf with args "install dnf-plugin-remove-dummy"
   When I execute dnf with args "remove dummy"
   Then the exit code is 1
   And stderr is
   """
   Error: An rpm exception occurred: package not installed
   """
