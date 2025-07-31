SHELL := /bin/bash

# supress Make output
MAKEFLAGS += --no-print-directory

ifndef $IN  
IN := ./traces
endif

ifndef $OUT  
OUT := ./results
endif

ifndef $TO # seconds
TO := 60
endif

ifndef $LOG
LOG := $(OUT)/_log.txt
endif

UTILS   := utils
INPUTS  := $(wildcard $(IN)/*.csv)
DIGEXP  := ${INPUTS:$(IN)/%.csv=$(OUT)/%.dig}
TCLEXP  := ${INPUTS:$(IN)/%.csv=$(OUT)/%.tacle}
MACHINE := $(OUT)/_host.txt
RUNNER  := bash $(UTILS)/runner.sh $(TO) "$(LOG)"

all: dig tacle
dig: $(DIGEXP) $(MACHINE)
tacle: $(TCLEXP) $(MACHINE)

$(OUT)/%.dig: $(IN)/%.csv ensure_out
	$(RUNNER) "python -O dig/src/dig.py -log 0 $< -noss -nomp -nocongruences > $@"

$(OUT)/%.tacle: $(IN)/%.csv ensure_out
	@python $(UTILS)/taclef.py $< > temp
	$(RUNNER) "cd tacle && python -m tacle ../temp -g > ../$@"
	@rm -rf temp

$(MACHINE):
	@bash $(UTILS)/machine.sh > $(MACHINE)

ensure_out:
	@mkdir -p $(OUT)

clean:
	@rm -rf $(OUT)
