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

from behave import model
from behave.formatter.ansi_escapes import escapes

from common.lib.cmd import print_last_command
from common.lib.file import ensure_directory_exists
from common.lib.tag_matcher import VersionedActiveTagMatcher


FIXTURES_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "fixtures"))

DEFAULT_DNF_COMMAND = "dnf"
DEFAULT_CONFIG = os.path.join(FIXTURES_DIR, "dnf.conf")
DEFAULT_REPOS_LOCATION = os.path.join(FIXTURES_DIR, "repos")
DEFAULT_RELEASEVER="29"
DEFAULT_PLATFORM_ID="platform:f29"

# If a test is marked with any of these tags, it will be considered
# "destructive" to the system running it.
DESTRUCTIVE_TAGS = [
    "destructive",
    "no_installroot",
]


class DNFContext(object):
    def __init__(self, userdata, force_installroot=False, no_installroot=False):
        self._scenario_data = {}

        self.repos = {}
        self.ports = {}

        self.invalid_utf8_char = '\udcfd'

        self.tempdir = tempfile.mkdtemp(prefix="dnf_ci_tempdir_")
        # some tests need to be run inside the installroot, it can be forced
        # per scenario by using @force_installroot decorator
        if no_installroot:
            self.installroot = "/"
            # never delete root
            self.delete_installroot = False
        elif "installroot" in userdata and not force_installroot:
            self.installroot = userdata["installroot"]
            # never delete user defined installroot - this allows running tests on /
            self.delete_installroot = False
        else:
            self.installroot = tempfile.mkdtemp(prefix="dnf_ci_installroot_")
            # if we're creating installroot, ensure /etc/yum.repos.d exists,
            # otherwise dnf picks repo configs from the host
            ensure_directory_exists(os.path.join(self.installroot, "etc/yum.repos.d"))
            self.delete_installroot = True

        self.dnf_command = userdata.get("dnf_command", DEFAULT_DNF_COMMAND)
        self.config = userdata.get("config", DEFAULT_CONFIG)
        self.releasever = userdata.get("releasever", DEFAULT_RELEASEVER)
        self.module_platform_id = userdata.get("module_platform_id", DEFAULT_PLATFORM_ID)
        self.fixturesdir = FIXTURES_DIR
        self.disable_plugins = True
        self.disable_repos_option = "--disablerepo='*'"
        self.assumeyes_option = "-y"

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
        result = [self.dnf_command]
        result.append(self.assumeyes_option)

        # installroot can't be set via context for safety reasons
        if self.installroot:
            result.append("--installroot={0}".format(self.installroot))

        config = self._get("config")
        if config:
            result.append("--config={0}".format(config))

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


def before_step(context, step):
    pass


def after_step(context, step):
    pass


def before_scenario(context, scenario):
    if context.tag_matcher.should_exclude_with(scenario.effective_tags):
        scenario.skip(reason="DISABLED ACTIVE-TAG")

    # Skip if destructive and not explicitly allowed by the user
    if ((set(scenario.effective_tags) & set(DESTRUCTIVE_TAGS)) and not
            context.config.userdata.get('destructive', 'no') == 'yes'):
        scenario.skip(reason="DESTRUCTIVE")

    context.dnf = DNFContext(context.config.userdata,
                             force_installroot='force_installroot' in scenario.tags,
                             no_installroot='no_installroot' in scenario.effective_tags)

    context.scenario.default_tmp_dir = context.dnf.installroot
    context.scenario.repos_location = context.config.userdata.get("repos_location", DEFAULT_REPOS_LOCATION)


def after_scenario(context, scenario):
    if scenario.status == model.Status.failed:
        context.dnf.scenario_failed = True
        print_last_command(context)

    del context.dnf


def before_feature(context, feature):
    pass


def after_feature(context, feature):
    pass


def after_tag(context, tag):
    pass


def before_all(context):
    context.tag_matcher = VersionedActiveTagMatcher({"os": context.config.userdata.get("os", None)})
    context.repos = {}


def after_all(context):
    pass
