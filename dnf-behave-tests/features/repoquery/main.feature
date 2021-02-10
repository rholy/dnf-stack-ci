Feature: The common repoquery tests, core functionality, odds and ends.

Background:
 Given I use repository "repoquery-main"


# simple nevra matching tests
Scenario: repoquery (no arguments, i.e. list all packages)
 When I execute dnf with args "repoquery"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:1.0-1.noarch
      bottom-a1-1:1.0-1.src
      bottom-a1-1:2.0-1.noarch
      bottom-a1-1:2.0-1.src
      bottom-a2-1:1.0-1.src
      bottom-a2-1:1.0-1.x86_64
      bottom-a3-1:1.0-1.src
      bottom-a3-1:1.0-1.x86_64
      bottom-a3-1:2.0-1.src
      bottom-a3-1:2.0-1.x86_64
      broken-deps-1:1.0-1.src
      broken-deps-1:1.0-1.x86_64
      mid-a1-1:1.0-1.src
      mid-a1-1:1.0-1.x86_64
      mid-a2-1:1.0-1.src
      mid-a2-1:1.0-1.x86_64
      top-a-1:1.0-1.src
      top-a-1:1.0-1.x86_64
      top-a-1:2.0-1.src
      top-a-1:2.0-1.x86_64
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """

Scenario: repoquery NAME (nonexisting package)
 When I execute dnf with args "repoquery dummy"
 Then the exit code is 0
  And stdout is empty

Scenario: repoquery NAME
 When I execute dnf with args "repoquery top-a"
 Then the exit code is 0
  And stdout is
      """
      top-a-1:1.0-1.src
      top-a-1:1.0-1.x86_64
      top-a-1:2.0-1.src
      top-a-1:2.0-1.x86_64
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """

Scenario: repoquery NAME-VERSION
 When I execute dnf with args "repoquery top-a-2.0"
 Then the exit code is 0
  And stdout is
      """
      top-a-1:2.0-1.src
      top-a-1:2.0-1.x86_64
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """

Scenario: repoquery NAME-VERSION-RELEASE
 When I execute dnf with args "repoquery top-a-2.0-2"
 Then the exit code is 0
  And stdout is
      """
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """

Scenario: repoquery NAME-EPOCH:VERSION-RELEASE
 When I execute dnf with args "repoquery top-a-2:2.0-2"
 Then the exit code is 0
  And stdout is
      """
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """

Scenario: repoquery NAME-EPOCH:VERSION-RELEASE old epoch
 When I execute dnf with args "repoquery top-a-1:2.0-2"
 Then the exit code is 0
  And stdout is empty

Scenario: repoquery NAME NAME-EPOCH:VERSION-RELEASE
 When I execute dnf with args "repoquery bottom-a1 top-a-2:2.0-2"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:1.0-1.noarch
      bottom-a1-1:1.0-1.src
      bottom-a1-1:2.0-1.noarch
      bottom-a1-1:2.0-1.src
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """

Scenario: repoquery NAME-VERSION NAME-EPOCH:VERSION_GLOB-RELEASE
 When I execute dnf with args "repoquery bottom-a1-1.0 top-a-1:[12].0-1"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:1.0-1.noarch
      bottom-a1-1:1.0-1.src
      top-a-1:1.0-1.src
      top-a-1:1.0-1.x86_64
      top-a-1:2.0-1.src
      top-a-1:2.0-1.x86_64
      """

@xfail
@bz1735687
Scenario: repoquery NAME-VERSION NAME-EPOCH:VERSION_GLOB2-RELEASE
 When I execute dnf with args "repoquery bottom-a1-1.0 top-a-1:[1-2].0-1"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:1.0-1.noarch
      bottom-a1-1:1.0-1.src
      top-a-1:1.0-1.src
      top-a-1:1.0-1.x86_64
      top-a-1:2.0-1.src
      top-a-1:2.0-1.x86_64
      """


