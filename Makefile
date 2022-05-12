
PERL_MODULES = \
    lib/Module/ScanDeps/Static.pm

PERL_SCRIPTS = \
    bin/scandeps-static.pl

all: README.md Module-ScanDeps-Static.tar.gz

Module-ScanDeps-Static.tar.gz: $(PERL_MODULES) $(PERL_SCRIPTS)
	 make-cpan-dist \
	   -e bin \
	   -l lib \
	   -m Module::ScanDeps::Static \
	   -a 'Rob Lauer <rlauer6@comcast.net>' \
	   -d 'scan modules for dependencies' \
	   -r requires \
	   -t t/
	cp $$(ls -1rt *.tar.gz | tail -1) $@

README.md: $(PERL_MODULES)
	pod2markdown $< > $@ || rm -f $@


clean:
	rm -f *.tar.gz
	rm -f README.md
