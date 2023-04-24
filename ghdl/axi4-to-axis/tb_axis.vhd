----------------------------------------------------------------------------------
-- Company:        
-- Engineer:       simon.burkhardt
-- 
-- Create Date:    2023-04-21
-- Design Name:    skid buffer testbench
-- Module Name:    tb_axis - bh
-- Project Name:   
-- Target Devices: 
-- Tool Versions:  GHDL 0.37
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

-- this testbench acts as a streaming master, sending bursts of data
-- counting from 1-4, also asserting tlast on the 4th data packet

-- the testbench itself acts as a correct streaming master which keeps the data
-- until it is acknowledged by the DUT by asserting tready.

-- the data pattern can be influenced by the user in 2 ways
-- + Tx requests are generated by changing the pattern in p_stimuli_tready
--   the master will try to send data for as long as sim_valid_data = '1'
-- + Rx acknowledgements are generated by changing the pattern in p_stimuli_tready
--   the downstream slave after the DUT will signal ready-to-receive 
--   when sim_ready_data = '1'

-- simulate both with OPT_DATA_REG = True / False
entity tb_axis is
  generic
  (
    OPT_DATA_REG         : boolean   := True;
    -- Width of ID for for write address, write data, read address and read data
    C_S_AXI_ID_WIDTH     : integer   := 3;
    -- Width of S_AXI data bus
    C_S_AXI_DATA_WIDTH   : integer   := 8;
    -- Width of S_AXI address bus
    C_S_AXI_ADDR_WIDTH   : integer   := 8;
    -- Width of optional user defined signal in write address channel
    C_S_AXI_AWUSER_WIDTH : integer   := 0;
    -- Width of optional user defined signal in read address channel
    C_S_AXI_ARUSER_WIDTH : integer   := 0;
    -- Width of optional user defined signal in write data channel
    C_S_AXI_WUSER_WIDTH  : integer   := 0;
    -- Width of optional user defined signal in read data channel
    C_S_AXI_RUSER_WIDTH  : integer   := 0;
    -- Width of optional user defined signal in write response channel
    C_S_AXI_BUSER_WIDTH  : integer   := 0;

    -- Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_DATA_WIDTH.
    C_M_AXIS_DATA_WIDTH  : integer   := 8
  );
end tb_axis;

