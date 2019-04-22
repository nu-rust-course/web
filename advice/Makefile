MD	= $(wildcard *.md)
HTML	= $(MD:%.md=%.html)

default: $(HTML)

%.html: %.md
	pandoc --mathjax --standalone -o $@ $<
