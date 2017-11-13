
default: dist

dist: clean
	fatpack trace installer.pl
	fatpack packlists-for `cat fatpacker.trace` > packlists
	fatpack tree `cat packlists`
	fatpack file installer.pl > installer.dist.pl
	chmod +x installer.dist.pl
	cp installer.dist.pl ../installer.pl

clean:
	rm -rf fatlib fatpacker.trace packlists installer.dist.pl
