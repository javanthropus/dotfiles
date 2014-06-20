#!/bin/bash

if type gvim >&/dev/null; then
	col -b | gvim -R -c 'set ft=man nomod nolist' - 2>/dev/null
elif type vim >&/dev/null; then
	col -b | vim -R -c 'set ft=man nomod nolist' -
else
	less
fi
