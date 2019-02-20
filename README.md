# UART
Implementation of Universal Asynchronous receiver and transmitter module in Fpga

When do we need a UART?

1) Control the receiving and transmitting time of the data:
Since the data stream has no clock, data recovery depends on the transmitting device and the receiving device operating at close to the same bit rate. The UART receiver is responsible for the synchronization of the serial data stream and the recovery of data characters.

2) Increase the accuracy and decrease the effect of the noise:
The UART system can tolerate a moderate amount of system noise without losing any information.

### Data Format
 ![alt text]( http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/1999f/UART/uart-format.jpg)
 > Four states
 - sending start bit state
 - shifting data and sending it
 - sending parity bit
 - sending stop bit
 
 ### Modules
- Transmitter Module
- Reciever Module
- Clock Generator Module for adjusting baud_rate
- error checking(frame_error, parity_check, over_run)

> Transmitter Module

| signal | Type | Description |
| ------ | ------ | ------ |
| I_CLK | Input | system clock |
| I_clk_baud_count | Input | the number of cycles of I_clk between baud ticks |
| I_reset | Input | reset line. ideally, reset whilst changing baud. |
| I_tx_data | Input | data to transmit |
| I_txSig | Input | signal to start transmitting |
| O_txRdy | output | o:indicate uart in use 1:indicate not in use |
| O_tx | output | serial output |
| I_rx | Input | serial input |
| I_rxcont | Input | signal to start recieve |
| O_rxdata | output | data_recieved |
| O_rxsig | output | uart reg is full |
| O_rx_frameError | output | error in transmission and recieving operation |
