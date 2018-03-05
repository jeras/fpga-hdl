module uart_rx #(
  // UART parameters
  parameter int BYTESIZE = 8,              // transfer size in bits
  parameter     PARITY   = "NONE",         // parity type "EVEN", "ODD", "NONE"
  parameter int STOPSIZE = 1,              // number of stop bits
  parameter int N_BIT    = 2               // clock cycles per bit
)(
  // system signals
  input  logic           clk,  // clock
  input  logic           rst,  // reset (asynchronous)
  // byte data stream
  input  logic           str_tvalid,
  input  logic   [8-1:0] str_tdata,
  output logic           str_tready,
  // serial signal
  output logic           uart_txd   // transmit
);

localparam int N_LOG = $clog2(N_BIT);  // size of boudrate generator counter

// UART transfer length
localparam int UTL = BYTESIZE + (PARITY!="NONE") + STOPSIZE;

// parity option
localparam bit PRT = (PARITY!="EVEN");

// stream signals
logic str_transfer;

// baudrate counter
logic    [N_LOG-1:0] bdr_cnt;
logic    [N_LOG-1:0] bdr_nxt;
logic                bdr_end;

// bit counter
logic          [3:0] bit_cnt;
logic          [3:0] bit_nxt;
logic                bit_end;

// UART signals
logic [BYTESIZE-1:0] shr_dat;  // data shift register
logic                txd_prt;  // parity bit

//////////////////////////////////////////////////////////////////////////////
// UART transmitter
//////////////////////////////////////////////////////////////////////////////

// baudrate generator from clock (it counts down to 0 generating a baud pulse)
always @ (posedge clk, posedge rst)
if (rst) bdr_cnt <= 'd0;
else     bdr_cnt <= bdr_end ? 'd0 : bdr_nxt;

// next boudrate counter value
assign bdr_nxt = bdr_cnt + 1;

// enable signal for shifting logic
assign bdr_end = bdr_nxt == N_BIT;

// bit counter
always @ (posedge clk, posedge rst)
if (rst) bit_cnt <= 'd0;
else     bit_cnt <= bit_end ? 'd0 : bit_nxt;

// next boudrate counter value
assign bit_nxt = bit_cnt + bdr_end;

// enable signal for shifting logic
assign bit_end = bit_nxt == UTL;

// shift status
always @ (posedge clk, posedge rst)
if (rst)             txd_run <= 1'b0;
else begin
  if (str_transfer)  txd_run <= 1'b1;
  else if (txd_ena)  txd_run <= ~;
end

// data shift register
//
// since shr_dat[0] is used as serial output,
// the proper idle state must be set at reset
always @ (posedge clk)
if (rst) shr_dat <= 'd1;
else
  if (str_transfer)  shr_dat <= {^str_tdata, str_tdata};
  else if (bdr_ena)  shr_dat <= {1'b1, shr_dat[+:1]};
end

// serial output
assign uart_txd <= shr_dat[0];

endmodule: uart_tx
