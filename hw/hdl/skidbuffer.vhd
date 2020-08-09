--
-- DVB IP
--
-- source: https://raw.githubusercontent.com/suoto/fpga_cores/master/src/skidbuffer.vhd
-- modified by Alexandre Amory

-- Copyright 2019 by Suoto <andre820@gmail.com>
--
-- This file is part of DVB IP.
--
-- DVB IP is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- DVB IP is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with DVB IP.  If not, see <http://www.gnu.org/licenses/>.

-- ##########################################################################
-- ## Based on Dan Gisselquist's skidbuffer.v the original can be found in ##
-- ## https://github.com/ZipCPU/wb2axip/blob/master/rtl/skidbuffer.v       ##
-- ##########################################################################

--------------------------------------------------------------------------------
--
-- Filename: 	skidbuffer.v
--
-- Project:	WB2AXIPSP: bus bridges and other odds and ends
--
-- Purpose:	A basic SKID buffer.
--
--	Skid buffers are required for high throughput AXI code, since the AXI
--	specification requires that all outputs be registered.  This means
--	that, if there are any stall conditions calculated, it will take a clock
--	cycle before the stall can be propagated up stream.  This means that
--	the data will need to be buffered for a cycle until the stall signal
--	can make it to the output.
--
--	Handling that buffer is the purpose of this core.
--
--	On one end of this core, you have the s_valid_i and s_data_i inputs to
--	connect to your bus interface.  There's also a registered s_ready_o
--	signal to signal stalls for the bus interface.
--
--	The other end of the core has the same basic interface, but it isn't
--	registered.  This allows you to interact with the bus interfaces
--	as though they were combinatorial logic, by interacting with this half
--	of the core.
--
--	If at any time the incoming !stall signal, m_ready_i, signals a stall,
--	the incoming data is placed into a buffer.  Internally, that buffer
--	is held in r_data with the r_valid flag used to indicate that valid
--	data is within it.
--
-- Parameters:
--	DW or data width
--		In order to make this core generic, the width of the data in the
--		skid buffer is parameterized
--
--
--	OPT_OUTREG
--		Causes the outputs to be registered
--
--
-- Creator:	Dan Gisselquist, Ph.D.
--		Gisselquist Technology, LLC
--

---------------
-- Libraries --
---------------
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
            o_last_i <= (s_valid_i = '1' or r_valid = '1') and (s_last_i = '1');
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
