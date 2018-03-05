# Procesorsko vodilo

Ta vaja prikazuje SoC vodilo Avalon MM in v Verilogu napisan RAM pomnilnik.

# Avalon MM standard

Avalonn MM vodilo je definiral FPGA proizvajalec Altera za potrebe svojih SoC sistemov in Nios II procesorja.
Tukaj je opisan samo del signalov in protokola, ki je nujno potreben za osnovno komunikacijo med naprimer procesorjem in pomnilnikom.

V naslednji tabeli so našteti signali vodila Avalon MM kakor jih imenuje standard.
Za širino posameznih signalov so tukaj uporabljene posplošitve.
32 bitno podatkovno vodilo je popolnoma smiselna predpostavka.
Za naslovno vodilo pa je smiseln celoten nabor širin od 0 do 32 bit,
kar predstavlja naslovni prostor od 1 do 2^32=4gibi byte-ov
ali 2^32/4=1gibi 32bitnih besed (glej IEC binarne predpone).

Skratka naslov lahko naslavlja vsako lokacijo velikosti byte posebej, to pomeni,
da je potrebno za dostop do naslednje 32 bitne besede naslov povečati za 4.
Dejansko po Avalon MM standardu naslov na vodilu nikoli ne sme kazati na poljubno lokacijo
ampak vedno na začetek besede (`address[1:0]=2'b00`).
Za granulacijo znotraj besede skrbi signal `byteenable[3:0]`.
Ampak v programu naslov (pointer v C) lahko kaže na lokacijo, ki ni poravnana z 4,
kako se interni procesorjev naslov prevaja v signala vodila `address`
in `byteenable` opisuje poglavje Endianness (ne poznam slovenskega prevoda).

| ime           | širina | smer   | opis                                |
|---------------|--------|--------|-------------------------------------|
| `read`        | 1      | M -> S | zahteva po bralnem ciklu            |
| `write`       | 1      | M -> S | zahteva po pisalnem ciklu           |
| `address`     | 0 - 32 | M -> S | naslov                              |
| `byteenable`  | 4      | M -> S | omogočanje vpisa posameznega byte-a |
| `writedata`   | 32     | M -> S | podatek za vpis                     |
| `readdata`    | 32     | M <- S | prebrani podatek                    |
| `waitrequest` | 1      | M <- S | zahteva za podaljšanje cikla        |

Večina signalov gre v smeri od master proti slave,
kar pomeni da so signali na master strani izhodi in na slave strani vhodi.
Te signale uporablja master, da naredi zahtevek za pisalni ali bralni podatkovni cikel.
Manjši del signalov pa potuje v obratni smeri od slave proti master,
kar pomeni, da so izhodi na slave strani in vhodi na master stani.
Te signale uporablja slave da po potrebi oblikuje podatkovni cikel
in v primeru branja odgovori s prebranim podatkom.

![Avalon master<->slave](../avalon_master_slave.svg)

## Pisalni cikel

Za začetek pisalnega cikla na naslov `A0` master postavi signal write (čas 1).
Pisalni cikel se zaključi, ko master ob prehodu ure zazna neaktivno stanje signala waitrequest (čas 2).
Na sliki so še trije pisalni cikli, med njimi in prvim ciklom je obdobje ene urine periode,
ko vodilo ni aktivo (od časa 2 do 3).
Dostop do naslova A2 traja eno urino periodo (od časa 3 do 4).
Takoj sledi dostop do naslova A2 (čas 4), kjer pa slave zahteva podaljšanje cikla tako,
da postavi signal `waitrequest` v aktivno stanje.
Ob koncu prve urine periode cikla (čas 5) slave umakne signal `waitrequest`,
tako da se cikel ob koncu naslednje urine periode lahko zaključi (čas 6).
Podobno zgleda dostop do naslova `A3`, prav tako je podaljšan za eno urino periodo
in torej traja dve periodi (od časa 6 do 8).

![Avalon write](../avalon_write.svg)

V primeru pisalnega cikla mora master poleg naslova `addres[31:0]` podati
(in ne spreminjati za čas trajanja cikla) tudi podatek za vpis `writedata[31:0]` in masko `byteenable[3:0]`,
s katero pove katere byte bi rad vpisal in katerih ne.
Bit `byteenable[0]` omogoča vpis za byte `writedata[7:0]`,
bit `byteenable[1]` omogoča vpis za byte `writedata[15:8]`,
bit `byteenable[2]` omogoča vpis za byte `writedata[23:16]`,
bit `byteenable[3]` omogoča vpis za byte `writedata[31:24]`.
Dejansko je dovoljenih le 7 kombinacij bitov znotraj `byteenable[3:0]`,
podrobneje so opisana v poglavju Endianness.

