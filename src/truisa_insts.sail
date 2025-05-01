/*=======================================================================================*/
/*  TRUISA RISCV Sail Model                                                              */
/*                                                                                       */
/*  This Sail TRUISA RISC-V architecture model, comprising all files and                 */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*                                                                                       */
/*  Copyright (c) 2019-2025                                                              */
/*    Dong Tong, Peking University                                                       */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*=======================================================================================*/

/*
 *  Descritptor Lookaside Buffer instruction
 */

/* ****************************************************************** */
union clause ast = TFENCE_VMA : (regidx, regidx)

mapping clause encdec = TFENCE_VMA(cs1)
  <-> 0b0001001 @ 0b00000 @ cs1 @ 0b000 @ 0b00000 @ 0b0001111

function clause execute TFENCE_VMA(cs1) = {
  let cs1_val = C(cs1);
  let full: bits(1) = if cs1 == 0b00000 then 0b1 else 0b0;
  flush_DLB(full, cs1_val.E, cs1_val.address); 
  RETIRE_SUCCESS
}

mapping clause assembly = TFENCE_VMA(cs1)
  <-> "tfence.vma" ^ spc() ^ reg_name(cs1)

/* ****************************************************************** */
union clause ast = TDLBRW : unit

mapping clause encdec = TDLBRW
  <-> 0b0001010 @ 0b00000 @0bcs1 @0b000 @0b00000 @0b0001111

function clause execute (TDLBRW) = {
  DLBWriteEntry(OLBFIFO);
}

function clause assembly (TDLBINSERT()) = "tdlbrw"

/* ****************************************************************** */
union clause ast = TSETDESCRIPTOR : (regidx, regidx, regidx)

mapping clause encdec = TSETDESCRIPTOR(cd, cs1, rs2)
  <-> 0b0000100 @ rs2 @ rs1 @ 0b011 @ cd @ 0b0001111

function clause execute (TSETDESCRIPTOR(cd, rs1, rs2)) = {
  let cs1_val = C(cs1);
  let len : option(xlenbits) = Some(X(rs2));

  if not(hasValidDescriptor(capVal)) then {
    handle_cheri_reg_exception(CapEx_DescriptorViolation, cs1);
    RETIRE_FAIL
  } else {
    C(cd) = buildDescriptor(cs1_val, 0b0 @ len); /* return Capability with tag clear if BuildDescriptor cause Error
    RETIRE_SUCCESS
  }
}

mapping clause assembly = TSETDESCRIPTOR(cd, rs1, rs2)
  <-> "tsetdescr" ^ spc() ^ cap_reg_name(cd) ^ sep() ^ reg_name(cs1) ^ sep() ^ reg_name(rs2)
