#!/bin/sh

ROOT_PATH="`git rev-parse --show-toplevel`/.git/hooks/"
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Symlinking rtler script..." 
ln -sF "$CURRENT_PATH"/rtler /usr/local/bin/rtler

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Not inside of any git repo, cannot proceed.\n";
  exit;
fi

echo "Symlinking scripts..."
ln -sF "$CURRENT_PATH"/rtler-pre-commit $ROOT_PATH

cd $ROOT_PATH

if [ ! -f "pre-commit" ]; then
  echo "Creating new pre-commit hook..."
	echo '#!/bin/sh' > pre-commit
elif ! grep -q 'rtler-pre-commit' 'pre-commit'; then
  echo "Updating pre-commit hook"
  string="`echo $ROOT_PATH`rtler-pre-commit"
  echo $string >> pre-commit 
fi

chmod 777 rtler-pre-commit
chmod 777 pre-commit

echo "`tput setaf 2`All done :) Enjoy!";
