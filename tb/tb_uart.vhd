
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.ENV.ALL;

entity tb_uart is
end tb_uart;

architecture Behavioral of tb_uart is

    constant CLK_PERIOD : time := 20 ns;
    constant BIT_PERIOD : time := 8680 ns;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';

    signal tx_start  : std_logic := '0';
    signal tx_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_serial : std_logic;
    signal tx_busy   : std_logic;
    signal tx_done   : std_logic;

    signal rx_data   : std_logic_vector(7 downto 0);
    signal rx_done   : std_logic;
    signal rx_error  : std_logic;

begin

    -- Clock generation: 50 MHz
    clk <= not clk after CLK_PERIOD / 2;

    -- UART transmitter
    TX: entity work.uart_tx
        generic map (
            CLOCK_FREQ => 50000000,
            BAUD_RATE  => 115200
        )
        port map (
            clk       => clk,
            rst       => rst,
            tx_start  => tx_start,
            tx_data   => tx_data,
            tx_serial => tx_serial,
            tx_busy   => tx_busy,
            tx_done   => tx_done
        );

    -- UART receiver
    RX: entity work.uart_rx
        generic map (
            CLOCK_FREQ => 50000000,
            BAUD_RATE  => 115200
        )
        port map (
            clk       => clk,
            rst       => rst,
            rx_serial => tx_serial,
            rx_data   => rx_data,
            rx_done   => rx_done,
            rx_error  => rx_error
        );

    -- Test process
    TEST: process

        procedure send_byte(
            constant value : in std_logic_vector(7 downto 0)
        ) is
        begin

            wait until falling_edge(clk);
            tx_data  <= value;
            tx_start <= '1';

            wait until falling_edge(clk);
            tx_start <= '0';

            -- Wait for received byte
            wait until rx_done = '1';

            assert rx_data = value
                report "ERROR: received data mismatch"
                severity failure;

            assert rx_error = '0'
                report "ERROR: UART framing error"
                severity failure;

            report "PASS: byte " &
                integer'image(to_integer(unsigned(value)))
                severity note;

            wait until tx_busy = '0';
            wait for BIT_PERIOD;

        end procedure;

    begin

        -- Reset
        rst <= '1';
        wait for 100 ns;
        wait until falling_edge(clk);
        rst <= '0';

        -- Send test bytes
        send_byte(x"55");
        send_byte(x"A5");
        send_byte(x"3C");
        send_byte(x"FF");

        report "ALL UART TESTS PASSED"
            severity note;

        finish;

    end process;

    -- Timeout protection
    WATCHDOG: process
    begin
        wait for 1 ms;
        assert false
            report "ERROR: simulation timeout"
            severity failure;
    end process;

end Behavioral;
