library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity skidbuffer is
  generic (
    DW  : integer := 32;
    OPT_INREG : boolean := True
  );
  port (
    clock     : in std_logic;
    reset_n   : in std_logic;

    s_valid_i : in  std_logic;
    s_last_i  : in  std_logic;
    s_ready_o : out std_logic;
    s_data_i  : in  std_logic_vector(DW - 1 downto 0);

    m_valid_o : out std_logic;
    m_last_o  : out std_logic;
    m_ready_i : in  std_logic;
    m_data_o  : out std_logic_vector(DW - 1 downto 0)
  );
end skidbuffer;

architecture arch_imp of skidbuffer is
  -- input signals (registered depending on OPT_INREG)
  signal reg_data  : std_logic_vector(DW-1 downto 0);
  signal reg_last  : std_logic;
  signal reg_valid : std_logic;
  signal reg_ready : std_logic;

  -- skid buffer signals from Slave to Master direction
  signal skd_data  : std_logic_vector(DW-1 downto 0);
  signal skd_last  : std_logic;

  -- output signals
  signal out_data  : std_logic_vector(DW-1 downto 0);
  signal out_last  : std_logic;
  signal out_ready : std_logic;

begin
  -- I/O connections assignments
  m_valid_o <= reg_valid;
  reg_valid <= s_valid_i;

  out_ready <= reg_ready;
  s_ready_o <= out_ready;

  m_data_o  <= out_data;
  m_last_o  <= out_last;

  -- combinatorial multiplexers
  -- "output" = "input" when ready==1, otherwise use "buffer content"
  out_data <= s_data_i when (reg_ready = '1') else skd_data;
  out_last <= s_last_i when (reg_ready = '1') else skd_last;

  p_reg_ready : process(clock)
  begin
    if rising_edge(clock) then 
      if reset_n = '0' then
        reg_ready <= '0';
      else
        reg_ready <= m_ready_i;
      end if;
    end if;
  end process;

  -- skid buffer looping output back into register
  p_skid_buf : process (clock)
  begin
    if rising_edge(clock) then 
      if reset_n = '0' then
        skd_data <= (others => '0');
        skd_last <= '0';
      else
        if reg_ready = '1' then
          skd_data <= s_data_i;
          skd_last <= s_last_i;
        else
          skd_data <= skd_data;
          skd_last <= skd_last;
        end if;
      end if;
    end if;
  end process;

end arch_imp;
