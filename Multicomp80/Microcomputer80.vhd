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

		sramData		: inout std_logic_vector(7 downto 0);
		sramAddress	: out std_logic_vector(15 downto 0);
		n_sRamWE		: out std_logic;
		n_sRamCS		: out std_logic;
		n_sRamOE		: out std_logic;

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

rom1 : entity work.Z80_BASIC_ROM -- 8KB BASIC
port map(
	addra => cpuAddress(12 downto 0),
	clka => clk,
	douta => basRomData
);

-- ____________________________________________________________________________________
-- RAM GOES HERE

ram1: entity work.InternalRam4K
port map
(
	address => cpuAddress(11 downto 0),
	clock => clk,
	data => cpuDataOut,
	wren => not(n_memWR or n_internalRam1CS),
	q => internalRam1DataOut
);

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
	access_regs => mapperCS,
	write_enable => not n_ioWR,
	page_reg_read => not n_ioRD,
	mapen => not n_basRomCS,
	abus_high => '0' & cpuAddress(15 downto 13),
	abus_low => cpuAddress(3 downto 0),
	dbus_in => cpuDataOut,
	dbus_out => mapperDataOut
--	translated_addr => x"0000"
);

-- ____________________________________________________________________________________
-- MEMORY READ/WRITE LOGIC GOES HERE

n_ioWR <= n_WR or n_IORQ;
n_memWR <= n_WR or n_MREQ;
n_ioRD <= n_RD or n_IORQ;
n_memRD <= n_RD or n_MREQ;

-- ____________________________________________________________________________________
-- CHIP SELECTS GO HERE

n_basRomCS <= '0' when cpuAddress(15 downto 13) = "000" else '1'; --8K at bottom of memory
n_internalRam1CS <= '0' when cpuAddress(15 downto 12) = "0010" else '1';

n_interface1CS <= '0' when cpuAddress(7 downto 1) = "1000000" and (n_ioWR='0' or
					n_ioRD = '0') else '1'; -- 2 Bytes $80-$81
mapperCS <= '1' when cpuAddress(7 downto 4) = "1001" and (n_ioWR='0' or
					n_ioRD = '0') else '0'; -- 16 Bytes $90-$9F

-- ____________________________________________________________________________________
-- BUS ISOLATION GOES HERE

cpuDataIn <=
	interface1DataOut when n_interface1CS = '0' else
	basRomData when n_basRomCS = '0' else
	internalRam1DataOut when n_internalRam1CS= '0' else
	mapperDataOut when mapperCS='1' else
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
