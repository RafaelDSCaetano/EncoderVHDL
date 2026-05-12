library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity decoder is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        bit_stream   : in  std_logic_vector(31 downto 0);
        bits_valid   : in  unsigned(5 downto 0);
        
        start_decode : in  std_logic;
        
        symbol_out   : out std_logic;
        symbol_valid : out std_logic;
        decode_done  : out std_logic
    );
end decoder;

architecture ARQ of decoder is
    constant P0       : unsigned(7 downto 0) := "00011001";
    constant P1       : unsigned(7 downto 0) := "11100110";
    constant MAX_NORM : integer := 8;

    signal s_range   : unsigned(7 downto 0) := x"FF";
    signal s_low     : unsigned(8 downto 0) := (others => '0');
    signal s_buf_dec : unsigned(8 downto 0) := (others => '0');
    signal s_stream  : std_logic_vector(31 downto 0) := (others => '0');
    
    signal s_ptr     : integer range -15 to 63 := 0; 
    signal s_active  : std_logic := '0';
    signal s_init_cnt: integer range 0 to 15 := 0;

begin
    process(clk, rst)
        variable v_range   : unsigned(7 downto 0);
        variable v_low     : unsigned(8 downto 0);
        variable v_buf_dec : unsigned(8 downto 0);
        variable v_ptr     : integer range -15 to 63;
        variable v_thresh_ext : unsigned(15 downto 0);
        variable v_thresh_val : unsigned(8 downto 0);
        variable v_bit     : std_logic;
    begin
        if rst = '1' then
            symbol_valid <= '0';
            symbol_out   <= '0';
            decode_done  <= '0';
            s_range      <= x"FF";
            s_low        <= (others => '0');
            s_buf_dec    <= (others => '0');
            s_active     <= '0';
            s_init_cnt   <= 0;
            
        elsif rising_edge(clk) then
            symbol_valid <= '0';
            decode_done  <= '0';

            if start_decode = '1' then
                s_stream   <= bit_stream;
                s_ptr      <= to_integer(bits_valid) - 1;
                s_range    <= x"FF";
                s_low      <= (others => '0');
                s_buf_dec  <= (others => '0');
                s_init_cnt <= 0;
                s_active   <= '1';
                
            elsif s_active = '1' then
                v_buf_dec := s_buf_dec;
                v_range   := s_range;
                v_low     := s_low;
                v_ptr     := s_ptr;

                if s_init_cnt < 9 then
                    if v_ptr >= 0 then
                        v_bit := s_stream(v_ptr);
                        v_ptr := v_ptr - 1;
                    else
                        v_bit := '0';
                        v_ptr := v_ptr - 1; 
                    end if;
                    v_buf_dec  := v_buf_dec(7 downto 0) & v_bit;
                    s_init_cnt <= s_init_cnt + 1;
                    
                else
                    v_thresh_ext := v_range * P0;
                    v_thresh_val := v_low + ("0" & v_thresh_ext(15 downto 8));

                    if v_buf_dec < v_thresh_val then
                        symbol_out <= '0';
                        v_range    := v_thresh_ext(15 downto 8);
                    else
                        symbol_out <= '1';
                        v_low      := v_thresh_val;
                        v_thresh_ext := v_range * P1; 
                        v_range    := v_thresh_ext(15 downto 8);
                    end if;
                    symbol_valid <= '1';

                    for i in 0 to MAX_NORM - 1 loop
                        exit when v_range(7) = '1';

                        if v_ptr >= 0 then
                            v_bit := s_stream(v_ptr);
                            v_ptr := v_ptr - 1;
                        else
                            v_bit := '0';
                            v_ptr := v_ptr - 1; 
                        end if;

                        if v_low(8) = '0' and v_low(7) = '0' then
                            v_low     := v_low(7 downto 0) & '0';
                            v_range   := v_range(6 downto 0) & '0';
                            v_buf_dec := v_buf_dec(7 downto 0) & v_bit;
                        elsif v_low(8) = '1' then
                            v_low     := v_low(7 downto 0) & '0';
                            v_range   := v_range(6 downto 0) & '0';
                            v_buf_dec := v_buf_dec(7 downto 0) & v_bit;
                        else
                            v_low     := "0" & v_low(6 downto 0) & '0'; 
                            v_range   := v_range(6 downto 0) & '0';
                            v_buf_dec := v_buf_dec(8) & v_buf_dec(6 downto 0) & v_bit;
                        end if;
                    end loop;

                    if v_ptr < -10 then
                        decode_done <= '1';
                        s_active    <= '0';
                    end if;
                end if;

                s_buf_dec <= v_buf_dec;
                s_range   <= v_range;
                s_low     <= v_low;
                s_ptr     <= v_ptr;
            end if;
        end if;
    end process;
end ARQ;