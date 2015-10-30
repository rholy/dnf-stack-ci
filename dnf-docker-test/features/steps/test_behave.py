#!/usr/bin/python -tt

from behave import *
import os
import subprocess
import glob
import re

DNF_FLAGS = ['-y', '--disablerepo=*', '--nogpgcheck']
RPM_INSTALL_FLAGS = ['-Uvh']
RPM_ERASE_FLAGS = ['-e']


def _left_decorator(item):
    """ Removed packages """
    return u'-' + item


def _right_decorator(item):
    """ Installed packages """
    return u'+' + item


def find_pkg(pkg):
    """ Find the package file in the repository """
    candidates = glob.glob('/repo/'+pkg+'*.rpm')
    if len(candidates) == 0:
        print("No candidates for: '{0}'".format(pkg))
    assert len(candidates) == 1
    return candidates[0]


def decorate_rpm_packages(pkgs):
    """ Converts package names like TestA, TestB into absolute paths """
    return [find_pkg(p) for p in pkgs]


def get_package_list():
    """ Gets all installed packages in the system """
    pkgstr = subprocess.check_output(['rpm', '-qa', '--queryformat', '%{NAME}\n'])
    return pkgstr.splitlines()


def get_package_version_list():
    """ Gets all installed packages in the system with version"""
    pkgverstr = subprocess.check_output(['rpm', '-qa', '--queryformat', '%{NAME}-%{VERSION}-%{RELEASE}\n'])
    return pkgverstr.splitlines()


def get_package_dnf_version_list():
    """ Gets all installed packages in the system with version"""
    pkgverstr = subprocess.check_output(['dnf', 'repoquery', '--installed', '-C', '--queryformat', '%{name}.%{version}.%{release}\n'])
    pkgverstr = pkgverstr.splitlines()
    return pkgverstr[1:]



def diff_package_lists(a, b):
    """ Computes both left/right diff between lists `a` and `b` """
    sa, sb = set(a), set(b)
    return (map(_left_decorator, list(sa - sb)),
        map(_right_decorator, list(sb - sa)))


def package_version_lists(pkg, list_ver):
    """ Select package versions """
    new_list = [x for x in list_ver if re.search('^' + pkg, x)]
    assert len(new_list) == 1
    return str(new_list[0])


def package_absence(pkg, list_ver):
    """ Select package versions """
    new_list = [x for x in list_ver if re.search('^' + pkg, x)]
    assert len(new_list) == 0
    return None


def execute_dnf_command(cmd, reponame):
    """ Execute DNF command with default flags and the specified `reponame` enabled """
    flags = DNF_FLAGS + ['--enablerepo={0}'.format(reponame)]
    return subprocess.check_call(['dnf'] + flags + cmd, stdout=subprocess.PIPE)


def execute_dnf_command_notinstall(cmd, reponame):
    """ Execute DNF command with default flags and the specified `reponame` enabled """
    flags = DNF_FLAGS + ['--enablerepo={0}'.format(reponame)]
    return subprocess.call(['dnf'] + flags + cmd, stdout=subprocess.PIPE)


def execute_rpm_command(pkg, action):
    """ Execute given action over specified pkg(s) """
    if not isinstance(pkg, list):
        pkg = [pkg]
    if action == "remove":
        action = RPM_ERASE_FLAGS
    elif action == "install":
        action = RPM_INSTALL_FLAGS
        pkg = decorate_rpm_packages(pkg)
    return subprocess.check_call(['rpm'] + action + pkg, stdout=subprocess.PIPE)


def piecewise_compare(a, b):
    """ Check if the two sequences are identical regardless of ordering """
    return sorted(a) == sorted(b)


def split(pkg):
    return [p.strip() for p in pkg.split(',')]


@given('I use the repository "{repo}"')
def given_repo_condition(context, repo):
    """ :type context: behave.runner.Context """
    assert repo
    context.repo = repo
    assert context.repo
    assert os.path.exists('/var/www/html/repo/' + repo)
    subprocess.check_call(['echo -ne "[' + repo + ']\nname=' + repo + '\nbaseurl=http://127.0.0.1/repo/' + repo + '\nenabled=1\ngpgcheck=0" > /etc/yum.repos.d/' + repo + '.repo'], shell=True)


