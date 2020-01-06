-- This file is copyright by Grant Searle 2014
-- You are free to use this file in your own projects but must never charge for it nor use it without
-- acknowledgement.
-- Please ask permission from Grant Searle before republishing elsewhere.
-- If you use this file or any part of it, please add an acknowledgement to myself and
-- a link back to my main web site http://searle.hostei.com/grant/
-- and to the "multicomp" page at http://searle.hostei.com/grant/Multicomp/index.html
--
-- Please check on the above web pages to see if there are any updates before using this file.
-- If for some reason the page is no longer available, please search for "Grant Searle"
-- on the internet to see if I have moved to another web hosting service.
--
-- Grant Searle
-- eMail address available on my main web page link above.

library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity Microcomputer is
	port(
		n_reset		: in std_logic;
		clk33			: in std_logic;

		sram_data		: inout std_logic_vector(7 downto 0);
		sram_addr		: out std_logic_vector(19 downto 0);
		n_sram_we		: out std_logic;
		n_sram_ce		: out std_logic;
		n_sram_oe		: out std_logic;

		rxd1			: in std_logic;
		txd1			: out std_logic;
		rts1			: out std_logic;

		rxd2			: in std_logic;
		txd2			: out std_logic;
		rts2			: out std_logic;

		videoSync	: out std_logic;
		video			: out std_logic;

		videoR0		: out std_logic;
		videoG0		: out std_logic;
		videoB0		: out std_logic;
		videoR1		: out std_logic;
		videoG1		: out std_logic;
		videoB1		: out std_logic;
		hSync			: out std_logic;
		vSync			: out std_logic;

		ps2Clk		: inout std_logic;
		ps2Data		: inout std_logic;

		sdCS			: out std_logic;
		sdMOSI		: out std_logic;
		sdMISO		: in std_logic;
		sdSCLK		: out std_logic;
		driveLED		: out std_logic :='1'
	);
end Microcomputer;

architecture struct of Microcomputer is

	signal n_WR							: std_logic;
	signal n_RD							: std_logic;
	signal cpuAddress					: std_logic_vector(15 downto 0);
	signal cpuDataOut					: std_logic_vector(7 downto 0);
	signal cpuDataIn					: std_logic_vector(7 downto 0);

	signal mapperAddress				: std_logic_vector(19 downto 0);

	signal basRomData					: std_logic_vector(7 downto 0);
	signal internalRam1DataOut		: std_logic_vector(7 downto 0);
	signal internalRam2DataOut		: std_logic_vector(7 downto 0);
	signal interface1DataOut		: std_logic_vector(7 downto 0);
	signal interface2DataOut		: std_logic_vector(7 downto 0);
	signal mapperDataOut			: std_logic_vector(7 downto 0);
	signal sdCardDataOut				: std_logic_vector(7 downto 0);

	signal n_memWR						: std_logic :='1';
	signal n_memRD 					: std_logic :='1';

	signal n_ioWR						: std_logic :='1';
	signal n_ioRD 						: std_logic :='1';

	signal n_MREQ						: std_logic :='1';
	signal n_IORQ						: std_logic :='1';

	signal n_int1						: std_logic :='1';
	signal n_int2						: std_logic :='1';

	signal n_externalRamCS			: std_logic :='1';
	signal n_internalRam1CS			: std_logic :='1';
	signal n_internalRam2CS			: std_logic :='1';
	signal n_basRomCS					: std_logic :='1';
	signal n_interface1CS			: std_logic :='1';
	signal n_interface2CS			: std_logic :='1';
	signal mapperCS					: std_logic :='0';
	signal n_sdCardCS					: std_logic :='1';

	signal serialClkCount			: std_logic_vector(15 downto 0);
	signal cpuClkCount				: std_logic_vector(5 downto 0);
	signal sdClkCount					: std_logic_vector(5 downto 0);
	signal cpuClock					: std_logic;
	signal serialClock				: std_logic;
	signal sdClock						: std_logic;
	signal clk							: std_logic;

begin
-- ____________________________________________________________________________________
-- CPU CHOICE GOES HERE

cpu1 : entity work.t80s
generic map(mode => 1, t2write => 1, iowait => 0)
port map(
	reset_n => n_reset,
	clk_n => cpuClock,
	wait_n => '1',
	int_n => '1',
	nmi_n => '1',
	busrq_n => '1',
	mreq_n => n_MREQ,
	iorq_n => n_IORQ,
	rd_n => n_RD,
	wr_n => n_WR,
	a => cpuAddress,
	di => cpuDataIn,
	do => cpuDataOut
);

