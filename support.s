

/*****************************************************************************

Copyright © 1994, Digital Equipment Corporation, Maynard, Massachusetts. 

                        All Rights Reserved

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose and without fee is hereby granted, provided  
that the copyright notice and this permission notice appear in all copies  
of software and supporting documentation, and that the name of Digital not  
be used in advertising or publicity pertaining to distribution of the software 
without specific, written prior permission. Digital grants this permission 
provided that you prominently mark, as not part of the original, any 
modifications made to this software or documentation.

Digital Equipment Corporation disclaims all warranties and/or guarantees  
with regard to this software, including all implied warranties of fitness for 
a particular purpose and merchantability, and makes no representations 
regarding the use of, or the results of the use of, the software and 
documentation in terms of correctness, accuracy, reliability, currentness or
otherwise; and you rely on the software, documentation and results solely at 
your own risk. 

******************************************************************************/
/*
 * $Log$
 */

#ifdef _WIN32
#include <kxalpha.h>
#include <ksalpha.h>
#else
#include <alpha/regdef.h>
#include "osf.h"
#define PAL$WRENT_ENTRY PAL_WRENT_ENTRY
#define PAL$RTI_ENTRY   PAL_RTI_ENTRY
#endif

#include "osf.h"
#include "eb.h"

/*
 *  Just in case you (the reader) does not have the Alpha assembler reference manual
 *  handy, there are 32 integer registers and 32 floating point registers.  They are
 *  all 64 bits in size and there is a defined register use for OSF (which uC/OS for
 *  Alpha follows as its written to run against OSF PALcode.
 *
 * 	$0,	v0	expression return values
 *	$1-8,	t0-t7	Temporary registers, not preserved across proceedure calls.
 *	$9-15,	s0-s6	Saved registers, preserved across procedure calls.
 *	$16-21,	a0-a5	Used to pass the first six integer type arguments to a proceedure.
 *	$22-25,	t8-t11	more temporary registers
 *	$26,	ra	Contains the return address, preserved.
 *	$27,	pv,t12	Proceedure value/temporary, not preserved.
 *	$28,	AT	Reserved for assembler, not preserved.
 *	$29,	gp	Global pointer, not preserved.
 *	$30,	sp	Stack pointer, not preserved.
 *	$31	zero	Always has the value 0.
 *
 */
	.text
	.align	2
	.file	2 "support.s"
	.set noat
/*
 *  Set up the event handlers in the tester program.  The only
 *  one that we're really interested in is PC.
 */
	.text
	.align 4
	.globl OSInitEntries
	.ent OSInitEntries
OSInitEntries:
	ldgp gp,0($27)
	.frame sp,0,ra
	/* This doesn't corrupt anything that is defined to be preserved across procedure calls */
	/* so no stack frame is needed */

	/* Set up interrupt call back */
	lda a0,OSInterrupt
	lda a1,0($31)
	call_pal PAL$WRENT_ENTRY

/*
	lda a0,OSTrap
	lda a1,1($31)
	call_pal PAL$WRENT_ENTRY
	lda a0,OSTrap
	lda a1,2($31)
	call_pal PAL$WRENT_ENTRY
	lda a0,OSTrap
	lda a1,3($31)
	call_pal PAL$WRENT_ENTRY
	lda a0,OSTrap
	lda a1,4($31)
	call_pal PAL$WRENT_ENTRY
	lda a0,OSTrap
	lda a1,5($31)
	call_pal PAL$WRENT_ENTRY
*/
	ret $31,(ra)
	.end OSInitEntries


	.data
	.globl trap_counter
trap_counter:
	.quad 0

	.globl OSTCBCur
	.globl OSTCBHighRdy

	.text
	.align 4
	.ent OSTrap
	/* Entry point for unexpected traps */
OSTrap:
	/* create some stack space */
	lda sp, -8(sp)
	.frame sp,56,ra
	.prologue 0
	/* save the registers that we're going to use. */
	stq a1,0(sp)
	/* increment the count */
	ldq a1, trap_counter
	addl a1, 1, a1
	stq a1, trap_counter
	/* pop the saved stuff off of the stack */
	ldq a1, 0(sp)
	lda sp, 8(sp)
	/* And end the interrupt */
	call_pal PAL$RTI_ENTRY	
	.end OSTrap	

