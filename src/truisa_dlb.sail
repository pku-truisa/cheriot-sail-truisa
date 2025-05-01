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

/* idealized generic DLB entry to model fence.vm and also speed up simulation. */

val match_DLB_Entry : (bits(cap_E_width), CapAddrBits, Descriptor) > bool
function match_DLBEntry(expon, addr, entry) =
  let centroidIn  = calcCentroid(expon, addr) in
  let centroidEntry = calcDescrCentroid(entry) in
  ( 
    centroidIn == CentroidEntry
  )

val lookup_DLB : (bits(cap_E_width), CapAddrBits) -> (bool, Descriptor)
function lookup_DLB(expon, addr) = {
    if match_DLB_Entry(expoin, addr, DLBEntry) then
      (true, DLBEntry)
    else
      (false, null_descr)
}

val flush_DLB : (bool, bits(cap_E_width), CapAddrBits) -> unit
function flush_DLB(full, expon, addr) = {
  if full then
    DLBEntry = null_descr
  else if match_DLB_Entry(expoin, addr, DLBEntry) then
    DLBEntry = null_descr
}

val write_DLB : Descriptor -> unit
function write_DLB : (ent) = {
  DLBEntry = ent
}