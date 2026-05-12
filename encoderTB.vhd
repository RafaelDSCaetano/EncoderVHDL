library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity encoder_tb is
end encoder_tb;

architecture sim of encoder_tb is
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal symbol      : std_logic := '0';
    signal read_enable : std_logic := '0';
    signal flush       : std_logic := '0';
    signal bit_stream  : std_logic_vector(31 downto 0);
    signal bits_valid  : unsigned(5 downto 0);
    signal low_out     : std_logic_vector(7 downto 0);
    
    signal sim_done    : boolean := false;
    constant CLK_PERIOD : time := 10 ns;

    function to_bstring(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            if slv(i) = '1' then
                result(slv'high - i + 1) := '1';
            else
                result(slv'high - i + 1) := '0';
            end if;
        end loop;
        return result;
    end function;

begin
    uut: entity work.encoder
        port map (
            clk         => clk,
            rst         => rst,
            symbol      => symbol,
            read_enable => read_enable,
            flush       => flush,
            bit_stream  => bit_stream,
            bits_valid  => bits_valid,
            low_out     => low_out
        );

    clk_process: process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_proc: process
        file     sym_file : text;
        variable v_line   : line;
        variable v_sym    : std_logic;
		  variable v_char   : character;
        variable v_ok     : boolean;
        file     out_file   : text;
        variable v_out_line : line;
        variable v_sym_count : integer := 0;
    begin
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;

        file_open(sym_file, "input.txt", read_mode);

        while not endfile(sym_file) loop
            readline(sym_file, v_line);
            
            -- Enquanto ainda houver caracteres na linha lida
            while v_line'length > 0 loop
                read(v_line, v_char, v_ok);
                next when not v_ok;
                if v_char = '1' then
                    v_sym := '1';
                elsif v_char = '0' then
                    v_sym := '0';
                else
                    next; -- Ignora espaços vazios ou lixo
                end if;

                v_sym_count := v_sym_count + 1;

                symbol      <= v_sym;
                read_enable <= '1';
                wait until rising_edge(clk);
                wait for 1 ns;
                read_enable <= '0';
                symbol      <= '0';
                wait for CLK_PERIOD - 1 ns;
            end loop;
        end loop;
        file_close(sym_file);

        flush <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        flush <= '0';

        wait for CLK_PERIOD * 10;

        file_open(out_file, "encoded_data.txt", write_mode);
        
        write(v_out_line, v_sym_count);
        writeline(out_file, v_out_line);
        
        write(v_out_line, to_integer(bits_valid));
        writeline(out_file, v_out_line);
        
        write(v_out_line, to_bstring(bit_stream));
        writeline(out_file, v_out_line);
        file_close(out_file);

        report "Sucesso! Simbolos lidos: " & integer'image(v_sym_count);
        sim_done <= true;
        wait;
    end process;
end sim;