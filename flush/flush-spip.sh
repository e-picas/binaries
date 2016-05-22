#!/bin/bash

echo "> flushing cache in '`pwd`/tmp/cache/*' ..."
rm -rf "`pwd`/tmp/cache/*"

echo "> flushing cache in '`pwd`/local/*' ..."
rm -rf "`pwd`/local/*"

echo "_ ok"

# Endfile
