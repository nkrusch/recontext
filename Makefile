SHELL := /bin/bash

# supress Make output
MAKEFLAGS += --no-print-directory

# options
ifndef $PYTHON
PYTHON := python3
endif

ifndef $OUT  
OUT := results
endif

ifndef $TMP
TMP := .tmp
endif

ifndef $TO # seconds
TO := 90
endif

ifndef $DOPT # DIG options
DOPT :=
endif

ifndef $SZ # sizes for timing
SZ := 25 50 75 100
endif

# paths
UTILS    := scripts
IN_CSV	 := input/csv
IN_TRC	 := input/traces
ARGS_F   := config.txt
LOG 	 := $(OUT)/_log.txt
MACHINE  := $(OUT)/_host.txt
STATS    := $(OUT)/_inputs.txt
SCORE    := $(OUT)/_results.txt
RUNNER   := bash $(UTILS)/runner.sh $(TO) "$(LOG)"
TIMER    := bash $(UTILS)/timer.sh "$(LOG)"

# problems
T_SET    := f_xy f_2x3y f_logxy
INPUTS   := $(wildcard $(IN_TRC)/*.csv)
D_PROBS  := $(wildcard $(IN_TRC)/ds_*.csv)
DIG_ALL  := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_UPS  := ${D_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.digup}
T_PROBS  := ${T_SET:%=$(OUT)/%.time}

#=======================
# main recipes
#=======================
all:     stats host dig digup times score
stats:   $(STATS)
host:    $(MACHINE)
dig:     $(DIG_ALL)
digup:   $(DIG_UPS)
times:   $(T_PROBS) clean_tmp
score:   $(SCORE)

# scoped input series
MATH_F   := xy xxy xxxy 2x₊y 2xy 3xy 2x3y axby axbycz m2x0 m8x0 m2xa mbxa mbxya logxy sinxy
LINEAR   := 001 003 007 009 015 023 024 025 028 035 038 040 050 063 065 067 071 077 083 087 091 093 094 095 097 099 101 107 108 109 110 114 120 124 128 130 132 133

CHECKS   := $(patsubst %.dig,%.check,$(wildcard $(OUT)/*.dig))
DIG_MTH  := $(patsubst $(IN_TRC)/%.csv,$(OUT)/%.dig,$(wildcard $(IN_TRC)/f_*.csv))
DIG_LIN  := $(patsubst $(IN_TRC)/%.csv,$(OUT)/%.dig,$(wildcard $(IN_TRC)/l_*.csv))
DIG_DSS  := $(patsubst $(IN_TRC)/%.csv,$(OUT)/%.dig,$(D_PROBS))
COMP     := $(wildcard $(OUT)/*.digup)
GEN_F    := ${MATH_F:%=gen/f_%}
GEN_L    := ${LINEAR:%=gen/l_%}

# debugging + generators
math:    $(DIG_MTH) score
linear:  $(DIG_LIN) score
sets:    $(DIG_DSS) digup score
compare: $(COMP)
check:   $(CHECKS)
trc_f:   $(GEN_F)
trc_l:   $(GEN_L)

$(IN_CSV)/%.csv: $(IN_TRC)/%.csv $(IN_CSV)
	@$(PYTHON) -m $(UTILS) -a csv $< > $@

$(OUT)/%.dig: $(IN_TRC)/%.csv $(OUT)
	$(eval ARGS := $(shell grep $(basename $(notdir $@)) $(ARGS_F) | head -n 1 | cut -d' ' -f 2-))
	$(RUNNER) "$(PYTHON) -O dig/src/dig.py $< -log 0 -noss -nomp -noarrays $(DOPT)$(ARGS) > $@"

$(OUT)/%.digup: $(IN_TRC)/%.csv $(OUT)
	$(eval proc_to=$(shell echo $$(($(TO)-1))))
	export TO=$(proc_to) && $(RUNNER) "$(PYTHON) -m digup $< -log 0 -noss -nomp -noarrays $(DOPT) > $@"
	@$(PYTHON) -m digup $@

$(OUT)/%.tacle: $(IN_CSV)/%.csv $(OUT)
	$(RUNNER) "cd tacle && $(PYTHON) -m tacle ../$< -g > ../$@"

$(TMP)/%.csv: $(TMP)
	$(eval CSV := $(subst $(TMP),$(IN_CSV),$@))
	$(eval TRC := $(subst $(TMP),$(IN_TRC),$@))
	@make --silent $(CSV)
	@$(foreach N,$(SZ),\
		head -n $$(($(N)+1)) $(CSV) > $(subst .csv,.$(N).csv,$@) ; \
		head -n $$(($(N)+1)) $(TRC) > $(subst .csv,.$(N).trc,$@) ;)

$(OUT)/%.time: $(TMP)/%.csv $(OUT)
	$(eval ARGS := $(shell grep $(basename $(notdir $@)) $(ARGS_F) | head -n 1 | cut -d' ' -f 2-))
	$(eval f := $(subst .csv,,$(subst $(TMP)/,,$<)))
	@$(foreach N,$(SZ), \
	   echo "Processing $(f) and size=$(N) [of $(SZ)]…" ; \
	   $(TIMER) "Tacle" $(N) "(cd tacle && $(PYTHON) -m tacle ../$(TMP)/$(f).$(N).csv -g)" >> $@ ; \
	   $(TIMER) "Dig"   $(N) "$(PYTHON) -O dig/src/dig.py $(TMP)/$(f).$(N).trc -log 0 -noss -nomp -noarrays $(DOPT)$(ARGS)" >> $@ ; )

gen/%:
	$(eval fname := $(subst gen/,,$@))
	$(PYTHON) -m $(UTILS) -a gen $(fname) > $(IN_TRC)/$(fname).csv

$(OUT)/%.check:
	export T_DTYPE=d && $(PYTHON) -m $(UTILS) -a check $(subst .check,.dig,$@) > $@

$(COMP):
	@$(PYTHON) -m $(UTILS) -a match $@

$(MACHINE): $(OUT)
	@bash $(UTILS)/machine.sh > $@

$(STATS): $(OUT)
	@$(PYTHON) -m $(UTILS) -a stats $(IN_TRC) > $@

$(SCORE): $(OUT)
	$(PYTHON) -m $(UTILS) -a score $(OUT) > $@

$(OUT) $(IN_CSV) $(TMP):
	@mkdir -p $@

clean_tmp:
	@-rm -rf $(TMP)

clean:
	@rm -rf $(OUT)/*
	@-rm -rf $(OUT)


.PHONY: $(SCORE) $(STATS) $(MACHINE) $(COMP)

#=======================
# Build an archive
#=======================

ARC       := sources
ARC_NO    := $(ARC) .* __*__ results venv rdoc *.zip
ACT_RM   := __MACOSX/* *.pyo *.pyc __pycache__ *.DS_Store
ARC_FLTR  := $(patsubst %,! -name '%',$(ARC_NO))
ARC_ITEMS := $(patsubst ./%,%,$(shell find . -mindepth 1 -maxdepth 1 $(ARC_FLTR))) .dockerignore

%.zip:
	@mkdir -p $(ARC)
	@$(foreach x, $(ARC_ITEMS), cp -R $(x) $(ARC) ;)
	@-rm -rf $(ARC)/$(IN_CSV) && make $(ACT_RM)
	@zip -r $@ $(ARC)
	@rm -rf $(ARC)

$(ACT_RM):
	@find $(ARC) -name $@ -exec rm -rf {} +