/*
 *  Interrupt handling code.   At the point where this code is called,
 *  the PALcode has seen and handled the interrupt and put the following
 *  information on the stack:
 *
 *	Value	Offset
 *	PS	0
 *	pc	8
 *	gp	16
 *	a0	24
 *	a1	32
 *	a2	40
 * 
 *  And passes the following arguments:
 *
 *	a0	Interrupt type
 *	a1	Interrupt vector
 *	a2 	Unpredictable
 *
 */
	.text
	.align 4
	.ent OSInterrupt
	/* Entry point for expected interrupts */
OSInterrupt:
	/* set up the gp */
	br gp,OSInterrupt2
OSInterrupt2:
	ldgp gp,0(gp)

	/* I need space on the stack to save the registers that can be corrupted by called 
	 * functions and have not already been saved by PAL code.  These are a3 to a5, v0, 
	 * t0 to t12, ra, at, f0, f1, and f10 to f30
	 */
	lda sp, -64*8(sp)
	.frame sp,64*8,ra
	.prologue 0	
	
	/* Now save the registers */
	stq v0,0*8(sp)			/* $0	*/
	stq t0,1*8(sp)			/* $1	*/
	stq t1,2*8(sp)			/* $2	*/
	stq t2,3*8(sp)			/* $3	*/
	stq t3,4*8(sp)			/* $4	*/
	stq t4,5*8(sp)			/* $5	*/
	stq t5,6*8(sp)			/* $6	*/
	stq t6,7*8(sp)			/* $7	*/
	stq t7,8*8(sp)			/* $8	*/
	stq a3,19*8(sp)			/* $19	*/
	stq a4,20*8(sp)			/* $20	*/
	stq a5,21*8(sp)			/* $21	*/
	stq t8,22*8(sp)			/* $22	*/
	stq t9,23*8(sp)			/* $23	*/
	stq t10,24*8(sp)		/* $24	*/
	stq t11,25*8(sp)		/* $25	*/
	stq ra,26*8(sp)			/* $26	*/
	stq t12,27*8(sp)		/* $27	*/
	stq AT,28*8(sp)			/* $28	*/

/*
 * Make sure that floating point is enabled in case
 * it was disabled by the user program.
 */
	bis a0, $31, t1
	lda a0, 1(zero)
	call_pal PAL_WRFEN_ENTRY
	bis t1, $31, a0

	stt $f0,32*8(sp)
	stt $f1,33*8(sp)
	stt $f10,34*8(sp)
	stt $f11,35*8(sp)
	stt $f12,36*8(sp)
	stt $f13,37*8(sp)
	stt $f14,38*8(sp)
	stt $f15,39*8(sp)
	stt $f16,40*8(sp)
	stt $f17,41*8(sp)
	stt $f18,42*8(sp)
	stt $f19,43*8(sp)
	stt $f20,44*8(sp)
	stt $f21,45*8(sp)
	stt $f22,46*8(sp)
	stt $f23,47*8(sp)
	stt $f24,48*8(sp)
	stt $f25,49*8(sp)
	stt $f26,50*8(sp)
	stt $f27,51*8(sp)
	stt $f28,52*8(sp)
	stt $f29,53*8(sp)
	stt $f30,54*8(sp)

	/* Call the C interrupt handler; the interrupt data is in a0 to a2 so will be
	 * passed as arguments */
	lda pv,OSInterruptHandler
	jsr ra,(pv),OSInterruptHandler

	/* Restore the global pointer */
	ldgp gp,0(ra)

	/* Returned from C interrupt routine; disable other interrupts to avoid the sort of
	 * messing around I had to do at the start of the routine */
	lda a0,7($31)
	call_pal PAL_SWPIPL_ENTRY
/*
 *  Check to see if we need to swap context.
 */
	ldq a0, OSIntSwap
	bne a0, OSSwapInterruptThread
/* 
 *  Now restore the registers of the thread that will continue to
 *  run when this interrupt is post-processed by the PALcode.
 */