Signal `readdata[31:0]` pri pisalnem ciklu nima pomena,
zato ga lahko slave postavi na poljubno vrednost.

## Bralni cikel

Za začetek bralnega cikla iz naslov `A0` master postavi signal read (čas 1).
Bralni cikel cikel se zaključi, ko master ob prehodu ure zazna neaktivno stanje signala `waitrequest` (čas 2),
v tem trenutku master tudi registrira podatek, ki ga je slave postavil na `readdata[31:0]`.
Na sliki so še trije bralni cikli, med njimi in prvim ciklom je obdobje ene urine periode,
ko vodilo ni aktivo (od časa 2 do 3).
Dostop do naslova `A2` traja eno urino periodo (od časa 3 do 4).
Takoj sledi dostop do naslova `A2` (čas 4), kjer pa slave zahteva podaljšanje cikla tako,
da postavi signal `waitrequest` v aktivno stanje.
Ob koncu prve urine periode cikla (čas 5) slave z umikom signala `waitrequest`, nakaže,
da je na vodilo dal tudi veljavne podatke `readdata[31:0]`,
tako da se cikel ob koncu naslednje urine periode lahko zaključi (čas 6),
takrat master tudi registrira podatke.
Podobno zgleda dostop do naslova `A3`, prav tako je podaljšan za eno urino periodo
in torej traja dve periodi (od časa 6 do 8).

![Avalon read](../avalon_read.svg)

V primeru bralnega cikla lahko slave vedno odgovarja
s podatki polne širine `readdata[31:0]` in tako ignorira `byteenable[3:0]`.
Prav tako `writedata[31:0]` nima pomena in lahko master da na vodilo poljubno vrednost.

## Endianness

Avalon MM vodilo je po definiciji *big-endian*,
čeprav ima to pomen le znotraj procesorja (Altera Nios II je *big-endian*)
ali pa kjer vodilo spreminja širino podatkovnega vodila (naprimer 32bit Avalon in 16bit DDR SDRAM).

Naslednja tabela prikazuje dovoljene načine dostopa do pomnilnika (velikost podatka in poravnan naslov) za 32 bitno vodilo (4 byte).
Ostalim kombinacijam se reče neporavnan dostop (unaligned access) in so prepovedane,
običajno prožijo napako vodila (bus error).

Spodnja bita naslova `address[1:0]` sta definirana samo znotraj procesorja,
na 32bitnem vodilu nimata pomena.

| velikost dostopa | `address[31:2]` | `address[1:0]` | `byteenable[3:0]` | `writedata[32:0]` |
|------------------|-----------------|----------------|-------------------|-------------------|
| 1                | 30'hVVVVVVVv    | 2'b00          | 4'b1000           | 32'hVVxxxxxx      |
| 1                | 30'hVVVVVVVv    | 2'b01          | 4'b0100           | 32'hxxVVxxxx      |
| 1                | 30'hVVVVVVVv    | 2'b10          | 4'b0010           | 32'hxxxxVVxx      |
| 1                | 30'hVVVVVVVv    | 2'b11          | 4'b0001           | 32'hxxxxxxVV      |
| 2                | 30'hVVVVVVVv    | 1'b00          | 4'b1100           | 32'hVVVVxxxx      |
| 2                | 30'hVVVVVVVv    | 2'b10          | 4'b0011           | 32'hxxxxVVVV      |
| 4                | 30'hVVVVVVVv    | 2'b00          | 4'b1111           | 32'hVVVVVVVV      |

Legenda:

`0`, `1` - kostanti,

`v`, `V` - definirana vrednost, ki ima vpliv na učinek ciklaV - definirana vrednost, ki ima vpliv na učinek cikla

`x`, `X` - nedefinirana poljubna vrednost, ki nima vpliva na učinek cikla

## Primer: Avalon MM RAM

Dani primer obsega Verilog zapis RAM-a z Avalon MM vmesnikom in testbench kodo,
ki prikaže zaporedje pisalnih in bralnih ciklov do pomnilnika.

### RTL

Koda je sestavljena iz dveh kosov, prvo je Verilog zapis RAM pomnilnika,
ki ga Quartus neposredno prevede v namenske RAM bloke znotraj FPGA vezij.
Navodila, kako zapisati RAM, da se pravilno prevede v FPGA RAM
ponuja Altera v dokumentu "Recommended HDL Coding Styles"
poglavje "Inferring Memory Functions from HDL Code".

