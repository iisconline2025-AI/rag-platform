# Minimal makefile for Sphinx documentation

SPHINXOPTS    ?= -W --keep-going
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = .
BUILDDIR      = _build

.PHONY: help html clean livehtml

help:
	@echo "  html      — build HTML docs in _build/html/"
	@echo "  clean     — remove _build/"
	@echo "  livehtml  — live-reload server (requires sphinx-autobuild)"

html:
	$(SPHINXBUILD) -b html $(SOURCEDIR) $(BUILDDIR)/html $(SPHINXOPTS)
	@echo ""
	@echo "Build finished. Open $(BUILDDIR)/html/index.html in your browser."

clean:
	rm -rf $(BUILDDIR)

livehtml:
	sphinx-autobuild $(SOURCEDIR) $(BUILDDIR)/html $(SPHINXOPTS) --port 8080
