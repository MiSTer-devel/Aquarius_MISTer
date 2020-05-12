library IEEE;
use IEEE.std_logic_1164.all;

entity PS2_to_matrix is port
(
    clk      : in  std_logic;
    reset    : in  std_logic;

    sfrdatao : out std_logic_vector(7 downto 0);
    addr     : in  std_logic_vector(15 downto 8);
	 
	 pad0     : out std_logic_vector(9 downto 0);
	 pad1     : out std_logic_vector(9 downto 0);

    psdatai  : in  std_logic_vector(7 downto 0);
	 pspress  : in  std_logic;
	 psdataex : in  std_logic;
    psstate  : in  std_logic
);
end PS2_to_matrix;

architecture behavioral of PS2_to_matrix is

    Constant KEY_A:             std_logic_vector (7 downto 0) := X"1C";
    Constant KEY_B:             std_logic_vector (7 downto 0) := X"32";
    Constant KEY_C:             std_logic_vector (7 downto 0) := X"21";
    Constant KEY_D:             std_logic_vector (7 downto 0) := X"23";
    Constant KEY_E:             std_logic_vector (7 downto 0) := X"24";
    Constant KEY_F:             std_logic_vector (7 downto 0) := X"2B";
    Constant KEY_G:             std_logic_vector (7 downto 0) := X"34";
    Constant KEY_H:             std_logic_vector (7 downto 0) := X"33";
    Constant KEY_I:             std_logic_vector (7 downto 0) := X"43";
    Constant KEY_J:             std_logic_vector (7 downto 0) := X"3B";
    Constant KEY_K:             std_logic_vector (7 downto 0) := X"42";
    Constant KEY_L:             std_logic_vector (7 downto 0) := X"4B";
    Constant KEY_M:             std_logic_vector (7 downto 0) := X"3A";
    Constant KEY_N:             std_logic_vector (7 downto 0) := X"31";
    Constant KEY_O:             std_logic_vector (7 downto 0) := X"44";
    Constant KEY_P:             std_logic_vector (7 downto 0) := X"4D";
    Constant KEY_Q:             std_logic_vector (7 downto 0) := X"15";
    Constant KEY_R:             std_logic_vector (7 downto 0) := X"2D";
    Constant KEY_S:             std_logic_vector (7 downto 0) := X"1B";
    Constant KEY_T:             std_logic_vector (7 downto 0) := X"2C";
    Constant KEY_U:             std_logic_vector (7 downto 0) := X"3C";
    Constant KEY_V:             std_logic_vector (7 downto 0) := X"2A";
    Constant KEY_W:             std_logic_vector (7 downto 0) := X"1D";
    Constant KEY_X:             std_logic_vector (7 downto 0) := X"22";
    Constant KEY_Y:             std_logic_vector (7 downto 0) := X"35";
    Constant KEY_Z:             std_logic_vector (7 downto 0) := X"1A";
    Constant KEY_0:             std_logic_vector (7 downto 0) := X"45";
    Constant KEY_1:             std_logic_vector (7 downto 0) := X"16";
    Constant KEY_2:             std_logic_vector (7 downto 0) := X"1E";
    Constant KEY_3:             std_logic_vector (7 downto 0) := X"26";
    Constant KEY_4:             std_logic_vector (7 downto 0) := X"25";
    Constant KEY_5:             std_logic_vector (7 downto 0) := X"2E";
    Constant KEY_6:             std_logic_vector (7 downto 0) := X"36";
    Constant KEY_7:             std_logic_vector (7 downto 0) := X"3D";
    Constant KEY_8:             std_logic_vector (7 downto 0) := X"3E";
    Constant KEY_9:             std_logic_vector (7 downto 0) := X"46";
    Constant KEY_APOSTROPHE:    std_logic_vector (7 downto 0) := X"0E";
    Constant KEY_MINUS:         std_logic_vector (7 downto 0) := X"4E";
    Constant KEY_EQUAL:         std_logic_vector (7 downto 0) := X"55";
    Constant KEY_BACK_SLASH:    std_logic_vector (7 downto 0) := X"5D";
    Constant KEY_BKSP:          std_logic_vector (7 downto 0) := X"66";
    Constant KEY_SPACE:         std_logic_vector (7 downto 0) := X"29";
    Constant KEY_TAB:           std_logic_vector (7 downto 0) := X"0D";
    Constant KEY_CAPS:          std_logic_vector (7 downto 0) := X"58";
    Constant KEY_L_SHFT:        std_logic_vector (7 downto 0) := X"12";
    Constant KEY_L_CTRL:        std_logic_vector (7 downto 0) := X"14";
    Constant KEY_L_ALT:         std_logic_vector (7 downto 0) := X"11";
    Constant KEY_R_SHFT:        std_logic_vector (7 downto 0) := X"59";
    Constant KEY_ENTER:         std_logic_vector (7 downto 0) := X"5A";
    Constant KEY_ESC:           std_logic_vector (7 downto 0) := X"76";
    Constant KEY_F1:            std_logic_vector (7 downto 0) := X"05";
    Constant KEY_F2:            std_logic_vector (7 downto 0) := X"06";
    Constant KEY_F3:            std_logic_vector (7 downto 0) := X"04";
    Constant KEY_F4:            std_logic_vector (7 downto 0) := X"0C";
    Constant KEY_F5:            std_logic_vector (7 downto 0) := X"03";
    Constant KEY_F6:            std_logic_vector (7 downto 0) := X"0B";
    Constant KEY_F7:            std_logic_vector (7 downto 0) := X"83";
    Constant KEY_F8:            std_logic_vector (7 downto 0) := X"0A";
    Constant KEY_F9:            std_logic_vector (7 downto 0) := X"01";
    Constant KEY_F10:           std_logic_vector (7 downto 0) := X"09";
    Constant KEY_F11:           std_logic_vector (7 downto 0) := X"78";
    Constant KEY_F12:           std_logic_vector (7 downto 0) := X"07";
    Constant KEY_SCROLL:        std_logic_vector (7 downto 0) := X"7E";
    Constant KEY_RIGHT_BRACKET: std_logic_vector (7 downto 0) := X"54";
    Constant KEY_NUM:           std_logic_vector (7 downto 0) := X"77";
    Constant KEY_KP_ASTERISK:   std_logic_vector (7 downto 0) := X"7C";
    Constant KEY_KP_MINUS:      std_logic_vector (7 downto 0) := X"7B";
    Constant KEY_KP_PLUS:       std_logic_vector (7 downto 0) := X"79";
    Constant KEY_KP_PERIOD:     std_logic_vector (7 downto 0) := X"71";
    Constant KEY_KP_0:          std_logic_vector (7 downto 0) := X"70";
    Constant KEY_KP_1:          std_logic_vector (7 downto 0) := X"69";
    Constant KEY_KP_2:          std_logic_vector (7 downto 0) := X"72";
    Constant KEY_KP_3:          std_logic_vector (7 downto 0) := X"7A";
    Constant KEY_KP_4:          std_logic_vector (7 downto 0) := X"6B";
    Constant KEY_KP_5:          std_logic_vector (7 downto 0) := X"73";
    Constant KEY_KP_6:          std_logic_vector (7 downto 0) := X"74";
    Constant KEY_KP_7:          std_logic_vector (7 downto 0) := X"6C";
    Constant KEY_KP_8:          std_logic_vector (7 downto 0) := X"75";
    Constant KEY_KP_9:          std_logic_vector (7 downto 0) := X"7D";
    Constant KEY_LEFT_BRACKET:  std_logic_vector (7 downto 0) := X"5B";
    Constant KEY_SEMI_COLON:    std_logic_vector (7 downto 0) := X"4C";
    Constant KEY_ACCENT:        std_logic_vector (7 downto 0) := X"52";
    Constant KEY_COMMA:         std_logic_vector (7 downto 0) := X"41";
    Constant KEY_PERIOD:        std_logic_vector (7 downto 0) := X"49";
    Constant KEY_SLASH:         std_logic_vector (7 downto 0) := X"4A";

    -- Extended keys

    Constant E_KEY_KP_ENTER:    std_logic_vector (7 downto 0) := X"5A";
    Constant E_KEY_KP_SLASH:    std_logic_vector (7 downto 0) := X"4A";
    Constant E_KEY_R_ARROW:     std_logic_vector (7 downto 0) := X"74";
    Constant E_KEY_D_ARROW:     std_logic_vector (7 downto 0) := X"72";
    Constant E_KEY_L_ARROW:     std_logic_vector (7 downto 0) := X"6B";
    Constant E_KEY_U_ARROW:     std_logic_vector (7 downto 0) := X"75";
    Constant E_KEY_PG_DN:       std_logic_vector (7 downto 0) := X"7A";
    Constant E_KEY_END:         std_logic_vector (7 downto 0) := X"69";
    Constant E_KEY_DELETE:      std_logic_vector (7 downto 0) := X"71";
    Constant E_KEY_PG_UP:       std_logic_vector (7 downto 0) := X"7D";
    Constant E_KEY_HOME:        std_logic_vector (7 downto 0) := X"6C";
    Constant E_KEY_INSERT:      std_logic_vector (7 downto 0) := X"70";
    Constant E_KEY_APPS:        std_logic_vector (7 downto 0) := X"2F";
    Constant E_KEY_R_ALT:       std_logic_vector (7 downto 0) := X"11";
    Constant E_KEY_R_GUI:       std_logic_vector (7 downto 0) := X"27";
    Constant E_KEY_R_CTRL:      std_logic_vector (7 downto 0) := X"14";
    Constant E_KEY_L_GUI:       std_logic_vector (7 downto 0) := X"1F";

    -- Commands from PS2

    Constant C_KEY_EXTENDED:    std_logic_vector (7 downto 0) := X"E0";
    Constant C_KEY_BREAK:       std_logic_vector (7 downto 0) := X"F0";
    Constant C_KEY_ACKNOWLEDGE: std_logic_vector (7 downto 0) := X"FA";
    Constant C_KEY_RST_FAILED:  std_logic_vector (7 downto 0) := X"AA";
    Constant C_KEY_RST_PASSED:  std_logic_vector (7 downto 0) := X"FC";

    -- Commands from Host

    Constant C_KEY_RESET:       std_logic_vector (7 downto 0) := X"FF";
    Constant C_KEY_SCAN_CODE:   std_logic_vector (7 downto 0) := X"F0";
    Constant C_KEY_SET_LEDS:    std_logic_vector (7 downto 0) := X"ED";

	 
	 signal old_psstate : std_logic;