restore_registers:
	/* Restore the saved registers from the stack */

	ldq a3,19*8(sp)
	ldq a4,20*8(sp)
	ldq a5,21*8(sp)
	ldq v0,0*8(sp)
	ldq t0,1*8(sp)
	ldq t1,2*8(sp)
	ldq t2,3*8(sp)
	ldq t3,4*8(sp)
	ldq t4,5*8(sp)
	ldq t5,6*8(sp)
	ldq t6,7*8(sp)
	ldq t7,8*8(sp)
	ldq t8,22*8(sp)
	ldq t9,23*8(sp)
	ldq t10,24*8(sp)
	ldq t11,25*8(sp)
	ldq t12,27*8(sp)
	ldq ra,26*8(sp)
	ldq AT,28*8(sp)

	ldt $f0,32*8(sp)
	ldt $f1,33*8(sp)
	ldt $f10,34*8(sp)
	ldt $f11,35*8(sp)
	ldt $f12,36*8(sp)
	ldt $f13,37*8(sp)
	ldt $f14,38*8(sp)
	ldt $f15,39*8(sp)
	ldt $f16,40*8(sp)
	ldt $f17,41*8(sp)
	ldt $f18,42*8(sp)
	ldt $f19,43*8(sp)
	ldt $f20,44*8(sp)
	ldt $f21,45*8(sp)
	ldt $f22,46*8(sp)
	ldt $f23,47*8(sp)
	ldt $f24,48*8(sp)
	ldt $f25,49*8(sp)
	ldt $f26,50*8(sp)
	ldt $f27,51*8(sp)
	ldt $f28,52*8(sp)
	ldt $f29,53*8(sp)
	ldt $f30,54*8(sp)

	/* Restore the stack */
	lda sp,64*8(sp)

	/* And end the interrupt */
	call_pal PAL_RTI_ENTRY	
	.end OSInterrupt	

/*
 *  Load the current thread's context. 
 *	a0 = address of saved registers.
 */
	.set noat
	.set noreorder
	.text
	.align 4
	.globl OSLoadThread
	.ent OSLoadThread
OSLoadThread:
	ldq $0,0*8(a0)
	ldq $1,1*8(a0)
	ldq $2,2*8(a0)
	ldq $3,3*8(a0)
	ldq $4,4*8(a0)
	ldq $5,5*8(a0)
	ldq $6,6*8(a0)
	ldq $7,7*8(a0)
	ldq $8,8*8(a0)
	ldq $9,9*8(a0)
	ldq $10,10*8(a0)
	ldq $11,11*8(a0)
	ldq $12,12*8(a0)
	ldq $13,13*8(a0)
	ldq $14,14*8(a0)
	ldq $15,15*8(a0)

	ldq $17,17*8(a0)
	ldq $18,18*8(a0)
	ldq $19,19*8(a0)
	ldq $20,20*8(a0)
	ldq $21,21*8(a0)
	ldq $22,22*8(a0)
	ldq $23,23*8(a0)
	ldq $24,24*8(a0)
	ldq $25,25*8(a0)
	ldq $26,26*8(a0)
	ldq $27,27*8(a0)

	ldt $f0,32*8(a0)
	ldt $f1,33*8(a0)
	ldt $f10,34*8(a0)
	ldt $f11,35*8(a0)
	ldt $f12,36*8(a0)
	ldt $f13,37*8(a0)
	ldt $f14,38*8(a0)
	ldt $f15,39*8(a0)
	ldt $f16,40*8(a0)
	ldt $f17,41*8(a0)
	ldt $f18,42*8(a0)
	ldt $f19,43*8(a0)
	ldt $f20,44*8(a0)
	ldt $f21,45*8(a0)
	ldt $f22,46*8(a0)
	ldt $f23,47*8(a0)
	ldt $f24,48*8(a0)
	ldt $f25,49*8(a0)
	ldt $f26,50*8(a0)
	ldt $f27,51*8(a0)
	ldt $f28,52*8(a0)
	ldt $f29,53*8(a0)
	ldt $f30,54*8(a0)

	ldq $30,30*8(a0)
