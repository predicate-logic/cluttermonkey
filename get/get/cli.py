#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Command line wrapper
"""

import click
import logging

from get import etl
from get import __version__

logging.basicConfig()
log = logging.getLogger('get')


def set_console_log_level(level):
    """Set log level to increase console verbosity.  Usually for implementing a --verbose flag."""

    # set console logger to a higher logging level
    [h.setLevel(level) for h in log.handlers if type(h) == logging.StreamHandler]
    log.info('Logging level changed to {}.'.format(level))


# shared arguments for all cli commands
class State(object):

    def __init__(self):
        self.verbose = 0
        self.quiet = False


pass_state = click.make_pass_decorator(State, ensure=True)


# Shared CLI option(s)
# Set console/file level log verbosity
def verbose_option(f):
    def callback(ctx, param, value):
        state = ctx.ensure_object(State)
        state.verbose = value

        # turn on verbose console logging?
        if state.verbose == 1:
            set_console_log_level(logging.INFO)
            log.warn("Verbose console logging enabled.")
        elif state.verbose == 2:
            set_console_log_level(logging.DEBUG)
            log.warn("Debug console logging enabled.")

        return value

    return click.option('-v', '--verbose', count=True, default=0,
                        expose_value=False, help='Turn on verbose logging.',
                        callback=callback)(f)


# Quiet all output except for errors and output data.
def quiet_option(f):
    def callback(ctx, param, value):
        state = ctx.ensure_object(State)
        state.quiet = value

        if state.quiet:
            set_console_log_level(logging.ERROR)

        return value

    return click.option('-q', '--quiet', is_flag=True,
                        expose_value=False,
                        help='Only show errors or output data to terminal.',
                        callback=callback)(f)


def common_options(f):
    f = verbose_option(f)
    f = quiet_option(f)
    return f


@click.group()
@click.version_option(version=__version__)
def cli():
    pass


@cli.command("stream")
@common_options
@pass_state
@click.option("--event-type", type=click.STRING, help="Filter event types.  Defaults to 'message' type.", default="message")
@click.option("--frac", type=click.FLOAT, help="Sample data fraction.  Defaults to 1.0", default=1.0)
def stream(state, event_type, frac):
    """Retrieve stream of events.
    """

    if frac != 1.0:
        print("Sampling data: {}".format(frac))

    etl.process_stream(event_type, frac)


if '__main__' == __name__:
    cli()
