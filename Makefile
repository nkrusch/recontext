SHELL := /bin/bash

ifndef $IN  
IN := ./inputs
endif

ifndef $OUT  
OUT := ./results
endif

INPUTS  := $(wildcard $(IN)/*.csv)
DIGEXP  := ${INPUTS:$(IN)/%.csv=$(OUT)/%.dig}
TCLEXP  := ${INPUTS:$(IN)/%.csv=$(OUT)/%.tacle}
MACHINE := $(OUT)/_host.txt
UTILS   := .github

# supress Make output
MAKEFLAGS += --no-print-directory --silent

all: dig tacle

dig: ensure_out $(DIGEXP) $(MACHINE)
tacle: ensure_out $(TCLEXP) $(MACHINE)

$(OUT)/%.dig: $(IN)/%.csv
	python -O dig/src/dig.py -log 0 $< -noss -nomp >> $@

$(OUT)/%.tacle: $(IN)/%.csv
	python $(UTILS)/taclef.py $< > temp
	(cd tacle && python -m tacle ../temp -g >> ../$@)
	rm -rf temp

$(MACHINE):
	@bash $(UTILS)/machine.sh > $(MACHINE)

ensure_out:
	@mkdir -p $(OUT)

clean:
	@rm -rf $(OUT)