/*
 *	set up the PC and arguments and then jump to it.
 */
	ldq $29,29*8(a0)	/* gp */
	ldq $28,64*8(a0)	/* AT -> PC */
	ldq a0,16*8(a0)		/* a0 */
	jmp $31, ($28)

	.set reorder
	.end OSLoadThread

/*
 *  Initialize the thread's saved register set.
 *	a0 = saved register area for this thread
 *	a1 = sp
 *	a2 = routine to call
 *  	a3 = data pointer
 */
	.text
	.align 4
	.globl OSInitThread
	.ent OSInitThread
OSInitThread:
	.set noat
	.set noreorder
	/* set up the gp */
	br gp,OSInitThread2
OSInitThread2:
	ldgp gp,0(gp)
	stq a2,64*8(a0)
	stq a2,27*8(a0)		/* r27 = t12 */
	stq a3,16*8(a0)
	stq a1 30*8(a0)
	stq gp,29*8(a0)
	ldq a1,0($31)		/* PS = 0 */
	stq a1,65*8(a0)
	ret $31, (ra)
	.set reorder
	.end OSInitThread

/*
 *   Swap the current thread for the new thread.
 *
 */
	.data
	.globl OSTaskSwapEndAddress
OSTaskSwapEndAddress:
	.quad OSTaskSwapEnd
	.globl OSTCBCur
	.globl OSTCBHighRdy

	.text
	.align 4
	.globl OSTaskSwap
	.ent OSTaskSwap
OSTaskSwap:
	.set noat
	.set noreorder
	/* set up the gp */
	br gp,OSTaskSwap2
OSTaskSwap2:
	ldgp gp,0(gp)

/* 
 *   Swap the current task pointer with the one we're just about to run.
 */
	ldq t0, OSTCBCur
	ldq t1, OSTCBHighRdy
	stq t1, OSTCBCur
	ldq t2, 0($31)
	stq t2, OSTCBHighRdy
/*
 *   Pull the pointers to the saved register areas, t0 = old, t1 = new
 */
	ldq t0, 0(t0)
	ldq t1, 0(t1)
/*
 *   Now save the register set of the old thread and load the
 *   register set of the new thread.
 */
	stq $0,0*8(t0)
	stq $1,1*8(t0)
	stq $2,2*8(t0)
	stq $3,3*8(t0)
	stq $4,4*8(t0)
	stq $5,5*8(t0)
	stq $6,6*8(t0)
	stq $7,7*8(t0)
	stq $8,8*8(t0)
	stq $9,9*8(t0)
	stq $10,10*8(t0)
	stq $11,11*8(t0)
	stq $12,12*8(t0)
	stq $13,13*8(t0)
	stq $14,14*8(t0)
	stq $15,15*8(t0)
	stq $16,16*8(t0)
	stq $17,17*8(t0)
	stq $18,18*8(t0)
	stq $19,19*8(t0)
	stq $20,20*8(t0)
	stq $21,21*8(t0)
	stq $22,22*8(t0)
	stq $23,23*8(t0)
	stq $24,24*8(t0)
	stq $25,25*8(t0)
	stq $26,26*8(t0)
	stq $27,27*8(t0)
	stq $28, 28*8(t0)
	stq $29, 29*8(t0)
	stq $30, 30*8(t0)
	/* Register 31 is always 0; store it anyway */
	stq $31,31*8(t0)
/*
 * Make sure that floating point is enabled incase
 * it was disabled by the user program.
 */
	bis a0, $31, $9
	bis t0, $31, $10
	bis t1, $31, $11
	lda a0, 1(zero)
	call_pal PAL_WRFEN_ENTRY
	bis $9, $31, a0
	bis $10, $31, t0
	bis $11, $31, t1

	stt $f0,32*8(t0)
	stt $f1,33*8(t0)
	stt $f10,34*8(t0)
	stt $f11,35*8(t0)
	stt $f12,36*8(t0)
	stt $f13,37*8(t0)
	stt $f14,38*8(t0)
	stt $f15,39*8(t0)
	stt $f16,40*8(t0)
	stt $f17,41*8(t0)
	stt $f18,42*8(t0)
	stt $f19,43*8(t0)
	stt $f20,44*8(t0)
	stt $f21,45*8(t0)
	stt $f22,46*8(t0)
	stt $f23,47*8(t0)
	stt $f24,48*8(t0)
	stt $f25,49*8(t0)
	stt $f26,50*8(t0)
	stt $f27,51*8(t0)
	stt $f28,52*8(t0)
	stt $f29,53*8(t0)
	stt $f30,54*8(t0)
