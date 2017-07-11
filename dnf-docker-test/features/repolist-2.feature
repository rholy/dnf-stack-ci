Feature: Handling of --disablerepo and --enablerepo
  strict=false --disablerepo -> warning
  strict=false --enablerepo  -> warning
  strict=true  --disablerepo -> warning
  strict=true  --enablerepo  -> error

  @setup
  Scenario: Feature Setup
      Given empty repository "test-1"
      When I successfully run "dnf --enablerepo=test* makecache"

  Scenario: Handling of --disablerepo and --enablerepo with one repo
       When I successfully run "dnf repolist --enablerepo=test* --setopt=strict=true"
       Then the command stdout should match regexp "repo id +repo name +status\s+test-1 +test-1 +0"

       When I successfully run "dnf repolist --disablerepo=test* --setopt=strict=true"
       Then the command stdout should be empty

       When I successfully run "dnf repolist --enablerepo=test* --setopt=strict=false"

       Then the command stdout should match regexp "repo id +repo name +status\s+test-1 +test-1 +0"

       When I successfully run "dnf repolist --disablerepo=test* --setopt=strict=false"
       Then the command stdout should be empty
