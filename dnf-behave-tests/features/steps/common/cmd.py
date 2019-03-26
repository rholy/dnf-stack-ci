# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import print_function

import subprocess


def run(cmd, shell=False, can_fail=True, cwd=None):
    """
    Run a command.
    Return exitcode, stdout, stderr
    """

    proc = subprocess.Popen(
        cmd,
        shell=shell,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
    )

    stdout, stderr = proc.communicate()

    if not can_fail and proc.returncode != 0:
        raise RuntimeError("Running command failed: %s" % cmd)

    return proc.returncode, stdout, stderr
