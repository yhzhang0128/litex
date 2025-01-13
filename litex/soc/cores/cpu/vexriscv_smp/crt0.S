.global main
.global isr
.global _start

.global smp_lottery_target
.global smp_lottery_lock
.global smp_lottery_args
.global smp_slave
.global boot_core

_start:
  li t0, 0x88
  csrc mstatus, t0
  la t0, bios_exception
  csrw mtvec, t0
  la sp, _fstack
  csrr a0, mhartid
  beqz a0, data_init

smp_slave:
  .word(0x500F)
  la t0, boot_core
  lw t1, 0(t0)
  bne t1, a0, smp_slave
  call core_start

data_init:
  la a0, _fdata
  la a1, _edata
  la a2, _fdata_rom
data_loop:
  beq a0,a1,data_done
  lw a3,0(a2)
  sw a3,0(a0)
  add a0,a0,4
  add a2,a2,4
  j data_loop
data_done:

bss_init:
  la a0, _fbss
  la a1, _ebss
bss_loop:
  beq a0,a1,bss_done
  sw zero,0(a0)
  add a0,a0,4
  j bss_loop
bss_done:

  call plic_init // initialize external interrupt controller
  li t0, 0x800   // external interrupt sources only (using LiteX timer);
                 // NOTE: must still enable mstatus.MIE!
  csrw mie,t0

  call main
infinit_loop:
  j infinit_loop



//Initialized to avoid having them set to zero by BSS clear
.bss
  boot_core:          .word 0
  smp_lottery_target: .word 0
  smp_lottery_args:   .word 0; .word 0; .word 0
  smp_lottery_lock:   .word 0

