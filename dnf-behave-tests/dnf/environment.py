# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import print_function

import os
import shutil
import sys
import tempfile

# add the behave tests root to python path so that the `common` module can be found
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
# make sure behave loads the common steps
import common
import consts
import subprocess
import time

from behave import model
from behave.formatter.ansi_escapes import escapes

from steps.lib.config import write_config
from common.lib.cmd import print_last_command
from common.lib.file import ensure_directory_exists
from common.lib.os_version import detect_os_version
from common.lib.tag_matcher import VersionedActiveTagMatcher


DEFAULT_DNF_COMMAND = "dnf"
DEFAULT_REPOS_LOCATION = os.path.join(consts.FIXTURES_DIR, "repos")
DEFAULT_RELEASEVER="29"
DEFAULT_PLATFORM_ID="platform:f29"


class DNFContext(object):
    def __init__(self, userdata, force_installroot=False, no_installroot=False, dnf5_mode=False, dnfdaemon_mode=False):
        self._scenario_data = {}

        self.repos = {}
        self.ports = {}
        self.config = {
            "[main]": {
                "gpgcheck": "1",
                "installonly_limit": "3",
                "clean_requirements_on_remove": "True",
                "best": "True"
            }
        }

        # Since protected_packages don't work in installroot override host configuration
        if not no_installroot:
            self.config["[main]"]["protected_packages"] = ","

        self.tempdir = tempfile.mkdtemp(prefix="dnf_ci_tempdir_")
        # some tests need to be run inside the installroot, it can be forced
        # per scenario by using @force_installroot decorator
        if no_installroot:
            self.installroot = "/"

            # move the following original system setup files to a backup location,
            # so that they don't interfere and the tests start with a clean state
            for path in ("/etc/dnf/dnf.conf", "/etc/yum.repos.d", "/var/lib/dnf/modulefailsafe"):
                backup_path = path + ".backup"
                if os.path.exists(backup_path):
                    raise AssertionError(
                        'System backup path "%s" already exists. '
                        'Rerunning a no_installroot test in an unclean environment?' % backup_path)
                try:
                    shutil.move(path, backup_path)
                except FileNotFoundError:
                    pass

            # never delete root
            self.delete_installroot = False
        elif "installroot" in userdata and not force_installroot:
            self.installroot = userdata["installroot"]
            # never delete user defined installroot - this allows running tests on /
            self.delete_installroot = False
        else:
            self.installroot = tempfile.mkdtemp(prefix="dnf_ci_installroot_")
            self.delete_installroot = True

        ensure_directory_exists(os.path.join(self.installroot, "etc/yum.repos.d"))

        self.dnf_command = userdata.get("dnf_command", DEFAULT_DNF_COMMAND)
        self.releasever = userdata.get("releasever", DEFAULT_RELEASEVER)
        self.module_platform_id = userdata.get("module_platform_id", DEFAULT_PLATFORM_ID)
        self.fixturesdir = consts.FIXTURES_DIR
        self.disable_plugins = True
        self.disable_repos_option = "--disablerepo='*'"
        self.assumeyes_option = "-y"
        self.dnf5_mode = dnf5_mode
        self.dnfdaemon_mode = dnfdaemon_mode

        self.preserve_temporary_dirs = "none"
        preserve = userdata.get("preserve", "no")
        if preserve in ("yes", "y", "1", "true"):
            self.preserve_temporary_dirs = "all"
        elif preserve in ("failed", "fail", "f"):
            self.preserve_temporary_dirs = "failed"

        self.scenario_failed = False

    def __del__(self):
        preserved_dirs = []
        if os.path.realpath(self.tempdir) not in ["/", "/tmp"]:
            if (self.preserve_temporary_dirs == "all"
                    or (self.preserve_temporary_dirs == "failed" and self.scenario_failed)):
                preserved_dirs.append(self.tempdir)
            else:
                shutil.rmtree(self.tempdir)

        if self.delete_installroot and os.path.realpath(self.installroot) not in ["/"]:
            if (self.preserve_temporary_dirs == "all"
                    or (self.preserve_temporary_dirs == "failed" and self.scenario_failed)):
                preserved_dirs.append(self.installroot)
            else:
                shutil.rmtree(self.installroot)

        if preserved_dirs:
            print(escapes["undefined"] + "Temporary directories have been preserved for your browsing pleasure:")
            for d in preserved_dirs:
                print("   " + d)
            print(escapes["reset"])

    def __getitem__(self, name):
        return self._scenario_data[name]

    def __setitem__(self, name, value):
        self._scenario_data[name] = value

    def __contains__(self, name):
        return name in self._scenario_data

    def _get(self, name):
        if name in self:
            return self[name]
        return getattr(self, name, None)

    def _set(self, name, value):
        return setattr(self, name, value)

    def get_cmd(self, context):
        if self.dnf5_mode:
            result = self.get_dnf5_cmd(context)
        else:
            result = self.get_dnf4_cmd(context)
        return result

    def get_dnf4_cmd(self, context):
        result = [self.dnf_command]
        result.append(self.assumeyes_option)

        # installroot can't be set via context for safety reasons
        if self.installroot and self.installroot != "/":
            result.append("--installroot={0}".format(self.installroot))

        releasever = self._get("releasever")
        if releasever:
            result.append("--releasever={0}".format(releasever))

        module_platform_id = self._get("module_platform_id")
        if module_platform_id:
            result.append("--setopt=module_platform_id={0}".format(module_platform_id))

        disable_plugins = self._get("disable_plugins")
        if disable_plugins:
            result.append("--disableplugin='*'")
        plugins = self._get("plugins") or []
        for plugin in plugins:
            result.append("--enableplugin='{0}'".format(plugin))

        setopts = self._get("setopts") or {}
        for key,value in setopts.items():
            result.append("--setopt={0}={1}".format(key, value))

        return result

    def get_microdnf_cmd(self, context):
        result = ["microdnf"]
        result.append(self.assumeyes_option)

        # installroot can't be set via context for safety reasons
        if self.installroot and self.installroot != "/":
            result.append("--installroot={0}".format(self.installroot))

            # Microdnf in installroot mode requires the following options to be set.
            # The calculation of their default values is not implemented in microdnf.
            # New rules for default values are still being discussed.
            result.append("--noplugins")
            result.append("--config={0}".format(os.path.join(self.installroot, "etc/dnf/dnf.conf")))
            result.append("--setopt=reposdir={0}".format(os.path.join(self.installroot, "etc/yum.repos.d")))
            result.append("--setopt=varsdir={0}".format(os.path.join(self.installroot, "etc/dnf/vars")))
            result.append("--setopt=cachedir={0}".format(os.path.join(self.installroot, "var/cache/yum")))

        releasever = self._get("releasever")
        if releasever:
            result.append("--releasever={0}".format(releasever))

        module_platform_id = self._get("module_platform_id")
        if module_platform_id:
            result.append("--setopt=module_platform_id={0}".format(module_platform_id))

        # Plugins support is disabled in installroot mode. We can't disable/enable plugins.
        if not self.installroot or self.installroot == "/":
            disable_plugins = self._get("disable_plugins")
            if disable_plugins:
                result.append("--noplugins")
            plugins = self._get("plugins") or []
            for plugin in plugins:
                result.append("--enableplugin='{0}'".format(plugin))

        setopts = self._get("setopts") or {}
        for key, value in setopts.items():
            result.append("--setopt={0}={1}".format(key, value))

        return result

    def get_dnf5_cmd(self, context):
        result = [self.dnf_command]
        result.append(self.assumeyes_option)

        if self.installroot and self.installroot != "/":
            result.append("--installroot={0}".format(self.installroot))

        releasever = self._get("releasever")
        if releasever:
            result.append("--releasever={0}".format(releasever))

        module_platform_id = self._get("module_platform_id")
        if module_platform_id:
            result.append("--setopt=module_platform_id={0}".format(module_platform_id))

        plugins = self._get("plugins") or []
        for plugin in plugins:
            result.append("--enableplugin='{0}'".format(plugin))

        setopts = self._get("setopts") or {}
        for key,value in setopts.items():
            result.append("--setopt={0}={1}".format(key, value))

        result.append("--setopt=reposdir=%s" % self.installroot + "/etc/yum.repos.d")
        result.append("--setopt=config_file_path=%s" % self.installroot + "/etc/dnf/dnf.conf")
        result.append("--setopt=cachedir=%s" % self.installroot + "/var/cache/dnf")

        return result