architecture bh of tb_axis is
  -- DUT component declaration
  component axi4_to_axis is
    generic (
      C_S_AXI_ID_WIDTH     : integer;
      C_S_AXI_DATA_WIDTH   : integer;
      C_S_AXI_ADDR_WIDTH   : integer;
      C_S_AXI_AWUSER_WIDTH : integer;
      C_S_AXI_ARUSER_WIDTH : integer;
      C_S_AXI_WUSER_WIDTH  : integer;
      C_S_AXI_RUSER_WIDTH  : integer;
      C_S_AXI_BUSER_WIDTH  : integer;
      C_M_AXIS_DATA_WIDTH  : integer
    );
    port (
      AXIS_ACLK      : in  std_logic;
      AXIS_ARESETN   : in  std_logic;

      S_AXI_AWID     : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_AWADDR   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWLEN    : in  std_logic_vector(7 downto 0);
      S_AXI_AWSIZE   : in  std_logic_vector(2 downto 0);
      S_AXI_AWBURST  : in  std_logic_vector(1 downto 0);
      S_AXI_AWLOCK   : in  std_logic;
      S_AXI_AWCACHE  : in  std_logic_vector(3 downto 0);
      S_AXI_AWPROT   : in  std_logic_vector(2 downto 0);
      S_AXI_AWQOS    : in  std_logic_vector(3 downto 0);
      S_AXI_AWREGION : in  std_logic_vector(3 downto 0);
      S_AXI_AWUSER   : in  std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);
      S_AXI_AWVALID  : in  std_logic;
      S_AXI_AWREADY  : out std_logic;
      S_AXI_WDATA    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB    : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WLAST    : in  std_logic;
      S_AXI_WUSER    : in  std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
      S_AXI_WVALID   : in  std_logic;
      S_AXI_WREADY   : out std_logic;
      S_AXI_BID      : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_BRESP    : out std_logic_vector(1 downto 0);
      S_AXI_BUSER    : out std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
      S_AXI_BVALID   : out std_logic;
      S_AXI_BREADY   : in  std_logic;
      S_AXI_ARID     : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_ARADDR   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARLEN    : in  std_logic_vector(7 downto 0);
      S_AXI_ARSIZE   : in  std_logic_vector(2 downto 0);
      S_AXI_ARBURST  : in  std_logic_vector(1 downto 0);
      S_AXI_ARLOCK   : in  std_logic;
      S_AXI_ARCACHE  : in  std_logic_vector(3 downto 0);
      S_AXI_ARPROT   : in  std_logic_vector(2 downto 0);
      S_AXI_ARQOS    : in  std_logic_vector(3 downto 0);
      S_AXI_ARREGION : in  std_logic_vector(3 downto 0);
      S_AXI_ARUSER   : in  std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);
      S_AXI_ARVALID  : in  std_logic;
      S_AXI_ARREADY  : out std_logic;
      S_AXI_RID      : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_RDATA    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP    : out std_logic_vector(1 downto 0);
      S_AXI_RLAST    : out std_logic;
      S_AXI_RUSER    : out std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
      S_AXI_RVALID   : out std_logic;
      S_AXI_RREADY   : in  std_logic;

      M_AXIS_TVALID : out std_logic;
      M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
      M_AXIS_TSTRB  : out std_logic_vector((C_M_AXIS_DATA_WIDTH/8)-1 downto 0);
      M_AXIS_TLAST  : out std_logic;
      M_AXIS_TREADY : in  std_logic
    );
  end component;
  
  constant CLK_PERIOD: TIME := 5 ns;

  signal sim_start_write : std_logic := '0'; -- request AW channel
  signal sim_start_ready : std_logic := '0'; -- signal ready to receive from slave
  signal sim_valid_data  : std_logic := '0'; -- AW complete, now send W channel
  signal sim_data        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

  signal o_axis_tvalid : std_logic;
  signal o_axis_tdata  : std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
  signal o_axis_tstrb  : std_logic_vector((C_M_AXIS_DATA_WIDTH/8)-1 downto 0);
  signal o_axis_tlast  : std_logic;
  signal i_axis_tready : std_logic := '0';

  signal clk   : std_logic;
  signal rst_n : std_logic;

  signal o_axi_awid     : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
  signal o_axi_awaddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal o_axi_awlen    : std_logic_vector(7 downto 0);
  signal o_axi_awsize   : std_logic_vector(2 downto 0);
  signal o_axi_awburst  : std_logic_vector(1 downto 0);
  signal o_axi_awlock   : std_logic;
  signal o_axi_awcache  : std_logic_vector(3 downto 0);
  signal o_axi_awprot   : std_logic_vector(2 downto 0);
  signal o_axi_awqos    : std_logic_vector(3 downto 0);
  signal o_axi_awregion : std_logic_vector(3 downto 0);
  signal o_axi_awuser   : std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);
  signal o_axi_awvalid  : std_logic;
  signal i_axi_awready  : std_logic;

  signal o_axi_wdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal o_axi_wstrb    : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
  signal o_axi_wlast    : std_logic;
  signal o_axi_wuser    : std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
  signal o_axi_wvalid   : std_logic;
  signal i_axi_wready   : std_logic;

  signal i_axi_bid      : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
  signal i_axi_bresp    : std_logic_vector(1 downto 0);
  signal i_axi_buser    : std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
  signal i_axi_bvalid   : std_logic;
  signal o_axi_bready   : std_logic;
  signal o_axi_arid     : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
  signal o_axi_araddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal o_axi_arlen    : std_logic_vector(7 downto 0);
  signal o_axi_arsize   : std_logic_vector(2 downto 0);
  signal o_axi_arburst  : std_logic_vector(1 downto 0);
  signal o_axi_arlock   : std_logic;
  signal o_axi_arcache  : std_logic_vector(3 downto 0);
  signal o_axi_arprot   : std_logic_vector(2 downto 0);
  signal o_axi_arqos    : std_logic_vector(3 downto 0);
  signal o_axi_arregion : std_logic_vector(3 downto 0);
  signal o_axi_aruser   : std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);
  signal o_axi_arvalid  : std_logic;
  signal i_axi_arready  : std_logic;
  signal i_axi_rid      : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
  signal i_axi_rdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal i_axi_rresp    : std_logic_vector(1 downto 0);
  signal i_axi_rlast    : std_logic;
  signal i_axi_ruser    : std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
  signal i_axi_rvalid   : std_logic;
  signal o_axi_rready   : std_logic;

  signal clk_count : std_logic_vector(7 downto 0) := (others => '0');
  signal outstanding_xfers : std_logic_vector(7 downto 0) := (others => '0');
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

  -- generate AW request
  p_aw_stimuli : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        o_axi_awid     <= (others => '0'); 
        o_axi_awaddr   <= (others => '0'); 
        o_axi_awlen    <= (others => '0'); 
        o_axi_awsize   <= (others => '0'); 
        o_axi_awburst  <= (others => '0'); 
        o_axi_awlock   <= '0';
        o_axi_awcache  <= (others => '0'); 
        o_axi_awprot   <= (others => '0'); 
        o_axi_awqos    <= (others => '0'); 
        o_axi_awregion <= (others => '0'); 
        o_axi_awuser   <= (others => '0'); 
        o_axi_awvalid  <= '0';
        sim_valid_data <= '0';
      else
        if o_axi_awvalid = '1' then -- AW handshake ongoing, wait for slave to ack
          if i_axi_awready = '1' then -- slave is able to receive AW reqest
            o_axi_awid <= "000";
            o_axi_awaddr <= (others => '0'); 
            o_axi_awlen <= (others => '0'); 
            o_axi_awsize <= "000";
            o_axi_awburst <= "00";
            o_axi_awvalid <= '0';
            sim_valid_data <= '1';
          end if;
        else
          if sim_start_write = '1' then -- AW handshake requested by simulation
            o_axi_awid <= "101";
            o_axi_awaddr <= x"42";
            o_axi_awlen <= x"3f";  -- 63+1 bytes
            o_axi_awsize <= "110"; -- 64 bytes
            o_axi_awburst <= "01"; -- INCR
            o_axi_awvalid <= '1';
            --sim_valid_data <= '0';
          end if;
        end if;
        if sim_valid_data = '1' then
          if o_axi_wlast = '1' and i_axi_wready = '1' then
            if unsigned(outstanding_xfers) = 1 then 
              sim_valid_data <= '0';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- generate counter data when successfully acknowledged (tready) by slave
  p_stimuli_tdata : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        o_axi_wdata <= (others => '0');
        o_axi_wstrb <= (others => '0');
        sim_data    <= (others => '0');
        o_axi_wlast <= '0';
        o_axi_wvalid <= '0';
      else
        if (sim_valid_data = '1' or o_axi_awvalid='1') then -- and o_axi_wlast = '0'  then    -- OK from a valid AW handshake
        --  if o_axi_wlast = '0' then
            if i_axi_wready = '1' then    -- wready from slave
              if unsigned(o_axi_wdata) = 15 then
                o_axi_wlast <= '1';
              else 
                o_axi_wlast <= '0';
              end if;

              if unsigned(outstanding_xfers) /= 0 and o_axi_wlast = '0' then
                if unsigned(o_axi_wdata) = 16 then
                  -- restart counter at "1"
                  o_axi_wdata(C_S_AXI_DATA_WIDTH-1 downto 1) <= (others => '0');
                  o_axi_wdata(0) <= '1';
                  sim_data(C_S_AXI_DATA_WIDTH-1 downto 1) <= (others => '0');
                  sim_data(0) <= '1';
                else
                  if (unsigned(sim_data) > unsigned(o_axi_wdata)) and (unsigned(sim_data) < 4) then
                    o_axi_wdata <= std_logic_vector(unsigned(sim_data) + 1);
                  else
                    o_axi_wdata <= std_logic_vector(unsigned(o_axi_wdata) + 1);
                  end if;
                  
                  if unsigned(sim_data) = 16 then
                    sim_data(C_S_AXI_DATA_WIDTH-1 downto 1) <= (others => '0');
                    sim_data(0) <= '1';
                  else
                    sim_data <= std_logic_vector(unsigned(sim_data) + 1);
                  end if;
                end if;
                o_axi_wvalid <= '1';
                o_axi_wstrb  <= "1";
              else
                if unsigned(outstanding_xfers) = 1 then
                  o_axi_wdata <= (others => '0');
                  sim_data <= (others => '0');
                  o_axi_wvalid <= '0';
                  o_axi_wstrb  <= "0";
                else 
                  o_axi_wdata(C_S_AXI_DATA_WIDTH-1 downto 1) <= (others => '0');
                  o_axi_wdata(0) <= '1';
                  sim_data(C_S_AXI_DATA_WIDTH-1 downto 1) <= (others => '0');
                  sim_data(0) <= '1';
                end if;
              end if;
            else
              o_axi_wdata <= o_axi_wdata;
              sim_data    <= sim_data;
            end if;
        --  end if;
        else 
          o_axi_wvalid <= '0';
          o_axi_wstrb  <= "0";
          o_axi_wlast  <= '0';
          o_axi_wdata  <= (others => '0');
          sim_data <= sim_data;
        end if;
      end if;
    end if;
  end process;

  -- accept and ack BRESP
  p_ack_bresp : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
          o_axi_bready <= '1';
      else
        if i_axi_bvalid = '1' then
          o_axi_bready <= '0';
        else
          o_axi_bready <= '1';
        end if;
      end if;
    end if;
  end process;

  -- generate ready signal
  p_slave_tready : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
          i_axis_tready <= '0';
      else
        if sim_start_ready = '1' then
          i_axis_tready <= '1';
        else
          i_axis_tready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- generate valid signal
  p_stimuli_valid : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
          sim_start_write <= '0';
      else
        if o_axi_wlast = '1' and i_axi_wready = '1' then
          outstanding_xfers <= std_logic_vector(unsigned(outstanding_xfers) - 1);
        else
          if unsigned(clk_count) = 3 then
            sim_start_write <= '1';
            outstanding_xfers <= std_logic_vector(unsigned(outstanding_xfers) + 1);
          end if;
          if unsigned(clk_count) = 5 then
            sim_start_write <= '0';
          end if;

          if unsigned(clk_count) = 20 then
            sim_start_write <= '1';
            outstanding_xfers <= std_logic_vector(unsigned(outstanding_xfers) + 1);
          end if;
          if unsigned(clk_count) = 22 then
            sim_start_write <= '0';
          end if;

          if unsigned(clk_count) = 46 then
            sim_start_write <= '1';
            outstanding_xfers <= std_logic_vector(unsigned(outstanding_xfers) + 1);
          end if;
          if unsigned(clk_count) = 48 then
            sim_start_write <= '0';
          end if;
          if unsigned(clk_count) = 56 then
            sim_start_write <= '1';
            outstanding_xfers <= std_logic_vector(unsigned(outstanding_xfers) + 1);
          end if;
          if unsigned(clk_count) = 58 then
            sim_start_write <= '0';
          end if;

