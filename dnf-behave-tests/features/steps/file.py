# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import print_function

import behave
import glob
import re
import os

from common import *

def prepend_installroot(context, path):
    path = path.format(context=context)
    root = '/'
    if not path.startswith('//'):
        root = context.dnf.installroot
    return os.path.join(root, path.lstrip("/"))

@behave.given('I create directory "{dirpath}"')
def step_impl(context, dirpath):
    full_path = prepend_installroot(context, dirpath)
    ensure_directory_exists(full_path)


@behave.given('I create file "{filepath}" with')
def step_impl(context, filepath):
    full_path = prepend_installroot(context, filepath)
    ensure_directory_exists(os.path.dirname(full_path))
    create_file_with_contents(full_path, context.text)


@behave.given('I create and substitute file "{filepath}" with')
def step_impl(context, filepath):
    full_path = prepend_installroot(context, filepath)
    ensure_directory_exists(os.path.dirname(full_path))
    create_file_with_contents(full_path, context.text.format(context=context))


@behave.given('I create symlink "{dst}" to file "{src}"')
def step_impl(context, dst, src):
    dst = prepend_installroot(context, dst)
    src = prepend_installroot(context, src)
    ensure_directory_exists(os.path.dirname(dst))
    os.symlink(src, dst)


@behave.given('I delete file "{filepath}"')
def step_delete_file(context, filepath):
    full_path = prepend_installroot(context, filepath)
    delete_file(full_path)


@behave.given('I delete file "{filepath}" with globs')
def step_delete_file_with_globs(context, filepath):
    for path in glob.glob(prepend_installroot(context, filepath)):
        delete_file(path)


@behave.given('I delete directory "{dirpath}"')
def step_delete_directory(context, dirpath):
    full_path = prepend_installroot(context, dirpath)
    delete_directory(full_path)


@behave.step('file "{filepath}" exists')
def file_exists(context, filepath):
    full_path = prepend_installroot(context, filepath)
    ensure_file_exists(full_path)


@behave.step('file "{filepath}" does not exist')
def file_does_not_exist(context, filepath):
    full_path = prepend_installroot(context, filepath)
    ensure_file_does_not_exist(full_path)


@behave.step('file "{filepath}" contains lines')
def file_contains(context, filepath):
    regexp_lines = context.text.split('\n')
    full_path = prepend_installroot(context, filepath)
    ensure_directory_exists(os.path.dirname(full_path))
    read_str = read_file_contents(full_path)
    for line in regexp_lines:
        if not re.search(line, read_str):
            print("line: " + line + " not found")
            raise AssertionError("File %s contains: \n%s" % (filepath, read_str))
    return


@behave.step('file "{filepath}" does not contain lines')
def file_does_not_contain(context, filepath):
    regexp_lines = context.text.split('\n')
    full_path = os.path.join(context.dnf.installroot, filepath.lstrip("/"))
    ensure_directory_exists(os.path.dirname(full_path))
    read_str = read_file_contents(full_path)
    for line in regexp_lines:
        if re.search(line, read_str):
            print("line: " + line + " found")
            raise AssertionError("File %s contains: \n%s" % (filepath, read_str))
    return


@behave.step('I copy directory "{source}" to "{destination}"')
def step_impl(context, source, destination):
    source = source.format(context=context)
    destination = prepend_installroot(context, destination)
    ensure_directory_exists(os.path.dirname(destination))
    copy_tree(source, destination)


@behave.step('I copy file "{source}" to "{destination}"')
def copy_file_to(context, source, destination):
    source = source.format(context=context)
    destination = os.path.join(context.dnf.installroot, destination.lstrip("/"))
    ensure_directory_exists(os.path.dirname(destination))
    copy_file(source, destination)


@behave.step('the files "{first}" and "{second}" do not differ')
def step_impl(context, first, second):
    first = first.format(context=context)
    second = second.format(context=context)
    ensure_file_exists(first)
    ensure_file_exists(second)
    cmd = "diff {} {}".format(first, second)
    exitcode, _, _ = run(cmd, shell=True)
    assert exitcode == 0, 'Files "{}" and "{}" differ.'.format(first, second)


@behave.step('timestamps of the files "{first}" and "{second}" do not differ')
def step_impl(context, first, second):
    first = first.format(context=context)
    second = second.format(context=context)
    ensure_file_exists(first)
    ensure_file_exists(second)
    # strip the fractional part of timestamps as the precision of timestamps
    # in http headers is only in seconds.
    ts_first = int(file_timestamp(first))
    ts_second = int(file_timestamp(second))
    assert ts_first == ts_second, \
        'Timestamps of files "{}": {} and "{}": {} are differt.'.format(
            first, ts_first, second, ts_second)


@behave.step('size of file "{filepath}" is less than "{expected_size}"')
def file_size_less_than(context, filepath, expected_size):
    filepath = os.path.join(context.dnf.installroot, filepath)
    size = os.path.getsize(filepath)
    assert size <= int(expected_size), 'File "{}" has size "{}"'.format(filepath, size)
