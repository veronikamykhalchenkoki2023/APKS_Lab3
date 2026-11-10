
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_rx is
    generic (
        CLOCK_FREQ : integer := 50000000;
        BAUD_RATE  : integer := 115200
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        rx_serial : in  std_logic;
        rx_data   : out std_logic_vector(7 downto 0);
        rx_done   : out std_logic;
        rx_error  : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is

    constant CLKS_PER_BIT : integer := CLOCK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;

    signal clk_count : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal bit_index : integer range 0 to 7 := 0;

    signal data_reg : std_logic_vector(7 downto 0) :=
        (others => '0');

    signal done_reg  : std_logic := '0';
    signal error_reg : std_logic := '0';

begin

    rx_data  <= data_reg;
    rx_done  <= done_reg;
    rx_error <= error_reg;

    process(clk)
    begin
        if rising_edge(clk) then

            done_reg <= '0';
            error_reg <= '0';

            if rst = '1' then
                state <= IDLE;
                clk_count <= 0;
                bit_index <= 0;
                data_reg <= (others => '0');
                done_reg <= '0';
                error_reg <= '0';

            else
                case state is

                    when IDLE =>
                        clk_count <= 0;
                        bit_index <= 0;

                        if rx_serial = '0' then
                            state <= START_BIT;
                        end if;

                    when START_BIT =>
                        if clk_count = (CLKS_PER_BIT-1)/2 then
                            if rx_serial = '0' then
                                clk_count <= 0;
                                state <= DATA_BITS;
                            else
                                state <= IDLE;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                    when DATA_BITS =>
                        if clk_count = CLKS_PER_BIT-1 then
                            clk_count <= 0;
                            data_reg(bit_index) <= rx_serial;

                            if bit_index = 7 then
                                state <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                    when STOP_BIT =>
                        if clk_count = CLKS_PER_BIT-1 then
                            clk_count <= 0;

                            if rx_serial = '1' then
                                done_reg <= '1';
                            else
                                error_reg <= '1';
                            end if;

                            state <= IDLE;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
