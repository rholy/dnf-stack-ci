# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import print_function

from behave import given, step


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