/*
 *   Now we've got to give it a valid saved PC, ie the return
 *   point from this routine.   Note that this means that we will
 *   return to OSSched() and then call OS_EXIT_CRITICAL() before
 *   returning to the task itself via one of the service routines, for
 *   example OSSemPend().
 */
	ldq $0, OSTaskSwapEndAddress
	stq $0,64*8(t0)
/*
 *   Save the thread's current ps.
 */
	call_pal PAL_RDPS_ENTRY
	stq $0,65*8(t0)
/*
 *   Now load the new thread's context
 */
	ldq $0,0*8(t1)
	ldq $1,1*8(t1)

	ldq $3,3*8(t1)
	ldq $4,4*8(t1)
	ldq $5,5*8(t1)
	ldq $6,6*8(t1)
	ldq $7,7*8(t1)
	ldq $8,8*8(t1)
	ldq $9,9*8(t1)
	ldq $10,10*8(t1)
	ldq $11,11*8(t1)
	ldq $12,12*8(t1)
	ldq $13,13*8(t1)
	ldq $14,14*8(t1)
	ldq $15,15*8(t1)
	ldq $16,16*8(t1)
	ldq $17,17*8(t1)
	ldq $18,18*8(t1)
	ldq $19,19*8(t1)
	ldq $20,20*8(t1)
	ldq $21,21*8(t1)
	ldq $22,22*8(t1)
	ldq $23,23*8(t1)
	ldq $24,24*8(t1)
	ldq $25,25*8(t1)
	ldq $26,26*8(t1)
	ldq $27,27*8(t1)

	ldt $f0,32*8(t1)
	ldt $f1,33*8(t1)
	ldt $f10,34*8(t1)
	ldt $f11,35*8(t1)
	ldt $f12,36*8(t1)
	ldt $f13,37*8(t1)
	ldt $f14,38*8(t1)
	ldt $f15,39*8(t1)
	ldt $f16,40*8(t1)
	ldt $f17,41*8(t1)
	ldt $f18,42*8(t1)
	ldt $f19,43*8(t1)
	ldt $f20,44*8(t1)
	ldt $f21,45*8(t1)
	ldt $f22,46*8(t1)
	ldt $f23,47*8(t1)
	ldt $f24,48*8(t1)
	ldt $f25,49*8(t1)
	ldt $f26,50*8(t1)
	ldt $f27,51*8(t1)
	ldt $f28,52*8(t1)
	ldt $f29,53*8(t1)
	ldt $f30,54*8(t1)

	ldq $30,30*8(t1)	/* sp */
/*
 *  build a stack frame and call the PAL return from interrupt
 *  entry point to swap to this new thread context.
 */
	lda sp,-48(sp)
	stq a0, 24(sp)		/* a0 	*/
	stq a1, 32(sp)		/* a1 	*/
	stq a2, 40(sp)		/* a2 	*/
	ldq a0, 64*8(t1)	/* pc	*/
	stq a0, 8(sp)
	ldq a0, 65*8(t1)	/* ps	*/
	stq a0, 0(sp)		
	ldq a0, 29*8(t1)	/* gp	*/
	stq a0,16(sp)		
	ldq t1, 2*8(t1)
	call_pal PAL_RTI_ENTRY	

OSTaskSwapEnd:
	ret $31, (ra)
	
	.set reorder
	.end OSTaskSwap


	.globl rdps
	.ent rdps
rdps:
	/* C access to rdps pal routine */
	.frame sp,0,ra
	call_pal PAL_RDPS_ENTRY
	ret zero,(ra)
	.end rdps	


	.globl OSSwapInterruptThread
	.text
	.set noreorder
OSSwapInterruptThread:
/*
 *  First, clear the flag.
 */
	ldq a1,0($31)
	stq a1,OSIntSwap