@when('I "{action}" a package "{pkg}" with "{manager}"')
def when_action_package(context, action, pkg, manager):
    assert action in ["install", "remove", "upgrade", "downgrade", "notinstall", "autoremove", "upgrade-to"]
    assert manager in ["rpm", "dnf", "pkcon"]
    assert pkg
    context.pre_packages = get_package_list()
    assert context.pre_packages
    context.pre_packages_version = get_package_version_list()
    assert context.pre_packages_version
    context.pre_packages_dnf_version = get_package_dnf_version_list()
    assert context.pre_packages_dnf_version
    if manager == 'rpm':
        execute_rpm_command(split(pkg), action)
    elif manager == 'dnf':
        if action == 'upgrade':
            if pkg == 'all':
                execute_dnf_command([action], context.repo)
            else:
                execute_dnf_command([action] + split(pkg), context.repo)
        elif action == 'notinstall':
            exit_code = execute_dnf_command_notinstall(["install"] + split(pkg), context.repo)
            assert exit_code != 0
        elif action == 'autoremove':
            subprocess.check_call(['dnf', '-y', action], stdout=subprocess.PIPE)
        else:
            execute_dnf_command([action] + split(pkg), context.repo)


@then('package "{pkg}" should be "{state}"')
def then_package_state(context, pkg, state):
    assert state in ["installed", "removed", "absent", "upgraded", 'unupgraded', "downgraded", 'present', 'upgraded-to']
    assert pkg
    pkgs = get_package_list()
    pkgs_ver = get_package_version_list()
    pkgs_dnf_ver = get_package_dnf_version_list()
    assert pkgs
    assert context.pre_packages
    removed, installed = diff_package_lists(context.pre_packages, pkgs)
    assert removed is not None and installed is not None
  
    for n in split(pkg):
        if state == 'installed':
            assert ('+' + n) in installed
            installed.remove('+' + n)
            post_present = package_version_lists(n, pkgs_ver)
            assert post_present
            post_dnf_present = package_version_lists(n, pkgs_dnf_ver)
            assert post_dnf_present
        if state == 'removed':
            assert ('-' + n) in removed
            removed.remove('-' + n)
            post_absence = package_absence(n, pkgs_ver)
            assert not post_absence
            post_dnf_absence = package_absence(n, pkgs_dnf_ver)
            assert not post_dnf_absence
        if state == 'absent':
            assert ('+' + n) not in installed
            assert ('-' + n) not in removed
            post_absence = package_absence(n, pkgs_ver)
            assert not post_absence
            post_dnf_absence = package_absence(n, pkgs_dnf_ver)
            assert not post_dnf_absence
        if state == 'upgraded':
            pre_ver = package_version_lists(n, context.pre_packages_version)
            post_ver = package_version_lists(n, pkgs_ver)
            assert post_ver
            assert pre_ver
            assert post_ver > pre_ver
        if state == 'unupgraded':
            pre_ver = package_version_lists(n, context.pre_packages_version)
            post_ver = package_version_lists(n, pkgs_ver)
            assert post_ver
            assert pre_ver
            assert post_ver == pre_ver
        if state == 'downgraded':
            pre_ver = package_version_lists(n, context.pre_packages_version)
            post_ver = package_version_lists(n, pkgs_ver)
            assert post_ver
            assert pre_ver
            assert post_ver < pre_ver
        if state == 'present':
            assert ('+' + n) not in installed
            assert ('-' + n) not in removed
            post_present = package_version_lists(n, pkgs_ver)
            assert post_present
            post_dnf_present = package_version_lists(n, pkgs_dnf_ver)
            assert post_dnf_present
        if state == 'upgraded-to':
            assert n in package_version_lists(n, pkgs_ver)

    """ This checks that installations/removals are always fully specified,
    so that we always cover the requirements/expecations entirely """
    if state in ["installed", "removed"]:
        assert not installed and not removed
