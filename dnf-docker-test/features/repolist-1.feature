Feature: Handling of --disablerepo and --enablerepo

Scenario: Handling of --disablerepo and --enablerepo with no repo
  When I execute "dnf" command "repolist --enablerepo=* --setopt=strict=true" with "fail"
  Then line from "stderr" should "start" with "Error: Unknown repo:"
  When I execute "dnf" command "repolist --disablerepo=* --setopt=strict=true" with "success"
  Then line from "stderr" should "start" with "No repository match:"
  When I execute "dnf" command "repolist --enablerepo=* --setopt=strict=false" with "success"
  Then line from "stderr" should "start" with "No repository match:"
  When I execute "dnf" command "repolist --disablerepo=* --setopt=strict=false" with "success"
  Then line from "stderr" should "start" with "No repository match:"
