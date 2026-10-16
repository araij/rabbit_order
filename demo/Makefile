CXXFLAGS += -Wall -Wextra -Wcast-align -Wcast-qual -Wconversion -Wfloat-equal \
	    -Wformat=2 -Winit-self -Wmissing-declarations \
	    -Wmissing-include-dirs -Wpointer-arith -Wredundant-decls \
	    -Wswitch-default -Wuninitialized -Wwrite-strings \
	    -Wno-sign-conversion -Wno-unused-function \
            -Wno-missing-declarations \
            -fopenmp -std=c++17 -mcx16 -O3 -DNDEBUG
LDLIBS   += -ltcmalloc_minimal -lnuma
TARGETS   = reorder
FORMAT ?= clang-format

.PHONY: all
all: $(TARGETS)

$(TARGETS): %: %.cc
	$(LINK.cc) -MD -o $@ $< $(LDLIBS)
	@cp $*.d .$*.P; \
	  sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	      -e '/^$$/ d' -e 's/$$/ :/' < $*.d >> .$*.P; \
	  rm -f $*.d

.PHONY: format
format:
	$(FORMAT) -i ../rabbit_order.hpp *.cc *.hpp

.PHONY: clean
clean:
	$(RM) $(TARGETS) $(TARGETS:%=.%.P)

-include .*.P

