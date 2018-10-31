
npm install
grunt

### Setting up external libraries
###

git submodule init
git submodule update

cd ext/jquery
npm run build
cd ../..

cd ext/jquery-validation
npm install
npm install -g grunt
grunt release
cd ../..

cd ext/mermaid
npm install
npm install -g yarn
yarn add mermaid
npm run-script build
cd ../..
