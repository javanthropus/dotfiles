#!/bin/bash

if type vim >&/dev/null; then
	col -b | vim -R -c 'set ft=man nomod nolist' -
else
	less
fi
