#!/bin/sh

if [ -f /usr/local/bin/rtler ]; then
  echo "Removing rtler command..."
  rm /usr/local/bin/rtler
fi

cd "`git rev-parse --show-toplevel`/.git/hooks/"

echo "Removing rtler pre-commit hook if it exists..."

if [ -f rtler-pre-commit ]; then
	rm rtler-pre-commit
fi

if [ -f pre-commit ]; then
	sed -i '' '/rtler-pre-commit/d' 'pre-commit'
fi
