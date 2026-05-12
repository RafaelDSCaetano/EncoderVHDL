library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;

entity decoder_tb is
end decoder_tb;

architecture sim of decoder_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    
    signal bit_stream   : std_logic_vector(31 downto 0) := (others => '0');
    signal bits_valid   : unsigned(5 downto 0) := (others => '0');
    signal start_decode : std_logic := '0';
    
    signal symbol_out   : std_logic;
    signal symbol_valid : std_logic;
    signal decode_done  : std_logic;

    signal expected_symbols : integer := 0;
    signal decoded_count    : integer := 0;
    signal sim_done         : boolean := false;
    constant CLK_PERIOD : time := 10 ns;

begin
    uut: entity work.decoder
        port map (
            clk => clk, rst => rst,
            bit_stream => bit_stream, bits_valid => bits_valid,
            start_decode => start_decode,
            symbol_out => symbol_out, symbol_valid => symbol_valid,
            decode_done => decode_done
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
        file in_file         : text;
        variable v_line      : line;
        variable v_sym_total : integer;
        variable v_bits_val  : integer;
        variable v_stream_str: string(1 to 32);
    begin
        rst <= '1'; wait for 20 ns; rst <= '0'; wait for 20 ns;

        file_open(in_file, "encoded_data.txt", read_mode);

        -- Linha 1: Símbolos
        readline(in_file, v_line);
        read(v_line, v_sym_total);
        expected_symbols <= v_sym_total;

        -- Linha 2: Bits válidos
        readline(in_file, v_line);
        read(v_line, v_bits_val);
        bits_valid <= to_unsigned(v_bits_val, 6);

        -- Linha 3: Stream
        readline(in_file, v_line);
        read(v_line, v_stream_str);
        for i in 1 to 32 loop
            if v_stream_str(i) = '1' then
                bit_stream(32-i) <= '1';
            else
                bit_stream(32-i) <= '0';
            end if;
        end loop;
        file_close(in_file);

        wait until rising_edge(clk);
        start_decode <= '1';
        wait until rising_edge(clk);
        start_decode <= '0';

        wait until decode_done = '1';
        wait for 50 ns;
        sim_done <= true;
        wait;
    end process;

    record_proc: process
        file out_file : text;
        variable v_line : line;
    begin
        file_open(out_file, "output_decoded.txt", write_mode);
        
        while not sim_done loop
            wait until rising_edge(clk);
            if symbol_valid = '1' and decoded_count < expected_symbols then
                -- Apenas acumula os bits no buffer da linha
                if symbol_out = '1' then 
                    write(v_line, string'("1"));
                else 
                    write(v_line, string'("0")); 
                end if;
                
                decoded_count <= decoded_count + 1;
            end if;
        end loop;
        writeline(out_file, v_line);
        file_close(out_file);
        wait;
    end process;
end sim;