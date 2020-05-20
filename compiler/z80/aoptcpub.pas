 {
    Copyright (c) 1998-2002 by Jonas Maebe, member of the Free Pascal
    Development Team

    This unit contains several types and constants necessary for the
    optimizer to work on the Z80 architecture

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
Unit aoptcpub; { Assembler OPTimizer CPU specific Base }

{$i fpcdefs.inc}

{ enable the following define if memory references can have a scaled index }
{ define RefsHaveScale}

{ enable the following define if memory references can have a segment }
{ override                                                            }

{ define RefsHaveSegment}

Interface

Uses
  cpubase,
  cgbase,
  aasmcpu,aasmtai,
  AOptBase;

Type

{ type of a normal instruction }
  TInstr = Taicpu;
  PInstr = ^TInstr;

{ ************************************************************************* }
{ **************************** TCondRegs ********************************** }
{ ************************************************************************* }
{ Info about the conditional registers                                      }
  TCondRegs = Object
    Constructor Init;
    Destructor Done;
  End;

{ ************************************************************************* }
{ **************************** TAoptBaseCpu ******************************* }
{ ************************************************************************* }

  TAoptBaseCpu = class(TAoptBase)
    { checks whether reading the value in reg1 depends on the value of reg2. This
      is very similar to SuperRegisterEquals, except it takes into account that
      R_SUBH and R_SUBL are independendent (e.g. reading from AL does not
      depend on the value in AH). }
    function Reg1ReadDependsOnReg2(reg1, reg2: tregister): boolean;
    function RegModifiedByInstruction(Reg: TRegister; p1: tai): boolean; override;
  End;


{ ************************************************************************* }
{ ******************************* Constants ******************************* }
{ ************************************************************************* }
Const

{ the maximum number of things (registers, memory, ...) a single instruction }
{ changes                                                                    }

  MaxCh = 2;

{ the maximum number of operands an instruction has }

  MaxOps = 2;

{Oper index of operand that contains the source (reference) with a load }
{instruction                                                            }

  LoadSrc = 1;

{Oper index of operand that contains the destination (register) with a load }
{instruction                                                                }

  LoadDst = 0;

{Oper index of operand that contains the source (register) with a store }
{instruction                                                            }

  StoreSrc = 1;

{Oper index of operand that contains the destination (reference) with a load }
{instruction                                                                 }

  StoreDst = 0;

  aopt_uncondjmp = [A_JP,A_JR];
  aopt_condjmp = [A_JP,A_JR];

Implementation

{ ************************************************************************* }
{ **************************** TCondRegs ********************************** }
{ ************************************************************************* }
  Constructor TCondRegs.init;
    Begin
    End;

  Destructor TCondRegs.Done; {$ifdef inl} inline; {$endif inl}
    Begin
    End;


  function TAoptBaseCpu.Reg1ReadDependsOnReg2(reg1, reg2: tregister): boolean;
    begin
      case reg1 of
        NR_AF:
          result:=(reg2=NR_A) or (reg2=NR_AF) or SuperRegistersEqual(reg2,NR_DEFAULTFLAGS);
        NR_A:
          result:=(reg2=NR_A) or (reg2=NR_AF);
        NR_F:
          result:=SuperRegistersEqual(reg2,NR_DEFAULTFLAGS);
        NR_BC:
          result:=(reg2=NR_B) or (reg2=NR_C) or (reg2=NR_BC);
        NR_B:
          result:=(reg2=NR_B) or (reg2=NR_BC);
        NR_C:
          result:=(reg2=NR_C) or (reg2=NR_BC);
        NR_DE:
          result:=(reg2=NR_D) or (reg2=NR_E) or (reg2=NR_DE);
        NR_D:
          result:=(reg2=NR_D) or (reg2=NR_DE);
        NR_E:
          result:=(reg2=NR_E) or (reg2=NR_DE);
        NR_HL:
          result:=(reg2=NR_H) or (reg2=NR_L) or (reg2=NR_HL);
        NR_H:
          result:=(reg2=NR_H) or (reg2=NR_HL);
        NR_L:
          result:=(reg2=NR_L) or (reg2=NR_HL);
        NR_AF_:
          result:=(reg2=NR_A_) or (reg2=NR_AF_) or SuperRegistersEqual(reg2,NR_F_);
        NR_A_:
          result:=(reg2=NR_A_) or (reg2=NR_AF_);
        NR_F_:
          result:=SuperRegistersEqual(reg2,NR_F_);
        NR_BC_:
          result:=(reg2=NR_B_) or (reg2=NR_C_) or (reg2=NR_BC_);
        NR_B_:
          result:=(reg2=NR_B_) or (reg2=NR_BC_);
        NR_C_:
          result:=(reg2=NR_C_) or (reg2=NR_BC_);
        NR_DE_:
          result:=(reg2=NR_D_) or (reg2=NR_E_) or (reg2=NR_DE_);
        NR_D_:
          result:=(reg2=NR_D_) or (reg2=NR_DE_);
        NR_E_:
          result:=(reg2=NR_E_) or (reg2=NR_DE_);
        NR_HL_:
          result:=(reg2=NR_H_) or (reg2=NR_L_) or (reg2=NR_HL_);
        NR_H_:
          result:=(reg2=NR_H_) or (reg2=NR_HL_);
        NR_L_:
          result:=(reg2=NR_L_) or (reg2=NR_HL_);
        else
          result:=reg1=reg2;
      end;
    end;


  function TAoptBaseCpu.RegModifiedByInstruction(Reg: TRegister; p1: tai): boolean;
    var
      i : Longint;
    begin
      result:=false;
      for i:=0 to taicpu(p1).ops-1 do
        if (taicpu(p1).oper[i]^.typ=top_reg) and Reg1ReadDependsOnReg2(Reg,taicpu(p1).oper[i]^.reg) and (taicpu(p1).spilling_get_operation_type(i) in [operand_write,operand_readwrite]) then
          begin
            result:=true;
            exit;
          end;
    end;

End.