-- ____________________________________________________________________________________
-- ROM GOES HERE

rom1 : entity work.Z80_BASIC_ROM -- 4KB BASIC
port map(
	addra => cpuAddress(11 downto 0),
	clka => clk,
	douta => basRomData
);

-- ____________________________________________________________________________________
-- RAM GOES HERE

sram_addr <= mapperAddress;
sram_data <= cpuDataOut when n_memWR='0' else (others => 'Z');
n_sram_we <= n_memWR or n_externalRamCS;
n_sram_oe <= n_memRD or n_externalRamCS;
n_sram_ce <= n_externalRamCS;

-- ____________________________________________________________________________________
-- INPUT/OUTPUT DEVICES GO HERE

io1 : entity work.bufferedUART
port map(
	clk => clk,
	n_wr => n_interface1CS or n_ioWR,
	n_rd => n_interface1CS or n_ioRD,
	n_int => n_int1,
	regSel => cpuAddress(0),
	dataIn => cpuDataOut,
	dataOut => interface1DataOut,
	rxClock => serialClock,
	txClock => serialClock,
	rxd => rxd1,
	txd => txd1,
	n_cts => '0',
	n_dcd => '0',
	n_rts => rts1
);

mapper: entity work.pager612
port map(
	clk => clk,
	mapperCS => mapperCS,
	mapperWE => not n_ioWR,
	mapperRE => not n_ioRD,
	mapen => n_basRomCS,
	abus => cpuAddress,
	dbus_in => cpuDataOut,
	dbus_out => mapperDataOut,
	translated_addr => mapperAddress
);

-- ____________________________________________________________________________________
-- MEMORY READ/WRITE LOGIC GOES HERE

n_ioWR <= n_WR or n_IORQ;
n_memWR <= n_WR or n_MREQ;
n_ioRD <= n_RD or n_IORQ;
n_memRD <= n_RD or n_MREQ;

-- ____________________________________________________________________________________
-- CHIP SELECTS GO HERE

n_basRomCS <= '0' when cpuAddress(15 downto 12) = "0000" else '1'; --4K at bottom of memory
n_interface1CS <= '0' when cpuAddress(7 downto 1) = "1000000" and (n_ioWR='0' or
					n_ioRD = '0') else '1'; -- 2 Bytes $80-$81
mapperCS <= '1' when cpuAddress(7 downto 1) = "1001000" and (n_ioWR='0' or
					n_ioRD = '0') else '0'; -- 2 Bytes $90-$91
n_externalRamCS<= not n_basRomCS;

-- ____________________________________________________________________________________
-- BUS ISOLATION GOES HERE

cpuDataIn <=
	interface1DataOut when n_interface1CS = '0' else
	basRomData when n_basRomCS = '0' else
	mapperDataOut when mapperCS='1' else
	sram_data when n_externalRamCS= '0' else
	x"FF";

-- ____________________________________________________________________________________
-- SYSTEM CLOCKS GO HERE

-- SUB-CIRCUIT CLOCK SIGNALS

pll: entity work.clk_wiz_v3_6 PORT MAP(
		CLK_IN1 => clk33,
		CLK_OUT1 => clk
	);

serialClock <= serialClkCount(15);
process (clk)
begin
	if rising_edge(clk) then
		if cpuClkCount < 4 then -- 4 = 10MHz, 3 = 12.5MHz, 2=16.6MHz, 1=25MHz
			cpuClkCount <= cpuClkCount + 1;
		else
			cpuClkCount <= (others=>'0');
		end if;
		if cpuClkCount < 2 then -- 2 when 10MHz, 2 when 12.5MHz, 2 when 16.6MHz, 1 when 25MHz
			cpuClock <= '0';
		else
			cpuClock <= '1';
		end if;

		if sdClkCount < 49 then -- 1MHz
			sdClkCount <= sdClkCount + 1;
		else
			sdClkCount <= (others=>'0');
		end if;
		if sdClkCount < 25 then
			sdClock <= '0';
		else
			sdClock <= '1';
		end if;

		-- Serial clock DDS
		-- 50MHz master input clock:
		-- OR INCREMENT = (BAUDRATE * 16 * 65526) / 50000000
		-- Baud Increment
		-- 115200 2416
		-- 57600 1208
		-- 38400 805
		-- 19200 403
		-- 9600 201
		-- 4800 101
		-- 2400 50
		-- 1200 25
		-- 300 6
		serialClkCount <= serialClkCount + 201;
	end if;
end process;

end;