# --all: compatibility option, basically does nothing
Scenario: dnf repoquery --all
 When I execute dnf with args "repoquery"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:1.0-1.noarch
      bottom-a1-1:1.0-1.src
      bottom-a1-1:2.0-1.noarch
      bottom-a1-1:2.0-1.src
      bottom-a2-1:1.0-1.src
      bottom-a2-1:1.0-1.x86_64
      bottom-a3-1:1.0-1.src
      bottom-a3-1:1.0-1.x86_64
      bottom-a3-1:2.0-1.src
      bottom-a3-1:2.0-1.x86_64
      broken-deps-1:1.0-1.src
      broken-deps-1:1.0-1.x86_64
      mid-a1-1:1.0-1.src
      mid-a1-1:1.0-1.x86_64
      mid-a2-1:1.0-1.src
      mid-a2-1:1.0-1.x86_64
      top-a-1:1.0-1.src
      top-a-1:1.0-1.x86_64
      top-a-1:2.0-1.src
      top-a-1:2.0-1.x86_64
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """

Scenario: dnf repoquery --all NAME (illogical combination, --all is a compatibility noop)
 When I execute dnf with args "repoquery --all top-a"
 Then the exit code is 0
  And stdout is
      """
      top-a-1:1.0-1.src
      top-a-1:1.0-1.x86_64
      top-a-1:2.0-1.src
      top-a-1:2.0-1.x86_64
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """


# --available is the default, scenarios above should cover it
Scenario: dnf repoquery --available NAME
 When I execute dnf with args "repoquery --available top-a-2.0"
 Then the exit code is 0
  And stdout is
      """
      top-a-1:2.0-1.src
      top-a-1:2.0-1.x86_64
      top-a-2:2.0-2.src
      top-a-2:2.0-2.x86_64
      """


# --arch
Scenario: repoquery --arch ARCH
 When I execute dnf with args "repoquery --arch noarch"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:1.0-1.noarch
      bottom-a1-1:2.0-1.noarch
      """

Scenario: repoquery --arch ARCH (nonexisting arch)
 When I execute dnf with args "repoquery --arch yesarch"
 Then the exit code is 0
  And stdout is empty


# --cacheonly
Scenario: repoquery -C (without any cache)
 When I execute dnf with args "repoquery --available -C"
 Then the exit code is 1
 Then stdout is empty
 Then stderr is
      """
      Error: Cache-only enabled but no cache for 'repoquery-main'
      """

Scenario: repoquery -Cq (without any cache)
 When I execute dnf with args "repoquery --available -Cq"
 Then the exit code is 1
 Then stdout is empty
 Then stderr is
      """
      Error: Cache-only enabled but no cache for 'repoquery-main'
      """

Scenario: repoquery -C (with cache)
Given I successfully execute dnf with args "makecache"
 When I execute dnf with args "repoquery -C mid*"
 Then the exit code is 0
 Then stdout is
      """
      mid-a1-1:1.0-1.src
      mid-a1-1:1.0-1.x86_64
      mid-a2-1:1.0-1.src
      mid-a2-1:1.0-1.x86_64
      """

