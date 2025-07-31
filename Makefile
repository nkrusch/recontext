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
IN_CSV	:= $(IN)/csv
INPUTS  := $(wildcard $(IN)/*.csv)
DIGEXP  := ${INPUTS:$(IN)/%.csv=$(OUT)/%.dig}
TCLEXP  := ${INPUTS:$(IN)/%.csv=$(OUT)/%.tacle}
CSV_IN  := ${INPUTS:$(IN)/%.csv=$(IN_CSV)/%.csv}
MACHINE := $(OUT)/_host.txt
RUNNER  := bash $(UTILS)/runner.sh $(TO) "$(LOG)"

all: dig tacle
dig: pyenv $(DIGEXP) $(MACHINE)
tacle: pyenv $(TCLEXP) $(MACHINE)
csv: pyenv ensure_csv $(CSV_IN)

$(IN_CSV)/%.csv: $(IN)/%.csv
	python3 -m utils -a csv $< > $@

$(OUT)/%.dig: $(IN)/%.csv ensure_out
	$(RUNNER) "python3 -O dig/src/dig.py -log 0 $< -noss -nomp -nocongruences -nominmaxplus > $@"
	python3 -m utils -a check $@

$(OUT)/%.tacle: $(IN_CSV)/%.csv ensure_out
	$(RUNNER) "cd tacle && python3 -m tacle ../$< -g > ../$@"

$(MACHINE):
	@bash $(UTILS)/machine.sh > $(MACHINE)

pyenv:
	@test -d .venv || python3 -m venv .venv;
	@source .venv/bin/activate;
	@pip3 install -q -r requirements.txt

ensure_out:
	@mkdir -p $(OUT)

ensure_csv:
	@mkdir -p $(IN_CSV)

clean:
	@rm -rf $(OUT) $(IN_CSV)
