# UART
Implementation of Universal Asynchronous receiver and transmitter module in Fpga

When do we need a UART?

1) Control the receiving and transmitting time of the data:
Since the data stream has no clock, data recovery depends on the transmitting device and the receiving device operating at close to the same bit rate. The UART receiver is responsible for the synchronization of the serial data stream and the recovery of data characters.

2) Increase the accuracy and decrease the effect of the noise:
The UART system can tolerate a moderate amount of system noise without losing any information.

### Data Format
 ![alt text]( http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/1999f/UART/uart-format.jpg)
 
 ### Modules
- Transmitter Module
- Reciever Module
- Clock Generator Module for adjusting baud_rate
- error checking(frame_error, parity_check, over_run)
| signal| Type | Description |
| ------ | ------ |
| I_CLK | Input CLK |
