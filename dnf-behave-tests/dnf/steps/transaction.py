# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import print_function

import behave
import re

from common.lib.behave_ext import check_context_table
from common.lib.diff import print_lines_diff
from lib.dnf import ACTIONS, parse_transaction_table
from lib.rpm import RPM, diff_rpm_lists
from lib.rpmdb import get_rpmdb_rpms


def parse_context_table(context):
    result = {}
    for action in ACTIONS.values():
        result[action] = []
    result["obsoleted"] = []

    for action, nevras in context.table:
        if action not in result:
            continue
        if action.startswith('group-') or action.startswith('env-') or action.startswith('module-'):
            for group in nevras.split(", "):
                result[action].append(group)
        else:
            for nevra in nevras.split(", "):
                rpm = RPM(nevra)
                result[action].append(rpm)

    return result


def check_rpmdb_transaction(context, mode):
    check_context_table(context, ["Action", "Package"])

    if not "rpmdb_pre" in context.dnf:
        raise ValueError("RPMDB snapshot wasn't created before running this step.")

    context.dnf["rpmdb_post"] = get_rpmdb_rpms(context.dnf.installroot)

    # check changes in RPMDB
    rpmdb_transaction = diff_rpm_lists(context.dnf["rpmdb_pre"], context.dnf["rpmdb_post"])
    for action, nevras in context.table:
        if action.startswith("install-"):
            action = "install"
        if action.startswith("remove-"):
            action = "remove"

        if action in ["broken"] or action in ["conflict"]:
            continue
        for nevra in nevras.split(", "):
            if action.startswith('group-') or action.startswith('env-') or action.startswith('module-'):
                continue
            rpm = RPM(nevra)
            if action == "reinstall" and rpm not in rpmdb_transaction["reinstall"]:
                action = "unchanged"
            if (action == "remove" and rpm not in rpmdb_transaction["remove"]
                and rpm in rpmdb_transaction["obsoleted"]):
                action = "obsoleted"
            elif (action == "obsoleted" and rpm not in rpmdb_transaction["obsoleted"]
                  and rpm in rpmdb_transaction["remove"]):
                action = "remove"
            if action == "absent":
                if rpm in rpmdb_transaction["present"]:
                    raise AssertionError("[rpmdb] Package %s not '%s'" % (rpm, action))
                continue
            if rpm not in rpmdb_transaction[action]:
                candidates = ", ".join([str(i) for i in sorted(rpmdb_transaction[action])])
                raise AssertionError("[rpmdb] Package %s not '%s'; Possible candidates: %s" % (
                                     rpm, action, candidates))

    if mode == 'exact_match':
        context_table = parse_context_table(context)
        for action, nevras in context_table.items():
            if action.startswith("install-"):
                action = "install"
            if action.startswith("remove-") or action == "obsoleted":
                action = "remove"

            if action not in ["install", "remove", "upgrade", "downgrade"]:
                continue

            for nevra in nevras:
                if nevra in rpmdb_transaction[action]:
                    rpmdb_transaction[action].remove(nevra)
                elif action == "remove" and nevra in rpmdb_transaction["obsoleted"]:
                    rpmdb_transaction["obsoleted"].remove(nevra)

        for action in ["install", "remove", "upgrade", "downgrade", "obsoleted"]:
            if rpmdb_transaction[action]:
                raise AssertionError(
                    "[rpmdb] Following packages weren't captured in the table for action '%s': %s" % (
                    action, ", ".join([str(rpm) for rpm in sorted(rpmdb_transaction[action])])))

def check_dnf_transaction(context, mode):
    check_context_table(context, ["Action", "Package"])

    # check changes in DNF transaction table
    lines = context.cmd_stdout.splitlines()
    dnf_transaction = parse_transaction_table(lines)

    for action, nevras in context.table:
        if action in ["absent", "present", "unchanged", "changed"]:
            continue
        for nevra in nevras.split(", "):
            if action.startswith('group-') or action.startswith('env-') or action.startswith('module-'):
                title = action.split('-')[0].capitalize()
                group = nevra
                if group not in dnf_transaction[action]:
                    candidates = ", ".join([str(i) for i in sorted(dnf_transaction[action])])
                    raise AssertionError("[dnf] %s %s not %s; Possible candidates: %s" % (
                        title, group, action, candidates))
            else:
                rpm = RPM(nevra)
                if rpm not in dnf_transaction[action]:
                    candidates = ", ".join([str(i) for i in sorted(dnf_transaction[action])])
                    raise AssertionError("[dnf] Package %s not %s; Possible candidates: %s" % (
                                         rpm, action, candidates))

    if mode == 'exact_match':
        context_table = parse_context_table(context)
        for action, rpms in dnf_transaction.items():
            delta = rpms.difference(context_table[action])
            if delta:
                raise AssertionError(
                        "[dnf] Following packages weren't captured in the table for action '%s': %s" % (
                        action, ", ".join([str(rpm) for rpm in sorted(delta)])))


