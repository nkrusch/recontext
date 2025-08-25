SHELL := /bin/bash

# supress Make output
MAKEFLAGS += --no-print-directory


ifndef $OUT  
OUT := ./results
endif

ifndef $TO # seconds
TO := 60
endif

ifndef $DOPT # DIG options
DOPT :=
endif

ifndef $LOG
LOG := $(OUT)/_log.txt
endif

ifndef $PYTHON
PYTHON := python3
endif


MATH_F := xy xxy xxxy 2xy+ 2xy 3xy 2x3y axby axbycz xm20 xm80 xm2a xmba xymba
LINEAR := 001 003 007 009 015 023 024 025 028 035 038 040 045 050 063 065 067 071 077 083 \
		  087 091 093 094 095 097 099 101 103 107 108 109 110 114 120 124 128 130 132 133

# paths
UTILS   := src
IN_CSV	:= ./input/csv
IN_TRC	:= ./input/traces
RUNNER  := bash $(UTILS)/runner.sh $(TO) "$(LOG)"
MACHINE := $(OUT)/_host.txt
STATS   := $(OUT)/_inputs.txt
SCORE   := $(OUT)/_results.txt

# problems
INPUTS  := $(wildcard $(IN_TRC)/*.csv)
DIG_EXP := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
TCL_EXP := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.tacle}

M_PROBS := $(wildcard $(IN_TRC)/f_*.csv)
L_PROBS := $(wildcard $(IN_TRC)/l_*.csv)
D_PROBS := $(wildcard $(IN_TRC)/ds_*.csv)
DIG_MTH := ${M_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_LIN := ${L_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_DSS := ${D_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}

# generators
CHECKS  := $(patsubst %.dig,%.check,$(wildcard $(OUT)/*.dig))
CSV_IN  := ${INPUTS:$(IN_TRC)/%.csv=$(IN_CSV)/%.csv}
GEN_F   := ${MATH_F:%=gen/f_%}
GEN_L   := ${LINEAR:%=gen/l_%}

# main recipes
all:   csv stats host dig tacle score
dig:   $(DIG_EXP)
tacle: $(TCL_EXP)
stats: $(STATS)
score: $(SCORE)
host:  $(MACHINE)
csv:   $(CSV_IN)

# debugging
dig_f: $(DIG_MTH)
dig_l: $(DIG_LIN)
math: dig_f score
linr: dig_l score
check: $(CHECKS)

# trace generators
trc_f: $(GEN_F)
trc_l: $(GEN_L)


$(IN_CSV)/%.csv: $(IN_TRC)/%.csv ensure_csv
	$(PYTHON) -m $(UTILS) -a csv $< > $@

$(OUT)/%.dig: $(IN_TRC)/%.csv ensure_out
	$(RUNNER) "python3 -O dig/src/dig.py -log 0 $< -noss -nomp -noarrays $(DOPT) > $@"

$(OUT)/%.tacle: $(IN_CSV)/%.csv ensure_out
	$(RUNNER) "cd tacle && python3 -m tacle ../$< -g > ../$@"

$(OUT)/%.check:
	$(PYTHON) -m $(UTILS) -a check $(subst .check,.dig,$@) > $@

gen/%:
	$(eval fname := $(subst gen/,,$@))
	$(PYTHON) -m $(UTILS) -a gen $(fname) > $(IN_TRC)/$(fname).csv

$(MACHINE):
	@bash $(UTILS)/machine.sh > $@

$(STATS):
	@$(PYTHON) -m $(UTILS) -a stats $(IN_TRC) > $@

$(SCORE):
	$(PYTHON) -m $(UTILS) -a score $(OUT) > $@

ensure_out:
	@mkdir -p $(OUT)

ensure_csv:
	@mkdir -p $(IN_CSV)

clean_check:
	@rm -rf $(OUT)/*.check

clean:
	@rm -rf $(OUT)

.PHONY: $(SCORE) $(STATS) $(MACHINE)


#VENV	:= .venv
#$(VENV):
#	@test -d .venv || python3 -m venv .venv;
#	@source .venv/bin/activate;
#	@pip3 install -q -r requirements.txt