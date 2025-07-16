define build_pdf
	xelatex -halt-on-error -output-directory _build $(1).tex
endef


build:
	#$(call build_pdf,01_01_processes)
	$(call build_pdf,01_03_link)

clean:
	rm _build/*

show:
	#evince _build/01_01_processes.pdf &
	evince _build/01_03_link.pdf &