Scenario: repoquery -C (with cache, installed package)
Given I successfully execute dnf with args "makecache"
Given I successfully execute dnf with args "install bottom-a1"
 Then Transaction is following
      | Action        | Package                                   |
      | install       | bottom-a1-1:2.0-1.noarch                  |
 When I execute dnf with args "repoquery --installed -C"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:2.0-1.noarch
      """

Scenario: repoquery -C (with cache, but disabled repository)
Given I successfully execute dnf with args "makecache"
Given I drop repository "repoquery-main"
 When I execute dnf with args "repoquery --available -C"
 Then the exit code is 0
  And stdout is empty


# --deplist
Scenario: repoquery --deplist NAME
 When I execute dnf with args "repoquery --deplist top-a"
 Then the exit code is 0
  And stdout is
      """
      package: top-a-1:1.0-1.src

      package: top-a-1:1.0-1.x86_64
        dependency: bottom-a1 = 1:1.0-1
         provider: bottom-a1-1:1.0-1.noarch
        dependency: mid-a1 >= 2
         provider: mid-a1-1:1.0-1.x86_64
        dependency: mid-a2 = 1:1.0-1
         provider: mid-a2-1:1.0-1.x86_64

      package: top-a-1:2.0-1.src

      package: top-a-1:2.0-1.x86_64
        dependency: bottom-a1 = 1:1.0-1
         provider: bottom-a1-1:1.0-1.noarch
        dependency: mid-a1 >= 2
         provider: mid-a1-1:1.0-1.x86_64
        dependency: mid-a2 = 1:1.0-1
         provider: mid-a2-1:1.0-1.x86_64

      package: top-a-2:2.0-2.src

      package: top-a-2:2.0-2.x86_64
        dependency: bottom-a1 = 1:1.0-1
         provider: bottom-a1-1:1.0-1.noarch
        dependency: mid-a1 >= 2
         provider: mid-a1-1:1.0-1.x86_64
      """

@bz1784148
Scenario: repoquery --deplist REMOTE_RPM
 When I execute dnf with args "repoquery --deplist {context.dnf.fixturesdir}/repos/repoquery-main/x86_64/top-a-1.0-1.x86_64.rpm"
 Then the exit code is 0
  And stdout is
      """
      package: top-a-1:1.0-1.x86_64
        dependency: bottom-a1 = 1:1.0-1
         provider: bottom-a1-1:1.0-1.noarch
        dependency: mid-a1 >= 2
         provider: mid-a1-1:1.0-1.x86_64
        dependency: mid-a2 = 1:1.0-1
         provider: mid-a2-1:1.0-1.x86_64
        dependency: rpmlib(CompressedFileNames) <= 3.0.4-1
        dependency: rpmlib(FileDigests) <= 4.6.0-1
        dependency: rpmlib(PayloadFilesHavePrefix) <= 4.0-1
      """

@bz1784148
Scenario: repoquery --deplist NEVRA REMOTE_RPM
 When I execute dnf with args "repoquery --deplist top-a-2:2.0-2.x86_64 {context.dnf.fixturesdir}/repos/repoquery-main/x86_64/top-a-1.0-1.x86_64.rpm"
 Then the exit code is 0
  And stdout is
      """
      package: top-a-1:1.0-1.x86_64
        dependency: bottom-a1 = 1:1.0-1
         provider: bottom-a1-1:1.0-1.noarch
        dependency: mid-a1 >= 2
         provider: mid-a1-1:1.0-1.x86_64
        dependency: mid-a2 = 1:1.0-1
         provider: mid-a2-1:1.0-1.x86_64
        dependency: rpmlib(CompressedFileNames) <= 3.0.4-1
        dependency: rpmlib(FileDigests) <= 4.6.0-1
        dependency: rpmlib(PayloadFilesHavePrefix) <= 4.0-1

      package: top-a-2:2.0-2.x86_64
        dependency: bottom-a1 = 1:1.0-1
         provider: bottom-a1-1:1.0-1.noarch
        dependency: mid-a1 >= 2
         provider: mid-a1-1:1.0-1.x86_64
      """

Scenario: repoquery --deplist NAME (no such package)
 When I execute dnf with args "repoquery --deplist dummy"
 Then the exit code is 0
  And stdout is empty

Scenario: repoquery --deplist --latest-limit
 When I execute dnf with args "repoquery --deplist --latest-limit 1 top-a"
 Then the exit code is 0
  And stdout is
      """
      package: top-a-2:2.0-2.src

      package: top-a-2:2.0-2.x86_64
        dependency: bottom-a1 = 1:1.0-1
         provider: bottom-a1-1:1.0-1.noarch
        dependency: mid-a1 >= 2
         provider: mid-a1-1:1.0-1.x86_64
      """

Scenario: deplist --latest-limit (deplist is an alias for repoquery --deplist)
 When I execute dnf with args "deplist --latest-limit 1 top-a"
 Then the exit code is 0
  And stdout is
      """
      package: top-a-2:2.0-2.src

      package: top-a-2:2.0-2.x86_64
        dependency: bottom-a1 = 1:1.0-1
         provider: bottom-a1-1:1.0-1.noarch
        dependency: mid-a1 >= 2
         provider: mid-a1-1:1.0-1.x86_64
      """


# --extras: installed pkgs, not from known repos
Scenario: repoquery --extras
Given I successfully execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/miscellaneous/x86_64/dummy-1.0-1.x86_64.rpm"
 When I execute dnf with args "repoquery --extras"
 Then the exit code is 0
  And stdout is
      """
      dummy-1:1.0-1.x86_64
      """

Scenario: repoquery --extras (no such packages)
 When I execute dnf with args "repoquery --extras"
 Then the exit code is 0
  And stdout is empty

Scenario: repoquery --extras NAME (package is installed)
Given I successfully execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/miscellaneous/x86_64/dummy-1.0-1.x86_64.rpm"
Given I successfully execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/miscellaneous/x86_64/weird-1.0-1.x86_64.rpm"
 When I execute dnf with args "repoquery --extras dummy"
 Then the exit code is 0
  And stdout is
      """
      dummy-1:1.0-1.x86_64
      """

Scenario: repoquery --extras NAME (package is not installed)
 When I execute dnf with args "repoquery --extras dummy"
 Then the exit code is 0
  And stdout is empty

   # --extras: installed pkgs, different NEVRA in available repository
Scenario: dnf repoquery --extras (when there are such pkgs with different NEVRA in repository)
Given I drop repository "repoquery-main"
 When I execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/repoquery-main-multilib/x86_64/mid-a1-1.0-1.x86_64.rpm"
 Then the exit code is 0
 When I execute dnf with args "repoquery --installed"
 Then stdout is
 """
 mid-a1-1:1.0-1.x86_64
 """
Given I use repository "repoquery-main"
 When I execute dnf with args "repoquery --extras"
 Then stdout is empty

  # --extras: installed pkgs, no NA in available repository
Scenario: dnf repoquery --extras (no NA in available repository)
 When I execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/repoquery-main-multilib/i686/mid-a1-1.0-1.i686.rpm"
 Then the exit code is 0
 When I execute dnf with args "repoquery --installed"
 Then stdout is
 """
 mid-a1-1:1.0-1.i686
 """
 When I execute dnf with args "repoquery --extras"
 Then the exit code is 0
  And stdout is
 """
 mid-a1-1:1.0-1.i686
 """
Given I use repository "repoquery-main-multilib"
 When I execute dnf with args "repoquery --extras"
 Then the exit code is 0
  And stdout is empty

# --installed: list only installed packages
Scenario: repoquery --installed
Given I successfully execute dnf with args "install bottom-a1"
 When I execute dnf with args "repoquery --installed"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:2.0-1.noarch
      """

