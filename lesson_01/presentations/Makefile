define build_pdf
	xelatex -halt-on-error -output-directory _build $(1).tex
	mv _build/$(1).pdf .
endef


build:
	#(call build_pdf,02_01_history)
	$(call build_pdf,01_01_processes)

clean:
	rm _build/*

show:
	# evince 02_01_history.pdf &
	evince 01_01_processes.pdf &