def check_transaction(context, mode):
    check_rpmdb_transaction(context, mode)
    check_dnf_transaction(context, mode)


@behave.then("Transaction is following")
def then_Transaction_is_following(context):
    check_transaction(context, 'exact_match')


@behave.then("RPMDB Transaction is following")
def then_RPMDB_Transaction_is_following(context):
    check_rpmdb_transaction(context, 'exact_match')


@behave.then("DNF Transaction is following")
def then_DNF_Transaction_is_following(context):
    check_dnf_transaction(context, 'exact_match')


@behave.then("Transaction contains")
def then_Transaction_contains(context):
    check_transaction(context, 'contains')


@behave.then("RPMDB Transaction is empty")
def then_RPMDB_transaction_is_empty(context):
    if not "rpmdb_pre" in context.dnf:
        raise ValueError("RPMDB snapshot wasn't created before running this step.")

    context.dnf["rpmdb_post"] = get_rpmdb_rpms(context.dnf.installroot)

    # check changes in RPMDB
    rpmdb_transaction = diff_rpm_lists(context.dnf["rpmdb_pre"], context.dnf["rpmdb_post"])
    if rpmdb_transaction["changed"]:
        changes = ", ".join([str(i) for i in sorted(rpmdb_transaction["changed"])])
        raise AssertionError("[rpmdb] Packages have changed: {}".format(changes))


@behave.then("DNF Transaction is empty")
def then_DNF_transaction_is_empty(context):
    # check changes in DNF transaction table
    lines = context.cmd_stdout.splitlines()
    try:
        dnf_transaction = parse_transaction_table(lines)
    except RuntimeError:
        dnf_transaction = {}
    if dnf_transaction:
        changes = ", ".join([str(i) for i in set().union(*dnf_transaction.values())])
        raise AssertionError("[dnf] Packages have changed: {}".format(changes))


@behave.then("Transaction is empty")
def then_transaction_is_empty(context):
    context.execute_steps(u"Then RPMDB Transaction is empty")
    context.execute_steps(u"Then DNF Transaction is empty")


def parse_microdnf_transaction_table(lines):
    """
    Find and parse transaction table.
    Return {action: set([rpms])}
    """
    trans_start_re = re.compile(r"Package +Repository +Size")
    transaction_start = None
    for i in range(0, len(lines) - 1):
        if trans_start_re.match(lines[i]):
            transaction_start = i + 1
            break
    assert transaction_start is not None, "Transaction table start not found"
    lines = lines[transaction_start:]

    transaction_end = None
    for i in range(0, len(lines)):
        if lines[i].startswith("Transaction Summary:"):
            transaction_end = i
    assert transaction_end is not None, "Transaction table end not found"
    lines = lines[:transaction_end]

    label_re = re.compile(r"^([^ ].+):$")
    replacing_re = re.compile(r"^replacing +(?P<nevra>[^ ]*)$")
    action = None
    result = []
    for line in lines:
        line = line.strip()

        label_match = label_re.match(line)
        if label_match:
            action = ACTIONS[label_match.group(1)]
            continue

        replacing_match = replacing_re.match(line)
        if replacing_match:
            real_action = "replaced"
            package = replacing_match.group("nevra")
        else:
            real_action = action
            package = line.split(" ")[0]

        # use RPM to parse and format the NEVRA to add epoch if missing
        result.append((real_action, str(RPM(package))))

    return sorted(result)


def check_microdnf_transaction(context, mode):
    check_context_table(context, ["Action", "Package"])

    transaction = parse_microdnf_transaction_table(context.cmd_stdout.splitlines())
    table = sorted([(a, p) for a, p in context.table])

    updated_table = []
    for action, nevra in table:
        if action in ["upgraded", "downgraded", "reinstalled", "obsoleted"]:
            action = "replaced"
        if action.startswith("install-"):
            action = "install"
        if action.startswith("remove-"):
            action = "remove"
        updated_table.append((action, nevra))
    updated_table.sort()

    if transaction != updated_table:
        print_lines_diff(updated_table, transaction)
        raise AssertionError("Transaction table mismatch")


@behave.then("microdnf transaction is")
def then_microdnf_transaction_is_following(context):
    check_microdnf_transaction(context, 'exact_match')
    check_rpmdb_transaction(context, 'exact_match')
