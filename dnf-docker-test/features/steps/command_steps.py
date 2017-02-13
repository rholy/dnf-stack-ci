from __future__ import absolute_import
from __future__ import unicode_literals

from behave import register_type
from behave import then
from behave import when
import parse

import command_utils
import repo_utils

@parse.with_pattern(r"stdout|stderr")
def parse_stdout_stderr(text):
    return text

register_type(stdout_stderr=parse_stdout_stderr)

@when('I run "{command}"')
def step_i_run_command(ctx, command):
    """
    Run a ``{command}`` as subprocess, collect its output and returncode.
    """
    ctx.cmd_result = command_utils.run(ctx, command)

@when('I successfully run "{command}" in repository "{repository}"')
def step_i_successfully_run_command_in_repository(ctx, command, repository):
    repo = repo_utils.get_repo_dir(repository)
    ctx.assertion.assertIsNotNone(repo, "repository does not exist")
    ctx.cmd_result = command_utils.run(ctx, command, cwd=repo)
    ctx.assertion.assertEqual(ctx.cmd_result.returncode, 0)

@when('I successfully run "{command}"')
def step_i_successfully_run_command(ctx, command):
    step_i_run_command(ctx, command)
    step_the_command_should_pass(ctx)

@then("the command should pass")
def step_the_command_should_pass(ctx):
    ctx.assertion.assertEqual(ctx.cmd_result.returncode, 0)

@then("the command should fail")
def step_the_command_should_fail(ctx):
    ctx.assertion.assertNotEqual(ctx.cmd_result.returncode, 0)

@then("the command exit code is {values}")
def step_the_command_exit_code_is(ctx, values):
    """
    Compares the exit code of the previous command with a given value or comma separated list of values or ranges, e.g. '1,3,100-102'.
    """
    codes = []
    parts = values.split(',')
    for part in parts:
        if '-' in part:  # range a-b
            (lower, upper) = part.split('-', 1)
            lower = int(lower.strip())
            upper = int(upper.strip())
            codes.extend(range(lower, upper+1))
        else:
            codes.append(int(part.strip()))  # just plain number
    ctx.assertion.assertIn(ctx.cmd_result.returncode, codes)

@then("the command {stream:stdout_stderr} should match exactly")
def step_the_command_stream_should_match_exactly(ctx, stream):
    ctx.assertion.assertIsNotNone(ctx.text, "Multiline text is not provided")
    text = getattr(ctx.cmd_result, stream)
    ctx.assertion.assertMultiLineEqual(text, ctx.text)

@then("the command {stream:stdout_stderr} should be empty")
def step_the_command_stream_should_be_empty(ctx, stream):
    ctx.text = ""
    step_the_command_stream_should_match_exactly(ctx, stream)

@then('the command {stream:stdout_stderr} should match regexp "{regexp}"')
def step_the_command_stream_should_match_regexp(ctx, stream, regexp):
    text = getattr(ctx.cmd_result, stream)
    ctx.assertion.assertRegexpMatches(text, regexp)

@then('the command {stream:stdout_stderr} should not match regexp "{regexp}"')
def step_the_command_stream_should_not_match_regexp(ctx, stream, regexp):
    text = getattr(ctx.cmd_result, stream)
    ctx.assertion.assertNotRegexpMatches(text, regexp)
