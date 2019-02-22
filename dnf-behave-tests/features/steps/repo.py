# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import print_function

from behave import given, when, then, step

from common.rpmdb import get_rpmdb_rpms


@step("I use the repository \"{repo}\"")
def step_repo_use(context, repo):
    if "repos" not in context.dnf:
        context.dnf["repos"] = []
    if repo not in context.dnf["repos"]:
        context.dnf["repos"].append(repo)


@step("I disable the repository \"{repo}\"")
def step_repo_disable(context, repo):
    if "repos" not in context.dnf:
        context.dnf["repos"] = []
    context.dnf["repos"].remove(repo)


@given("There are no repositories")
def given_no_repos(context):
    context.dnf["reposdir"] = "/dev/null"


@given("I am running a system identified as the \"{system}\"")
def given_system(context, system):
    fields = system.split(' ')
    if len(fields) == 2:
        # No VARIANT_ID
        fields.append(None)
    data = dict(zip(('NAME', 'VERSION_ID', 'VARIANT_ID'), fields))
    context.osrelease.set(data)


@given("I am using libdnf of the version X.Y.Z")
def given_libdnf_version(context):
    rpms = [rpm for rpm in get_rpmdb_rpms() if rpm.name == 'libdnf']
    assert len(rpms) == 1, 'There should be exactly one libdnf RPM installed'
    context.libdnf_version = rpms[0].version


@given("I have enabled a remote repository")
def step_remote_repo(context):
    context.dnf["repos"] = ["dnf-ci-http"]


@when("I refresh the metadata")
def step_refresh_metadata(context):
    context.execute_steps('when I execute dnf with args "makecache"')


@then("{quantifier} HTTP request {what} should contain")
def step_check_http_requests(context, quantifier, what):
    requests = context.httpd.requests

    # Filter the requests by the given type (if any)
    if what == 'to the repository':
        # We want all requests, hence no filtering
        pass
    assert len(requests) > 0, 'Some HTTP requests should have been received'

    # Detect what kind of data we have in the table
    headings = context.table.headings
    if 'header' in headings:
        # Create a copy of the context table, to substitute X.Y.Z in the
        # User-Agent field (if present) with the libdnf version (we can't
        # hard-code the version in the feature files for obvious reasons).
        table = []
        for row in context.table:
            header, value = row['header'], row['value']
            if header == 'User-Agent':
                value = value.replace('X.Y.Z', context.libdnf_version)
            table.append({'header': header, 'value': value})

        headers = [req['headers'] for req in requests]
        matches = [row['value'] == hdr[row['header']]
                   for hdr in headers
                   for row in table]

    if quantifier == 'every':
        assert all(matches), 'Every request should match the table'
    elif quantifier == 'exactly one':
        assert len([m for m in matches if m]) == 1, \
            'Exactly one request should match the table'
