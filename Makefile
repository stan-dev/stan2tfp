all:
	dune build src/stan2tfp/stan2tfp.exe

.PHONY: test
test:
	dune runtest

format:
	dune build @fmt

clean:
	dune clean
