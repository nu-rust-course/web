CURRENT = 02-mutual-exclusion

TEXS = $(wildcard *.tex)
PDFS = $(TEXS:.tex=.pdf)
ZIPS =

Publish: $(PDFS) $(ZIPS)
	echo index.html > $@
	ls $^ >> $@

%.zip: %
	zip -r $@ $<

%.pdf: %.tex
	cp $< build
	( cd build; xelatex -interaction=nonstopmode $< )
	cp build/$@ .

clean:
	git clean -xf

.PHONY: clean
