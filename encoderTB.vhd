library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity encoder_tb is
end encoder_tb;

architecture sim of encoder_tb is
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal symbol  : std_logic := '0';
    signal low_out : std_logic_vector(7 downto 0);

    constant clk_period : time := 10 ns;

begin
    uut: entity work.encoder
        port map (
            clk     => clk,
            rst     => rst,
            symbol  => symbol,
            low_out => low_out
        );
    clk_process : process
    begin
        while now < 200 ns loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;
	 
    stim_proc: process
    begin		
        --rst <= '1';
        --wait for 20 ns;
        --rst <= '0';
        --wait for 10 ns;
		  symbol <= '1'; wait for clk_period;
        symbol <= '0'; wait for clk_period;
        symbol <= '1'; wait for clk_period;
        symbol <= '1'; wait for clk_period; 
        symbol <= '0'; wait for clk_period;
        symbol <= '1'; wait for clk_period;
		  
        wait;
    end process;	 

end sim;