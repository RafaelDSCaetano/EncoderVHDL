library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity encoder is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        symbol   : in  std_logic;
        low_out  : out std_logic_vector(7 downto 0)
    );  
end encoder;

architecture ARQ of encoder is 
    signal s_range : unsigned(7 downto 0) := x"FF"; 
    signal s_low   : unsigned(7 downto 0) := x"00";
    
    -- Probabilidades na escala de 8 bits
    constant P0 : unsigned(7 downto 0) := "00011010"; -- 26 (0.1)
    constant P1 : unsigned(7 downto 0) := "11100110"; -- 230 (0.9)
    constant C1 : unsigned(7 downto 0) := "00011010"; -- C(1) = P(0)
begin
    process(clk, rst)
        -- variable of 16 bits to save the results.
        variable v_range_ext : unsigned(15 downto 0);
        variable v_low_ext   : unsigned(15 downto 0);
    begin
        if rst = '1' then
            s_range <= x"FF";
            s_low   <= x"00";
        elsif rising_edge(clk) then
            if symbol = '0' then
				 -- Calcula o novo range
						v_range_ext := s_range * P0;
				 -- Pega apenas os 8 bits mais significativos
						s_range     <= v_range_ext(15 downto 8); 
                
            else
				 -- Calcula Low em 16 bits
						v_low_ext   := s_range * C1;
				 -- Soma ao Low atual a parte mais significativa
						s_low <= s_low + v_low_ext(15 downto 8);
				 -- Calcula range em 16 bits
						v_range_ext := s_range * P1;
				 -- parte mais significativa do range
						s_range     <= v_range_ext(15 downto 8);
            end if;
        end if;
    end process;

    low_out <= std_logic_vector(s_low);
end ARQ;