Scenario: repoquery --installed (no such packages)
 When I execute dnf with args "repoquery --installed"
 Then the exit code is 0
  And stdout is empty

Scenario: repoquery --installed NAME
Given I successfully execute dnf with args "install bottom-a1 bottom-a2"
 When I execute dnf with args "repoquery --installed bottom-a1"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:2.0-1.noarch
      """

Scenario: repoquery --installed NAME (no such packages)
 When I execute dnf with args "repoquery --installed bottom-a1"
 Then the exit code is 0
  And stdout is empty


# --location
@bz1639827
Scenario: repoquery --location NAME
 When I execute dnf with args "repoquery --location top-a-2.0"
 Then the exit code is 0
  And stdout matches line by line
      """
      .+/fixtures/repos/repoquery-main/src/top-a-2.0-1.src.rpm$
      .+/fixtures/repos/repoquery-main/src/top-a-2.0-2.src.rpm$
      .+/fixtures/repos/repoquery-main/x86_64/top-a-2.0-1.x86_64.rpm$
      .+/fixtures/repos/repoquery-main/x86_64/top-a-2.0-2.x86_64.rpm$
      """

Scenario: repoquery --location NAME (in an HTTP repo)
Given I use repository "repoquery-main" as https
 When I execute dnf with args "repoquery --location top-a-2.0"
 Then the exit code is 0
  And stdout matches line by line
      """
      https://localhost:[0-9]+/src/top-a-2.0-1.src.rpm$
      https://localhost:[0-9]+/src/top-a-2.0-2.src.rpm$
      https://localhost:[0-9]+/x86_64/top-a-2.0-1.x86_64.rpm$
      https://localhost:[0-9]+/x86_64/top-a-2.0-2.x86_64.rpm$
      """

Scenario: repoquery --location NAME (no such package)
 When I execute dnf with args "repoquery --location dummy"
 Then the exit code is 0
  And stdout is empty


@bz1873146
@not.with_os=rhel__eq__8
Scenario: repoquery --location for local package with file protocol is empty (no traceback)
 When I execute dnf with args "repoquery --location file://{context.dnf.fixturesdir}/repos/repoquery-main/noarch/bottom-a1-1.0-1.noarch.rpm"
 Then the exit code is 0
  And stdout is empty


@bz1873146
@not.with_os=rhel__eq__8
Scenario: repoquery --location for local package without file protocol is empty (no traceback)
 When I execute dnf with args "repoquery --location /{context.dnf.fixturesdir}/repos/repoquery-main/noarch/bottom-a1-1.0-1.noarch.rpm"
 Then the exit code is 0
  And stdout is empty


@bz1873146
@not.with_os=rhel__eq__8
Scenario: repoquery --location NAME for --installed is empty (no traceback)
Given I successfully execute dnf with args "install bottom-a1"
 When I execute dnf with args "repoquery --installed bottom-a1 --location"
 Then the exit code is 0
  And stdout is empty


# --srpm
Scenario: repoquery --srpm
 When I execute dnf with args "repoquery --srpm"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:1.0-1.src
      bottom-a1-1:2.0-1.src
      bottom-a2-1:1.0-1.src
      bottom-a3-1:1.0-1.src
      bottom-a3-1:2.0-1.src
      broken-deps-1:1.0-1.src
      mid-a1-1:1.0-1.src
      mid-a2-1:1.0-1.src
      top-a-1:1.0-1.src
      top-a-1:2.0-1.src
      top-a-2:2.0-2.src
      """

