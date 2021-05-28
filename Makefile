include MarkdownMakefile

.PHONY: all
all: html style

.PHONY: html
html: $(HTMLS)

.PHONY: style
style:
	make -C style