def before_step(context, step):
    pass


def after_step(context, step):
    if step.status == model.Status.failed:
        print_last_command(context)


def before_scenario(context, scenario):
    if "xfail" in scenario.effective_tags:
        skip = True
        for ors in context.config.tags.ands:
            if "xfail" in ors:
                skip = False
                break

        if skip:
            scenario.skip(reason="Disabled by default by @xfail.")

    if context.tag_matcher.should_exclude_with(scenario.effective_tags):
        scenario.skip(reason="Disabled by OS version tag.")

    # Skip if destructive and not explicitly allowed by the user
    if ((set(scenario.effective_tags) & set(consts.DESTRUCTIVE_TAGS)) and not
            context.config.userdata.get('destructive', 'no') == 'yes'):
        scenario.skip(reason="Disabled by destructive tag.")

    # if we are skipping a scenario, don't create the environment
    # in case of a destructive scenario, that could mean modifying the current (non-temporary) system!
    if scenario.status == model.Status.skipped:
        context.dnf = None
        return

    # if "dnf5" is in the commandline tags, turn on dnf5 mode
    # if "dnfdaemon" turn on dnfdaemon mode and dnf5 mode
    dnf5_mode = False
    dnfdaemon_mode = False
    for ors in context.config.tags.ands:
        if "dnf5" in ors:
            dnf5_mode = True
            break
        if "dnfdaemon" in ors:
            dnf5_mode = True
            dnfdaemon_mode = True
            break


    context.dnf = DNFContext(context.config.userdata,
                             force_installroot='force_installroot' in scenario.tags,
                             no_installroot='no_installroot' in scenario.effective_tags,
                             dnf5_mode = dnf5_mode,
                             dnfdaemon_mode = dnfdaemon_mode)

    write_config(context)

    context.scenario.default_tmp_dir = context.dnf.installroot
    context.scenario.repos_location = context.config.userdata.get("repos_location", DEFAULT_REPOS_LOCATION)


def after_scenario(context, scenario):
    if scenario.status == model.Status.failed:
        context.dnf.scenario_failed = True

    # TODO workaround to avoid
    # terminate called after throwing an instance of 'sdbus::Error'
    # what():  [org.freedesktop.DBus.Error.NoReply] Message recipient disconnected from message bus without replying
    if context.dnf and context.dnf.dnfdaemon_mode:
        time.sleep(2)

    del context.dnf


def before_feature(context, feature):
    pass


def after_feature(context, feature):
    pass


def after_tag(context, tag):
    pass


def before_all(context):
    context.tag_matcher = VersionedActiveTagMatcher({"os": context.config.userdata.get("os", detect_os_version())})
    context.repos = {}
    context.invalid_utf8_char = consts.INVALID_UTF8_CHAR

    for ors in context.config.tags.ands:
        if "dnfdaemon" in ors:
            p_dbus_daemon = subprocess.Popen(['/usr/bin/dbus-daemon', '--system'])
            p_polkitd = subprocess.Popen(['/usr/lib/polkit-1/polkitd', '&'])


def after_all(context):
    pass
