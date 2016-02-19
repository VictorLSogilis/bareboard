------------------------------------------------------------------------------
--                                                                          --
--                    Copyright (C) 2015, AdaCore                           --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of STMicroelectronics nor the names of its       --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

with STM32_SVD.DMA2D; use STM32_SVD.DMA2D;

package body STM32.DMA2D.Polling is

   Transferring : Boolean := False;

   ---------------------------
   -- DMA2D_InitAndTransfer --
   ---------------------------

   procedure DMA2D_Init_Transfer
   is
   begin
      Transferring := True;
      DMA2D_Periph.IFCR.CTCIF := 1;
      DMA2D_Periph.IFCR.CCTCIF := 1;
      DMA2D_Periph.CR.START := DMA2D_START'Enum_Rep (Start);
   end DMA2D_Init_Transfer;

   -------------------------
   -- DMA2D_Wait_Transfer --
   -------------------------

   procedure DMA2D_Wait_Transfer
   is
   begin
      if not Transferring then
         return;
      end if;

      Transferring := False;

      if DMA2D_Periph.ISR.CEIF = 1 then --  Conf error
         raise Constraint_Error with "DMA2D Configuration error";
      elsif DMA2D_Periph.ISR.TEIF = 1 then -- Transfer error
         raise Constraint_Error with "DMA2D Transfer error";
      else
         while DMA2D_Periph.ISR.TCIF = 0 loop --  Transfer completed
            if DMA2D_Periph.ISR.TEIF = 1 then
               raise Constraint_Error with "DMA2D Transfer error";
            end if;
         end loop;

         DMA2D_Periph.IFCR.CTCIF := 1; --  Clear the TCIF flag
      end if;
   end DMA2D_Wait_Transfer;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      STM32.DMA2D.DMA2D_Init
        (Init => DMA2D_Init_Transfer'Access,
         Wait => DMA2D_Wait_Transfer'Access);
   end Initialize;

end STM32.DMA2D.Polling;