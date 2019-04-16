CURRENT = 05-ownership

TEXS = $(wildcard *.tex)
PDFS = $(TEXS:.tex=.pdf)
ZIPS =

Publish: $(PDFS) $(ZIPS)
	echo index.html > $@
	ls $^ >> $@

hard: $(CURRENT).pdf

%.zip: %
	zip -r $@ $<

%.pdf: %.tex
	cp $< build
	( cd build; xelatex -interaction=nonstopmode $< )
	cp build/$@ .

clean:
	git clean -xf

.PHONY: clean