Scenario: repoquery --srpm NAME
 When I execute dnf with args "repoquery --srpm bottom-a1"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:1.0-1.src
      bottom-a1-1:2.0-1.src
      """


# --unneeded
Scenario: repoquery --unneeded
Given I successfully execute dnf with args "install top-a-1.0"
Given I successfully execute dnf with args "upgrade top-a"
 When I execute dnf with args "repoquery --unneeded"
 Then the exit code is 0
  And stdout is
      """
      bottom-a3-1:1.0-1.x86_64
      mid-a2-1:1.0-1.x86_64
      """


# --unsatisfied
Scenario: repoquery --unsatisfied
Given I successfully execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/repoquery-main/x86_64/broken-deps-1.0-1.x86_64.rpm"
 When I execute dnf with args "repoquery --unsatisfied"
 Then the exit code is 0
  And stdout is
      """

       Problem: problem with installed package broken-deps-1:1.0-1.x86_64
        - nothing provides broken-dep-1 needed by broken-deps-1:1.0-1.x86_64
        - nothing provides broken-dep-2 >= 2.0 needed by broken-deps-1:1.0-1.x86_64
      """


# --upgrades: lists packages that upgrade installed packages
Scenario: repoquery --upgrades
Given I successfully execute dnf with args "install bottom-a1-1.0"
 When I execute dnf with args "repoquery --upgrades"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:2.0-1.noarch
      bottom-a1-1:2.0-1.src
      """

Scenario: repoquery --upgrades (no such packages)
Given I successfully execute dnf with args "install bottom-a2-1.0"
 When I execute dnf with args "repoquery --upgrades"
 Then the exit code is 0
  And stdout is empty

Scenario: repoquery --upgrades NAME
Given I successfully execute dnf with args "install bottom-a1-1.0 bottom-a3-1.0"
 When I execute dnf with args "repoquery --upgrades bottom-a1"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1:2.0-1.noarch
      bottom-a1-1:2.0-1.src
      """

Scenario: repoquery --upgrades NAME (no such packages)
Given I successfully execute dnf with args "install bottom-a1-1.0 bottom-a2-1.0"
 When I execute dnf with args "repoquery --upgrades bottom-a2"
 Then the exit code is 0
  And stdout is empty


# --userinstalled
Scenario: repoquery --userinstalled
Given I successfully execute dnf with args "install top-a"
 When I execute dnf with args "repoquery --userinstalled"
 Then the exit code is 0
  And stdout is
      """
      top-a-2:2.0-2.x86_64
      """


# --queryformat
Scenario: repoquery --queryformat NVR
 When I execute dnf with args "repoquery --queryformat %{{name}}-%{{version}}-%{{release}} bottom-a1"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1.0-1
      bottom-a1-2.0-1
      """

