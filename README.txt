npm install
./node_modules/grunt/bin/grunt

### Setting up external libraries
###

git submodule init
git submodule update

cd ext/jquery
npm run build
cd ../..

cd ext/jquery-validation
npm install
../../node_modules/grunt/bin/grunt release
cd ../..

cd ext/mermaid
npm install
../../node_modules/yarn/bin/yarn add mermaid
npm run-script build
cd ../..

