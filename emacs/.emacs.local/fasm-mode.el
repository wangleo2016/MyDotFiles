;;; fasm-mode.el --- FASM x86 assembly major mode -*- lexical-binding: t; -*-

;; This is free and unencumbered software released into the public domain.

;; Author: Gabriel Frigo <gabriel.frigo4@gmail.com>
;; URL: https://github.com/GabrielFrigo4/fasm-mode
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; A major mode for editing FASM x86 assembly programs. It includes
;; syntax highlighting, automatic indentation, and imenu integration.
;; Unlike Emacs generic `asm-mode`, it understands FASM-specific
;; syntax.

;; FASM Home: https://flatassembler.net
;; FASM GitHub: https://github.com/tgrysztar/fasm

;; Labels without colons are not recognized as labels by this mode,
;; since, without a parser equal to that of FASM itself, it's
;; otherwise ambiguous between macros and labels. This covers both
;; indentation and imenu support.

;; The keyword lists are up to date as of FASM 1.73.32.
;; https://flatassembler.net/docs.php

;; TODO:
;; [ ] None

;;; Code:

(require 'imenu)

(defgroup fasm-mode ()
  "Options for `fasm-mode`."
  :group 'languages)

(defgroup fasm-mode-faces ()
  "Faces used by `fasm-mode`."
  :group 'fasm-mode)

(defcustom fasm-basic-offset (default-value 'tab-width)
  "Indentation level for `fasm-mode`."
  :type 'integer
  :group 'fasm-mode)

(defcustom fasm-after-mnemonic-whitespace :tab
  "In `fasm-mode`, determines the whitespace to use after mnemonics.
This can be :tab, :space, or nil (do nothing)."
  :type '(choice (const :tab) (const :space) (const nil))
  :group 'fasm-mode)

(defface fasm-registers
  '((t :inherit (font-lock-variable-name-face)))
  "Face for registers."
  :group 'fasm-mode-faces)

(defface fasm-prefix
  '((t :inherit (font-lock-builtin-face)))
  "Face for prefix."
  :group 'fasm-mode-faces)

(defface fasm-types
  '((t :inherit (font-lock-type-face)))
  "Face for types."
  :group 'fasm-mode-faces)

(defface fasm-instructions
  '((t :inherit (font-lock-builtin-face)))
  "Face for instructions."
  :group 'fasm-mode-faces)

(defface fasm-directives
  '((t :inherit (font-lock-keyword-face)))
  "Face for directives."
  :group 'fasm-mode-faces)

(defface fasm-preprocessor
  '((t :inherit (font-lock-preprocessor-face)))
  "Face for preprocessor directives."
  :group 'fasm-mode-faces)

(defface fasm-labels
  '((t :inherit (font-lock-function-name-face)))
  "Face for nonlocal labels."
  :group 'fasm-mode-faces)

(defface fasm-local-labels
  '((t :inherit (font-lock-function-name-face)))
  "Face for local labels."
  :group 'fasm-mode-faces)

(defface fasm-section-name
  '((t :inherit (font-lock-type-face)))
  "Face for section name face."
  :group 'fasm-mode-faces)

(defface fasm-constant
  '((t :inherit (font-lock-constant-face)))
  "Face for constant."
  :group 'fasm-mode-faces)

(eval-and-compile
  (defconst fasm-registers
    '("al" "ah" "ax" "eax" "rax"
      "bl" "bh" "bx" "ebx" "rbx"
      "cl" "ch" "cx" "ecx" "rcx"
      "dl" "dh" "dx" "edx" "rdx"
      "spl" "sp" "esp" "rsp"
      "bpl" "bp" "ebp" "rbp"
      "sil" "si" "esi" "rsi"
      "dil" "di" "edi" "rdi"
      "r8b" "r9b" "r10b" "r11b" "r12b" "r13b" "r14b" "r15b"
      "r8w" "r9w" "r10w" "r11w" "r12w" "r13w" "r14w" "r15w"
      "r8d" "r9d" "r10d" "r11d" "r12d" "r13d" "r14d" "r15d"
      "r8" "r9" "r10" "r11" "r12" "r13" "r14" "r15"
      "es" "cs" "ss" "ds" "fs" "gs"
      "segr6" "segr7"
      "cr0" "cr1" "cr2" "cr3" "cr4" "cr5" "cr6" "cr7" "cr8" "cr9" "cr10" "cr11" "cr12" "cr13" "cr14" "cr15"
      "dr0" "dr1" "dr2" "dr3" "dr4" "dr5" "dr6" "dr7" "dr8" "dr9" "dr10" "dr11" "dr12" "dr13" "dr14" "dr15"
      "tr0" "tr1" "tr2" "tr3" "tr4" "tr5" "tr6" "tr7"
      "st0" "st1" "st2" "st3" "st4" "st5" "st6" "st7"
      "mm0" "mm1" "mm2" "mm3" "mm4" "mm5" "mm6" "mm7"
      "xmm0" "xmm1" "xmm2" "xmm3" "xmm4" "xmm5" "xmm6" "xmm7" "xmm8" "xmm9" "xmm10" "xmm11" "xmm12" "xmm13" "xmm14" "xmm15" "xmm16" "xmm17" "xmm18" "xmm19" "xmm20" "xmm21" "xmm22" "xmm23" "xmm24" "xmm25" "xmm26" "xmm27" "xmm28" "xmm29" "xmm30" "xmm31"
      "ymm0" "ymm1" "ymm2" "ymm3" "ymm4" "ymm5" "ymm6" "ymm7" "ymm8" "ymm9" "ymm10" "ymm11" "ymm12" "ymm13" "ymm14" "ymm15" "ymm16" "ymm17" "ymm18" "ymm19" "ymm20" "ymm21" "ymm22" "ymm23" "ymm24" "ymm25" "ymm26" "ymm27" "ymm28" "ymm29" "ymm30" "ymm31"
      "zmm0" "zmm1" "zmm2" "zmm3" "zmm4" "zmm5" "zmm6" "zmm7" "zmm8" "zmm9" "zmm10" "zmm11" "zmm12" "zmm13" "zmm14" "zmm15" "zmm16" "zmm17" "zmm18" "zmm19" "zmm20" "zmm21" "zmm22" "zmm23" "zmm24" "zmm25" "zmm26" "zmm27" "zmm28" "zmm29" "zmm30" "zmm31"
      "tmm0" "tmm1" "tmm2" "tmm3" "tmm4" "tmm5" "tmm6" "tmm7"
      "k0" "k1" "k2" "k3" "k4" "k5" "k6" "k7"
      "bnd0" "bnd1" "bnd2" "bnd3")
    "FASM registers (SOURCE/TABLES.INC) for `fasm-mode`."))

(eval-and-compile
  (defconst fasm-directives
    '("define" "include" "irp" "irps" "macro" "match" "purge" "rept" "restore"
      "restruc" "struc" "common" "forward" "local" "reverse" "equ" "fix"
      "struct" "union" "ends" "frame" "endf" "resdata" "endres"
      "format" "public" "import" "library" "export"
      "if" "else" "end" "while" "repeat" "break" "assert"
      ".code" ".data" ".end"
      ".if" ".elseif" ".else" ".endif" ".while" ".endw" ".repeat" ".until"
      "err" "org" "data" "heap" "stack"
      "align" "entry" "extrn" "label" "load" "store"
      "display" "section" "segment" "virtual" "prologuedef" "epiloguedef"
      "interface" "directory" "resource"
      "!" "!=" "<=" "<=>" ">=" "=" "==" "<" ">" "<>" "+" "-" "*" "/" "(" ")" "[" "]" "{" "}"
      ":" "," "|" "&" "~" "#" "`" "$" "$$"
      "use16" "use32" "use64")
    "FASM directives (SOURCE/TABLES.INC) for `fasm-mode`."))

(eval-and-compile
  (defconst fasm-instructions
    '("DB" "DW" "DD" "DQ" "DT" "DO" "DY" "DZ" "RESB" "RESW" "RESD" "RESQ" "REST" "RESO" "RESY" "RESZ" "INCBIN"
      "AAA" "AAD" "AAM" "AAS" "ADC" "ADD" "AND" "ARPL" "BB0_RESET" "BB1_RESET" "BOUND" "BSF" "BSR" "BSWAP" "BT" "BTC" "BTR" "BTS" "CALL"
      "CBW" "CDQ" "CDQE" "CLC" "CLD" "CLI" "CLTS" "CMC" "CMP" "CMPSB" "CMPSD" "CMPSQ" "CMPSW" "CMPXCHG" "CMPXCHG486" "CMPXCHG8B" "CMPXCHG16B" "CPUID" "CPU_READ" "CPU_WRITE" "CQO" "CWD" "CWDE" "DAA" "DAS" "DEC" "DIV" "DMINT" "EMMS" "ENTER" "EQU" "F2XM1" "FABS" "FADD" "FADDP" "FBLD" "FBSTP" "FCHS" "FCLEX" "FCMOVB" "FCMOVBE" "FCMOVE" "FCMOVNB" "FCMOVNBE" "FCMOVNE" "FCMOVNU" "FCMOVU" "FCOM" "FCOMI" "FCOMIP" "FCOMP" "FCOMPP" "FCOS" "FDECSTP" "FDISI" "FDIV" "FDIVP" "FDIVR" "FDIVRP" "FEMMS" "FENI" "FFREE" "FFREEP" "FIADD" "FICOM" "FICOMP" "FIDIV" "FIDIVR" "FILD" "FIMUL" "FINCSTP" "FINIT" "FIST" "FISTP" "FISTTP" "FISUB" "FISUBR" "FLD" "FLD1" "FLDCW" "FLDENV" "FLDL2E" "FLDL2T" "FLDLG2" "FLDLN2" "FLDPI" "FLDZ" "FMUL" "FMULP" "FNCLEX" "FNDISI" "FNENI" "FNINIT" "FNOP" "FNSAVE" "FNSTCW" "FNSTENV" "FNSTSW" "FPATAN" "FPREM" "FPREM1" "FPTAN" "FRNDINT" "FRSTOR" "FSAVE" "FSCALE" "FSETPM" "FSIN" "FSINCOS" "FSQRT" "FST" "FSTCW" "FSTENV" "FSTP" "FSTSW" "FSUB" "FSUBP" "FSUBR" "FSUBRP" "FTST" "FUCOM" "FUCOMI" "FUCOMIP" "FUCOMP" "FUCOMPP" "FXAM" "FXCH" "FXTRACT" "FYL2X" "FYL2XP1" "HLT" "IBTS" "ICEBP" "IDIV" "IMUL" "IN" "INC" "INSB" "INSD" "INSW" "INT" "INT01" "INT1" "INT03" "INT3" "INTO" "INVD" "INVPCID" "INVLPG" "INVLPGA" "IRET" "IRETD" "IRETQ" "IRETW" "JCXZ" "JECXZ" "JRCXZ" "JMP"
      "JMPE" "LAHF" "LAR" "LDS" "LEA" "LEAVE" "LES" "LFENCE" "LFS" "LGDT" "LGS" "LIDT" "LLDT" "LMSW" "LOADALL" "LOADALL286" "LODSB" "LODSD" "LODSQ" "LODSW" "LOOP" "LOOPE" "LOOPNE" "LOOPNZ" "LOOPZ" "LSL" "LSS" "LTR" "MFENCE" "MONITOR" "MONITORX" "MOV" "MOVD" "MOVQ" "MOVSB" "MOVSD" "MOVSQ" "MOVSW" "MOVSX" "MOVSXD" "MOVZX" "MUL" "MWAIT" "MWAITX" "NEG" "NOP" "NOT" "OR" "OUT" "OUTSB" "OUTSD" "OUTSW" "PACKSSDW" "PACKSSWB" "PACKUSWB" "PADDB" "PADDD" "PADDSB" "PADDSIW" "PADDSW" "PADDUSB" "PADDUSW" "PADDW" "PAND" "PANDN" "PAUSE" "PAVEB" "PAVGUSB" "PCMPEQB" "PCMPEQD" "PCMPEQW" "PCMPGTB" "PCMPGTD" "PCMPGTW" "PDISTIB" "PF2ID" "PFACC" "PFADD" "PFCMPEQ" "PFCMPGE" "PFCMPGT" "PFMAX" "PFMIN" "PFMUL" "PFRCP" "PFRCPIT1" "PFRCPIT2" "PFRSQIT1" "PFRSQRT" "PFSUB" "PFSUBR" "PI2FD" "PMACHRIW" "PMADDWD" "PMAGW" "PMULHRIW" "PMULHRWA" "PMULHRWC" "PMULHW" "PMULLW" "PMVGEZB" "PMVLZB" "PMVNZB" "PMVZB" "POP" "POPA" "POPAD" "POPAW" "POPF" "POPFD" "POPFQ" "POPFW" "POR" "PREFETCH" "PREFETCHW" "PSLLD" "PSLLQ" "PSLLW" "PSRAD" "PSRAW" "PSRLD" "PSRLQ" "PSRLW" "PSUBB" "PSUBD" "PSUBSB" "PSUBSIW" "PSUBSW" "PSUBUSB" "PSUBUSW" "PSUBW" "PUNPCKHBW" "PUNPCKHDQ" "PUNPCKHWD" "PUNPCKLBW" "PUNPCKLDQ" "PUNPCKLWD" "PUSH" "PUSHA" "PUSHAD" "PUSHAW" "PUSHF" "PUSHFD" "PUSHFQ" "PUSHFW" "PXOR" "RCL" "RCR" "RDSHR" "RDMSR" "RDPMC" "RDTSC" "RDTSCP" "RET" "RETF" "RETN" "RETW" "RETFW" "RETNW" "RETD" "RETFD" "RETND" "RETQ" "RETFQ" "RETNQ"
      "ROL" "ROR" "RDM" "RSDC" "RSLDT" "RSM" "RSTS" "SAHF" "SAL" "SALC" "SAR" "SBB" "SCASB" "SCASD" "SCASQ" "SCASW" "SFENCE" "SGDT" "SHL" "SHLD" "SHR" "SHRD" "SIDT" "SLDT" "SKINIT" "SMI" "SMINT" "SMINTOLD" "SMSW" "STC" "STD" "STI" "STOSB" "STOSD" "STOSQ" "STOSW" "STR" "SUB" "SVDC" "SVLDT" "SVTS" "SWAPGS" "SYSCALL" "SYSENTER" "SYSEXIT" "SYSRET" "TEST" "UD0" "UD1" "UD2B" "UD2" "UD2A" "UMOV" "VERR" "VERW" "FWAIT" "WBINVD" "WRSHR" "WRMSR" "XADD" "XBTS" "XCHG" "XLATB" "XLAT" "XOR" "CMOVA" "CMOVAE" "CMOVB" "CMOVBE" "CMOVC" "CMOVE" "CMOVG" "CMOVGE" "CMOVL" "CMOVLE" "CMOVNA" "CMOVNAE" "CMOVNB" "CMOVNBE" "CMOVNC" "CMOVNE" "CMOVNG" "CMOVNGE" "CMOVNL" "CMOVNLE" "CMOVNO" "CMOVNP" "CMOVNS" "CMOVNZ" "CMOVO" "CMOVP" "CMOVPE" "CMOVPO" "CMOVS" "CMOVZ" "JA" "JAE" "JB" "JBE" "JC" "JCXZ" "JECXZ" "JRCXZ" "JE" "JG" "JGE" "JL" "JLE" "JNA" "JNAE" "JNB" "JNBE" "JNC" "JNE" "JNG" "JNGE" "JNL" "JNLE" "JNO" "JNP" "JNS" "JNZ" "JO" "JP" "JPE" "JPO" "JS" "JZ"
      "SETA" "SETAE" "SETB" "SETBE" "SETC" "SETE" "SETG" "SETGE" "SETL" "SETLE" "SETNA" "SETNAE" "SETNB" "SETNBE" "SETNC" "SETNE" "SETNG" "SETNGE" "SETNL" "SETNLE" "SETNO" "SETNP" "SETNS" "SETNZ" "SETO" "SETP" "SETPE" "SETPO" "SETS" "SETZ"
      "ADDPS" "ADDSS" "ANDNPS" "ANDPS" "CMPEQPS" "CMPEQSS" "CMPLEPS" "CMPLESS" "CMPLTPS" "CMPLTSS" "CMPNEQPS" "CMPNEQSS" "CMPNLEPS" "CMPNLESS" "CMPNLTPS" "CMPNLTSS" "CMPORDPS" "CMPORDSS" "CMPUNORDPS" "CMPUNORDSS" "CMPPS" "CMPSS" "COMISS" "CVTPI2PS" "CVTPS2PI" "CVTSI2SS" "CVTSS2SI" "CVTTPS2PI" "CVTTSS2SI" "DIVPS" "DIVSS" "LDMXCSR" "MAXPS" "MAXSS" "MINPS" "MINSS" "MOVAPS" "MOVHPS" "MOVLHPS" "MOVLPS" "MOVHLPS" "MOVMSKPS" "MOVNTPS" "MOVSS" "MOVUPS" "MULPS" "MULSS" "ORPS" "RCPPS" "RCPSS" "RSQRTPS" "RSQRTSS" "SHUFPS" "SQRTPS" "SQRTSS" "STMXCSR" "SUBPS" "SUBSS" "UCOMISS" "UNPCKHPS" "UNPCKLPS" "XORPS"
      "FXRSTOR" "FXRSTOR64" "FXSAVE" "FXSAVE64"
      "XGETBV" "XSETBV" "XSAVE" "XSAVE64" "XSAVEC" "XSAVEC64" "XSAVEOPT" "XSAVEOPT64" "XSAVES" "XSAVES64" "XRSTOR" "XRSTOR64" "XRSTORS" "XRSTORS64"
      "PREFETCHNTA" "PREFETCHT0" "PREFETCHT1" "PREFETCHT2" "PREFETCHIT0" "PREFETCHIT1" "SFENCE"
      "MASKMOVQ" "MOVNTQ" "PAVGB" "PAVGW" "PEXTRW" "PINSRW" "PMAXSW" "PMAXUB" "PMINSW" "PMINUB" "PMOVMSKB" "PMULHUW" "PSADBW" "PSHUFW"
      "PF2IW" "PFNACC" "PFPNACC" "PI2FW" "PSWAPD"
      "MASKMOVDQU" "CLFLUSH" "MOVNTDQ" "MOVNTI" "MOVNTPD" "LFENCE" "MFENCE"
      "MOVD" "MOVDQA" "MOVDQU" "MOVDQ2Q" "MOVQ" "MOVQ2DQ" "PACKSSWB" "PACKSSDW" "PACKUSWB" "PADDB" "PADDW" "PADDD" "PADDQ" "PADDSB" "PADDSW" "PADDUSB" "PADDUSW" "PAND" "PANDN" "PAVGB" "PAVGW" "PCMPEQB" "PCMPEQW" "PCMPEQD" "PCMPGTB" "PCMPGTW" "PCMPGTD" "PEXTRW" "PINSRW" "PMADDWD" "PMAXSW" "PMAXUB" "PMINSW" "PMINUB" "PMOVMSKB" "PMULHUW" "PMULHW" "PMULLW" "PMULUDQ" "POR" "PSADBW" "PSHUFD" "PSHUFHW" "PSHUFLW" "PSLLDQ" "PSLLW" "PSLLD" "PSLLQ" "PSRAW" "PSRAD" "PSRLDQ" "PSRLW" "PSRLD" "PSRLQ" "PSUBB" "PSUBW" "PSUBD" "PSUBQ" "PSUBSB" "PSUBSW" "PSUBUSB" "PSUBUSW" "PUNPCKHBW" "PUNPCKHWD" "PUNPCKHDQ" "PUNPCKHQDQ" "PUNPCKLBW" "PUNPCKLWD" "PUNPCKLDQ" "PUNPCKLQDQ" "PXOR"
      "ADDPD" "ADDSD" "ANDNPD" "ANDPD" "CMPEQPD" "CMPEQSD" "CMPLEPD" "CMPLESD" "CMPLTPD" "CMPLTSD" "CMPNEQPD" "CMPNEQSD" "CMPNLEPD" "CMPNLESD" "CMPNLTPD" "CMPNLTSD" "CMPORDPD" "CMPORDSD" "CMPUNORDPD" "CMPUNORDSD" "CMPPD" "CMPSD" "COMISD" "CVTDQ2PD" "CVTDQ2PS" "CVTPD2DQ" "CVTPD2PI" "CVTPD2PS" "CVTPI2PD" "CVTPS2DQ" "CVTPS2PD" "CVTSD2SI" "CVTSD2SS" "CVTSI2SD" "CVTSS2SD" "CVTTPD2PI" "CVTTPD2DQ" "CVTTPS2DQ" "CVTTSD2SI" "DIVPD" "DIVSD" "MAXPD" "MAXSD" "MINPD" "MINSD" "MOVAPD" "MOVHPD" "MOVLPD" "MOVMSKPD" "MOVSD" "MOVUPD" "MULPD" "MULSD" "ORPD" "SHUFPD" "SQRTPD" "SQRTSD" "SUBPD" "SUBSD" "UCOMISD" "UNPCKHPD" "UNPCKLPD" "XORPD"
      "ADDSUBPD" "ADDSUBPS" "HADDPD" "HADDPS" "HSUBPD" "HSUBPS" "LDDQU" "MOVDDUP" "MOVSHDUP" "MOVSLDUP"
      "CLGI" "STGI" "VMCALL" "VMCLEAR" "VMFUNC" "VMLAUNCH" "VMLOAD" "VMMCALL" "VMPTRLD" "VMPTRST" "VMREAD" "VMRESUME" "VMRUN" "VMSAVE" "VMWRITE" "VMXOFF" "VMXON" "INVEPT" "INVVPID" "PVALIDATE" "RMPADJUST" "VMGEXIT"
      "PABSB" "PABSW" "PABSD" "PALIGNR" "PHADDW" "PHADDD" "PHADDSW" "PHSUBW" "PHSUBD" "PHSUBSW" "PMADDUBSW" "PMULHRSW" "PSHUFB" "PSIGNB" "PSIGNW" "PSIGND"
      "EXTRQ" "INSERTQ" "MOVNTSD" "MOVNTSS"
      "LZCNT"
      "BLENDPD" "BLENDPS" "BLENDVPD" "BLENDVPS" "DPPD" "DPPS" "EXTRACTPS" "INSERTPS" "MOVNTDQA" "MPSADBW" "PACKUSDW" "PBLENDVB" "PBLENDW" "PCMPEQQ" "PEXTRB" "PEXTRD" "PEXTRQ" "PEXTRW" "PHMINPOSUW" "PINSRB" "PINSRD" "PINSRQ" "PMAXSB" "PMAXSD" "PMAXUD" "PMAXUW" "PMINSB" "PMINSD" "PMINUD" "PMINUW" "PMOVSXBW" "PMOVSXBD" "PMOVSXBQ" "PMOVSXWD" "PMOVSXWQ" "PMOVSXDQ" "PMOVZXBW" "PMOVZXBD" "PMOVZXBQ" "PMOVZXWD" "PMOVZXWQ" "PMOVZXDQ" "PMULDQ" "PMULLD" "PTEST" "ROUNDPD" "ROUNDPS" "ROUNDSD" "ROUNDSS"
      "CRC32" "PCMPESTRI" "PCMPESTRM" "PCMPISTRI" "PCMPISTRM" "PCMPGTQ" "POPCNT"
      "GETSEC"
      "PFRCPV" "PFRSQRTV"
      "MOVBE"
      "AESENC" "AESENCLAST" "AESDEC" "AESDECLAST" "AESIMC" "AESKEYGENASSIST"
      "VAESENC" "VAESENCLAST" "VAESDEC" "VAESDECLAST" "VAESIMC" "VAESKEYGENASSIST"
      "VADDPD" "VADDPS" "VADDSD" "VADDSS" "VADDSUBPD" "VADDSUBPS" "VANDPD" "VANDPS" "VANDNPD" "VANDNPS" "VBLENDPD" "VBLENDPS" "VBLENDVPD" "VBLENDVPS" "VBROADCASTSS" "VBROADCASTSD" "VBROADCASTF128" "VCMPEQ_OSPD" "VCMPEQPD" "VCMPLT_OSPD" "VCMPLTPD" "VCMPLE_OSPD" "VCMPLEPD" "VCMPUNORD_QPD" "VCMPUNORDPD" "VCMPNEQ_UQPD" "VCMPNEQPD" "VCMPNLT_USPD" "VCMPNLTPD" "VCMPNLE_USPD" "VCMPNLEPD" "VCMPORD_QPD" "VCMPORDPD" "VCMPEQ_UQPD" "VCMPNGE_USPD" "VCMPNGEPD" "VCMPNGT_USPD" "VCMPNGTPD" "VCMPFALSE_OQPD" "VCMPFALSEPD" "VCMPNEQ_OQPD" "VCMPGE_OSPD" "VCMPGEPD" "VCMPGT_OSPD" "VCMPGTPD" "VCMPTRUE_UQPD" "VCMPTRUEPD" "VCMPLT_OQPD" "VCMPLE_OQPD" "VCMPUNORD_SPD" "VCMPNEQ_USPD" "VCMPNLT_UQPD" "VCMPNLE_UQPD" "VCMPORD_SPD" "VCMPEQ_USPD" "VCMPNGE_UQPD" "VCMPNGT_UQPD" "VCMPFALSE_OSPD" "VCMPNEQ_OSPD" "VCMPGE_OQPD" "VCMPGT_OQPD" "VCMPTRUE_USPD" "VCMPPD" "VCMPEQ_OSPS" "VCMPEQPS" "VCMPLT_OSPS" "VCMPLTPS" "VCMPLE_OSPS" "VCMPLEPS" "VCMPUNORD_QPS" "VCMPUNORDPS" "VCMPNEQ_UQPS" "VCMPNEQPS" "VCMPNLT_USPS" "VCMPNLTPS" "VCMPNLE_USPS" "VCMPNLEPS" "VCMPORD_QPS" "VCMPORDPS" "VCMPEQ_UQPS" "VCMPNGE_USPS" "VCMPNGEPS" "VCMPNGT_USPS" "VCMPNGTPS" "VCMPFALSE_OQPS" "VCMPFALSEPS" "VCMPNEQ_OQPS" "VCMPGE_OSPS" "VCMPGEPS" "VCMPGT_OSPS" "VCMPGTPS" "VCMPTRUE_UQPS" "VCMPTRUEPS" "VCMPLT_OQPS" "VCMPLE_OQPS" "VCMPUNORD_SPS" "VCMPNEQ_USPS" "VCMPNLT_UQPS" "VCMPNLE_UQPS" "VCMPORD_SPS" "VCMPEQ_USPS" "VCMPNGE_UQPS" "VCMPNGT_UQPS" "VCMPFALSE_OSPS" "VCMPNEQ_OSPS" "VCMPGE_OQPS" "VCMPGT_OQPS" "VCMPTRUE_USPS" "VCMPPS" "VCMPEQ_OSSD" "VCMPEQSD" "VCMPLT_OSSD" "VCMPLTSD" "VCMPLE_OSSD" "VCMPLESD" "VCMPUNORD_QSD" "VCMPUNORDSD" "VCMPNEQ_UQSD" "VCMPNEQSD" "VCMPNLT_USSD" "VCMPNLTSD" "VCMPNLE_USSD" "VCMPNLESD" "VCMPORD_QSD" "VCMPORDSD" "VCMPEQ_UQSD" "VCMPNGE_USSD" "VCMPNGESD" "VCMPNGT_USSD" "VCMPNGTSD" "VCMPFALSE_OQSD" "VCMPFALSESD" "VCMPNEQ_OQSD" "VCMPGE_OSSD" "VCMPGESD" "VCMPGT_OSSD" "VCMPGTSD" "VCMPTRUE_UQSD" "VCMPTRUESD" "VCMPLT_OQSD" "VCMPLE_OQSD" "VCMPUNORD_SSD" "VCMPNEQ_USSD" "VCMPNLT_UQSD" "VCMPNLE_UQSD" "VCMPORD_SSD" "VCMPEQ_USSD" "VCMPNGE_UQSD" "VCMPNGT_UQSD" "VCMPFALSE_OSSD" "VCMPNEQ_OSSD" "VCMPGE_OQSD" "VCMPGT_OQSD" "VCMPTRUE_USSD" "VCMPSD" "VCMPEQ_OSSS" "VCMPEQSS" "VCMPLT_OSSS" "VCMPLTSS" "VCMPLE_OSSS" "VCMPLESS" "VCMPUNORD_QSS" "VCMPUNORDSS" "VCMPNEQ_UQSS" "VCMPNEQSS" "VCMPNLT_USSS" "VCMPNLTSS" "VCMPNLE_USSS" "VCMPNLESS" "VCMPORD_QSS" "VCMPORDSS" "VCMPEQ_UQSS" "VCMPNGE_USSS" "VCMPNGESS" "VCMPNGT_USSS" "VCMPNGTSS" "VCMPFALSE_OQSS" "VCMPFALSESS" "VCMPNEQ_OQSS" "VCMPGE_OSSS" "VCMPGESS" "VCMPGT_OSSS" "VCMPGTSS" "VCMPTRUE_UQSS" "VCMPTRUESS" "VCMPLT_OQSS" "VCMPLE_OQSS" "VCMPUNORD_SSS" "VCMPNEQ_USSS" "VCMPNLT_UQSS" "VCMPNLE_UQSS" "VCMPORD_SSS" "VCMPEQ_USSS" "VCMPNGE_UQSS" "VCMPNGT_UQSS" "VCMPFALSE_OSSS" "VCMPNEQ_OSSS" "VCMPGE_OQSS" "VCMPGT_OQSS" "VCMPTRUE_USSS" "VCMPSS" "VCOMISD" "VCOMISS" "VCVTDQ2PD" "VCVTDQ2PS" "VCVTPD2DQ" "VCVTPD2PS" "VCVTPS2DQ" "VCVTPS2PD" "VCVTSD2SI" "VCVTSD2SS" "VCVTSI2SD" "VCVTSI2SS" "VCVTSS2SD" "VCVTSS2SI" "VCVTTPD2DQ" "VCVTTPS2DQ" "VCVTTSD2SI" "VCVTTSS2SI" "VDIVPD" "VDIVPS" "VDIVSD" "VDIVSS" "VDPPD" "VDPPS" "VEXTRACTF128" "VEXTRACTPS" "VHADDPD" "VHADDPS" "VHSUBPD" "VHSUBPS" "VINSERTF128" "VINSERTPS" "VLDDQU" "VLDQQU" "VLDMXCSR" "VMASKMOVDQU" "VMASKMOVPS" "VMASKMOVPD" "VMAXPD" "VMAXPS" "VMAXSD" "VMAXSS" "VMINPD" "VMINPS" "VMINSD" "VMINSS" "VMOVAPD" "VMOVAPS" "VMOVD" "VMOVQ" "VMOVDDUP" "VMOVDQA" "VMOVQQA" "VMOVDQU" "VMOVQQU" "VMOVHLPS" "VMOVHPD" "VMOVHPS" "VMOVLHPS" "VMOVLPD" "VMOVLPS" "VMOVMSKPD" "VMOVMSKPS" "VMOVNTDQ" "VMOVNTQQ" "VMOVNTDQA" "VMOVNTPD" "VMOVNTPS" "VMOVSD" "VMOVSHDUP" "VMOVSLDUP" "VMOVSS" "VMOVUPD" "VMOVUPS" "VMPSADBW" "VMULPD" "VMULPS" "VMULSD" "VMULSS" "VORPD" "VORPS" "VPABSB" "VPABSW" "VPABSD" "VPACKSSWB" "VPACKSSDW" "VPACKUSWB" "VPACKUSDW" "VPADDB" "VPADDW" "VPADDD" "VPADDQ" "VPADDSB" "VPADDSW" "VPADDUSB" "VPADDUSW" "VPALIGNR" "VPAND" "VPANDN" "VPAVGB" "VPAVGW" "VPBLENDVB" "VPBLENDW" "VPCMPESTRI" "VPCMPESTRM" "VPCMPISTRI" "VPCMPISTRM" "VPCMPEQB" "VPCMPEQW" "VPCMPEQD" "VPCMPEQQ" "VPCMPGTB" "VPCMPGTW" "VPCMPGTD" "VPCMPGTQ" "VPERMILPD" "VPERMILPS" "VPERM2F128" "VPEXTRB" "VPEXTRW" "VPEXTRD" "VPEXTRQ" "VPHADDW" "VPHADDD" "VPHADDSW" "VPHMINPOSUW" "VPHSUBW" "VPHSUBD" "VPHSUBSW" "VPINSRB" "VPINSRW" "VPINSRD" "VPINSRQ" "VPMADDWD" "VPMADDUBSW" "VPMAXSB" "VPMAXSW" "VPMAXSD" "VPMAXUB" "VPMAXUW" "VPMAXUD" "VPMINSB" "VPMINSW" "VPMINSD" "VPMINUB" "VPMINUW" "VPMINUD" "VPMOVMSKB" "VPMOVSXBW" "VPMOVSXBD" "VPMOVSXBQ" "VPMOVSXWD" "VPMOVSXWQ" "VPMOVSXDQ" "VPMOVZXBW" "VPMOVZXBD" "VPMOVZXBQ" "VPMOVZXWD" "VPMOVZXWQ" "VPMOVZXDQ" "VPMULHUW" "VPMULHRSW" "VPMULHW" "VPMULLW" "VPMULLD" "VPMULUDQ" "VPMULDQ" "VPOR" "VPSADBW" "VPSHUFB" "VPSHUFD" "VPSHUFHW" "VPSHUFLW" "VPSIGNB" "VPSIGNW" "VPSIGND" "VPSLLDQ" "VPSRLDQ" "VPSLLW" "VPSLLD" "VPSLLQ" "VPSRAW" "VPSRAD" "VPSRLW" "VPSRLD" "VPSRLQ" "VPTEST" "VPSUBB" "VPSUBW" "VPSUBD" "VPSUBQ" "VPSUBSB" "VPSUBSW" "VPSUBUSB" "VPSUBUSW" "VPUNPCKHBW" "VPUNPCKHWD" "VPUNPCKHDQ" "VPUNPCKHQDQ" "VPUNPCKLBW" "VPUNPCKLWD" "VPUNPCKLDQ" "VPUNPCKLQDQ" "VPXOR" "VRCPPS" "VRCPSS" "VRSQRTPS" "VRSQRTSS" "VROUNDPD" "VROUNDPS" "VROUNDSD" "VROUNDSS" "VSHUFPD" "VSHUFPS" "VSQRTPD" "VSQRTPS" "VSQRTSD" "VSQRTSS" "VSTMXCSR" "VSUBPD" "VSUBPS" "VSUBSD" "VSUBSS" "VTESTPS" "VTESTPD" "VUCOMISD" "VUCOMISS" "VUNPCKHPD" "VUNPCKHPS" "VUNPCKLPD" "VUNPCKLPS" "VXORPD" "VXORPS" "VZEROALL" "VZEROUPPER"
      "PCLMULLQLQDQ" "PCLMULHQLQDQ" "PCLMULLQHQDQ" "PCLMULHQHQDQ" "PCLMULQDQ"
      "VPCLMULLQLQDQ" "VPCLMULHQLQDQ" "VPCLMULLQHQDQ" "VPCLMULHQHQDQ" "VPCLMULQDQ"
      "VFMADD132PS" "VFMADD132PD" "VFMADD312PS" "VFMADD312PD" "VFMADD213PS" "VFMADD213PD" "VFMADD123PS" "VFMADD123PD" "VFMADD231PS" "VFMADD231PD" "VFMADD321PS" "VFMADD321PD" "VFMADDSUB132PS" "VFMADDSUB132PD" "VFMADDSUB312PS" "VFMADDSUB312PD" "VFMADDSUB213PS" "VFMADDSUB213PD" "VFMADDSUB123PS" "VFMADDSUB123PD" "VFMADDSUB231PS" "VFMADDSUB231PD" "VFMADDSUB321PS" "VFMADDSUB321PD" "VFMSUB132PS" "VFMSUB132PD" "VFMSUB312PS" "VFMSUB312PD" "VFMSUB213PS" "VFMSUB213PD" "VFMSUB123PS" "VFMSUB123PD" "VFMSUB231PS" "VFMSUB231PD" "VFMSUB321PS" "VFMSUB321PD" "VFMSUBADD132PS" "VFMSUBADD132PD" "VFMSUBADD312PS" "VFMSUBADD312PD" "VFMSUBADD213PS" "VFMSUBADD213PD" "VFMSUBADD123PS" "VFMSUBADD123PD" "VFMSUBADD231PS" "VFMSUBADD231PD" "VFMSUBADD321PS" "VFMSUBADD321PD" "VFNMADD132PS" "VFNMADD132PD" "VFNMADD312PS" "VFNMADD312PD" "VFNMADD213PS" "VFNMADD213PD" "VFNMADD123PS" "VFNMADD123PD" "VFNMADD231PS" "VFNMADD231PD" "VFNMADD321PS" "VFNMADD321PD" "VFNMSUB132PS" "VFNMSUB132PD" "VFNMSUB312PS" "VFNMSUB312PD" "VFNMSUB213PS" "VFNMSUB213PD" "VFNMSUB123PS" "VFNMSUB123PD" "VFNMSUB231PS" "VFNMSUB231PD" "VFNMSUB321PS" "VFNMSUB321PD" "VFMADD132SS" "VFMADD132SD" "VFMADD312SS" "VFMADD312SD" "VFMADD213SS" "VFMADD213SD" "VFMADD123SS" "VFMADD123SD" "VFMADD231SS" "VFMADD231SD" "VFMADD321SS" "VFMADD321SD" "VFMSUB132SS" "VFMSUB132SD" "VFMSUB312SS" "VFMSUB312SD" "VFMSUB213SS" "VFMSUB213SD" "VFMSUB123SS" "VFMSUB123SD" "VFMSUB231SS" "VFMSUB231SD" "VFMSUB321SS" "VFMSUB321SD" "VFNMADD132SS" "VFNMADD132SD" "VFNMADD312SS" "VFNMADD312SD" "VFNMADD213SS" "VFNMADD213SD" "VFNMADD123SS" "VFNMADD123SD" "VFNMADD231SS" "VFNMADD231SD" "VFNMADD321SS" "VFNMADD321SD" "VFNMSUB132SS" "VFNMSUB132SD" "VFNMSUB312SS" "VFNMSUB312SD" "VFNMSUB213SS" "VFNMSUB213SD" "VFNMSUB123SS" "VFNMSUB123SD" "VFNMSUB231SS" "VFNMSUB231SD" "VFNMSUB321SS" "VFNMSUB321SD"
      "RDFSBASE" "RDGSBASE" "RDRAND" "WRFSBASE" "WRGSBASE" "VCVTPH2PS" "VCVTPS2PH"
      "ADCX" "ADOX" "RDSEED"
      "CLAC" "STAC"
      "XSTORE" "XCRYPTECB" "XCRYPTCBC" "XCRYPTCTR" "XCRYPTCFB" "XCRYPTOFB" "MONTMUL" "XSHA1" "XSHA256"
      "LLWPCB"
      "SLWPCB"
      "LWPVAL"
      "LWPINS"
      "VFMADDPD"
      "VFMADDPS"
      "VFMADDSD"
      "VFMADDSS"
      "VFMADDSUBPD"
      "VFMADDSUBPS"
      "VFMSUBADDPD"
      "VFMSUBADDPS"
      "VFMSUBPD"
      "VFMSUBPS"
      "VFMSUBSD"
      "VFMSUBSS"
      "VFNMADDPD"
      "VFNMADDPS"
      "VFNMADDSD"
      "VFNMADDSS"
      "VFNMSUBPD"
      "VFNMSUBPS"
      "VFNMSUBSD"
      "VFNMSUBSS"
      "VFRCZPD"
      "VFRCZPS"
      "VFRCZSD"
      "VFRCZSS" "VPCMOV"
      "VPCOMB" "VPCOMD" "VPCOMQ" "VPCOMUB" "VPCOMUD" "VPCOMUQ" "VPCOMUW" "VPCOMW"
      "VPHADDBD" "VPHADDBQ" "VPHADDBW" "VPHADDDQ" "VPHADDUBD" "VPHADDUBQ" "VPHADDUBW" "VPHADDUDQ" "VPHADDUWD" "VPHADDUWQ" "VPHADDWD" "VPHADDWQ"
      "VPHSUBBW" "VPHSUBDQ" "VPHSUBWD"
      "VPMACSDD" "VPMACSDQH" "VPMACSDQL" "VPMACSSDD" "VPMACSSDQH" "VPMACSSDQL" "VPMACSSWD" "VPMACSSWW" "VPMACSWD" "VPMACSWW" "VPMADCSSWD" "VPMADCSWD"
      "VPPERM"
      "VPROTB"
      "VPROTD" "VPROTQ" "VPROTW"
      "VPSHAB"
      "VPSHAD"
      "VPSHAQ"
      "VPSHAW"
      "VPSHLB"
      "VPSHLD"
      "VPSHLQ"
      "VPSHLW"
      "VBROADCASTI128" "VPBLENDD" "VPBROADCASTB" "VPBROADCASTW" "VPBROADCASTD" "VPBROADCASTQ"
      "VPERMD" "VPERMPD" "VPERMPS" "VPERMQ" "VPERM2I128" "VEXTRACTI128"
      "VINSERTI128" "VPMASKMOVD" "VPMASKMOVQ"
      "VPSLLVD" "VPSLLVQ"
      "VPSRAVD"
      "VPSRLVD" "VPSRLVQ"
      "VGATHERDPD" "VGATHERQPD"
      "VGATHERDPS" "VGATHERQPS"
      "VPGATHERDD" "VPGATHERQD"
      "VPGATHERDQ" "VPGATHERQQ"
      "XABORT" "XBEGIN" "XEND" "XTEST"
      "ANDN" "BEXTR" "BLCI" "BLCIC" "BLSI" "BLSIC" "BLCFILL" "BLSFILL" "BLCMSK" "BLSMSK" "BLSR" "BLCS" "BZHI" "MULX" "PDEP" "PEXT" "RORX" "SARX" "SHLX" "SHRX" "TZCNT" "TZMSK" "T1MSKC"
      "PREFETCHWT1"
      "BNDMK" "BNDCL" "BNDCU" "BNDCN" "BNDMOV" "BNDLDX" "BNDSTX"
      "SHA1MSG1" "SHA1MSG2" "SHA1NEXTE" "SHA1RNDS4" "SHA256MSG1" "SHA256MSG2" "SHA256RNDS2" "VSHA512MSG1" "VSHA512MSG2" "VSHA512RNDS2"
      "VSM3MSG1" "VSM3MSG2" "VSM3RNDS2"
      "VSM4KEY4" "VSM4RNDS4"
      "VBCSTNEBF16PS" "VBCSTNESH2PS" "VCVTNEEBF162PS" "VCVTNEEPH2PS" "VCVTNEOBF162PS" "VCVTNEOPH2PS" "VCVTNEPS2BF16"
      "VPDPBSSD" "VPDPBSSDS" "VPDPBSUD" "VPDPBSUDS" "VPDPBUUD" "VPDPBUUDS"
      "VPMADD52HUQ" "VPMADD52LUQ"
      "KADDB" "KADDD" "KADDQ" "KADDW" "KANDB" "KANDD" "KANDNB" "KANDND" "KANDNQ" "KANDNW" "KANDQ" "KANDW" "KMOVB" "KMOVD" "KMOVQ" "KMOVW" "KNOTB" "KNOTD" "KNOTQ" "KNOTW" "KORB" "KORD" "KORQ" "KORW" "KORTESTB" "KORTESTD" "KORTESTQ" "KORTESTW" "KSHIFTLB" "KSHIFTLD" "KSHIFTLQ" "KSHIFTLW" "KSHIFTRB" "KSHIFTRD" "KSHIFTRQ" "KSHIFTRW" "KTESTB" "KTESTD" "KTESTQ" "KTESTW" "KUNPCKBW" "KUNPCKDQ" "KUNPCKWD" "KXNORB" "KXNORD" "KXNORQ" "KXNORW" "KXORB" "KXORD" "KXORQ" "KXORW"
      "KADD" "KAND" "KANDN" "KMOV" "KNOT" "KOR" "KORTEST" "KSHIFTL" "KSHIFTR" "KTEST" "KUNPCK" "KXNOR" "KXOR"
      "VALIGND" "VALIGNQ" "VBLENDMPD" "VBLENDMPS" "VBROADCASTF32X2" "VBROADCASTF32X4" "VBROADCASTF32X8" "VBROADCASTF64X2" "VBROADCASTF64X4" "VBROADCASTI32X2" "VBROADCASTI32X4" "VBROADCASTI32X8" "VBROADCASTI64X2" "VBROADCASTI64X4" "VCMPEQ_OQPD" "VCMPEQ_OQPS" "VCMPEQ_OQSD" "VCMPEQ_OQSS" "VCOMPRESSPD" "VCOMPRESSPS" "VCVTPD2QQ" "VCVTPD2UDQ" "VCVTPD2UQQ" "VCVTPS2QQ" "VCVTPS2UDQ" "VCVTPS2UQQ" "VCVTQQ2PD" "VCVTQQ2PS" "VCVTSD2USI" "VCVTSS2USI" "VCVTTPD2QQ" "VCVTTPD2UDQ" "VCVTTPD2UQQ" "VCVTTPS2QQ" "VCVTTPS2UDQ" "VCVTTPS2UQQ" "VCVTTSD2USI" "VCVTTSS2USI" "VCVTUDQ2PD" "VCVTUDQ2PS" "VCVTUQQ2PD" "VCVTUQQ2PS" "VCVTUSI2SD" "VCVTUSI2SS" "VDBPSADBW" "VEXP2PD" "VEXP2PS" "VEXPANDPD" "VEXPANDPS" "VEXTRACTF32X4" "VEXTRACTF32X8" "VEXTRACTF64X2" "VEXTRACTF64X4" "VEXTRACTI32X4" "VEXTRACTI32X8" "VEXTRACTI64X2" "VEXTRACTI64X4" "VFIXUPIMMPD" "VFIXUPIMMPS" "VFIXUPIMMSD" "VFIXUPIMMSS" "VFPCLASSPD" "VFPCLASSPS" "VFPCLASSSD" "VFPCLASSSS" "VGATHERPF0DPD" "VGATHERPF0DPS" "VGATHERPF0QPD" "VGATHERPF0QPS" "VGATHERPF1DPD" "VGATHERPF1DPS" "VGATHERPF1QPD" "VGATHERPF1QPS" "VGETEXPPD" "VGETEXPPS" "VGETEXPSD" "VGETEXPSS" "VGETMANTPD" "VGETMANTPS" "VGETMANTSD" "VGETMANTSS" "VINSERTF32X4" "VINSERTF32X8" "VINSERTF64X2" "VINSERTF64X4" "VINSERTI32X4" "VINSERTI32X8" "VINSERTI64X2" "VINSERTI64X4" "VMOVDQA32" "VMOVDQA64" "VMOVDQU16" "VMOVDQU32" "VMOVDQU64" "VMOVDQU8" "VPABSQ" "VPANDD" "VPANDND" "VPANDNQ" "VPANDQ" "VPBLENDMB" "VPBLENDMD" "VPBLENDMQ" "VPBLENDMW" "VPBROADCASTMB2Q" "VPBROADCASTMW2D" "VPCMPEQUB" "VPCMPEQUD" "VPCMPEQUQ" "VPCMPEQUW" "VPCMPGEB" "VPCMPGED" "VPCMPGEQ" "VPCMPGEUB" "VPCMPGEUD" "VPCMPGEUQ" "VPCMPGEUW" "VPCMPGEW" "VPCMPGTUB" "VPCMPGTUD" "VPCMPGTUQ" "VPCMPGTUW" "VPCMPLEB" "VPCMPLED" "VPCMPLEQ" "VPCMPLEUB" "VPCMPLEUD" "VPCMPLEUQ" "VPCMPLEUW" "VPCMPLEW" "VPCMPLTB" "VPCMPLTD" "VPCMPLTQ" "VPCMPLTUB" "VPCMPLTUD" "VPCMPLTUQ" "VPCMPLTUW" "VPCMPLTW" "VPCMPNEQB" "VPCMPNEQD" "VPCMPNEQQ" "VPCMPNEQUB" "VPCMPNEQUD" "VPCMPNEQUQ" "VPCMPNEQUW" "VPCMPNEQW" "VPCMPNGTB" "VPCMPNGTD" "VPCMPNGTQ" "VPCMPNGTUB" "VPCMPNGTUD" "VPCMPNGTUQ" "VPCMPNGTUW" "VPCMPNGTW" "VPCMPNLEB" "VPCMPNLED" "VPCMPNLEQ" "VPCMPNLEUB" "VPCMPNLEUD" "VPCMPNLEUQ" "VPCMPNLEUW" "VPCMPNLEW" "VPCMPNLTB" "VPCMPNLTD" "VPCMPNLTQ" "VPCMPNLTUB" "VPCMPNLTUD" "VPCMPNLTUQ" "VPCMPNLTUW" "VPCMPNLTW" "VPCMPB" "VPCMPD" "VPCMPQ" "VPCMPUB" "VPCMPUD" "VPCMPUQ" "VPCMPUW" "VPCMPW" "VPCOMPRESSD" "VPCOMPRESSQ" "VPCONFLICTD" "VPCONFLICTQ" "VPERMB" "VPERMI2B" "VPERMI2D" "VPERMI2PD" "VPERMI2PS" "VPERMI2Q" "VPERMI2W" "VPERMT2B" "VPERMT2D" "VPERMT2PD" "VPERMT2PS" "VPERMT2Q" "VPERMT2W" "VPERMW" "VPEXPANDD" "VPEXPANDQ" "VPLZCNTD" "VPLZCNTQ" "VPMAXSQ" "VPMAXUQ" "VPMINSQ" "VPMINUQ" "VPMOVB2M" "VPMOVD2M" "VPMOVDB" "VPMOVDW" "VPMOVM2B" "VPMOVM2D" "VPMOVM2Q" "VPMOVM2W" "VPMOVQ2M" "VPMOVQB" "VPMOVQD" "VPMOVQW" "VPMOVSDB" "VPMOVSDW" "VPMOVSQB" "VPMOVSQD" "VPMOVSQW" "VPMOVSWB" "VPMOVUSDB" "VPMOVUSDW" "VPMOVUSQB" "VPMOVUSQD" "VPMOVUSQW" "VPMOVUSWB" "VPMOVW2M" "VPMOVWB" "VPMULLQ" "VPMULTISHIFTQB" "VPORD" "VPORQ" "VPROLD" "VPROLQ" "VPROLVD" "VPROLVQ" "VPRORD" "VPRORQ" "VPRORVD" "VPRORVQ" "VPSCATTERDD" "VPSCATTERDQ" "VPSCATTERQD" "VPSCATTERQQ" "VPSLLVW" "VPSRAQ" "VPSRAVQ" "VPSRAVW" "VPSRLVW" "VPTERNLOGD" "VPTERNLOGQ" "VPTESTMB" "VPTESTMD" "VPTESTMQ" "VPTESTMW" "VPTESTNMB" "VPTESTNMD" "VPTESTNMQ" "VPTESTNMW" "VPXORD" "VPXORQ" "VRANGEPD" "VRANGEPS" "VRANGESD" "VRANGESS" "VRCP14PD" "VRCP14PS" "VRCP14SD" "VRCP14SS" "VRCP28PD" "VRCP28PS" "VRCP28SD" "VRCP28SS" "VREDUCEPD" "VREDUCEPS" "VREDUCESD" "VREDUCESS" "VRNDSCALEPD" "VRNDSCALEPS" "VRNDSCALESD" "VRNDSCALESS" "VRSQRT14PD" "VRSQRT14PS" "VRSQRT14SD" "VRSQRT14SS" "VRSQRT28PD" "VRSQRT28PS" "VRSQRT28SD" "VRSQRT28SS" "VSCALEFPD" "VSCALEFPS" "VSCALEFSD" "VSCALEFSS" "VSCATTERDPD" "VSCATTERDPS" "VSCATTERPF0DPD" "VSCATTERPF0DPS" "VSCATTERPF0QPD" "VSCATTERPF0QPS" "VSCATTERPF1DPD" "VSCATTERPF1DPS" "VSCATTERPF1QPD" "VSCATTERPF1QPS" "VSCATTERQPD" "VSCATTERQPS" "VSHUFF32X4" "VSHUFF64X2" "VSHUFI32X4" "VSHUFI64X2"
      "RDPKRU" "WRPKRU"
      "RDPID"
      "CLFLUSHOPT" "CLWB" "PCOMMIT"
      "CLZERO"
      "PTWRITE"
      "CLDEMOTE" "MOVDIRI" "MOVDIR64B" "PCONFIG" "TPAUSE" "UMONITOR" "UMWAIT" "WBNOINVD"
      "GF2P8AFFINEINVQB" "VGF2P8AFFINEINVQB" "GF2P8AFFINEQB" "VGF2P8AFFINEQB" "GF2P8MULB" "VGF2P8MULB"
      "VPCOMPRESSB" "VPCOMPRESSW" "VPEXPANDB" "VPEXPANDW" "VPSHLDW" "VPSHLDD" "VPSHLDQ" "VPSHLDVW" "VPSHLDVD" "VPSHLDVQ" "VPSHRDW" "VPSHRDD" "VPSHRDQ" "VPSHRDVW" "VPSHRDVD" "VPSHRDVQ"
      "VPDPBUSD" "VPDPBUSDS" "VPDPWSSD" "VPDPWSSDS"
      "VPOPCNTB" "VPOPCNTW" "VPOPCNTD" "VPOPCNTQ" "VPSHUFBITQMB"
      "V4FMADDPS" "V4FNMADDPS" "V4FMADDSS" "V4FNMADDSS"
      "V4DPWSSDS" "V4DPWSSD"
      "ENCLS" "ENCLU" "ENCLV"
      "CLRSSBSY" "ENDBR32" "ENDBR64" "INCSSPD" "INCSSPQ" "RDSSPD" "RDSSPQ" "RSTORSSP" "SAVEPREVSSP" "SETSSBSY" "WRUSSD" "WRUSSQ" "WRSSD" "WRSSQ"
      "ENQCMD" "ENQCMDS" "SERIALIZE" "XRESLDTRK" "XSUSLDTRK"
      "VCVTNE2PS2BF16" "VDPBF16PS"
      "VP2INTERSECTD"
      "LDTILECFG" "STTILECFG" "TDPBF16PS" "TDPBSSD" "TDPBSUD" "TDPBUSD" "TDPBUUD" "TILELOADD" "TILELOADDT1" "TILERELEASE" "TILESTORED" "TILEZERO"
      "VADDPH" "VADDSH" "VCMPPH" "VCMPSH" "VCOMISH" "VCVTDQ2PH" "VCVTPD2PH" "VCVTPH2DQ" "VCVTPH2PD" "VCVTPH2PSX" "VCVTPH2QQ" "VCVTPH2UDQ" "VCVTPH2UQQ" "VCVTPH2UW" "VCVTPH2W" "VCVTQQ2PH" "VCVTSD2SH" "VCVTSH2SD" "VCVTSH2SI" "VCVTSH2SS" "VCVTSH2USI" "VCVTSI2SH" "VCVTSS2SH" "VCVTTPH2DQ" "VCVTTPH2QQ" "VCVTTPH2UDQ" "VCVTTPH2UQQ" "VCVTTPH2UW" "VCVTTPH2W" "VCVTTSH2SI" "VCVTTSH2USI" "VCVTUDQ2PH" "VCVTUQQ2PH" "VCVTUSI2SH" "VCVTUW2PH" "VCVTW2PH" "VDIVPH" "VDIVSH" "VFCMADDCPH" "VFMADDCPH" "VFCMADDCSH" "VFMADDCSH" "VFCMULCPCH" "VFMULCPCH" "VFCMULCSH" "VFMULCSH" "VFMADDSUB132PH" "VFMADDSUB213PH" "VFMADDSUB231PH" "VFMSUBADD132PH" "VFMSUBADD213PH" "VFMSUBADD231PH" "VPMADD132PH" "VPMADD213PH" "VPMADD231PH" "VFMADD132PH" "VFMADD213PH" "VFMADD231PH" "VPMADD132SH" "VPMADD213SH" "VPMADD231SH" "VPNMADD132SH" "VPNMADD213SH" "VPNMADD231SH" "VPMSUB132PH" "VPMSUB213PH" "VPMSUB231PH" "VFMSUB132PH" "VFMSUB213PH" "VFMSUB231PH" "VPMSUB132SH" "VPMSUB213SH" "VPMSUB231SH" "VPNMSUB132SH" "VPNMSUB213SH" "VPNMSUB231SH" "VFPCLASSPH" "VFPCLASSSH" "VGETEXPPH" "VGETEXPSH" "VGETMANTPH" "VGETMANTSH" "VGETMAXPH" "VGETMAXSH" "VGETMINPH" "VGETMINSH" "VMOVSH" "VMOVW" "VMULPH" "VMULSH" "VRCPPH" "VRCPSH" "VREDUCEPH" "VREDUCESH" "VENDSCALEPH" "VENDSCALESH" "VRSQRTPH" "VRSQRTSH" "VSCALEFPH" "VSCALEFSH" "VSQRTPH" "VSQRTSH" "VSUBPH" "VSUBSH" "VUCOMISH"
      "AADD" "AAND" "AXOR"
      "CLUI" "SENDUIPI" "STUI" "TESTUI" "UIRET"
      "CMPBEXADD" "CMPBEXADD" "CMPBEXADD" "CMPBXADD" "CMPBXADD" "CMPBXADD" "CMPLEXADD" "CMPLEXADD" "CMPLEXADD" "CMPLXADD" "CMPLXADD" "CMPLXADD" "CMPNBEXADD" "CMPNBEXADD" "CMPNBEXADD" "CMPNBXADD" "CMPNBXADD" "CMPNBXADD" "CMPNLEXADD" "CMPNLEXADD" "CMPNLEXADD" "CMPNLXADD" "CMPNLXADD" "CMPNLXADD" "CMPNOXADD" "CMPNOXADD" "CMPNPXADD" "CMPNPXADD" "CMPNSXADD" "CMPNSXADD" "CMPNZXADD" "CMPNZXADD" "CMPOXADD" "CMPOXADD" "CMPPXADD" "CMPPXADD" "CMPSXADD" "CMPSXADD" "CMPZXADD" "CMPZXADD"
      "ERETS" "ERETU" "LKGS"
      "WRMSRNS" "RDMSRLIST" "WRMSRLIST"
      "HRESET"
      "HINT_NOP0" "HINT_NOP1" "HINT_NOP2" "HINT_NOP3" "HINT_NOP4" "HINT_NOP5" "HINT_NOP6" "HINT_NOP7" "HINT_NOP8" "HINT_NOP9" "HINT_NOP10" "HINT_NOP11" "HINT_NOP12" "HINT_NOP13" "HINT_NOP14" "HINT_NOP15" "HINT_NOP16" "HINT_NOP17" "HINT_NOP18" "HINT_NOP19" "HINT_NOP20" "HINT_NOP21" "HINT_NOP22" "HINT_NOP23" "HINT_NOP24" "HINT_NOP25" "HINT_NOP26" "HINT_NOP27" "HINT_NOP28" "HINT_NOP29" "HINT_NOP30" "HINT_NOP31" "HINT_NOP32" "HINT_NOP33" "HINT_NOP34" "HINT_NOP35" "HINT_NOP36" "HINT_NOP37" "HINT_NOP38" "HINT_NOP39" "HINT_NOP40" "HINT_NOP41" "HINT_NOP42" "HINT_NOP43" "HINT_NOP44" "HINT_NOP45" "HINT_NOP46" "HINT_NOP47" "HINT_NOP48" "HINT_NOP49" "HINT_NOP50" "HINT_NOP51" "HINT_NOP52" "HINT_NOP53" "HINT_NOP54" "HINT_NOP55" "HINT_NOP56" "HINT_NOP57" "HINT_NOP58" "HINT_NOP59" "HINT_NOP60" "HINT_NOP61" "HINT_NOP62" "HINT_NOP63")
    "FASM instructions (SOURCE/TABLES.INC) for `fasm-mode`."))

(eval-and-compile
  (defconst fasm-types
    '("byte" "word" "dword" "fword" "pword" "qword" "tbyte" "tword" "dqword" "xword" "qqword" "yword"
      "file" "db" "rb" "dw" "du" "rw" "dd" "rd" "dp" "df" "rp" "rf" "dq" "rq" "dt" "rt"
      "ptr" "dup")
    "FASM types (SOURCE/TABLES.INC) for `fasm-mode`."))

(eval-and-compile
  (defconst fasm-prefix
    '("invoke" "stdcall" "ccall" "cinvoke" "proc" "comcall" "cominvk"
      "lock" "times")
    "FASM prefixes (SOURCE/TABLES.INC) for `fasm-mode`."))

(eval-and-compile
  (defconst fasm-pp-directives
    '("mod" "rva" "plt" "as" "at" "on" "defined" "signed" 
      "eqtype" "lt" "le" "gt" "ge" "eq" "neq" "false" "true"
      "from" "relativeto" "used" "binary" "fixups"  
      "static" "dynamic" "linkinfo" "readable" "writable"
      "shareable" "writeable" "executable" "notpageable"
      "discardable" "linkremove" "interpreter" "code" "data"
      "console" "native" "large" "NX" "EFI" "EFIboot" "EFIruntime"
      "MZ" "PE" "PE64" "GUI" "DLL" "WDM" "MS" "COFF" "ELF" "ELF64"
      "ZERO?" "CARRY?" "SIGN?" "OVERFLOW?" "PARITY?")
    "FASM preprocessor directives (SOURCE/TABLES.INC) for `fasm-mode`."))

(defconst fasm-nonlocal-label-rexexp
  "\\(\\_<[a-zA-Z_?][a-zA-Z0-9_$#@~?]*\\_>\\)\\s-*:"
  "Regexp for `fasm-mode` for matching nonlocal labels.")

(defconst fasm-local-label-regexp
  "\\(\\_<\\.[a-zA-Z_?][a-zA-Z0-9_$#@~?]*\\_>\\)\\(?:\\s-*:\\)?"
  "Regexp for `fasm-mode` for matching local labels.")

(defconst fasm-label-regexp
  (concat fasm-nonlocal-label-rexexp "\\|" fasm-local-label-regexp)
  "Regexp for `fasm-mode` for matching labels.")

(defconst fasm-constant-regexp
  "\\_<$?[-+]?[0-9][-+_0-9A-Fa-fHhXxDdTtQqOoBbYyeE.]*\\_>"
  "Regexp for `fasm-mode` for matching numeric constants.")

(defconst fasm-section-name-regexp
  "^\\s-*section[ \t]+\\(\\_<\\.[a-zA-Z0-9_$#@~.?]+\\_>\\)"
  "Regexp for `fasm-mode` for matching section names.")

(defmacro fasm--opt (keywords)
  "Prepare KEYWORDS for `looking-at`."
  `(eval-when-compile
     (regexp-opt ,keywords 'symbols)))

(defconst fasm-imenu-generic-expression
  `((nil ,(concat "^\\s-*" fasm-nonlocal-label-rexexp) 1)
    (nil ,(concat (fasm--opt '("define" "macro"))
                  "\\s-+\\([a-zA-Z0-9_$#@~.?]+\\)") 2))
  "Expressions for `imenu-generic-expression`.")

(defconst fasm-full-instruction-regexp
  (eval-when-compile
    (let ((pfx (fasm--opt fasm-prefix))
          (ins (fasm--opt fasm-instructions)))
      (concat "^\\(" pfx "\\s-+\\)?" ins "$")))
  "Regexp for `fasm-mode` matching a valid full FASM instruction field.
This includes prefixes or modifiers (eg \"mov\", \"rep mov\", etc match)")

(defconst fasm-font-lock-keywords
  `((,fasm-section-name-regexp (1 'fasm-section-name))
    (,(fasm--opt fasm-registers) . 'fasm-registers)
    (,(fasm--opt fasm-prefix) . 'fasm-prefix)
    (,(fasm--opt fasm-types) . 'fasm-types)
    (,(fasm--opt fasm-instructions) . 'fasm-instructions)
    (,(fasm--opt fasm-pp-directives) . 'fasm-preprocessor)
    (,(concat "^\\s-*" fasm-nonlocal-label-rexexp) (1 'fasm-labels))
    (,(concat "^\\s-*" fasm-local-label-regexp) (1 'fasm-local-labels))
    (,fasm-constant-regexp . 'fasm-constant)
    (,(fasm--opt fasm-directives) . 'fasm-directives))
  "Keywords for `fasm-mode`.")

(defconst fasm-mode-syntax-table
  (with-syntax-table (copy-syntax-table)
    (modify-syntax-entry ?_  "_")
    (modify-syntax-entry ?#  "_")
    (modify-syntax-entry ?@  "_")
    (modify-syntax-entry ?\? "_")
    (modify-syntax-entry ?~  "_")
    (modify-syntax-entry ?\. "w")
    (modify-syntax-entry ?\; "<")
    (modify-syntax-entry ?\n ">")
    (modify-syntax-entry ?\" "\"")
    (modify-syntax-entry ?\' "\"")
    (syntax-table))
  "Syntax table for `fasm-mode`.")

(defvar fasm-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (define-key map (kbd ":") #'fasm-colon)
      (define-key map (kbd ";") #'fasm-comment)
      (define-key map [remap join-line] #'fasm-join-line)))
  "Key bindings for `fasm-mode`.")

(defun fasm-colon ()
  "Insert a colon and convert the current line into a label."
  (interactive)
  (call-interactively #'self-insert-command)
  (fasm-indent-line))

(defun fasm-indent-line ()
  "Indent current line (or insert a tab) as FASM assembly code.
This will be called by `indent-for-tab-command` when TAB is
pressed. We indent the entire line as appropriate whenever POINT
is not immediately after a mnemonic; otherwise, we insert a tab."
  (interactive)
  (let ((before      ; text before point and after indentation
         (save-excursion
           (let ((point (point))
                 (bti (progn (back-to-indentation) (point))))
             (buffer-substring-no-properties bti point)))))
    (if (string-match fasm-full-instruction-regexp before)
        ;; We are immediately after a mnemonic
        (cl-case fasm-after-mnemonic-whitespace
          (:tab   (insert "\t"))
          (:space (insert-char ?\s fasm-basic-offset)))
      ;; We're literally anywhere else, indent the whole line
      (let ((orig (- (point-max) (point))))
        (back-to-indentation)
        (if (or (looking-at (fasm--opt fasm-directives))
                (looking-at (fasm--opt fasm-pp-directives))
                (looking-at "{")
                (looking-at "}")
                (looking-at "\\\\{")
                (looking-at "\\\\}")
                (looking-at ";;+")
                (looking-at fasm-label-regexp))
            (indent-line-to 0)
          (indent-line-to fasm-basic-offset))
        (when (> (- (point-max) orig) (point))
          (goto-char (- (point-max) orig)))))))

(defun fasm--current-line ()
  "Return the current line as a string."
  (save-excursion
    (let ((start (progn (beginning-of-line) (point)))
          (end (progn (end-of-line) (point))))
      (buffer-substring-no-properties start end))))

(defun fasm--empty-line-p ()
  "Return non-nil if current line has non-whitespace."
  (not (string-match-p "\\S-" (fasm--current-line))))

(defun fasm--line-has-comment-p ()
  "Return non-nil if current line contains a comment."
  (save-excursion
    (end-of-line)
    (nth 4 (syntax-ppss))))

(defun fasm--line-has-non-comment-p ()
  "Return non-nil of the current line has code."
  (let* ((line (fasm--current-line))
         (match (string-match-p "\\S-" line)))
    (when match
      (not (eql ?\; (aref line match))))))

(defun fasm--inside-indentation-p ()
  "Return non-nil if point is within the indentation."
  (save-excursion
    (let ((point (point))
          (start (progn (beginning-of-line) (point)))
          (end (progn (back-to-indentation) (point))))
      (and (<= start point) (<= point end)))))

(defun fasm-comment-indent ()
  "Compute desired indentation for comment on the current line."
  comment-column)

(defun fasm-insert-comment ()
  "Insert a comment if the current line doesn’t contain one."
  (let ((comment-insert-comment-function nil))
    (comment-indent)))

(defun fasm-comment (&optional arg)
  "Begin or edit a comment with context-sensitive placement.

The right-hand comment gutter is far away from the code, so this
command uses the mark ring to help move back and forth between
code and the comment gutter.

* If no comment gutter exists yet, mark the current position and
  jump to it.
* If already within the gutter, pop the top mark and return to
  the code.
* If on a line with no code, just insert a comment character.
* If within the indentation, just insert a comment character.
  This is intended prevent interference when the intention is to
  comment out the line.

With a prefix arg, kill the comment on the current line with
`comment-kill`."
  (interactive "p")
  (if (not (eql arg 1))
      (comment-kill nil)
    (cond
     ;; Empty line, or inside a string? Insert.
     ((or (fasm--empty-line-p) (nth 3 (syntax-ppss)))
      (insert ";"))
     ;; Inside the indentation? Comment out the line.
     ((fasm--inside-indentation-p)
      (insert ";"))
     ;; Currently in a right-side comment? Return.
     ((and (fasm--line-has-comment-p)
           (fasm--line-has-non-comment-p)
           (nth 4 (syntax-ppss)))
      (goto-char (mark))
      (pop-mark))
     ;; Line has code? Mark and jump to right-side comment.
     ((fasm--line-has-non-comment-p)
      (push-mark)
      (comment-indent))
     ;; Otherwise insert.
     ((insert ";")))))

(defun fasm-join-line (join-following-p)
  "Like `join-line`, but use a tab when joining with a label."
  (interactive "*P")
  (join-line join-following-p)
  (if (looking-back fasm-label-regexp (line-beginning-position))
      (let ((column (current-column)))
        (cond ((< column fasm-basic-offset)
               (delete-char 1)
               (insert-char ?\t))
              ((and (= column fasm-basic-offset) (eql ?: (char-before)))
               (delete-char 1))))
    (fasm-indent-line)))

;;;###autoload
(define-derived-mode fasm-mode prog-mode "FASM"
  "Major mode for editing FASM assembly programs."
  :group 'fasm-mode
  (make-local-variable 'indent-line-function)
  (make-local-variable 'comment-start)
  (make-local-variable 'comment-insert-comment-function)
  (make-local-variable 'comment-indent-function)
  (setf font-lock-defaults '(fasm-font-lock-keywords nil :case-fold)
        indent-line-function #'fasm-indent-line
        comment-start ";"
        comment-indent-function #'fasm-comment-indent
        comment-insert-comment-function #'fasm-insert-comment
        imenu-generic-expression fasm-imenu-generic-expression))

(provide 'fasm-mode)

;;; fasm-mode.el ends here
