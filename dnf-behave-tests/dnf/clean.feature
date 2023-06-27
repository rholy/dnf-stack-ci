Feature: Testing dnf clean command


@dnf5
Scenario: Ensure that metadata are unavailable after "dnf clean all"
  Given I use repository "dnf-ci-rich"
   When I execute dnf with args "makecache"
   Then the exit code is 0
   When I execute dnf with args "repoquery cream -C"
   Then the exit code is 0
    And stdout is
        """
        <REPOSYNC>
        cream-0:1.0-1.src
        cream-0:1.0-1.x86_64
        """
   When I execute dnf with args "clean all"
   Then the exit code is 0
   When I execute dnf with args "repoquery cream -C"
   Then the exit code is 1
    And stdout is
        """
        <REPOSYNC>
        """
    And stderr is 
        """
        Cache-only enabled but no cache for repository "dnf-ci-rich"
        """


@dnf5
@tier1
Scenario: Expire dnf cache and run repoquery for a package that has been removed meanwhile
  Given I copy repository "dnf-ci-thirdparty-updates" for modification
    And I use repository "dnf-ci-thirdparty-updates"
   When I execute dnf with args "repoquery --available SuperRipper"
   Then the exit code is 0
    And stdout is
        """
        <REPOSYNC>
        SuperRipper-0:1.2-1.src
        SuperRipper-0:1.2-1.x86_64
        SuperRipper-0:1.3-1.src
        SuperRipper-0:1.3-1.x86_64

        """
  Given I delete file "/{context.dnf.repos[dnf-ci-thirdparty-updates].path}/x86_64/SuperRipper-1.2-1.x86_64.rpm"
    And I generate repodata for repository "dnf-ci-thirdparty-updates"
   When I execute dnf with args "repoquery --available SuperRipper"
   Then the exit code is 0
    And stdout is
        """
        <REPOSYNC>
        SuperRipper-0:1.2-1.src
        SuperRipper-0:1.2-1.x86_64
        SuperRipper-0:1.3-1.src
        SuperRipper-0:1.3-1.x86_64

        """
   When I execute dnf with args "clean expire-cache"
   Then the exit code is 0
   When I execute dnf with args "repoquery --available SuperRipper"
   Then the exit code is 0
    And stdout is
        """
        <REPOSYNC>
        SuperRipper-0:1.2-1.src
        SuperRipper-0:1.3-1.src
        SuperRipper-0:1.3-1.x86_64
        """


@dnf5
@tier1
Scenario: Expire dnf cache and run repoquery when a package has been removed meanwhile
  Given I copy repository "dnf-ci-thirdparty-updates" for modification
    And I use repository "dnf-ci-thirdparty-updates"
   When I execute dnf with args "repoquery"
   Then the exit code is 0
    And stdout is
        """
        <REPOSYNC>
        CQRlib-extension-0:1.6-2.src
        CQRlib-extension-0:1.6-2.x86_64
        SuperRipper-0:1.2-1.src
        SuperRipper-0:1.2-1.x86_64
        SuperRipper-0:1.3-1.src
        SuperRipper-0:1.3-1.x86_64
        """
  Given I delete file "/{context.dnf.repos[dnf-ci-thirdparty-updates].path}/x86_64/SuperRipper-1.2-1.x86_64.rpm"
    And I generate repodata for repository "dnf-ci-thirdparty-updates"
   When I execute dnf with args "repoquery"
   Then the exit code is 0
    And stdout is
        """
        <REPOSYNC>
        CQRlib-extension-0:1.6-2.src
        CQRlib-extension-0:1.6-2.x86_64
        SuperRipper-0:1.2-1.src
        SuperRipper-0:1.2-1.x86_64
        SuperRipper-0:1.3-1.src
        SuperRipper-0:1.3-1.x86_64
        """
   When I execute dnf with args "clean expire-cache"
   Then the exit code is 0
   When I execute dnf with args "repoquery"
   Then the exit code is 0
    And stdout is
        """
        <REPOSYNC>
        CQRlib-extension-0:1.6-2.src
        CQRlib-extension-0:1.6-2.x86_64
        SuperRipper-0:1.2-1.src
        SuperRipper-0:1.3-1.src
        SuperRipper-0:1.3-1.x86_64
        """
