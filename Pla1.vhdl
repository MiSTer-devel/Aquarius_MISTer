
-------------------------------------------------------
--- Submodule Pla1.vhdl (Aquarius)
-------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity PLA1 is
port
(
    CLK            : in  std_logic;
    RST            : in  std_logic;

    CFG            : in  std_logic_vector(1 downto 0);

-- CPU interface

    CPU_IN         : in  std_logic_vector(7 downto 0);
    CPU_OUT        : out std_logic_vector(7 downto 0);
    ADDR           : in  std_logic_vector(15 downto 0);
    MEMWR          : in  std_logic;
    IOWR           : in  std_logic;
    IORD           : in  std_logic;

-- memory interface

    VIDEO_WE       : out std_logic;

    DATA_ROM       : in  std_logic_vector(7 downto 0);
    DATA_ROMPACK   : in  std_logic_vector(7 downto 0);
    ROM_EN         : in  std_logic;

    RAM_WE         : out std_logic;
    EXT_WE         : out std_logic;
    RAM_IN         : in  std_logic_vector(7 downto 0);
    RAM_OUT        : out std_logic_vector(7 downto 0);

-- Peripheral interface

    KEY_VALUE      : in  std_logic_vector(7 downto 0);
	 PSG_IN			 : in	 std_logic_vector(7 downto 0);	 
    PSG_SEL        : out std_logic;
    LED_OUT        : out std_logic;
    CASS_OUT       : out std_logic;
    CASS_IN        : in  std_logic;
    VSYNC          : in  std_logic
);
end PLA1;

architecture RTL of PLA1 is

signal ram_selected        : boolean;
signal rom_selected        : boolean;
signal video_selected      : boolean;
signal rompack_selected    : boolean;
signal kbd_swlock_selected : boolean;
signal cass_selected       : boolean;
signal ext_selected        : boolean;
signal sync_selected       : boolean;
signal led_selected        : boolean;
signal psg_selected        : boolean;

signal swlock : std_logic_vector(7 downto 0) := (others => '0');
signal old_wr : std_logic := '0';

begin
	rom_selected        <=  ADDR(15 downto 13) = "000";
	video_selected      <=  ADDR(15 downto 11) = "00110"; -- 2KB RAM
	ram_selected        <=  ADDR(15 downto 12) = X"3";    -- 2KB + 2KB RAM
	rompack_selected    <= (ADDR(15 downto 14) = "11") and (ROM_EN = '1');

	ext_selected        <=  ADDR(15 downto 12) = X"4"    when CFG="01" -- 4KB
                     else  ADDR(15 downto 14) = "01"    when CFG="10" -- 16KB
                     else (ADDR(15) xor ADDR(14)) = '1' when CFG="11" -- 32KB
                     else  false;

	kbd_swlock_selected <=  ADDR( 7 downto  0) = X"FF";
	led_selected        <=  ADDR( 7 downto  0) = X"FE";
	sync_selected       <=  ADDR( 7 downto  0) = X"FD";
	cass_selected       <=  ADDR( 7 downto  0) = X"FC";
	psg_selected        <=  ADDR( 7 downto  1) = "1111011"; -- 0xF6 / 0xF7

	VIDEO_WE <= MEMWR when video_selected else '0';
	RAM_WE   <= MEMWR when ram_selected   else '0';
	EXT_WE   <= MEMWR when ext_selected   else '0';

	CPU_OUT <= KEY_VALUE               when (IORD = '1') and kbd_swlock_selected else
	           PSG_IN						  when (IORD = '1') and psg_selected        else
	           "1111111" & CASS_IN     when (IORD = '1') and cass_selected       else
	           "1111111" & VSYNC       when (IORD = '1') and sync_selected       else
	           DATA_ROM                when (IORD = '0') and rom_selected        else
	           RAM_IN                  when (IORD = '0') and ram_selected        else
	           DATA_ROMPACK xor swlock when (IORD = '0') and rompack_selected    else
	           RAM_IN       xor swlock when (IORD = '0') and ext_selected        else
	           "00000000";

	RAM_OUT <= CPU_IN xor swlock when ext_selected else CPU_IN;

	-- Peripherals write
	PSG_SEL  <= '1' when (IOWR = '1' or IORD = '1') and (psg_selected = true) else '0';

	process begin
		wait until (clk = '1');
		
		old_wr <= IOWR;

		if RST = '1' then

			swlock   <= (others => '0');
			LED_OUT  <= '0';
			CASS_OUT <= '0';

		elsif old_wr = '0' and IOWR = '1' then

			if kbd_swlock_selected then swlock   <= CPU_IN;        end if;
			if led_selected        then LED_OUT  <= not CPU_IN(0); end if;
			if cass_selected       then CASS_OUT <= CPU_IN(0);     end if;

		end if;
	end process;
	  
end RTL;
