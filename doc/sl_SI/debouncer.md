# Debouncer

## Popravljanje odskakovanja tipke

Števec sam po sebi zgleda precej nekoristen,
dejansko tudi v praksi skoraj nikoli ne nastopa kakor samostojen modul,
ampak kakor par vrstic kode v večjem modulu.
Sledi primer praktičnega modula, ki s pomočjo števca preprečuje odskakovanje tipk ([Debounce](https://en.wikipedia.org/wiki/Switch#Contact_bounce)).
Ta modul bo koristno uporabljen v naslednjem delu tečaja, ko so opisani sistemi, ki uporabljajo tipke.
Predstavljen je tudi [LFSR](https://en.wikipedia.org/wiki/Linear-feedback_shift_register) števec,
ki sicer ne šteje binarno in ga je zato težje uporabiti,
zato pa je njegova implementacija preprostejša,
zasede manj logike in lahko teče na višjih frekvencah.

## Testbench

Teorijo odskakovanja tipk bom prepustil [Wikipediji](https://en.wikipedia.org/wiki/Switch#cite_note-4),
točneje priporočam [članek s primeri](http://www.ganssle.com/debouncing.htm).
Za potrebe simulacije bo tesbench generiral signale podobne odskakovanju.
Prva predpostavka je, da odskakovanje, ki ga generira `task` `bounce` ne bo trajalo dlje kakor 10ms.

Modul [debouncer_tb.sv](/hdl/debouncer/debouncer_tb.sv)
```SystemVerilog
`timescale 1ns / 1ps

module debouncer_tb;

// number of debounced signals
localparam DW = 2;

// counter length (max debounce time / clock period)
localparam CP= 200;
localparam CN = 10_000_000 / CP; 

// list of local signals
reg           clk;  // clock
reg  [DW-1:0] d_i;  // debouncer inptu
wire [DW-1:0] d_o;  // debouncer output

integer seed;       // random seed

// request for a dumpfile
initial begin
  $dumpfile("debouncer.vcd");
  $dumpvars(0, debouncer_tb);
end

// clock generation
initial        clk = 1'b1;
always #(CP/2) clk = ~clk;

// initialize random seed
initial seed = 0;

genvar d;
generate for (d=0; d<DW; d=d+1) begin

  // test signal generation
  // keypress timing is asynchronous
  initial begin
    // stable OFF before start for 50ms
    d_i[d] = 1'b0;
    # 50_000_000;
    // switch ON random pulses (max 10ms)
    bounce (d, 1'b1, 30, 5000, 10_000, 100_000, 80);
    // stable ON state for 50ms
    d_i[d] = 1'b1;
    # 50_000_000;
    // switch OFF random pulses (max 10ms)
    bounce (d, 1'b0, 30, 5000, 10_000, 100_000, 80);
    // stable OFF state at the end for 50ms
    d_i[d] = 1'b0;
    # 50_000_000;
    // end simulation
    $finish();
  end

end endgenerate

task automatic bounce (
  input         d,
  input         val,
  input integer t_pulse_min, t_pulse_max,
  input integer t_pause_min, t_pause_max,
  input integer n
);
  integer cnt, t;
begin
  for (cnt=0; cnt<n; cnt=cnt+1) begin
    // short pulses
    d_i[d] =  val;  t = $dist_uniform(seed, t_pulse_min, t_pulse_max);  #t;
    // folowed by longer pauses
    d_i[d] = ~val;  t = $dist_uniform(seed, t_pause_min, t_pause_max);  #t;
  end
end
endtask

// instantiate RTL DUT
debouncer #(
  .CN   (CN)
) debouncer_i [DW-1:0] (
  .clk  (clk),
  .d_i  (d_i),
  .d_o  (d_o)
);

endmodule
```

## RTL

Modul `debounce.sv` ima na vhodu nestabilen signal, na izhodu pa stabiliziran signal.
Za merjenje časa potrebuje modul še uro (izbrana je 50 MHz).
Logika je napisana tako, da če je na prehod ure zaznan pritisk tipke,
pritisk pobriše števec in s tam se postavi izhod modula.
Po zadnjem zaznanem stisku tipke naj števec šteje še 10ms.
Na ta način se popravi odskakovanje ob stisku in izpustu tipke.

Module [debouncer.sv](/hdl/debouncer/debouncer.sv)
```SystemVerilog
module debouncer #(
  parameter CN = 8,         // counter number (sequence length)
  parameter CW = $clog2(CN) // counter width in bits
)(
  input      clk,           // clock
  input      d_i,           // debouncer input
  output reg d_o            // debouncer output
);

reg [CW-1:0] cnt;           // counter
reg          d_r;           // input register

// TODO, check if this is done acording to Altera specifications
initial cnt <= 0;

// prevention of metastability problems
always @ (posedge clk)
d_r <= d_i;

// the counter should start running on a change
always @ (posedge clk)
if (|cnt)          cnt <= cnt - 1;
else if (d_r^d_o)  cnt <= CN;

// when the counter is zero the output should follow the input
always @ (posedge clk)
if (~|cnt) d_o <= d_r;

endmodule
```

Register takoj na vhodu v modul rešuje problem [metastabilnosti](https://en.wikipedia.org/wiki/Metastability_(electronics)),
v danem vezju morda sploh ni nujno potreben, ampak škodi tudi ne.

Podan števec je zaradi preprostosti še binaren,
s parametrom je možno nastaviti točen dolžino štetja,
v danem primeru je to `10ms*50MHz=500_000` urinih ciklov.
Koda je napisana tako, da avtomatično izračuna primerno število bitov števca `$clog2(500000)=20`.
