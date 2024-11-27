#-*- mode: makefile -*-

PERL_MODULES = \
    lib/Module/ScanDeps/Static.pm \
    lib/Module/ScanDeps/FindRequires.pm

PERL_SCRIPTS = \
    bin/scandeps-static.pl

UNIT_TESTS = \
	t/00-scandeps.t \
	t/01-scandeps.t

VERSION := $(shell perl -I lib -MModule::ScanDeps::Static -e 'print $$Module::ScanDeps::Static::VERSION;')

TARBALL = Module-ScanDeps-Static-$(VERSION).tar.gz

all: README.md $(TARBALL)

$(TARBALL): $(PERL_MODULES) $(PERL_SCRIPTS) requires
	 make-cpan-dist \
	   -e bin \
	   -l lib \
	   -c \
	   -m Module::ScanDeps::Static \
	   -a 'BIGFOOT <bigfoot@cpan.org>' \
	   -d 'scan modules for dependencies' \
	   -D requires \
	   -H . \
	   -T test-requires \
	   -t t/ \
	   -F postamble \
	   -V Module::ScanDeps::Static::VERSION

README.md: $(PERL_MODULES)
	pod2markdown $< > $@ || rm -f $@

.PHONY: check

check: $(PERL_MODULES)
	PERL5LIB=$(builddir)/lib perl -wc $(PERL_MODULES)
	perlcritic -1 $(PERL_MODULES)
	$(MAKE) test

test: $(TESTS)
	prove -v t/

install: $(TARBALL)
	cpanm -v $<

clean:
	rm -f $(TARBALL)
