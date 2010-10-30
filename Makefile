# Interface between Emacs Lisp and Python - Makefile.
# Copyright © 2001, 2002, 2003 Progiciels Bourbeau-Pinard inc.
# François Pinard <pinard@iro.umontreal.ca>, 2001.

emacs = emacs
python = python

PYSETUP = python=$(python) $(python) setup.py
RST2LATEX = rst2latex

all:
	$(PYSETUP) build

check: clean-debug
	$(PYSETUP) clean
	touch .stamp
	cd tests && \
	  emacs="$(emacs)" python="$(python)" \
	  PYMACS_OPTIONS="-d debug-protocol -s debug-signals" \
	  $(python) pytest -f t $(TEST)

install:
	$(PYSETUP) install

clean: clean-setup clean-debug
	rm -rf build* contrib/rebox/build
	rm -f */*py.class */*.pyc pymacs.pdf

clean-debug:
	rm -f tests/debug-protocol tests/debug-signals

clean-setup:
	rm -f .stamp Pymacs/__init__.py pymacs.el pymacs.rst
	cd contrib/Giorgi && rm -f setup.py Pymacs/__init__.py
	cd contrib/rebox && rm -f setup.py Pymacs/__init__.py

pymacs.pdf: pymacs.rst.in
	$(PYSETUP) clean
	touch .stamp
	rm -rf tmp-pdf
	mkdir tmp-pdf
	$(RST2LATEX) --use-latex-toc --input-encoding=UTF-8 \
	  pymacs.rst tmp-pdf/pymacs.tex
	cd tmp-pdf && pdflatex pymacs.tex
	cd tmp-pdf && pdflatex pymacs.tex
	mv -f tmp-pdf/pymacs.pdf $@
	rm -rf tmp-pdf

# (Note: python setup.py clean is the most no-op setup.py I could find.)
pymacs.el pymacs.rst Pymacs/__init__.py: .stamp
.stamp: pymacs.el.in pymacs.rst.in __init__.py.in
	$(PYSETUP) clean
	touch .stamp

# The following goals for the maintainer of the Pymacs Web site.

push: local
	find -name '*~' | xargs rm -fv
	push alcyon -d entretien/pymacs
	ssh alcyon 'make-web -C entretien/pymacs/web'

local: pymacs.pdf pymacs.rst
	make-web -C web

VERSION = `grep '^version' setup.py | sed -e "s/'$$//" -e "s/.*'//"`

publish:
	version=$(VERSION) && \
	  git archive --format=tar --prefix=Pymacs-$$version/ HEAD . \
	    | gzip > web/archives/Pymacs-$$version.tar.gz

official: publish
	rm -f web/archives/Pymacs.tar.gz
	version=$(VERSION) && \
	  ln -s Pymacs-$$version.tar.gz web/archives/Pymacs.tar.gz
