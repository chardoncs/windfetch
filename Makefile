PREFIX = /usr
MANDIR = $(PREFIX)/share/man
SRCDIR = src
TARGET = windfetch

all:
	@echo Run \'make install\' to install Windfetch.

build:
	@printf "Merging source files... "
	@paste -s $(SRCDIR)/*-*.bash $(TARGET)
	@printf "done\n"

	@printf "Add execution permission... "
	@chmod +x $(TARGET)
	@printf "done\n"

install: build
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@mkdir -p $(DESTDIR)$(MANDIR)/man1
	@cp -p $(TARGET) $(DESTDIR)$(PREFIX)/bin/$(TARGET)
	@cp -p $(TARGET).1 $(DESTDIR)$(MANDIR)/man1
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/$(TARGET)

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/$(TARGET)
	@rm -rf $(DESTDIR)$(MANDIR)/man1/$(TARGET).1*
