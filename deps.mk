# ./Module-ScanDeps-Static-1.9.1/bin/scandeps-static.pl.in
./Module-ScanDeps-Static-1.9.1/bin/scandeps-static.pl.in: \
    ./lib/Module/ScanDeps/Static.pm

# ./bin/scandeps-static.pl.in
./bin/scandeps-static.pl.in: \
    ./lib/Module/ScanDeps/Static.pm

# ./lib/Module/ScanDeps/FindRequires.pm.in
./lib/Module/ScanDeps/FindRequires.pm: \
    ./lib/Module/ScanDeps/Static.pm

