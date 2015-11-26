Feature: Richdeps/Behave test
 TestA `Requires: (TestB and ((TestC or TestE) if TestD))` and TestF `Conflicts: TestC`

Scenario: 
  Given I use the repository "rich-3"
  When I "install" a package "TestA" with "dnf"
  Then package "TestA, TestB" should be "installed"
  And package "TestC, TestD, TestE, TestF" should be "absent"
