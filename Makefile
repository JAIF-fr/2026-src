all: build

GIT_BRANCH:=$(shell git branch | sed -n '/\* /s///p')
build: stack_build
	stack exec website-generator -- $@
rebuild: stack_build
	stack exec website-generator -- $@
watch: stack_build
	stack exec website-generator -- $@
.PHONY: build rebuild watch

stack_build:
	stack build
.PHONY: stack_build

clean:
	rm -rf _site
.PHONY: clean