# note: %{{installtime}}, %{{buildtime}}, %{{size}}, %{{downloadsize}}, %{{installsize}} untested as they vary
Scenario: repoquery --queryformat EVERYTHING
 When I execute dnf with args "repoquery --queryformat '%{{name}} | %{{arch}} | %{{epoch}} | %{{version}} | %{{release}} | %{{reponame}} | %{{repoid}} | %{{evr}} | %{{debug_name}} | %{{source_name}} | %{{source_debug_name}} | %{{provides}} | %{{requires}} | %{{obsoletes}} | %{{conflicts}} | %{{sourcerpm}} | %{{description}} | %{{summary}} | %{{license}} | %{{url}} | %{{reason}}' top*.x86_64"
 Then the exit code is 0
  And stdout is
      """
      top-a | x86_64 | 1 | 1.0 | 1 | repoquery-main | repoquery-main | 1:1.0-1 | top-a-debuginfo | top-a | top-a-debuginfo | top-a = 1:1.0-1
      top-a(x86-64) = 1:1.0-1 | bottom-a1 = 1:1.0-1
      mid-a1 >= 2
      mid-a2 = 1:1.0-1 |  |  | top-a-1.0-1.src.rpm | Dummy. | Top level package (depends on others). | Public Domain | None | (none)
      top-a | x86_64 | 1 | 2.0 | 1 | repoquery-main | repoquery-main | 1:2.0-1 | top-a-debuginfo | top-a | top-a-debuginfo | top-a = 1:2.0-1
      top-a(x86-64) = 1:2.0-1 | bottom-a1 = 1:1.0-1
      mid-a1 >= 2
      mid-a2 = 1:1.0-1 |  |  | top-a-2.0-1.src.rpm | Dummy. | Top level package (depends on others). | Public Domain | None | (none)
      top-a | x86_64 | 2 | 2.0 | 2 | repoquery-main | repoquery-main | 2:2.0-2 | top-a-debuginfo | top-a | top-a-debuginfo | top-a = 2:2.0-2
      top-a(x86-64) = 2:2.0-2 | bottom-a1 = 1:1.0-1
      mid-a1 >= 2 |  |  | top-a-2.0-2.src.rpm | Dummy. | Top level package (depends on others). | Public Domain | None | (none)
      """


# install bottom-a1 using dnf (i.e. has record in history database)
# install bottom-a2 using rpm (no record in history database)
@bz1898968
@bz1879168
Scenario: repoquery --queryformat from_repo
Given I successfully execute dnf with args "install bottom-a1"
  And I successfully execute rpm with args "-i --nodeps {context.dnf.fixturesdir}/repos/repoquery-main/x86_64/bottom-a2-1.0-1.x86_64.rpm"
 When I execute dnf with args "repoquery --available --installed --queryformat '%{{name}}-%{{version}}-%{{release}} %{{repoid}} -%{{from_repo}}-' bottom-*"
 Then the exit code is 0
  And stdout is
      """
      bottom-a1-1.0-1 repoquery-main --
      bottom-a1-2.0-1 @System -repoquery-main-
      bottom-a1-2.0-1 repoquery-main --
      bottom-a2-1.0-1 @System --
      bottom-a2-1.0-1 repoquery-main --
      bottom-a3-1.0-1 repoquery-main --
      bottom-a3-2.0-1 repoquery-main --
      """


# --querytags
@bz1744073
Scenario: dnf repoquery --querytags
 When I execute dnf with args "repoquery --querytags"
 Then the exit code is 0
  And stdout is
      """
      name, arch, epoch, version, release, reponame (repoid), from_repo, evr,
      debug_name, source_name, source_debug_name,
      installtime, buildtime, size, downloadsize, installsize,
      provides, requires, obsoletes, conflicts, sourcerpm,
      description, summary, license, url, reason
      """
