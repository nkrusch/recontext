SHELL := /bin/bash

# supress Make output
MAKEFLAGS += --no-print-directory

ifndef $IN  
IN := ./input
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

TRACES := 001 003 007 009 015 023 024 025 028 035 038 040 045 050 063 065 067 071 077 083 084 085 087 133

UTILS   := src
VENV	:= .venv
IN_CSV	:= $(IN)/csv
IN_TRC	:= $(IN)/traces
INPUTS  := $(wildcard $(IN_TRC)/*.csv)
DIG_EXP := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
TCL_EXP := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.tacle}
CSV_IN  := ${INPUTS:$(IN_TRC)/%.csv=$(IN_CSV)/%.csv}
GEN_TRC := ${TRACES:%=gen/l_%}
CHECKS  := $(patsubst %.dig,%.check,$(wildcard $(OUT)/*.dig))
RUNNER  := bash $(UTILS)/runner.sh $(TO) "$(LOG)"
MACHINE := $(OUT)/_host.txt

all:   csv dig tacle
dig:   $(DIG_EXP) $(MACHINE)
tacle: $(TCL_EXP) $(MACHINE)
csv:   $(CSV_IN)
check: $(CHECKS)
trc:   $(GEN_TRC)

$(IN_CSV)/%.csv: $(IN_TRC)/%.csv ensure_csv
	python3 -m $(UTILS) -a csv $< > $@

$(OUT)/%.dig: $(IN_TRC)/%.csv ensure_out
	$(RUNNER) "python3 -O dig/src/dig.py -log 0 $< -noss -nomp -nocongruences > $@"

$(OUT)/%.tacle: $(IN_CSV)/%.csv ensure_out
	$(RUNNER) "cd tacle && python3 -m tacle ../$< -g > ../$@"

$(OUT)/%.check: $(OUT)/%.dig
	python3 -m $(UTILS) -a check $< > $@

gen/%:
	$(eval fname := $(subst gen/,,$@))
	python3 -m $(UTILS) -a gen $(fname) > $(IN_TRC)/$(fname).csv

$(VENV):
	@test -d .venv || python3 -m venv .venv;
	@source .venv/bin/activate;
	@pip3 install -q -r requirements.txt

$(MACHINE):
	@bash $(UTILS)/machine.sh > $@

ensure_out:
	@mkdir -p $(OUT)

ensure_csv:
	@mkdir -p $(IN_CSV)

clean:
	@rm -rf $(OUT)
