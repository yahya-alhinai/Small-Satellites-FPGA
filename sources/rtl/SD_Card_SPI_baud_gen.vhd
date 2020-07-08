----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/26/2017 12:51:08 PM
-- Design Name: 
-- Module Name: SD_Card_SPI_baud_gen - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY SD_Card_SPI_baud_gen IS
 GENERIC (
    INIT_BAUD_CLKDIV_c      : INTEGER := 525;
    NORMAL_BAUD_CLK_DIV_c   : INTEGER :=   6
 );
 PORT (
    clk210_p                : IN    STD_LOGIC;    
    reset_p                 : IN    STD_LOGIC;    
    sd_spi_normal_baud_p    : OUT   STD_LOGIC;
    sd_spi_init_baud_p      : OUT   STD_LOGIC
 );
END SD_Card_SPI_baud_gen;

ARCHITECTURE BEHAVIORAL OF SD_Card_SPI_baud_gen IS

    SIGNAL  sd_spi_normal_baud_s    : STD_LOGIC;
    SIGNAL  sd_spi_init_baud_s      : STD_LOGIC;
    SIGNAL  init_baud_count_s       : INTEGER RANGE 0 TO 600;
    SIGNAL  normal_baud_count_s     : INTEGER RANGE 0 TO 600;    
    
BEGIN

    -- output assignments
    sd_spi_init_baud_p      <= sd_spi_init_baud_s;
    sd_spi_normal_baud_p    <= sd_spi_normal_baud_s;    

    -- initialization baud generation
    INIT_BAUD_GEN:
    PROCESS (clk210_p, reset_p) BEGIN
        
        IF reset_p = '1' THEN
            init_baud_count_s   <= 0;
            
        ELSIF RISING_EDGE(clk210_p) THEN
            IF (init_baud_count_s = INIT_BAUD_CLKDIV_c) THEN
                init_baud_count_s   <= 0;
                sd_spi_init_baud_s  <= '1';
            ELSE
                sd_spi_init_baud_s  <= '0';
                init_baud_count_s   <= init_baud_count_s + 1;
            END IF;            
        END IF;
    END PROCESS;
    
    -- Normal Baud generation
    NORMAL_BAUD_GEN:
    PROCESS (clk210_p, reset_p) BEGIN
    
        IF reset_p = '1' THEN
            normal_baud_count_s         <= 0;
            
        ELSIF RISING_EDGE(clk210_p) THEN
            IF (normal_baud_count_s = INIT_BAUD_CLKDIV_c) THEN
                normal_baud_count_s     <= 0;
                sd_spi_normal_baud_s    <= '1';
            ELSE
                sd_spi_normal_baud_s    <= '0';
                normal_baud_count_s     <= normal_baud_count_s + 1;
            END IF;            
        END IF;
    END PROCESS;

END Behavioral;