/*
 *  Swap the current thread for the highest priority one.
 *  If either of them is zero, then go back to interrupt processing.
 */
	ldq a0, OSTCBCur
	beq a0, restore_registers
	ldq a1, OSTCBHighRdy
	beq a1, restore_registers
	stq a1, OSTCBCur
	ldq a2, 0($31)
	stq a2, OSTCBHighRdy
/*
 *  Pull out the pointers to the saved register areas for the 
 *  two threads.
 */
	ldq a0, 0(a0)
	ldq a1, 0(a1)
/*
 *  Save the context of the old thread (pointed at by a0).
 *  First pop everything we've saved off of the stack and put
 *  it into the saved register area for the new thread.
 */
	ldq a3,0*8(sp)			/* $0	*/
	stq a3,0*8(a0)		
	ldq a3,1*8(sp)			/* $1	*/
	stq a3,1*8(a0)	
	ldq a3,2*8(sp)			/* $2	*/
	stq a3,2*8(a0)		
	ldq a3,3*8(sp)			/* $3	*/
	stq a3,3*8(a0)
	ldq a3,4*8(sp)			/* $4	*/
	stq a3,4*8(a0)	
	ldq a3,5*8(sp)			/* $5	*/
	stq a3,5*8(a0)		
	ldq a3,6*8(sp)			/* $6	*/
	stq a3,6*8(a0)	
	ldq a3,7*8(sp)			/* $7	*/
	stq a3,7*8(a0)	
	ldq a3,8*8(sp)			/* $8	*/
	stq a3,8*8(a0)	
	ldq a3,19*8(sp)			/* $19	*/
	stq a3,19*8(a0)	
	ldq a3,20*8(sp)			/* $20	*/
	stq a3,20*8(a0)	
	ldq a3,21*8(sp)			/* $21	*/
	stq a3,21*8(a0)	
	ldq t3,22*8(sp)			/* $22	*/
	stq t3,22*8(a0)	
	ldq a3,23*8(sp)			/* $23	*/
	stq a3,23*8(a0)	
	ldq a3,24*8(sp)			/* $24	*/
	stq a3,24*8(a0)	
	ldq a3,25*8(sp)			/* $25	*/
	stq a3,25*8(a0)	
	ldq a3,26*8(sp)			/* $26	*/
	stq a3,26*8(a0)	
	ldq a3,27*8(sp)			/* $27	*/
	stq a3,27*8(a0)	
	ldq a3,28*8(sp)			/* $28	*/
	stq a3,28*8(a0)	

	ldt $f0,32*8(sp)
	stt $f0,32*8(a0)
	ldt $f1,33*8(sp)
	stt $f1,33*8(a0)
	ldt $f10,34*8(sp)
	stt $f10,34*8(a0)
	ldt $f11,35*8(sp)
	stt $f11,35*8(a0)
	ldt $f12,36*8(sp)
	stt $f12,36*8(a0)
	ldt $f13,37*8(sp)
	stt $f13,37*8(a0)
	ldt $f14,38*8(sp)
	stt $f14,38*8(a0)
	ldt $f15,39*8(sp)
	stt $f15,39*8(a0)
	ldt $f16,40*8(sp)
	stt $f16,40*8(a0)
	ldt $f17,41*8(sp)
	stt $f17,41*8(a0)
	ldt $f18,42*8(sp)
	stt $f18,42*8(a0)
	ldt $f19,43*8(sp)
	stt $f19,43*8(a0)
	ldt $f20,44*8(sp)
	stt $f20,44*8(a0)
	ldt $f21,45*8(sp)
	stt $f21,45*8(a0)
	ldt $f22,46*8(sp)
	stt $f22,46*8(a0)
	ldt $f23,47*8(sp)
	stt $f23,47*8(a0)
	ldt $f24,48*8(sp)
	stt $f24,48*8(a0)
	ldt $f25,49*8(sp)
	stt $f25,49*8(a0)
	ldt $f26,50*8(sp)
	stt $f26,50*8(a0)
	ldt $f27,51*8(sp)
	stt $f27,51*8(a0)
	ldt $f28,52*8(sp)
	stt $f28,52*8(a0)
	ldt $f29,53*8(sp)
	stt $f29,53*8(a0)
	ldt $f30,54*8(sp)
	stt $f30,54*8(a0)

