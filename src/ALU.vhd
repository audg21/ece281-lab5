----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0); -- ALU CONTROL
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

    component ripple_adder is
        port (
            A     : in std_logic_vector (7 downto 0);
            B     : in std_logic_vector (7 downto 0);
            Cin   : in std_logic;
            S     : out std_logic_vector (7 downto 0);
            Cout  : out std_logic
            );
        end component ripple_adder;

signal w_i_B : std_logic_vector (7 downto 0);
signal w_A_and_B : std_logic_vector (7 downto 0);
signal w_A_or_B : std_logic_vector (7 downto 0);
signal w_adder_result : std_logic_vector (7 downto 0);
signal w_Cout : std_logic;
signal w_ALU_result : std_logic_vector (7 downto 0);

begin

ripple_adder_inst : ripple_adder
Port Map ( 
A => i_A,
B => w_i_B, 
Cin => i_op(0),
S => w_adder_result,
Cout =>  w_Cout
);

w_i_B <=  i_B when i_op(0) = '0' else
          not(i_B);

w_A_and_B <= i_A and i_B;

w_A_or_B <= i_A or i_B;

w_ALU_Result <= w_adder_result when i_op = "000" else 
                w_adder_result when i_op = "001" else
                w_A_and_B when i_op = "010" else
                 w_A_or_B when i_op = "011";
       
o_result <= w_ALU_Result;
 --negative flag   
o_flags(3) <= w_ALU_result(7);  
 --zero
o_flags(2) <= not (w_ALU_result(7) or w_ALU_result(6) or w_ALU_result(5) or w_ALU_result(4) or w_ALU_result(3) or w_ALU_result(2) or w_ALU_result(1) or w_ALU_result(0));    
-- carry flag
o_flags(1) <= not (i_op(1)) and (w_Cout);
-- overflow
o_flags(0) <= (not(i_A(7) xor i_B(7) xor i_op(0))) and (i_A(7) xor w_adder_result(7)) and (not(i_op(1)));


end Behavioral;