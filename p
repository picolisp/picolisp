#!/bin/bash
# 23nov02abu
# (c) Software Lab. Alexander Burger

export LD_LIBRARY_PATH=.
exec ${0%/*}/bin/pico ${0%/*}/lib.l @ext.l "$@"
