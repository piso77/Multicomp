library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pager is
	Port (
			clk 			: in  STD_LOGIC;
			abus			: in  STD_LOGIC_VECTOR (15 downto 0);
			mapperCS		: in  STD_LOGIC;
			mapperWE		: in  STD_LOGIC;
			mapperRE		: in  STD_LOGIC;
			dbus_in 		: in  STD_LOGIC_VECTOR (7 downto 0);
			dbus_out 		: out  STD_LOGIC_VECTOR (7 downto 0);
			translated_addr : out  STD_LOGIC_VECTOR (19 downto 0)
		);
end pager;

architecture Behavioral of pager is
	type abank is array (natural range 0 to 15) of std_logic_vector(7 downto 0);
	signal banks		: abank := (others => (others => '0'));
	signal nbank		: natural range 0 to 15;
	signal abus_high	: natural range 0 to 15;
	signal cfgreg		: std_logic_vector(1 downto 0);
	signal mapen		: std_logic := '0';
begin
	cfgreg <= abus(1 downto 0);

	-- banks config registers
	process(clk)
	begin
		if rising_edge(clk) then
			if mapperCS = '1' and mapperWE = '1' then
				if cfgreg = "00" then
					nbank <= to_integer(unsigned(dbus_in));
				elsif cfgreg = "01" then
					banks(nbank) <= dbus_in;
				elsif cfgreg = "10" then
					mapen <= dbus_in(0);
				end if;
			end if;
		end if;
	end process;

	-- read back config registers
	dbus_out <=
		std_logic_vector(to_unsigned(nbank, dbus_out'length)) when mapperCS = '1' and mapperRE = '1' and abus(0) = '0' else
		banks(nbank) when mapperCS = '1' and mapperRE = '1' and abus(0) = '1' else
		(others => 'Z');

	-- mapen: transparent mode / mapping mode
	abus_high <= to_integer(unsigned(abus(15 downto 12)));
	translated_addr <=
		banks(abus_high) & abus(11 downto 0) when mapen = '1' else
		b"0000" & abus;
end Behavioral;
