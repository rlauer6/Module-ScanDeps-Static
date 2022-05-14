
PERL_MODULES = \
    lib/Module/ScanDeps/Static.pm

PERL_SCRIPTS = \
    bin/scandeps-static.pl

UNIT_TESTS = \
	t/00-scandeps.t \
	t/01-scandeps.t

TARBALL = Module-ScanDeps-Static.tar.gz

all: README.md $(TARBALL)

$(TARBALL): $(PERL_MODULES) $(PERL_SCRIPTS) requires
	 make-cpan-dist \
	   -e bin \
	   -l lib \
	   -m Module::ScanDeps::Static \
	   -a 'BIGFOOT <bigfoot@cpan.org>' \
	   -d 'scan modules for dependencies' \
	   -c \
	   -r requires \
	   -t t/
	cp $$(ls -1rt *.tar.gz | tail -1) $@

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