/*
 *  Now save those registers that weren't corrupted when calling
 *  proceedures.
 */
	stq s0,9*8(a0)
	stq s1,10*8(a0)
	stq s2,11*8(a0)
	stq s3,12*8(a0)
	stq s4,13*8(a0)
	stq s5,14*8(a0)
	stq s6,15*8(a0)
/*
 *  Pop the values saved by PALcode of the stack and save that
 *  stack pointer in the old thread's context.
 */

	lda sp,64*8(sp)	
	ldq a3,0(sp)		/* PS 	*/
	stq a3,65*8(a0)		
	ldq a3,8(sp)		/* pc 	*/
	stq a3,64*8(a0)
	ldq a3,16(sp)		/* gp 	*/
	stq a3,29*8(a0)
	ldq a3,24(sp)		/* a0	*/
	stq a3,16*8(a0)
	ldq a3,32(sp)		/* a1 	*/
	stq a3,17*8(a0)
	ldq a3,40(sp)		/* a2 	*/
	stq a3,18*8(a0)

	lda sp,48(sp)		/* sp back to before interrupt happened */
	stq sp,30*8(a0)
/*
 *  We have now removed and saved the current thread.  Now restore
 *  the old thread, first grab it's stack pointer and set up the
 *  values that PALcode wants to see.
 */
	ldq sp,30*8(a1)		/* restore sp */
	lda sp,-48(sp)		/* make room */
	ldq a3,65*8(a1)		/* ps 	*/
	stq a3,0(sp)
	ldq a3,64*8(a1)		/* pc 	*/
	stq a3,8(sp)
	ldq a3,29*8(a1)		/* gp 	*/
	stq a3,16(sp)
	ldq a3,16*8(a1)		/* a0	*/
	stq a3,24(sp)
	ldq a3,17*8(a1)		/* a1	*/
	stq a3,32(sp)
	ldq a3,18*8(a1)		/* a2	*/
	stq a3,40(sp)
/*
 *  Now restore all of the other registers.
 */
	ldq $0,0*8(a1)
	ldq $1,1*8(a1)
	ldq $2,2*8(a1)
	ldq $3,3*8(a1)
	ldq $4,4*8(a1)
	ldq $5,5*8(a1)
	ldq $6,6*8(a1)
	ldq $7,7*8(a1)
	ldq $8,8*8(a1)
	ldq $9,9*8(a1)
	ldq $10,10*8(a1)
	ldq $11,11*8(a1)
	ldq $12,12*8(a1)
	ldq $13,13*8(a1)
	ldq $14,14*8(a1)
	ldq $15,15*8(a1)
	ldq $16,16*8(a1)

	ldq $18,18*8(a1)
	ldq $19,19*8(a1)
	ldq $20,20*8(a1)
	ldq $21,21*8(a1)
	ldq $22,22*8(a1)
	ldq $23,23*8(a1)
	ldq $24,24*8(a1)
	ldq $25,25*8(a1)
	ldq $26,26*8(a1)
	ldq $27,27*8(a1)
	ldq $28,28*8(a1)

	ldt $f0,32*8(a1)
	ldt $f1,33*8(a1)
	ldt $f10,34*8(a1)
	ldt $f11,35*8(a1)
	ldt $f12,36*8(a1)
	ldt $f13,37*8(a1)
	ldt $f14,38*8(a1)
	ldt $f15,39*8(a1)
	ldt $f16,40*8(a1)
	ldt $f17,41*8(a1)
	ldt $f18,42*8(a1)
	ldt $f19,43*8(a1)
	ldt $f20,44*8(a1)
	ldt $f21,45*8(a1)
	ldt $f22,46*8(a1)
	ldt $f23,47*8(a1)
	ldt $f24,48*8(a1)
	ldt $f25,49*8(a1)
	ldt $f26,50*8(a1)
	ldt $f27,51*8(a1)
	ldt $f28,52*8(a1)
	ldt $f29,53*8(a1)
	ldt $f30,54*8(a1)

	ldq $17,17*8(a1)
/* 
 *  And end the interrupt 
 */
	call_pal PAL_RTI_ENTRY	