Opazite lahko, da RAM pomnilnik vrne prebrani podatek z enim ciklom zakasnitve za podanim naslovom,
to je običajna lastnost tako FPGA kakor ASIC pomnilnikov.

Pomnilnik je razdeljen v 4 kose, za vsak Byte posebej.
Da ne bi bilo potrebno 4 krat pisati podobne kode poskrbi stavek generate.
Verilog prevajalnik odvije generate for zanko v 4 kopije iste kode z različnimi konstantami.

Poleg pomnilnika modul vsebuje tudi kodo za Avalon MM vodilo.
Podatki so preprosto vezani na izhod readdata, waitrequest pa je zvezan tako,
da se pisanje izvede takoj (v enem ciklu) pri branju pa je dodan en cikel zakasnitve (skupaj dva cikla).

```SystemVerilog
module avalon_ram #(
  parameter ADW = 32,              // data width
  parameter ABW = ADW/8,           // byte enable width
  parameter ASZ = 1024,            // memory size
  parameter AAW = $clog2(ASZ/ABW)  // address width
)(
  // system signals
  input            clk,          // clock
  input            rst,          // reset
  // Avalon MM interface
  input            read,
  input            write,
  input  [AAW-1:0] address,
  input  [ABW-1:0] byteenable,
  input  [ADW-1:0] writedata,
  output [ADW-1:0] readdata,
  output           waitrequest
);

wire transfer;

reg [ADW-1:0] mem [0:ASZ-1];
reg [AAW-1:0] address_d;
reg           data_valid;

//////////////////////////////////////////////////////////////////////////////
// memory implementation
//////////////////////////////////////////////////////////////////////////////

genvar i;

// write access (writedata is written the same clock period write is asserted)
generate for (i=0; i<ABW; i=i+1) begin : byte
  // generate code for for each byte in a word
  always @ (posedge clk)
  if (write & byteenable[i])  mem[address][8*i+:8] <= writedata[8*i+:8];
end endgenerate

// read access (readdata is available one clock period after read is asserted)
always @ (posedge clk)
if (read)  address_d <= address;

assign readdata = mem[address_d];

//////////////////////////////////////////////////////////////////////////////
// avalon interface code
//////////////////////////////////////////////////////////////////////////////

// transfer cycle end
assign transfer = (read | write) & ~waitrequest;

always @ (posedge clk)
data_valid <= read & ~data_valid;

// read, write cycle timing
assign waitrequest = ~(write | data_valid);

endmodule
```

### Testbench

Testbench vsebuje task avalon_cycle, ki izvede Avalon MM cikel s podanimi parametri
in ob tem izpiše obsežen opis cikla.
Testbench je zapisan tako, da izvede celoten nabor dovoljenih načinov dostopa.

```SystemVerilog
`timescale 1ns / 1ps

module avalon_ram_tb;

// system clock parameters
localparam real FRQ = 24_000_000;     // clock frequency 24MHz
localparam real CP = 1000000000/FRQ;  // clock period

// Avalon MM parameters
localparam ADW = 32;               // data width
localparam ABW = ADW/8;            // byte enable width
localparam ASZ = 1024;             // address space size in bytes
localparam AAW = $clog2(ASZ/ABW);  // address width

// system_signals
reg            clk;  // clock
reg            rst;  // reset (asynchronous)
// Avalon MM interface
reg            avalon_read;
reg            avalon_write;
reg  [AAW-1:0] avalon_address;
reg  [ABW-1:0] avalon_byteenable;
reg  [ADW-1:0] avalon_writedata;
wire [ADW-1:0] avalon_readdata;
wire           avalon_waitrequest;
// Avalon MM local signals
wire           avalon_transfer;
reg  [ADW-1:0] data;

// request for a dumpfile
initial begin
  $dumpfile("avalon_ram.vcd");
  $dumpvars(0, avalon_ram_tb);
end


// clock generation
initial        clk = 1'b1;
always #(CP/2) clk = ~clk;

