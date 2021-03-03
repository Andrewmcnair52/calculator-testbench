#########################################################################

## Purpose: Makefile for Chap_1_Verification_Guidelines/homework_solution

## Author: Chris Spear

##

## REVISION HISTORY:

## $Log: Makefile,v $
## Revision 1.1  2011/05/28 14:57:35  tumbush.tumbush
## Check into cloud repository
##
## Revision 1.2  2011/05/03 22:06:50  Greg
## Updated to common Makefile and to use Makefile_non_DPI
##

#########################################################################



FILES = alu_input_stage.v  alu_output_stage.v  calc1_top.v  exdbin_mac.v  holdreg.v  mux_out.v  priority.v  shifter.v

TOPLEVEL = calculator_tb.sv



include ../Makefiles/non_DPI/Makefile_non_DPI
