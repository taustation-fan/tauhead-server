mkdir tmp
chgrp apache tmp
chmod g+w tmp

semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/vhosts/test.tauhead.com/perl(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/vhosts/test.tauhead.com/tmp(/.*)?'
semanage fcontext -a -t httpd_sys_script_exec_t '/var/www/vhosts/test.tauhead.com/script/tauhead_fastcgi.pl'
restorecon -r perl tmp script/tauhead_fastcgi.pl

#

git submodule init
git submodule update

npm install
./node_modules/grunt/bin/grunt

cd ext/jquery
npm run build

cd ../jquery-validation
npm install
../../node_modules/grunt/bin/grunt release

cd ../mermaid
npm install
../../node_modules/yarn/bin/yarn add mermaid
npm run-script build

cd ../..