// test signal generation
initial begin
  // initially the avalon_ram is under reset end disabled
  rst = 1'b1;
  // Avalon MM interface is idle
  avalon_read  = 1'b0;
  avalon_write = 1'b0;
  repeat (2) @(posedge clk);
  // remove reset
  rst = 1'b0;
  repeat (2) @(posedge clk);
  //  8bit write all, read all bytes
  avalon_cycle (1,  0, 4'b0001, 32'hxxxxxx67, data);
  avalon_cycle (1,  0, 4'b0010, 32'hxxxx45xx, data);
  avalon_cycle (1,  0, 4'b0100, 32'hxx23xxxx, data);
  avalon_cycle (1,  0, 4'b1000, 32'h01xxxxxx, data);
  avalon_cycle (0,  0, 4'b0001, 32'hxxxxxxxx, data);
  avalon_cycle (0,  0, 4'b0010, 32'hxxxxxxxx, data);
  avalon_cycle (0,  0, 4'b0100, 32'hxxxxxxxx, data);
  avalon_cycle (0,  0, 4'b1000, 32'hxxxxxxxx, data);
  repeat (1) @(posedge clk);
  //  8bit write, read byte interleave
  avalon_cycle (1,  4, 4'b0001, 32'h89abcdef, data);
  avalon_cycle (0,  4, 4'b0001, 32'h00000000, data);
  avalon_cycle (1,  4, 4'b0010, 32'h89abcdef, data);
  avalon_cycle (0,  4, 4'b0010, 32'h00000000, data);
  avalon_cycle (1,  4, 4'b0100, 32'h89abcdef, data);
  avalon_cycle (0,  4, 4'b0100, 32'h00000000, data);
  avalon_cycle (1,  4, 4'b1000, 32'h89abcdef, data);
  avalon_cycle (0,  4, 4'b1000, 32'h00000000, data);
  repeat (4) @(posedge clk);
  // 16bit write all, read all
  avalon_cycle (1,  8, 4'b0011, 32'hxxxxba98, data);
  avalon_cycle (1,  8, 4'b1100, 32'hfedcxxxx, data);
  avalon_cycle (0,  8, 4'b0011, 32'hxxxxxxxx, data);
  avalon_cycle (0,  8, 4'b1100, 32'hxxxxxxxx, data);
  repeat (1) @(posedge clk);
  // 16bit write, read interleave
  avalon_cycle (1, 12, 4'b0011, 32'hxxxx3210, data);
  avalon_cycle (0, 12, 4'b0011, 32'hxxxxxxxx, data);
  avalon_cycle (1, 12, 4'b1100, 32'h7654xxxx, data);
  avalon_cycle (0, 12, 4'b1100, 32'hxxxxxxxx, data);
  avalon_cycle (1,  8, 4'b1100, 32'hfedcxxxx, data);
  avalon_cycle (0,  8, 4'b0011, 32'hxxxxxxxx, data);
  repeat (4) @(posedge clk);
  // 32bit write, read
  avalon_cycle (1, 60, 4'b1111, 32'hdeadbeef, data);
  avalon_cycle (0, 60, 4'b1111, 32'hxxxxxxxx, data);
  repeat (2) @(posedge clk);
  $finish(); 
end


// avalon transfer cycle generation task
task avalon_cycle (
  input            r_w,  // 0-read or 1-write cycle
  input  [AAW-1:0] adr,
  input  [ABW-1:0] ben,
  input  [ADW-1:0] wdt,
  output [ADW-1:0] rdt
);
begin
  $display ("Avalon MM cycle start: T=%10tns, %s address=%08x byteenable=%04b writedata=%08x", $time/1000.0, r_w?"write":"read ", adr, ben, wdt);
  // start an Avalon cycle
  avalon_read       <= ~r_w;
  avalon_write      <=  r_w;
  avalon_address    <=  adr;
  avalon_byteenable <=  ben;
  avalon_writedata  <=  wdt;
  // wait for waitrequest to be retracted
  @ (posedge clk); while (~avalon_transfer) @ (posedge clk);
  // end Avalon cycle
  avalon_read       <= 1'b0;
  avalon_write      <= 1'b0;
  // read data
  rdt = avalon_readdata;
  $display ("Avalon MM cycle end  : T=%10tns, readdata=%08x", $time/1000.0, rdt);
end
endtask

// avalon cycle transfer cycle end status
assign avalon_transfer = (avalon_read | avalon_write) & ~avalon_waitrequest;

// instantiate avalon_ram RTL
avalon_ram #(
  .ADW   (ADW),
  .ASZ   (ASZ)
) avalon_ram_i (
  // system
  .clk  (clk),
  .rst  (rst),
  // Avalon
  .read         (avalon_read),
  .write        (avalon_write),
  .address      (avalon_address),
  .byteenable   (avalon_byteenable),
  .writedata    (avalon_writedata),
  .readdata     (avalon_readdata),
  .waitrequest  (avalon_waitrequest)
);

endmodule
```
