#!/bin/sh

curl -L -s -S https://raw.githubusercontent.com/elleestcrimi/rtler/master/uninstall.sh | sh

ROOT_PATH="`git rev-parse --show-toplevel`/.git/hooks/"

cd $ROOT_PATH

echo "Downloading scripts..."

curl -L -s -S https://raw.githubusercontent.com/elleestcrimi/rtler/master/rtler.pl > rtler.pl
curl -L -s -S https://raw.githubusercontent.com/elleestcrimi/rtler/master/generate_inline_rtl_css > generate_inline_rtl_css
curl -L -s -S https://raw.githubusercontent.com/elleestcrimi/rtler/master/rtler-pre-commit > rtler-pre-commit

if [ ! -f "pre-commit" ]; then
	echo '#!/bin/sh' > pre-commit
fi

echo "Updating pre-commit hook"

string="source `echo $ROOT_PATH`rtler-pre-commit && `echo $ROOT_PATH`rtler-pre-commit"

echo $string >> pre-commit 
echo "Fixing permissions..."

chmod 777 pre-commit
chmod 777 rtler-pre-commit
chmod 777 rtler.pl
chmod 777 generate_inline_rtl_css

echo "`tput setaf 2`All done :) Enjoy!"
