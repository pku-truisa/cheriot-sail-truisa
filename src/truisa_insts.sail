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
union clause ast = TFENCE_VMA : (regidx)

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
union clause ast = TDLBRW : (regidx)

mapping clause encdec = TDLBRW(cs1)
  <-> 0b0001010 @ 0b00000 @ cs1 @ 0b000 @ 0b00000 @ 0b0001111

function clause execute TDLBRW(cs1) = {
  let descr = capToDescriptor(MDDLBC);
  write_DLB(descr);
  RETIRE_SUCCESS
}

mapping clause assembly = TDLBRW(cs1)
  <-> "tdlbrw" ^ spc() ^ reg_name(cs1)

/* ****************************************************************** */
union clause ast = TSETDESCRIPTOR : (regidx, regidx, regidx)

mapping clause encdec = TSETDESCRIPTOR(cd, cs1, rs2)
  <-> 0b0000100 @ rs2 @ cs1 @ 0b011 @ cd @ 0b0001111

function clause execute TSETDESCRIPTOR(cd, cs1, rs2) = {
  let cs1_val = C(cs1);
  let bnd = X(rs2);

  if not(isCapabilityMode(cs1_val)) & not(hasValidDescriptor(cs1_val.E, cs1_val.address)) then {
    handle_cheri_reg_exception(CapEx_BoundsViolation, cs1);
    RETIRE_FAIL
  } else {  
    let descrcap = setDescriptor(cs1_val, bnd);
    C(cd) = descrcap;
    RETIRE_SUCCESS
  }
}

mapping clause assembly = TSETDESCRIPTOR(cd, cs1, rs2)
  <-> "tsetdescr" ^ spc() ^ cap_reg_name(cd) ^ sep() ^ reg_name(cs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause ast = TBUILDDESCRIPTOR : (regidx, regidx, regidx)

mapping clause encdec = TBUILDDESCRIPTOR(cd, cs1, rs2)
  <-> 0b0000101 @ rs2 @ cs1 @ 0b011 @ cd @ 0b0001111

function clause execute TBUILDDESCRIPTOR(cd, cs1, rs2) = {
  let cs1_val = C(cs1);
  let bnd = X(rs2);
  if not(isCapabilityMode(cs1_val)) & not(hasValidDescriptor(cs1_val.E, cs1_val.address)) then {
    handle_cheri_reg_exception(CapEx_BoundsViolation, cs1);
    RETIRE_FAIL
  } else {  
    let descr = buildDescriptor(cs1_val, bnd);

    C(cd) = descrToCapDescr(descr);
    RETIRE_SUCCESS
  }
}

mapping clause assembly = TBUILDDESCRIPTOR(cd, cs1, rs2)
  <-> "tbuilddescr" ^ spc() ^ cap_reg_name(cd) ^ sep() ^ reg_name(cs1) ^ sep() ^ reg_name(rs2)