begin

	proc_scan : process

		variable key_matrix  : std_logic_vector(47 downto 0);
		variable padnum      : std_logic;

		begin
			wait until (clk = '1');

			 if reset = '1' then
				pad0 <= (others => '0');
				pad1 <= (others => '0');
				key_matrix := (others => '1');
				padnum := '0';

			 elsif (old_psstate /= psstate) then
				case psdatai is
					when KEY_2          => key_matrix(0)  := not pspress;
					when KEY_W          => key_matrix(1)  := not pspress;
					when KEY_1          => key_matrix(2)  := not pspress;
					when KEY_Q          => key_matrix(3)  := not pspress;
					when KEY_L_SHFT     => key_matrix(4)  := not pspress;
					when KEY_R_SHFT     => key_matrix(4)  := not pspress;
					when KEY_L_CTRL     => key_matrix(5)  := not pspress;

					when KEY_3          => key_matrix(6)  := not pspress;
					when KEY_E          => key_matrix(7)  := not pspress;
					when KEY_S          => key_matrix(8)  := not pspress;
					when KEY_Z          => key_matrix(9)  := not pspress;
					when KEY_SPACE      => key_matrix(10) := not pspress;
					when KEY_A          => key_matrix(11) := not pspress;

					when KEY_5          => key_matrix(12) := not pspress;
					when KEY_T          => key_matrix(13) := not pspress;
					when KEY_4          => key_matrix(14) := not pspress;
					when KEY_R          => key_matrix(15) := not pspress;
					when KEY_D          => key_matrix(16) := not pspress;
					when KEY_X          => key_matrix(17) := not pspress;

					when KEY_6          => key_matrix(18) := not pspress;
					when KEY_Y          => key_matrix(19) := not pspress;
					when KEY_G          => key_matrix(20) := not pspress;
					when KEY_V          => key_matrix(21) := not pspress;
					when KEY_C          => key_matrix(22) := not pspress;
					when KEY_F          => key_matrix(23) := not pspress;

					when KEY_8          => key_matrix(24) := not pspress;
					when KEY_I          => key_matrix(25) := not pspress;
					when KEY_7          => key_matrix(26) := not pspress;
					when KEY_U          => key_matrix(27) := not pspress;
					when KEY_H          => key_matrix(28) := not pspress;
					when KEY_B          => key_matrix(29) := not pspress;

					when KEY_9          => key_matrix(30) := not pspress;
					when KEY_O          => key_matrix(31) := not pspress;
					when KEY_K          => key_matrix(32) := not pspress;
					when KEY_M          => key_matrix(33) := not pspress;
					when KEY_N          => key_matrix(34) := not pspress;
					when KEY_J          => key_matrix(35) := not pspress;

					when KEY_MINUS      => key_matrix(36) := not pspress;
					when KEY_SLASH      => key_matrix(37) := not pspress;
					when KEY_0          => key_matrix(38) := not pspress;
					when KEY_P          => key_matrix(39) := not pspress;
					when KEY_L          => key_matrix(40) := not pspress;
					when KEY_COMMA      => key_matrix(41) := not pspress;

					when KEY_EQUAL      => key_matrix(42) := not pspress;
					when KEY_BKSP       => key_matrix(43) := not pspress;
					when KEY_ACCENT     => key_matrix(44) := not pspress;
					when KEY_ENTER      => key_matrix(45) := not pspress;
					when KEY_SEMI_COLON => key_matrix(46) := not pspress;
					when KEY_PERIOD     => key_matrix(47) := not pspress;

					when KEY_TAB        => padnum := padnum xor pspress; pad0 <= (others => '0'); pad1 <= (others => '0');

					when E_KEY_R_ARROW  => if padnum = '0' then pad0(0) <= pspress; else pad1(0) <= pspress; end if;
					when E_KEY_L_ARROW  => if padnum = '0' then pad0(1) <= pspress; else pad1(1) <= pspress; end if;
					when E_KEY_D_ARROW  => if padnum = '0' then pad0(2) <= pspress; else pad1(2) <= pspress; end if;
					when E_KEY_U_ARROW  => if padnum = '0' then pad0(3) <= pspress; else pad1(3) <= pspress; end if;
					when KEY_F1         => if padnum = '0' then pad0(4) <= pspress; else pad1(4) <= pspress; end if;
					when KEY_F2         => if padnum = '0' then pad0(5) <= pspress; else pad1(5) <= pspress; end if;
					when KEY_F3         => if padnum = '0' then pad0(6) <= pspress; else pad1(6) <= pspress; end if;
					when KEY_F4         => if padnum = '0' then pad0(7) <= pspress; else pad1(7) <= pspress; end if;
					when KEY_F5         => if padnum = '0' then pad0(8) <= pspress; else pad1(8) <= pspress; end if;
					when KEY_F6         => if padnum = '0' then pad0(9) <= pspress; else pad1(9) <= pspress; end if;
					
					when others         => null;
				end case;
			end if;

			old_psstate <= psstate;

			sfrdatao<= "11" &
					  ( (key_matrix( 5 downto  0) or (std_logic_vector(5 downto 0)'range => addr(15)) ) and
						 (key_matrix(11 downto  6) or (std_logic_vector(5 downto 0)'range => addr(14)) ) and
						 (key_matrix(17 downto 12) or (std_logic_vector(5 downto 0)'range => addr(13)) ) and
						 (key_matrix(23 downto 18) or (std_logic_vector(5 downto 0)'range => addr(12)) ) and
						 (key_matrix(29 downto 24) or (std_logic_vector(5 downto 0)'range => addr(11)) ) and
						 (key_matrix(35 downto 30) or (std_logic_vector(5 downto 0)'range => addr(10)) ) and
						 (key_matrix(41 downto 36) or (std_logic_vector(5 downto 0)'range => addr(9))  ) and
						 (key_matrix(47 downto 42) or (std_logic_vector(5 downto 0)'range => addr(8))  ) );
  end process;


end behavioral;

