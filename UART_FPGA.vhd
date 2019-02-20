library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity uart_fpga is
port(
	I_CLK:in std_logic;
	I_CLK_BAUD_COUNT:in std_Logic_vector(15 downto 0);
---inputs for module to calculate generate clock for transmitter and receiver flipflops
	I_reset: in std_logic;

---transmitter module
	I_txdata: in std_logic_vector(7 downto 0);---register we add data into to transmit
	I_txSig: in std_logic;	----signal for starting transmission
	O_txrdy: out std_logic; ----signal for determining if uart is in use
	O_tx: inout std_logic;----output serial data ; I defined port inout in order to connect it to I_rx for
----testing operation but it must be defined out only if it is connected to outer cct

---receiver module
	I_rx : inout std_logic;
	I_rx_cont: in std_logic;---enabling signal for receiving data
	O_rxData: out std_logic_vector(7 downto 0);
	O_rxSig: out std_logic;
	O_rxFrameError:out std_logic;

-- Internal debug ports for inspecting issues
-- These can be removed 
	D_rxClk : out STD_LOGIC;
	D_rxState: out integer;
	D_txClk : out STD_LOGIC;
	D_txState: out integer );

end uart_fpga;

architecture behavioural of uart_fpga is
	signal tx_data : std_logic_vector(7 downto 0) := (others =>'0');----in order to shift I_txdata
	signal tx_state : integer := 0;----initialization of transmission state
	signal tx_rdy:	STD_LOGIC:= '1';----signal 1 means it is not in use
	signal tx:std_logic :='1';---initialization
	
	signal rx_sample_count:integer:=0;--lesah mesh fahmhom
	signal rx_sample_offset:integer:=3;
	--lesah mesh fahmhom
	signal rx_state:integer:=0;
	signal rx_data:std_logic_vector(7 downto 0):= (others =>'0');
	signal rx_sig: std_logic := '0';
	signal rx_frameError: std_logic := '0';
	
	signal rx_clk_counter : integer :=0;
	signal rx_clk_reset: std_logic:='0';
	signal rx_clk_baud_tick : std_logic :='0';
	
	signal tx_clk_counter:integer:=0;
	signal tx_clk:std_logic:='0';
	
	constant OFFSET_START_BIT: integer := 7;
	constant OFFSET_DATA_BITS: integer := 15;
	constant OFFSET_STOP_BIT: integer := 7;
	
	---my test signal for operation to connect transmitter module and receiver module
	signal test_sig:std_logic;
begin

	-- dbg signals
	D_rxClk <= rx_clk_baud_tick;
	D_rxState <= rx_state;
	D_txClk <= tx_clk;
	D_txState <= tx_state;
	test_sig<=o_tx;
	I_rx<=test_sig;
	-- dbg end

---clock generator architecture
	clk_gen: process(I_CLK)
	begin
		if rising_edge(I_CLK) then
			
			if rx_clk_counter = 0 then
				-----X16 sampled so chopoff 4LSB
				rx_clk_counter <= to_integer(unsigned(I_CLK_BAUD_COUNT(15 downto 4)));
				rx_clk_baud_tick <= '1';
			else
				if rx_clk_reset = '1' then
					rx_clk_counter <= to_integer(unsigned(I_CLK_BAUD_COUNT(15 downto 4)));
				else
					rx_clk_counter <= rx_clk_counter - 1;
				end if;
				rx_clk_baud_tick <= '0';
			end if;
		---TX BAUD CLOCK
		if tx_clk_counter=0 then
			---chop off lsb to get clock
			tx_clk_counter<=to_integer(unsigned(I_CLK_BAUD_COUNT(15 downto 1)));
			tx_clk<=not tx_clk;
		else
			tx_clk_counter<=tx_clk_counter-1;
		end if;
	end if;
	end process;
---architecture of receiver module
	O_rxFrameError <= rx_frameError;
	O_rxSig <= rx_sig;---signal indicate that data has been recieved
	
	rx_proc:process(I_CLK, I_reset, I_rx, I_rx_Cont)
	begin
		--RX uses system clock
		if rising_edge(I_CLK) then
			if rx_clk_reset = '1' then---mesh fahem
				rx_clk_reset<='0';
			end if;
			if I_reset = '1' then
				rx_state<=0;
				rx_sig<='0';
				rx_sample_count<=0;
				rx_sample_offset<= OFFSET_START_BIT;
				rx_data<= X"00";
				O_rxData<=X"00";
			elsif I_rx='0' and rx_state=0 and I_rx_cont='1' then---signal I_rxcont to start recieving
				---first encounter of falling edge
				rx_state<=1;---start bit sample stage
				rx_sample_offset<=OFFSET_START_BIT;
				rx_sample_count<=0;
				----bit leading edge
				rx_clk_reset<='1';
			---state 1 recieving start bit '0'
			elsif rx_clk_baud_tick = '1' and I_rx='0' and rx_state=1 then
				----inc sample count
				rx_sample_count <= rx_sample_count + 1;
				if rx_sample_count = rx_sample_offset then
					----start bit sampled
						rx_sig<='0';
						rx_state<=2;
						rx_data<=X"00";
						rx_sample_offset<=OFFSET_DATA_BITS;
						rx_sample_count<=0;
				end if;
			elsif rx_clk_baud_tick = '1' and rx_state >= 2 and rx_state<10 then
				---sampling data
				if rx_sample_count = rx_sample_offset then
					rx_data(6 downto 0)<=rx_data(7 downto 1);---freeing place for recieved bit
					rx_data(7)<=I_rx;---recieving bit
					rx_sample_count<=0;
					rx_state<=rx_state+1;
				else
					rx_sample_count<=rx_sample_count +1;
				end if;
			elsif rx_clk_baud_tick='1' and rx_state=10 then
				if rx_sample_count = OFFSET_STOP_BIT then
					rx_state<=0;
					rx_sig<='1';
					O_rxdata<=rx_data;
					
					if I_rx='1' then
						rx_frameError<='0';
					else
						rx_frameError<='1';
					end if;
				else
					rx_sample_count<=rx_sample_count+1;
				end if;
			end if;
		end if;
	end process;			
				


---architecture of transmitter module
	O_tx<=tx;
	O_txRdy<=tx_rdy;

	tx_proc: process(tx_clk, I_reset, I_txSig, tx_state)
	begin
		---TX BAUD CLOCK
		if rising_edge(tx_clk) then
			if I_reset = '1' then
				tx_state<=0;
				tx_data<= X"00";
				tx_rdy<='1';
				tx<='1';
			else
				if tx_state = 0 and I_txSig ='1' then
					tx_state<=1;
					tx_data<=I_txData;
					tx_rdy <= '0';----signal to indicate uart in use
					tx<='0';----start bit
				elsif tx_state < 9 and tx_rdy='0' then
					tx<=tx_data(0);--taking data from LSB
					tx_data<= '0' & tx_data(7 downto 1);---shifting right tx_data for next op
					tx_state<=tx_state + 1;
				elsif tx_state = 9 and tx_rdy='0' then
					tx<='1';-----stop bit
					tx_rdy <= '1';----to indicate uart is not inuse 
					tx_state<=0;----state initialization for next op
				end if;
			end if;
		end if;
	end process;
end behavioural;
					
			
				




	
	
		
	
	
	
