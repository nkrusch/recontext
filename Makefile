SHELL := /bin/bash

# supress Make output
MAKEFLAGS += --no-print-directory

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
UTILS   := utils

all: dig tacle

dig: $(DIGEXP) $(MACHINE)
tacle: $(TCLEXP) $(MACHINE)

$(OUT)/%.dig: $(IN)/%.csv ensure_out
	python -O dig/src/dig.py -log 0 $< -noss -nomp > $@

$(OUT)/%.tacle: $(IN)/%.csv ensure_out
	@python $(UTILS)/taclef.py $< > temp
	(cd tacle && python -m tacle ../temp -g > ../$@)
	@rm -rf temp

$(MACHINE):
	@bash $(UTILS)/machine.sh > $(MACHINE)

ensure_out:
	@mkdir -p $(OUT)

clean:
	@rm -rf $(OUT)
