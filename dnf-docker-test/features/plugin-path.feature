Feature: DNF/Behave test (pluginspath and pluginsconfpath test)

Scenario: Redirect host pluginspath
  When I execute "dnf" command "repoquery TestA" with "success"
  And I execute "dnf" command "copr list rpmsoftwaremanagement" with "success"
  When I copy plugin module "repoquery.py" from default plugin path into "/test/plugins"
  And I create a file "/etc/dnf/dnf.conf" with content: "[main]\npluginpath=/test/plugins"
  Then I execute "dnf" command "repoquery TestA" with "success"
  And I execute "dnf" command "copr list rpmsoftwaremanagement" with "fail"
  When I copy plugin module "copr.py" from default plugin path into "/test/plugins"
  Then I execute "dnf" command "copr list rpmsoftwaremanagement" with "success"
  When I create a file "/etc/dnf/dnf.conf" with content: "[main]"

Scenario: Redirect installroot pluginspath
  When I execute "dnf" command "--installroot=/dockertesting repoquery TestA" with "success"
  And I execute "dnf" command "--installroot=/dockertesting copr list rpmsoftwaremanagement" with "success"
  And I execute "dnf" command "--installroot=/dockertesting config-manager" with "success"
  When I copy plugin module "repoquery.py, copr.py" from default plugin path into "/test/plugins2"
  And I create a file "/dockertesting/etc/dnf/dnf.conf" with content: "[main]\npluginpath=/test/plugins2"
  Then I execute "dnf" command "--installroot=/dockertesting repoquery TestA" with "success"
  And I execute "dnf" command "--installroot=/dockertesting copr list rpmsoftwaremanagement" with "success"
  And I execute "dnf" command "--installroot=/dockertesting config-manager" with "fail"

Scenario: Test host default pluginsconfpath (/etc/dnf/plugins/)
  Given I use the repository "test-1"
  When I create a file "/etc/dnf/plugins/debuginfo-install.conf" with content: "[main]\nenabled=1\nautoupdate=0"
  When I create a file "/etc/yum.repos.d/test-1.repo" with content: "[test-1]\nname=test-1\nbaseurl=file:///var/www/html/repo/test-1-gpg\nenabled=1\ngpgcheck=0\n\n[test-1-debuginfo]\nname=test-1-debuginfo\nbaseurl=file:///var/www/html/repo/test-1\nenabled=0\ngpgcheck=0"
  Then I execute "dnf" command "-y debuginfo-install TestA" with "success"
  And transaction changes are as follows
   | State        | Packages                 |
   | installed    | TestA-debuginfo-1.0.0-1  |
  When I create a file "/etc/yum.repos.d/test-1.repo" with content: "[upgrade_1]\nname=upgrade_1\nbaseurl=file:///var/www/html/repo/upgrade_1-gpg\nenabled=1\ngpgcheck=0\n\n[upgrade_1-debuginfo]\nname=upgrade_1-debuginfo\nbaseurl=file:///var/www/html/repo/upgrade_1\nenabled=0\ngpgcheck=0"
  Then I execute "dnf" command "-y upgrade" with "success"
  And transaction changes are as follows
   | State        | Packages         |
   | present      | TestA-debuginfo  |
  When I create a file "/etc/dnf/plugins/debuginfo-install.conf" with content: "[main]\nenabled=1\nautoupdate=1"
  Then I execute "dnf" command "-y upgrade" with "success"
  And transaction changes are as follows
   | State        | Packages                 |
   | upgraded     | TestA-debuginfo-1.0.0-2  |
# Reset to original state
  When I execute "dnf" command "-y remove TestA-debuginfo" with "success"
  Then transaction changes are as follows
   | State        | Packages         |
   | removed      | TestA-debuginfo  |
  When I create a file "/etc/dnf/plugins/debuginfo-install.conf" with content: "[main]\nenabled=1\nautoupdate=0"

Scenario: Redirect host pluginsconfpath in dnf.conf
  Given I use the repository "test-1"
  When I create a file "/test/pluginconfpath/debuginfo-install.conf" with content: "[main]\nenabled=1\nautoupdate=1"
  When I create a file "/etc/yum.repos.d/test-1.repo" with content: "[test-1]\nname=test-1\nbaseurl=file:///var/www/html/repo/test-1-gpg\nenabled=1\ngpgcheck=0\n\n[test-1-debuginfo]\nname=test-1-debuginfo\nbaseurl=file:///var/www/html/repo/test-1\nenabled=0\ngpgcheck=0"
  Then I execute "dnf" command "-y debuginfo-install TestB" with "success"
  And transaction changes are as follows
   | State        | Packages                 |
   | installed    | TestB-debuginfo-1.0.0-1  |
  When I create a file "/etc/yum.repos.d/test-1.repo" with content: "[upgrade_1]\nname=upgrade_1\nbaseurl=file:///var/www/html/repo/upgrade_1-gpg\nenabled=1\ngpgcheck=0\n\n[upgrade_1-debuginfo]\nname=upgrade_1-debuginfo\nbaseurl=file:///var/www/html/repo/upgrade_1\nenabled=0\ngpgcheck=0"
  Then I execute "dnf" command "-y upgrade" with "success"
  And transaction changes are as follows
   | State        | Packages         |
   | present      | TestB-debuginfo  |
  When I create a file "/etc/dnf/dnf.conf" with content: "[main]\npluginconfpath=/test/pluginconfpath"
  Then I execute "dnf" command "-y upgrade" with "success"
  And transaction changes are as follows
   | State        | Packages                 |
   | upgraded     | TestB-debuginfo-1.0.0-2  |
