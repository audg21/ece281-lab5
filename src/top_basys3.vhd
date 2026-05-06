--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; -- asynchronous
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals

component controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0); -- ALU CONTROL
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
end component;

component sevenseg_decoder is
    Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
end component;

component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
end component;

component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
end component;
--signal
signal w_o_cycle : STD_LOGIC_VECTOR (3 downto 0);
signal w_o_clk   : STD_LOGIC;
signal w_i_Hex : std_logic_vector (3 downto 0);

signal w_i_RegA : STD_LOGIC_VECTOR (7 downto 0);
signal w_i_RegB : std_logic_vector (7 downto 0);
signal w_sw: std_logic_vector (7 downto 0);
signal w_o_result : std_logic_vector (7 downto 0);

signal w_i_bin: std_logic_vector(7 downto 0);
signal w_o_sign: std_logic;
signal w_o_hund: std_logic_vector(3 downto 0);
signal w_o_tens:std_logic_vector(3 downto 0);
signal w_o_ones: std_logic_vector(3 downto 0);


signal w_sign_MUX : std_logic_vector (6 downto 0);
signal w_bin_MUX : std_logic_vector (7 downto 0);
signal w_seg_mux : std_logic_vector (6 downto 0);
signal w_seg_n : std_logic_vector (6 downto 0);

signal w_an : std_logic_vector (3 downto 0);
signal w_clrdisp : std_logic_vector (3 downto 0);

begin
-- PORT MAPS ----------------------------------------
-- change K value to ... (elevator and generic map)
controller_fsm_inst : controller_fsm 
Port Map (
i_reset => btnU,
i_adv => btnC,
o_cycle => w_o_cycle
);

clock_divider_inst : clock_divider
generic map (k_DIV => 12500)
Port Map (
    i_clk => clk,
    i_reset => btnL,
	o_clk => w_o_clk
	);
	
ALU_inst : ALU
Port Map (
         i_A => w_i_RegA,
         i_B => w_i_RegB,
         i_op => sw(2 downto 0),
         o_result => w_o_result,
         o_flags => led(15 downto 12)
         );
         
sevenseg_decoder_inst : sevenseg_decoder
 Port Map (i_Hex => w_i_Hex,
           o_seg_n => w_seg_n
);

TDM4_inst : TDM4
	generic map (k_WIDTH => 4)-- bits in input and output
    Port Map ( 
           i_clk => w_o_clk,
           i_reset 	=> btnU,
           i_D3 => "0000",	--Hard coded to nothing.	
		   i_D2 => w_o_hund, 		
		   i_D1 => w_o_tens,	
		   i_D0 => w_o_ones,		
		   o_data => w_i_Hex,
		   o_sel => w_an
	);
twos_comp_inst : twos_comp 
    port map (
        i_bin => w_bin_MUX,
        o_sign => w_o_sign,
        o_hund => w_o_hund,
        o_tens => w_o_tens,
        o_ones => w_o_ones
        );

	--add more components
	-- CONCURRENT STATEMENTS ----------------------------
process (w_o_cycle(1)) 
    begin
        if btnU = '1' then 
            w_i_RegA <= "00000000";
        elsif rising_edge(w_o_cycle(1)) then
			w_i_RegA <= w_sw;
		end if;
	end process;
process (w_o_cycle(2)) 
    begin
        if btnU = '1' then 
            w_i_RegB <= "00000000";
        elsif rising_edge(w_o_cycle(2)) then
			w_i_RegB <= w_sw;
		end if;
	end process;
	
-- MUX #1
w_sign_MUX <= "1111111" when (w_o_sign = '0') else
              "1111110" when (w_o_sign = '1');
              
-- MUX #2
w_bin_MUX <= w_i_RegA when (w_o_cycle = "0010") else
             w_i_RegB when (w_o_cycle = "0100") else
             w_o_result when (w_o_cycle = "1000") else
             "00000000";
--MUX #3
w_seg_mux <= w_sign_MUX when (w_an = "0111") else --Passes the sign segment displayt val
             w_seg_n;
             
seg <= w_seg_mux;



-- MUX 4
w_clrdisp <= "1111" when (w_o_cycle = "0001") else
             w_an;
             
an <= w_clrdisp;

w_sw <= sw; -- connect switches
	
end top_basys3_arch;