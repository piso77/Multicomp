----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Erik Piehl
-- 
-- Create Date:    22:27:32 08/18/2016 
-- Design Name: 
-- Module Name:    pager612 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pager612 is
	Port (
			clk 			: in  STD_LOGIC;
			abus			: in  STD_LOGIC_VECTOR (15 downto 0);
			mapperCS		: in  STD_LOGIC;				-- 1 = read/write registers / CS
			mapperWE		: in  STD_LOGIC;				-- 1 = write to register
			mapperRE		: in  STD_LOGIC;				-- 1 = read from register
			dbus_in 		: in  STD_LOGIC_VECTOR (7 downto 0);
			dbus_out 		: out  STD_LOGIC_VECTOR (7 downto 0);
			mapen 			: in  STD_LOGIC;				-- 1 = enable mapping / MM
			translated_addr : out  STD_LOGIC_VECTOR (19 downto 0)
		);
end pager612;

architecture Behavioral of pager612 is
	type abank is array (natural range 0 to 15) of std_logic_vector(7 downto 0);
	signal regs   : abank := (others => (others => '0'));
	signal abus_low		: std_logic_vector(3 downto 0);
	signal abus_high	: std_logic_vector(3 downto 0);
begin
	abus_low <= abus(3 downto 0);
	abus_high <= abus(15 downto 12);

	process(clk)
	begin
		if rising_edge(clk) then
			-- write to paging register / WRITE MODE
			if mapperCS = '1' and mapperWE = '1' then
				regs(to_integer(unsigned(abus_low(3 downto 0)))) <= dbus_in;
			end if;
		end if;
	end process;

	-- read paging register / READ MODE
	dbus_out <=
		regs(to_integer(unsigned(abus_low))) when mapperCS = '1' and mapperRE = '1' else
		x"BF";

	-- mapping mode / MAP MODE
	translated_addr <=
		regs(to_integer(unsigned(abus_high))) & abus(11 downto 0) when mapen = '1' else
		(others => 'Z');

end Behavioral;
