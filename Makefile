PREFIX=${HOME}/galyleo
DESTDIR=

INSTDIR=$(DESTDIR)$(PREFIX)
INSTLIB=$(INSTDIR)/lib

all:
	@echo do nothing. try one of the targets:
	@echo "  install"
	@echo "  uninstall"

install:
	test -d $(INSTDIR) || mkdir -p $(INSTDIR)
	test -d $(INSTLIB) || mkdir -p $(INSTLIB)
	install -m 0755 -D lib/* $(INSTLIB)
	install -m 0755 galyleo $(INSTDIR)
	@echo Run galyleo --configure after install

uninstall:
	rm -rf $(INSTDIR)

.PHONY: all install uninstall
