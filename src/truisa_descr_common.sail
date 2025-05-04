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
  let descr_mddlbc: Descriptor = capDescrToDescriptor(MDDLBC);

  if calcCentroid(expon, addr) == calcDescrCentroid(descr_mddlbc) then
    (true, descr_mddlbc)       // 返回MDDLBC寄存器中的描述符
  else
    lookup_DLB(expon, addr)
}

function hasValidDescriptor(expon, addr) : (bits(cap_E_width), CapAddrBits) -> bool =
  let (v, _) = getDescriptor(expon, addr) in
  v

/*!
 * Returns the decoded base and top in descriptor of the given descriptor Cap.
 */
function getDescrCapBoundsBits(c) : Capability -> (CapAddrBits, CapLenBits) = {
  let (_, d : Descriptor) = getDescriptor(c.E, c.address);
  let base : CapAddrBits = zero_extend(d.base);
  let top : CapLenBits  = zero_extend(d.bound) + 1;
  (base, top)
}

function getDescrCapBounds(cap) : Capability -> (CapAddrInt, CapLen) =
  let (base : CapAddrBits, top : CapLenBits) = getDescrCapBoundsBits(cap) in
  (unsigned(base), unsigned(top))

function getDescrCapBaseBits(c) : Capability -> CapAddrBits =
    let (base, _) = getDescrCapBoundsBits(c) in
    base

function getDescrCapBase(c) : Capability -> CapAddrInt =
    unsigned(getDescrCapBaseBits(c))

function getDescrCapTopBits(c) : Capability -> CapLenBits =
    let (_, top) = getDescrCapBoundsBits(c) in
    top

function getDescrCapTop (c) : Capability -> CapLen =
    unsigned(getDescrCapTopBits(c))

function getDescrCapLength(c) : Capability -> CapLen =
    let ('base, 'top) = getDescrCapBounds(c) in {
        /* For valid capabilties we expect top >= base and hence
         * length >= 0 but representation does allow top < base in some
         * cases so might encounter on untagged capabilities. Here we just
         * pretend it is a 65-bit quantitiy and wrap.
         */
        assert (not(c.tag) | top >= base);
        (top - base) % pow2(cap_len_width)
    }

/*!
 * THIS(cap, addr, len) checks whether the descriptor cap includes the region
 * specified by addr and len. Specifically it checks whether
 * cap.base $\le$ addr AND addr + len $\le$ cap.top. Note that this definition
 * returns true if len is zero and addr $=$ cap.top.
 */
val inDescrCapBounds  : (Capability, CapAddrBits, CapLen) -> bool
function inDescrCapBounds (cap, addr, size) = {
  let (base, top) = getDescrCapBounds(cap);
  let a = unsigned(addr);
  (a >= base) & ((a + size) <= top) & hasValidDescriptor(cap.E, cap.address)
}

function capCentroidsEqual (c1, c2) : (Capability, Capability) -> bool =
    (calcCapCentroid(c1) == calcCapCentroid(c2))

/*!
 * Returns the given descriptor cap with the address set to the given value.
 */
val setDescrCapAddr : (Capability, CapAddrBits) -> (bool, Capability)
function setDescrCapAddr(c, addr) =
  let newCap = { c with address = addr } in
  let representable = capCentroidsEqual(c, newCap) in
  (representable, newCap)

/*!
 * Returns the given descriptor cap with the address incremented by the given value.
 */
val incDescrCapAddr : (Capability, CapAddrBits) -> (bool, Capability)
function incDescrCapAddr(c, delta) =
  let newAddress : CapAddrBits = c.address + delta in
  let newCap     = { c with address = newAddress } in
  let representable = capCentroidsEqual(c, newCap) in
  (representable, newCap)


function capToDescriptor(cap) : Capability -> Descriptor = {
  let (base, bound) = if isCapabilityMode(cap) then getCapBoundsBits(cap) else getDescrCapBoundsBits(cap);
  return struct {
    tag                    = cap.tag,
    perm_user0             = cap.perm_user0            ,
    permit_seal            = cap.permit_seal           ,
    permit_unseal          = cap.permit_unseal         ,
    permit_execute         = cap.permit_execute        ,
    access_system_regs     = cap.access_system_regs    ,
    permit_load_store_cap  = cap.permit_load_store_cap ,
    permit_load            = cap.permit_load           ,
    permit_store_local_cap = cap.permit_store_local_cap,
    permit_load_mutable    = cap.permit_load_mutable   ,
    permit_store           = cap.permit_store          ,
    permit_load_global     = cap.permit_load_global    ,
    global                 = cap.global                ,
    cmode                  = cap.cmode,
    dmode                  = cap.dmode,
    otype                  = cap.otype,
    E                      = cap.E,
    base                   = truncate(base, descr_addr_width),
    bound                  = truncate(bound, descr_addr_width)
  }
}

function buildDescriptor(cap, bnd) : (Capability, CapAddrBits) -> Descriptor = {
  /* TODO: descriptorViolation */
  let descr = capToDescriptor(cap);
  let newbnd = truncate(bnd, descr_addr_width);

  if unsigned(newbnd) <= unsigned(descr.bound)  then  
    { descr with E = calcDescrE(descr.base, newbnd), bound = newbnd}
  else 
    { descr with bound = zeros() }/* invalid descritpor */
  
}