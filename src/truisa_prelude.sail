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

type descr_addr_width : Int = 24
let  descr_addr_width = sizeof(descr_addr_width)

type DescrAddrBits  = bits(descr_addr_width)
type DescrAddrInt   = range(0, (2 ^ descr_addr_width) - 1)

/*! THIS represents descriptor-mode capabilities as stored in memory. */
struct EncDescrCapability = {
  cmode      : bits(1), /* 0, EncCapability; 1, EncDescrCapability */
  cperms     : bits(cap_cperms_width),
  cotype     : bits(cap_cotype_width),
  dmode      : bits(1), /* 0, EnDescrCapability; 1, EncDescriptor */
  E          : bits(cap_E_width),
  reserved16 : bits(16),
  address    : bits(cap_addr_width)
}

/*! THIS represents descriptor as stored in memory. */
struct EncDescriptor = {
  cmode      : bits(1), /* 0, EncCapability; 1, EncDescrCapability */
  cperms     : bits(cap_cperms_width),
  cotype     : bits(cap_cotype_width),
  dmode      : bits(1), /* 0, EnDescrCapability; 1, EncDescriptor */
  E          : bits(cap_E_width),
  base       : bits(descr_addr_width),
  bound      : bits(descr_addr_width)
}

struct Descriptor = {
  tag                    : bool,
  perm_user0             : bool,
  permit_seal            : bool,
  permit_unseal          : bool,
  permit_execute         : bool,
  access_system_regs     : bool,
  permit_load_store_cap  : bool,
  permit_load            : bool,
  permit_store_local_cap : bool,
  permit_load_mutable    : bool,
  permit_store           : bool,
  permit_load_global     : bool,
  global                 : bool,
  cmode                  : bits(1),
  dmode                  : bits(1),
  otype                  : bits(cap_otype_width),
  E                      : bits(cap_E_width),
  base                   : bits(descr_addr_width),
  bound                  : bits(descr_addr_width)
}

register MDDLBC    : Capability
register DLBEntry0 : Descriptor

function capDescrToDescriptor(cap) : Capability -> Descriptor = {
  let temp : bits(50) = cap.B @ cap.T @ cap.address;
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
    base                   = temp[47..24],
    bound                  = temp[23..0]
  }
}


function descrToCapDescr(descr) : Descriptor -> Capability = {
  let temp : bits(53) = descr.E @ descr.base @ descr.bound;
  return struct {
    tag                    = descr.tag,
    perm_user0             = descr.perm_user0            ,
    permit_seal            = descr.permit_seal           ,
    permit_unseal          = descr.permit_unseal         ,
    permit_execute         = descr.permit_execute        ,
    access_system_regs     = descr.access_system_regs    ,
    permit_load_store_cap  = descr.permit_load_store_cap ,
    permit_load            = descr.permit_load           ,
    permit_store_local_cap = descr.permit_store_local_cap,
    permit_load_mutable    = descr.permit_load_mutable   ,
    permit_store           = descr.permit_store          ,
    permit_load_global     = descr.permit_load_global    ,
    global                 = descr.global                ,
    cmode                  = descr.cmode,
    dmode                  = descr.dmode,
    otype                  = descr.otype,
    E                      = descr.E,
    B                      = temp[49..41],
    T                      = temp[40..32],
    address                = temp[31..0]
  }
}

/* The null descriptor is defined as all zeros. */
let null_descr : Descriptor = struct {
  tag                    = false,
  perm_user0             = false,
  permit_seal            = false,
  permit_unseal          = false,
  permit_execute         = false,
  access_system_regs     = false,
  permit_load_store_cap  = false,
  permit_load            = false,
  permit_store_local_cap = false,
  permit_load_mutable    = false,
  permit_store           = false,
  permit_load_global     = false,
  global                 = false,
  cmode                  = zeros(),
  dmode                  = ones(),
  E                      = zeros(),
  otype                  = to_bits(cap_otype_width, otype_unsealed),
  base                   = zeros(),
  bound                  = zeros()
}

function capBitsToEncDescrCapability(c) : CapBits -> EncDescrCapability = struct {
  cmode      = c[63..63],
  cperms     = c[62..57],
  cotype     = c[56..54],
  dmode      = c[53..53],
  E          = c[52..48],
  reserved16 = c[47..32],
  address    = c[31..0]
}

function encDescrCapToBits(cap) : EncDescrCapability -> CapBits =
  cap.cmode @
  cap.cperms @
  cap.cotype @
  cap.dmode @
  cap.E @
  cap.reserved16 @
  cap.address

function isDescrCapability(cap) : Capability -> bool = {
  bit_to_bool(cap.cmode[0]) & not(bit_to_bool(cap.dmode[0]))
}

function isDescriptor(cap) : Capability -> bool = {
  bit_to_bool(cap.cmode[0]) & bit_to_bool(cap.dmode[0])
}

function calcDescrE(base, bound) : (DescrAddrBits, DescrAddrBits) -> bits(cap_E_width) = {
  let E : range(0, 24) = 24 - count_leading_zeros( base ^ bound );
  to_bits(cap_E_width, E)
}

function calcCentroid(expo, addr) : (bits(cap_E_width), CapAddrBits) -> CapAddrBits = {
  var e = unsigned(expo);
  let mask : CapAddrBits = ones(sizeof(cap_addr_width)) << e;
  let tail_len : CapLenBits = (to_bits(sizeof(cap_len_width), 1) << e) >> 1;
  let centroid : CapAddrBits = addr & mask | tail_len[cap_addr_width - 1 .. 0 ];
  centroid
}

function calcCapCentroid(cap) : Capability -> CapAddrBits = {
  let e = cap.E;
  let a : CapAddrBits = cap.address;
  calcCentroid(e, a)
}

function calcDescrCentroid(descr) : Descriptor -> CapAddrBits = {
  let a : CapAddrBits = zero_extend(descr.base);
  let e = calcDescrE(descr.base, descr.bound);
  calcCentroid(e, a)
}