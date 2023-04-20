library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity skidbuffer is
  generic (
    DATA_WIDTH  : integer := 32;
    OPT_DATA_REG : boolean := True
  );
  port (
    clock     : in std_logic;
    reset_n   : in std_logic;

    s_valid_i : in  std_logic;
    s_last_i  : in  std_logic;
    s_ready_o : out std_logic;
    s_data_i  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);

    m_valid_o : out std_logic;
    m_last_o  : out std_logic;
    m_ready_i : in  std_logic;
    m_data_o  : out std_logic_vector(DATA_WIDTH - 1 downto 0)
  );
end skidbuffer;

architecture arch_imp of skidbuffer is
  -- input signals (registered depending on OPT_DATA_REG)
  signal reg_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal reg_last  : std_logic;
  signal reg_valid : std_logic;
  signal reg_ready : std_logic;

  -- output signals
  signal out_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal out_last  : std_logic;
  signal out_ready : std_logic;
  signal out_valid : std_logic;

begin
  -- I/O connections assignments
  m_valid_o <= out_valid;
  m_data_o  <= out_data;
  m_last_o  <= out_last;
  s_ready_o <= out_ready;

  out_ready <= reg_ready;
  out_valid <= reg_valid;

  -- ready is always registered
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

  -- combinatorial output signals
  gen_no_register : if not OPT_DATA_REG generate


    p_reg : process (clock)
    begin
      if rising_edge(clock) then 
        if reset_n = '0' then
          reg_data  <= (others => '0');
          reg_last  <= '0';
        else
          if m_ready_i = '1' then
            reg_data <= s_data_i;
            reg_last <= s_last_i;
          else
            reg_data <= reg_data;
            reg_last <= reg_last;
          end if;
        end if;
      end if;
    end process;
    
    -- output multiplexer
    out_data <= reg_data when (reg_ready = '1') else s_data_i;
    out_last <= reg_last when (reg_ready = '1') else s_last_i;

    reg_valid <= s_valid_i; -- valid is not registered
  end generate;

  gen_data_register : if OPT_DATA_REG generate
    out_data <= reg_data;
    out_last <= reg_last;
    -- registered output signals
    p_reg : process (clock)
    begin
      if rising_edge(clock) then 
        if reset_n = '0' then
          reg_data  <= (others => '0');
          reg_last  <= '0';
          reg_valid <= '0';
        else
          reg_valid <= s_valid_i;
          if(m_ready_i = '1') then
            reg_data  <= s_data_i;
            reg_last  <= s_last_i;
          else
            reg_data  <= reg_data;
            reg_last  <= reg_last;
          end if;
        end if;
      end if;
    end process;
  end generate;

end arch_imp;
