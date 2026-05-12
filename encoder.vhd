library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity encoder is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        symbol      : in  std_logic;
        read_enable : in  std_logic;
        flush       : in  std_logic;
        
        bit_stream  : out std_logic_vector(31 downto 0);
        bits_valid  : out unsigned(5 downto 0);
        low_out     : out std_logic_vector(7 downto 0)
    );
end encoder;

architecture ARQ of encoder is
    constant P0 : unsigned(7 downto 0) := "00011001"; -- P(0)=10%
    constant P1 : unsigned(7 downto 0) := "11100110"; -- P(1)=90%
    constant MAX_NORM   : integer := 8;
    constant FLUSH_BITS : integer := 8;

    signal s_range    : unsigned(7 downto 0)  := x"FF";
    signal s_low      : unsigned(8 downto 0)  := (others => '0');
    signal s_bits_buf : std_logic_vector(31 downto 0) := (others => '0');
    signal s_bits_cnt : unsigned(5 downto 0)  := (others => '0');
    signal s_bits_pendentes : integer range 0 to 31 := 0;

    -- Função original de preencher bits
    procedure append_bit (
        variable v_buf  : inout std_logic_vector(31 downto 0);
        variable v_cnt  : inout integer range 0 to 63;
        constant new_bit: in    std_logic
    ) is
    begin
        if v_cnt < 32 then
            v_buf := v_buf(30 downto 0) & new_bit;
            v_cnt := v_cnt + 1;
        end if;
    end procedure;

begin
    process(clk, rst)
        variable v_range : unsigned(7 downto 0);
        variable v_low   : unsigned(8 downto 0);
        variable v_buf   : std_logic_vector(31 downto 0);
        variable v_cnt   : integer range 0 to 63;
        variable v_bits_pendentes : integer range 0 to 31;
        variable v_thresh_ext : unsigned(15 downto 0);
        variable v_thresh_val : unsigned(8 downto 0);
    begin
        if rst = '1' then
            s_range <= x"FF";
            s_low   <= (others => '0');
            s_bits_buf <= (others => '0');
            s_bits_cnt <= (others => '0');
            s_bits_pendentes <= 0;
            
        elsif rising_edge(clk) then
            v_range := s_range;
            v_low   := s_low;
            v_buf   := s_bits_buf;
            v_cnt   := to_integer(s_bits_cnt);
            v_bits_pendentes := s_bits_pendentes;

            if read_enable = '1' then
                v_thresh_ext := v_range * P0;
                v_thresh_val := v_low + ("0" & v_thresh_ext(15 downto 8));

                if symbol = '0' then
                    v_range := v_thresh_ext(15 downto 8);
                else
                    v_low   := v_thresh_val;
                    v_thresh_ext := v_range * P1;
                    v_range := v_thresh_ext(15 downto 8);
                end if;

                for i in 0 to MAX_NORM - 1 loop
                    exit when v_range(7) = '1';

                    if v_low(8) = '0' and v_low(7) = '0' then
                        append_bit(v_buf, v_cnt, '0');
                        while v_bits_pendentes > 0 loop
                            append_bit(v_buf, v_cnt, '1');
                            v_bits_pendentes := v_bits_pendentes - 1;
                        end loop;
                        v_low   := v_low(7 downto 0) & '0';
                        v_range := v_range(6 downto 0) & '0';
                        
                    elsif v_low(8) = '1' then
                        append_bit(v_buf, v_cnt, '1');
                        while v_bits_pendentes > 0 loop
                            append_bit(v_buf, v_cnt, '0');
                            v_bits_pendentes := v_bits_pendentes - 1;
                        end loop;
                        v_low   := v_low(7 downto 0) & '0';
                        v_range := v_range(6 downto 0) & '0';
                        
                    else
                        v_bits_pendentes := v_bits_pendentes + 1;
                        v_low   := "0" & v_low(6 downto 0) & '0';
                        v_range := v_range(6 downto 0) & '0';
                    end if;
                end loop;
                
            elsif flush = '1' then
						append_bit(v_buf, v_cnt, v_low(7));
                
						while v_bits_pendentes > 0 loop
							append_bit(v_buf, v_cnt, not v_low(7));
							v_bits_pendentes := v_bits_pendentes - 1;
						end loop;
                
						for i in 1 to FLUSH_BITS loop
							append_bit(v_buf, v_cnt, '0');
						end loop;
				end if;

            s_range <= v_range;
            s_low   <= v_low;
            s_bits_buf <= v_buf;
            s_bits_pendentes <= v_bits_pendentes;

            if v_cnt > 32 then
                s_bits_cnt <= to_unsigned(32, 6);
            else
                s_bits_cnt <= to_unsigned(v_cnt, 6);
            end if;
        end if;
    end process;

    bit_stream <= s_bits_buf;
    bits_valid <= s_bits_cnt;
    low_out    <= std_logic_vector(s_low(7 downto 0));
end ARQ;