#!/bin/sh

cd "`git rev-parse --show-toplevel`/.git/hooks/"

echo "Removing rtler pre-commit hook if it exists..."

if [ -f make_rtl.pl ]; then
	rm make_rtl.pl
fi

if [ -f rtler.pl ]; then
	rm rtler.pl
fi

if [ -f generate_inline_rtl_css ]; then
	rm generate_inline_rtl_css
fi

if [ -f rtler-pre-commit ]; then
	rm rtler-pre-commit
fi

if [ -f pre-commit ]; then
	sed -i '' '/rtler-pre-commit/d' 'pre-commit'
fi
