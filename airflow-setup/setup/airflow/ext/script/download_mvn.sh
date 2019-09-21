#!/usr/bin/env bash
## download mvn and update maven home
wk_dir=$(pwd)

wget ftp://mirror.reverse.net/pub/apache/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz
tar -xzf apache-maven-3.5.3-bin.tar.gz
rm apache-maven-3.5.3-bin.tar.gz

mvn_home=$(ls -d apache-mave*)
echo ""  >> setup_env.sh
echo "export M2_HOME=\"$wk_dir/$mvn_home\"" >> setup_env.sh
echo "export PATH=\"\$M2_HOME/bin\":\$PATH" >> setup_env.sh
