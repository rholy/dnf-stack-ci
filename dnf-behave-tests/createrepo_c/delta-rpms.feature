@not.with_os=rhel__ge__9
Feature: Tests createrepo_c generating delta rpms


Scenario: --deltas on empty repo
 When I execute createrepo_c with args "--deltas ." in "/"
 Then the exit code is 0
  And repodata "/repodata/" are consistent
  And repodata in "/repodata/" is
      | Type          | File                                | Checksum Type | Compression Type |
      | primary       | ${checksum}-primary.xml.zst         | sha256        | zstd             |
      | filelists     | ${checksum}-filelists.xml.zst       | sha256        | zstd             |
      | other         | ${checksum}-other.xml.zst           | sha256        | zstd             |
      | prestodelta   | ${checksum}-prestodelta.xml.zst     | sha256        | zstd             |


Scenario: --deltas on repo
Given I copy file "{context.scenario.repos_location}/createrepo_c-ci-packages/x86_64/package-0.2.1-1.fc29.x86_64.rpm" to "/"
 When I execute createrepo_c with args "--deltas ." in "/"
 Then the exit code is 0
  And repodata "/repodata/" are consistent
  And repodata in "/repodata/" is
      | Type          | File                                | Checksum Type | Compression Type |
      | primary       | ${checksum}-primary.xml.zst         | sha256        | zstd             |
      | filelists     | ${checksum}-filelists.xml.zst       | sha256        | zstd             |
      | other         | ${checksum}-other.xml.zst           | sha256        | zstd             |
      | prestodelta   | ${checksum}-prestodelta.xml.zst     | sha256        | zstd             |


Scenario: --deltas with empty --oldpackagedirs on repo
Given I copy file "{context.scenario.repos_location}/createrepo_c-ci-packages/x86_64/package-0.2.1-1.fc29.x86_64.rpm" to "/"
  And I create directory "/old_packages"
 When I execute createrepo_c with args "--deltas --oldpackagedirs ./old_packages ." in "/"
 Then the exit code is 0
  And repodata "/repodata/" are consistent
  And repodata in "/repodata/" is
      | Type          | File                                | Checksum Type | Compression Type |
      | primary       | ${checksum}-primary.xml.zst         | sha256        | zstd             |
      | filelists     | ${checksum}-filelists.xml.zst       | sha256        | zstd             |
      | other         | ${checksum}-other.xml.zst           | sha256        | zstd             |
      | prestodelta   | ${checksum}-prestodelta.xml.zst     | sha256        | zstd             |


Scenario: --deltas with --oldpackagedirs on repo generates drpm
Given I copy file "{context.scenario.repos_location}/createrepo_c-ci-packages-2/x86_64/package-0.3.1-1.fc29.x86_64.rpm" to "/"
  And I create directory "/old_packages"
  And I copy file "{context.scenario.repos_location}/createrepo_c-ci-packages/x86_64/package-0.2.1-1.fc29.x86_64.rpm" to "/old_packages"
 When I execute createrepo_c with args "--deltas --oldpackagedirs ./old_packages ." in "/"
 Then the exit code is 0
  And repodata "/repodata/" are consistent
  And repodata in "/repodata/" is
      | Type          | File                                | Checksum Type | Compression Type |
      | primary       | ${checksum}-primary.xml.zst         | sha256        | zstd             |
      | filelists     | ${checksum}-filelists.xml.zst       | sha256        | zstd             |
      | other         | ${checksum}-other.xml.zst           | sha256        | zstd             |
      | prestodelta   | ${checksum}-prestodelta.xml.zst     | sha256        | zstd             |
  And file "/drpms/package-0.2.1-1.fc29_0.3.1-1.fc29.x86_64.drpm" exists


@bz1842036
Scenario: generate drpms from zstd compressed packages
Given I copy file "{context.scenario.repos_location}/createrepo_c-ci-packages/x86_64/zstd-package-0.3.1-1.fc29.x86_64.rpm" to "/"
  And I create directory "/old_packages"
  And I copy file "{context.scenario.repos_location}/createrepo_c-ci-packages/x86_64/zstd-package-0.2.1-1.fc29.x86_64.rpm" to "/old_packages"
 When I execute createrepo_c with args "--deltas --oldpackagedirs ./old_packages ." in "/"
 Then the exit code is 0
  And repodata "/repodata/" are consistent
  And repodata in "/repodata/" is
      | Type          | File                                | Checksum Type | Compression Type |
      | primary       | ${checksum}-primary.xml.zst         | sha256        | zstd             |
      | filelists     | ${checksum}-filelists.xml.zst       | sha256        | zstd             |
      | other         | ${checksum}-other.xml.zst           | sha256        | zstd             |
      | prestodelta   | ${checksum}-prestodelta.xml.zst     | sha256        | zstd             |
  And file "/drpms/zstd-package-0.2.1-1.fc29_0.3.1-1.fc29.x86_64.drpm" exists
  And I successfully execute "rpm -qp --qf '%{{PAYLOADCOMPRESSOR}}\n' {context.scenario.default_tmp_dir}/drpms/zstd-package-0.2.1-1.fc29_0.3.1-1.fc29.x86_64.drpm"
  And stdout is
  """
  zstd
  """
