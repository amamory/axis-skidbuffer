----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/22/2023 09:03:36 AM
-- Design Name: 
-- Module Name: tb_skid - bh
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_skid is
  generic
  (
    DATA_WIDTH   : natural := 8;
    OPT_DATA_REG : boolean := False
  );
end tb_skid;

architecture bh of tb_skid is
  -- component declaration
  component skidbuffer is
  generic (
    DATA_WIDTH         : natural;
    OPT_DATA_REG : boolean);
    port (
       clock     : in  std_logic;
       reset_n   : in  std_logic;

       s_valid_i : in  std_logic;
       s_last_i  : in  std_logic;
       s_ready_o : out std_logic;
       s_data_i  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);

       m_valid_o : out std_logic;
       m_last_o  : out std_logic;
       m_ready_i : in  std_logic;
       m_data_o  : out std_logic_vector(DATA_WIDTH - 1 downto 0));
  end component;
  
  constant CLK_PERIOD: TIME := 5 ns;

  signal sim_valid_data  : std_logic := '0';
  signal sim_ready_data  : std_logic := '1';
  signal sim_data        : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal s_axis_tvalid : std_logic := '0';
  signal s_axis_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_axis_tlast  : std_logic;
  signal s_axis_tready : std_logic;

  signal m_axis_tvalid : std_logic;
  signal m_axis_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal m_axis_tlast  : std_logic;
  signal m_axis_tready : std_logic := '0';

  signal clk   : std_logic;
  signal rst_n : std_logic;

  signal clk_count : std_logic_vector(7 downto 0) := (others => '0');
begin

  -- generate clk signal
  p_clk_gen : process
  begin
   clk <= '1';
   wait for (CLK_PERIOD / 2);
   clk <= '0';
   wait for (CLK_PERIOD / 2);
   clk_count <= std_logic_vector(unsigned(clk_count) + 1);
  end process;

  -- generate initial reset
  p_reset_gen : process
  begin 
    rst_n <= '0';
    wait until rising_edge(clk);
    wait for (CLK_PERIOD / 4);
    rst_n <= '1';
    wait;
  end process;

  -- generate ready signal
  p_stimuli_tready : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        m_axis_tready <= '1';
      else
        m_axis_tready <= sim_ready_data;
        if unsigned(clk_count) = 2 then
          sim_ready_data <= '1';
        end if;
        if unsigned(clk_count) = 7 then
          sim_ready_data <= '0';
        end if;
        if unsigned(clk_count) = 8 then
          sim_ready_data <= '1';
        end if;
        if unsigned(clk_count) = 11 then
          sim_ready_data <= '0';
        end if;
        if unsigned(clk_count) = 13 then
          sim_ready_data <= '1';
        end if;
        if unsigned(clk_count) = 14 then
          sim_ready_data <= '0';
        end if;
        if unsigned(clk_count) = 15 then
          sim_ready_data <= '1';
        end if;
      end if;
    end if;
  end process;

  -- generate valid signal
  p_stimuli_tvalid : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        sim_valid_data <= '0';
      else
        if unsigned(clk_count) = 2 then
          sim_valid_data <= '1';
        end if;
        if unsigned(clk_count) = 18 then
          sim_valid_data <= '0';
        end if;
        if unsigned(clk_count) = 21 then
          sim_valid_data <= '1';
        end if;
        if unsigned(clk_count) = 23 then
          sim_valid_data <= '0';
        end if;
        if unsigned(clk_count) = 24 then
          sim_valid_data <= '1';
        end if;
        if unsigned(clk_count) = 26 then
          sim_valid_data <= '0';
        end if;
      end if;
    end if;
  end process;

    -- TODO: this is a bug. m_axis is a stimulated signal and not read from the DUT
    -- why is this if-statement delayed by 1 clk? it should read from s_axis_tready instead
  -- generate counter data when successfully acknowledged by slave
  p_stimuli_tdata : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        s_axis_tdata <= (others => '0');
        sim_data <= (others => '0');
        s_axis_tlast <= '0';
      else
        if sim_valid_data = '1' then    -- VALID can be controlled
          if s_axis_tready = '1' then   -- READY can be controlled
            if unsigned(s_axis_tdata) = 3 then
              s_axis_tlast <= '1';
            else 
              s_axis_tlast <= '0';
            end if;

            if unsigned(s_axis_tdata) = 4 then
              -- restart counter at "1"
              s_axis_tdata(DATA_WIDTH-1 downto 1) <= (others => '0');
              s_axis_tdata(0) <= '1';
              sim_data(DATA_WIDTH-1 downto 1) <= (others => '0');
              sim_data(0) <= '1';
            else
              if (unsigned(sim_data) > unsigned(s_axis_tdata)) and (unsigned(sim_data) < 4) then
                s_axis_tdata <= std_logic_vector(unsigned(sim_data) + 1);
              else
                s_axis_tdata <= std_logic_vector(unsigned(s_axis_tdata) + 1);
              end if;
              
              if unsigned(sim_data) = 4 then
                sim_data(DATA_WIDTH-1 downto 1) <= (others => '0');
                sim_data(0) <= '1';
              else
                sim_data <= std_logic_vector(unsigned(sim_data) + 1);
              end if;
            end if;
          else
            s_axis_tdata <= s_axis_tdata;
            sim_data <= sim_data;
          end if;
          s_axis_tvalid <= '1';
        else 
          s_axis_tvalid <= '0';
          s_axis_tlast <= '0';
          s_axis_tdata <= (others => '0');
          sim_data <= sim_data;
        end if;
      end if;
    end if;
  end process;

  skidbuffer_inst : skidbuffer
  generic map (
      DATA_WIDTH    => DATA_WIDTH,
      OPT_DATA_REG  => OPT_DATA_REG
  )
  port map (
    clock     => clk,
    reset_n   => rst_n,

    s_valid_i => s_axis_tvalid,
    s_last_i  => s_axis_tlast,
    s_ready_o => s_axis_tready,
    s_data_i  => s_axis_tdata,

    m_valid_o => m_axis_tvalid,
    m_last_o  => m_axis_tlast,
    m_ready_i => m_axis_tready,
    m_data_o  => m_axis_tdata
  );

end bh;
