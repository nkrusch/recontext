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

UTILS   := src
VENV	:= .venv
IN_CSV	:= $(IN)/csv
IN_TRC	:= $(IN)/traces
INPUTS  := $(wildcard $(IN_TRC)/*.csv)
DIGEXP  := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
TCLEXP  := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.tacle}
CSV_IN  := ${INPUTS:$(IN_TRC)/%.csv=$(IN_CSV)/%.csv}
CHECKS  := $(patsubst %.dig,%.check,$(wildcard $(OUT)/*.dig))
RUNNER  := bash $(UTILS)/runner.sh $(TO) "$(LOG)"
MACHINE := $(OUT)/_host.txt

all: dig tacle
dig:  ensure_out $(VENV) $(DIGEXP) $(MACHINE)
tacle: ensure_out csv $(VENV) $(TCLEXP) $(MACHINE)
csv: ensure_csv $(VENV) $(CSV_IN)
check: ensure_out $(CHECKS)

$(IN_CSV)/%.csv: $(IN_TRC)/%.csv
	python3 -m $(UTILS) -a csv $< > $@

$(OUT)/%.dig: $(IN_TRC)/%.csv
	$(RUNNER) "python3 -O dig/src/dig.py -log 0 $< -noss -nomp -nocongruences > $@"

$(OUT)/%.tacle: $(IN_CSV)/%.csv
	$(RUNNER) "cd tacle && python3 -m tacle ../$< -g > ../$@"

$(MACHINE):
	@bash $(UTILS)/machine.sh > $@

$(VENV):
	@test -d .venv || python3 -m venv .venv;
	@source .venv/bin/activate;
	@pip3 install -q -r requirements.txt

$(OUT)/%.check: $(OUT)/%.dig
	@python -m $(UTILS) -a check $< > $@

ensure_out:
	@mkdir -p $(OUT)

ensure_csv:
	@mkdir -p $(IN_CSV)

clean:
	@rm -rf $(OUT)