--          if unsigned(clk_count) = 78 then
--            sim_start_write <= '1';
--            outstanding_xfers <= std_logic_vector(unsigned(outstanding_xfers) + 1);
--          end if;
--          if unsigned(clk_count) = 85 then
--            sim_start_write <= '0';
--          end if;
        end if;
      end if;
    end if;
  end process;

  -- generate ready signal
  p_stimuli_ready : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
          sim_start_ready <= '0';
      else
        if unsigned(clk_count) = 2 then
          sim_start_ready <= '1';
        end if;
        if unsigned(clk_count) = 52 then
          sim_start_ready <= '0';
        end if;
        if unsigned(clk_count) = 70 then
          sim_start_ready <= '1';
        end if;
--        if unsigned(clk_count) = 27 then
--          sim_start_ready <= '0';
--        end if;
--        if unsigned(clk_count) = 38 then
--          sim_start_ready <= '1';
--        end if;
      end if;
    end if;
  end process;

-- DUT instance and connections
  axi_converter_inst : axi4_to_axis
    generic map (
      C_S_AXI_ID_WIDTH     => C_S_AXI_ID_WIDTH,
      C_S_AXI_DATA_WIDTH   => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH   => C_S_AXI_ADDR_WIDTH,
      C_S_AXI_AWUSER_WIDTH => C_S_AXI_AWUSER_WIDTH,
      C_S_AXI_ARUSER_WIDTH => C_S_AXI_ARUSER_WIDTH,
      C_S_AXI_WUSER_WIDTH  => C_S_AXI_WUSER_WIDTH,
      C_S_AXI_RUSER_WIDTH  => C_S_AXI_RUSER_WIDTH,
      C_S_AXI_BUSER_WIDTH  => C_S_AXI_BUSER_WIDTH,
      C_M_AXIS_DATA_WIDTH  => C_M_AXIS_DATA_WIDTH
    )
    port map (
      AXIS_ACLK      => clk,
      AXIS_ARESETN   => rst_n,

      S_AXI_AWID     =>  o_axi_awid,
      S_AXI_AWADDR   =>  o_axi_awaddr,
      S_AXI_AWLEN    =>  o_axi_awlen,
      S_AXI_AWSIZE   =>  o_axi_awsize,
      S_AXI_AWBURST  =>  o_axi_awburst,
      S_AXI_AWLOCK   =>  o_axi_awlock,
      S_AXI_AWCACHE  =>  o_axi_awcache,
      S_AXI_AWPROT   =>  o_axi_awprot,
      S_AXI_AWQOS    =>  o_axi_awqos,
      S_AXI_AWREGION =>  o_axi_awregion,
      S_AXI_AWUSER   =>  o_axi_awuser,
      S_AXI_AWVALID  =>  o_axi_awvalid,
      S_AXI_AWREADY  =>  i_axi_awready,
      S_AXI_WDATA    =>  o_axi_wdata,
      S_AXI_WSTRB    =>  o_axi_wstrb,
      S_AXI_WLAST    =>  o_axi_wlast,
      S_AXI_WUSER    =>  o_axi_wuser,
      S_AXI_WVALID   =>  o_axi_wvalid,
      S_AXI_WREADY   =>  i_axi_wready,

      S_AXI_BID      =>  i_axi_bid,
      S_AXI_BRESP    =>  i_axi_bresp,
      S_AXI_BUSER    =>  i_axi_buser,
      S_AXI_BVALID   =>  i_axi_bvalid,
      S_AXI_BREADY   =>  o_axi_bready,
      S_AXI_ARID     =>  o_axi_arid,
      S_AXI_ARADDR   =>  o_axi_araddr,
      S_AXI_ARLEN    =>  o_axi_arlen,
      S_AXI_ARSIZE   =>  o_axi_arsize,
      S_AXI_ARBURST  =>  o_axi_arburst,
      S_AXI_ARLOCK   =>  o_axi_arlock,
      S_AXI_ARCACHE  =>  o_axi_arcache,
      S_AXI_ARPROT   =>  o_axi_arprot,
      S_AXI_ARQOS    =>  o_axi_arqos,
      S_AXI_ARREGION =>  o_axi_arregion,
      S_AXI_ARUSER   =>  o_axi_aruser,
      S_AXI_ARVALID  =>  o_axi_arvalid,
      S_AXI_ARREADY  =>  i_axi_arready,
      S_AXI_RID      =>  i_axi_rid,
      S_AXI_RDATA    =>  i_axi_rdata,
      S_AXI_RRESP    =>  i_axi_rresp,
      S_AXI_RLAST    =>  i_axi_rlast,
      S_AXI_RUSER    =>  i_axi_ruser,
      S_AXI_RVALID   =>  i_axi_rvalid,
      S_AXI_RREADY   =>  o_axi_rready,

      M_AXIS_TVALID  =>  o_axis_tvalid,
      M_AXIS_TDATA   =>  o_axis_tdata,
      M_AXIS_TSTRB   =>  o_axis_tstrb,
      M_AXIS_TLAST   =>  o_axis_tlast,
      M_AXIS_TREADY  =>  i_axis_tready 
    );

end bh;