# Reset to original state
  When I execute "dnf" command "-y remove TestB-debuginfo" with "success"
  Then transaction changes are as follows
   | State        | Packages         |
   | removed      | TestB-debuginfo  |
  When I create a file "/etc/dnf/plugins/debuginfo-install.conf" with content: "[main]\nenabled=1\nautoupdate=0"

Scenario: Test installroot default pluginsconfpath (/installroot/etc/dnf/plugins/)
  Given I use the repository "test-1-gpg"
  When I create a file "/dockertesting2/etc/dnf/plugins/debuginfo-install.conf" with content: "[main]\nenabled=1\nautoupdate=0"
  When I create a file "/dockertesting2/etc/yum.repos.d/test-1.repo" with content: "[test-1]\nname=test-1\nbaseurl=file:///var/www/html/repo/test-1-gpg\nenabled=1\ngpgcheck=0\n\n[test-1-debuginfo]\nname=test-1-debuginfo\nbaseurl=file:///var/www/html/repo/test-1\nenabled=0\ngpgcheck=0"
  Then I execute "dnf" command "--installroot=/dockertesting2 -y debuginfo-install TestA" with "success"
  And I execute "bash" command "rpm -q --root=/dockertesting2 TestA-debuginfo" with "success"
  And line from "stdout" should "start" with "TestA-debuginfo-1.0.0-1"
  When I create a file "/dockertesting2/etc/yum.repos.d/test-1.repo" with content: "[upgrade_1]\nname=upgrade_1\nbaseurl=file:///var/www/html/repo/upgrade_1-gpg\nenabled=1\ngpgcheck=0\n\n[upgrade_1-debuginfo]\nname=upgrade_1-debuginfo\nbaseurl=file:///var/www/html/repo/upgrade_1\nenabled=0\ngpgcheck=0"
  Then I execute "dnf" command "--installroot=/dockertesting2 -y upgrade" with "success"
  And I execute "bash" command "rpm -q --root=/dockertesting2 TestA-debuginfo" with "success"
  And line from "stdout" should "start" with "TestA-debuginfo-1.0.0-1"
  When I create a file "/dockertesting2/etc/dnf/plugins/debuginfo-install.conf" with content: "[main]\nenabled=1\nautoupdate=1"
  Then I execute "dnf" command "--installroot=/dockertesting2 -y upgrade" with "success"
  And I execute "bash" command "rpm -q --root=/dockertesting2 TestA-debuginfo" with "success"
  And line from "stdout" should "start" with "TestA-debuginfo-1.0.0-2"

Scenario: Redirect installroot pluginsconfpath in dnf.conf (path redirected into installroot)
  Given I use the repository "test-1"
  When I create a file "/dockertesting3/test/pluginconfpath/debuginfo-install.conf" with content: "[main]\nenabled=1\nautoupdate=1"
  When I create a file "/dockertesting3/etc/yum.repos.d/test-1.repo" with content: "[test-1]\nname=test-1\nbaseurl=file:///var/www/html/repo/test-1-gpg\nenabled=1\ngpgcheck=0\n\n[test-1-debuginfo]\nname=test-1-debuginfo\nbaseurl=file:///var/www/html/repo/test-1\nenabled=0\ngpgcheck=0"
  Then I execute "dnf" command "--installroot=/dockertesting3 -y debuginfo-install TestB" with "success"
  And I execute "bash" command "rpm -q --root=/dockertesting3 TestB-debuginfo" with "success"
  And line from "stdout" should "start" with "TestB-debuginfo-1.0.0-1"
  When I create a file "/dockertesting3/etc/yum.repos.d/test-1.repo" with content: "[upgrade_1]\nname=upgrade_1\nbaseurl=file:///var/www/html/repo/upgrade_1-gpg\nenabled=1\ngpgcheck=0\n\n[upgrade_1-debuginfo]\nname=upgrade_1-debuginfo\nbaseurl=file:///var/www/html/repo/upgrade_1\nenabled=0\ngpgcheck=0"
  Then I execute "dnf" command "--installroot=/dockertesting3 -y upgrade" with "success"
  And I execute "bash" command "rpm -q --root=/dockertesting3 TestB-debuginfo" with "success"
  And line from "stdout" should "start" with "TestB-debuginfo-1.0.0-1"
  When I create a file "/dockertesting3/etc/dnf/dnf.conf" with content: "[main]\npluginconfpath=/test/pluginconfpath"
  Then I execute "dnf" command "--installroot=/dockertesting3 -y upgrade" with "success"
  And I execute "bash" command "rpm -q --root=/dockertesting3 TestB-debuginfo" with "success"
  And line from "stdout" should "start" with "TestB-debuginfo-1.0.0-2"
