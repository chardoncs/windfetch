PREFIX = /usr
MANDIR = $(PREFIX)/share/man

all:
	@echo Run \'make install\' to install Windfetch.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@mkdir -p $(DESTDIR)$(MANDIR)/man1
	@cp -p windfetch $(DESTDIR)$(PREFIX)/bin/windfetch
	@cp -p windfetch.1 $(DESTDIR)$(MANDIR)/man1
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/windfetch

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/windfetch
	@rm -rf $(DESTDIR)$(MANDIR)/man1/windfetch.1*
