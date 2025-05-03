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

function getDescriptor(expon, addr) : (bits(cap_E_width), CapAddrBits) -> (bool, Descriptor) = {
  let descr_mddlbc: Descriptor = capToDescriptor(MDDLBC);

  if calcCentroid(expon, addr) == calcDescrCentroid(descr_mddlbc) then
    (true, descr_mddlbc)       // 返回MDDLBC寄存器中的描述符
  else
    lookup_DLB(expon, addr)
}

/*!
 * Returns the decoded base and top in descriptor of the given Capability.
 */
function getDescrCapBoundsBits(c) : Capability -> (bool, CapAddrBits, CapLenBits) = {
  let (descrmiss: bool, d : Descriptor) = getDescriptor(c.E, c.address);
  let base : CapAddrBits = sign_extend(d.base);
  let top : CapLenBits  = sign_extend((0b0 @ d.bound) + 1);
  (descrmiss, base, top)
}

function getDescrCapBounds(cap) : Capability -> (bool, CapAddrInt, CapLen) =
  let (descrmiss: bool, base : CapAddrBits, top : CapLenBits) = getDescrCapBoundsBits(cap) in
  (descrmiss, unsigned(base), unsigned(top))

function hasValidDescriptor(cap) : Capability -> bool =
  let (descrmiss: bool, _, _ ) = getDescrCapBoundsBits(cap) in
  descrmiss
/*
function buildDescriptor(cap, len) : (Capability, CapLenBits) -> Descriptor = {
  let newDescr = capToDescriptor(cap);
  let (_, base, top) = getDescrCapBounds(cap);
  let a = unsigned(cap.address);
  let l = unsigned(len);
  let b : bits(descr_addr_width)   = truncate(cap.address, 24);
  let bnd : bits(descr_addr_width) = truncate(cap.address + len, 24);
  if (a + l) <= top then {
    let newE = calcDescrE(cap.address, cap.address + len) in
    descr =  {
      newDescr with
      E = newE,
      bound = bnd
    } 
  } else {
    descr = {
    newDescr with 
    bound = zeros() /* invalid descritpor */
    }
  }
}
*/