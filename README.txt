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
