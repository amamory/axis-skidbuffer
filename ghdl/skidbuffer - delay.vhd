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
  out_ready <= reg_ready;
  s_ready_o <= out_ready;
  m_valid_o <= reg_valid;
  m_data_o  <= out_data;
  m_last_o  <= out_last;

  -- combinatorial multiplexers
  -- "output" = "input" when ready==1, otherwise use "buffer content"
  out_data <= reg_data when (reg_ready = '1') else skd_data;
  out_last <= reg_last when (reg_ready = '1') else skd_last;

  gen_input_register : if OPT_INREG generate
  -- registered input signals
    p_reg : process (clock)
    begin
      if rising_edge(clock) then 
        if reset_n = '0' then
          reg_data <= (others => '0');
          reg_last <= '0';
          reg_valid <= '0';
        else
          reg_valid <= s_valid_i;
          if(out_ready = '0') then
          reg_data  <= reg_data;
          reg_last  <= reg_last;
        else
          reg_data  <= s_data_i;
          reg_last  <= s_last_i;
        end if;
        end if;
      end if;
    end process;
  end generate;

  -- combinatorial input signals
  gen_no_input_register : if not OPT_INREG generate
    reg_valid <= s_valid_i;
    reg_data  <= s_data_i;
    reg_last  <= s_last_i;
  end generate;

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
        skd_data <= out_data;
        skd_last <= out_last;
      end if;
    end if;
  end process;

end arch_imp;
