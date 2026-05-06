----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    
    type fsm_state is (clrdis, regA, regB, result);
    
    signal f_Q, f_Q_next : fsm_state;

begin

f_Q_next <= regA when (f_Q = clrdis) else
            regB when (f_Q = regA) else
            result when (f_Q = regB) else
            clrdis when (f_Q = result);
            
with f_Q select
    o_cycle <= "0001" when clrdis,
               "0010" when regA,
               "0100" when regB,
               "1000" when result;
       
-- process
process (i_adv) 
    begin
        if i_reset = '1' then 
            f_Q <= clrdis;
        elsif rising_edge(i_adv) then
			f_Q <= f_Q_next;
		end if;
	end process;
	  
end FSM;
