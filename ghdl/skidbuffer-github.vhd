library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity skidbuffer is
  generic (
    DW         : natural :=8;
    OPT_OUTREG : boolean := True);
  port (
     clock     : in  std_logic;
     reset_n   : in  std_logic;

     s_valid_i : in  std_logic;
     s_last_i  : in  std_logic;
     s_ready_o : out std_logic;
     s_data_i  : in  std_logic_vector(DW - 1 downto 0);

     m_valid_o : out std_logic;
     m_last_o  : out std_logic;
     m_ready_i : in  std_logic;
     m_data_o  : out std_logic_vector(DW - 1 downto 0));
end skidbuffer;

architecture skidbuffer of skidbuffer is
  signal r_data    : std_logic_vector(DW - 1 downto 0);
  signal r_valid   : std_logic := '0';
  signal o_ready_i : std_logic;
  signal o_valid_i : std_logic;
  signal o_last_i  : std_logic;
begin

    s_ready_o <= o_ready_i;
    m_valid_o <= o_valid_i;
    m_last_o  <= o_last_i;

    process(clock)
    begin
      if rising_edge(clock) then
        if reset_n = '0' then
          r_valid <= '0';
        else
          if (s_valid_i = '1' and o_ready_i = '1') and (o_valid_i = '1' and m_ready_i = '0') then
            -- We have incoming data, but the output is stalled
            r_valid <= '1';
          elsif m_ready_i = '1' then
            r_valid <= '0';
          end if;
        end if;

      end if;
    end process;

    process(clock)
    begin
      if rising_edge(clock) then
        if (not OPT_OUTREG or s_valid_i = '1') and (o_ready_i = '1') then
          r_data <= s_data_i;
        end if;
      end if;
    end process;

    o_ready_i <= '1' when r_valid = '0' else '0';

		--
		-- And then move on to the output port
		--
    g_not_out_reg : if not OPT_OUTREG generate
      o_valid_i <= '1' when reset_n = '1' and (s_valid_i = '1' or r_valid = '1') else '0';
      o_last_i  <= '1' when reset_n = '1' and (s_valid_i = '1' or r_valid = '1') and s_last_i = '1' else '0';

      process(r_valid, r_data, s_data_i, s_valid_i)
      begin
        if r_valid = '1' then
          m_data_o <= r_data;
        elsif s_valid_i = '0' then
          m_data_o <= s_data_i;
        end if;
      end process;
    end generate g_not_out_reg;

    g_out_reg : if OPT_OUTREG generate
      process(clock)
      begin
        if rising_edge(clock) then
          if reset_n = '0' then
            o_valid_i <= '0';
          elsif o_valid_i = '0' or m_ready_i = '1' then
            o_valid_i <= s_valid_i or r_valid;
          end if;
        end if;
      end process;

      process(clock)
      begin
        if rising_edge(clock) then
          if reset_n = '0' then
            o_last_i <= '0';
          elsif o_last_i = '0' or m_ready_i = '1' then
            o_last_i <= (s_valid_i or r_valid ) and s_last_i;
          end if;
        end if;
      end process;

      process(clock)
      begin
        if rising_edge(clock) then
          if reset_n = '0' then
            m_data_o <= (others => '0');
          elsif o_valid_i = '0' or m_ready_i = '1' then
            if r_valid = '1' then
              m_data_o <= r_data;
            elsif s_valid_i = '1' then
              m_data_o <= s_data_i;
            end if;
          end if;
        end if;
      end process;

    end generate g_out_reg;


end skidbuffer;