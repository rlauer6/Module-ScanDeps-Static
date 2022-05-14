# README-BUILD.md

# You can install this module from CPAN

```
cpanm -v Module::ScanDeps::Static

scandeps-pl $(which scandeps-pl)
```

In the event the latest version has not yet been pushed to CPAN you
can clone this repository, build the distribution tarball and
install locally as described below.

# Building the Distribution Tarball

To build the distribution tarball you'll need...

* `make`
* `make-cpan-dist`

You can get `make-cpan-dist` from here:

https://github.com/rlauer6/make-cpan-dist

That comes with it's own requirements for `autotools`, `automake`,
etc. :-(

Assuming you've successfully installed `make-cpan-dist`:

```
make clean && make
cpanm -v Module-ScanDeps-Static.tar.gz
```





