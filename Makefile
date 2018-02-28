all: poster.pdf

%.pdf : %.tex *.pl images/*.pdf
	pdflatex $<

clean:
	rm -f poster.pdf poster.aux poster.log

.PHONY: clean
