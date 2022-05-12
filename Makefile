
PERL_MODULES = \
    lib/Module/ScanDeps/Static.pm

PERL_SCRIPTS = \
    bin/scandeps-static.pl

Module-ScanDeps-Static.tar.gz: $(PERL_MODULES) $(PERL_SCRIPTS)
	 make-cpan-dist \
	   -e bin \
	   -l lib \
	   -m Module::ScanDeps::Static \
	   -a 'Rob Lauer <rlauer6@comcast.net>' \
	   -d 'scan modules for dependencies' \
	   -r requires
	cp $$(ls -1rt *.tar.gz | tail -1) $@

clean:
	rm -f *.tar.gz
