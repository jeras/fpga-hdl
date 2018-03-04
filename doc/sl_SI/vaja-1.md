# Vaja 1: Števec

Prvi del tečaja je posvečen predstavitvi jezika Verilog.
Napisali, simulirali in implementirali (FPGA) bomo preprost binarni števec.

Pogosto so v tekstu uporabljeni angleški izrazi, temu je tako,
da lahko bralec kar najlažje poišče dodatne informacije na internetu.

Tekst ni mišljen kakor referenca za učenje jezika verilog,
opisani so samo osnovni konstrukti.
Če se bralec želi poglobiti v Verilog naj uporabi naslednje vire:
* [asic-world.com](http://www.asic-world.com/verilog/index.html) Verilog tutorial
* [opencores.org](https://opencores.org/) zaloga končanih in nedokončanih HDL izdelkov
* [Verilog-2001](http://sutherland-hdl.com/pdfs/verilog_2001_ref_guide.pdf) Quick Reference

## Osnovni konstrukti jezika Verilog

[Verilog](https://en.wikipedia.org/wiki/Verilog)
(predstavljena je verzija [SystemVerilog](https://en.wikipedia.org/wiki/SystemVerilog) 2012)
je [HDL](https://en.wikipedia.org/wiki/Hardware_description_language) (jezik za modeliranje in simulacijo logičnih vezij).
Dejansko je le [RTL (Register transfer level)](https://en.wikipedia.org/wiki/Register-transfer_level)
podskupina vseh konstruktov primerna za sintezo
(prevajanje v [FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array)
ali [ASIC](https://en.wikipedia.org/wiki/Application-specific_integrated_circuit)),
za simulacijo pa je primeren celoten jezik.
Najprej bo predstavljen RTL šele nato simulacijski del jezika.

![RTL is a subset of HDL](../language_subsets.svg)

### RTL

Začnimo kar s primerom SystemVerilog kode za števec ([counter.sv](/hdl/counter/counter.sv)).
To je RTL model, kar pomeni, da ga je možno sintetizirati. Kasneje bomo to kodo prevedli na FPGA in stanja posameznih registrov opazovali na LED.

Funkcijski opis in izvorna koda
Podani števec je sinhroni avtomat, vse spremembe stanja FlipFlop-ov se dogajajo na pozitivni (iz `0` v `1`) prehod urinega signala `clk`.
Z asinhroni reset signalom `rst` (aktivno stanje `1`) se vsi biti števca `cnt[CW-1:0]` pobrišejo na vrednost `1`.
Štetje je omogočeno, če je `ack` signal postavljen (`1`).
Če je signal za sinhrono brisanje `clr` postavljen (`1`), med tem, ko je štetje omogočeno,
se vsi biti števca `cnt[CW-1:0]` brišejo na stanje `1`, sicer števec odšteva proti nič.
Štetje se ustavi, ko števec doseže vrednost nič.
Signal `out` je postavljen, če je stanje števca različno od nič.

RTL modul števca [counter.sv](/hdl/counter/counter.sv):
```SystemVerilog
module counter #(
  parameter CW = 8,         // counter bit width
  parameter CR = (1<<CW)-1  // counter reset value
)(                                                                                                                                                                      
  input               clk,  // clock
  input               rst,  // reset (asynchronous)
  input               clr,  // clear (synchronous)
  input               ena,  // enable
  output reg [CW-1:0] cnt,  // counter
  output wire         out   // running status output
);
 
always @ (posedge clk, negedge rst)
if (rst)              cnt <= CR;
else if (ena) begin
  if (clr)            cnt <= (1<<CW)-1;
  else if (cnt != 0)  cnt <= cnt - 1;
end
 
assign out = (cnt != 0);
 
endmodule
```

### Verilog konstrukti za zapis RTL kode

Verilog koda je sestavljena iz modulov (v danem primeru samo modul `counter`),
ti imajo podobno vlogo kakor funkcije v jeziku C.
Sicer je možno hraniti več modulov v eni datoteki ampak to se počne le izjemoma,
običajno se hrani po en sam modul na datoteko,
in običajno je ime modula enako imenu datoteke.

Na začetku modula so parametri (konstante, ki se lahko spremenijo, ko se modul instancira)
in signali, ki sestavljajo podatkovni vmesnik (`input`, `output` or `inout` port) modula.
Signali znotraj modula so dveh tipov `wire` (omogoča le gradnjo asinhrone logike, logike z visoko impedan;nimi stanji)
in `logic`/`reg` (omogoča tudi pisanje sinhrone logike - [FlipFlop](https://en.wikipedia.org/wiki/Flip-flop_(electronics))).

Vektorje (signale dolžine `n`-bitov, več kakor 1-bit) se zapiše tako,
da se pred ime signala postavi njegovo dolžino `[n-1:0]`,
če se signal interpretira kakor število (na splošno so vsi signali števila)
je skrajno levi bit `n-1` [MSB](https://en.wikipedia.org/wiki/Most_significant_bit)
in skrajno desni bit `0` [LSB](https://en.wikipedia.org/wiki/Least_significant_bit).
Redkeje se bite razporedi obratno `[0:n-1]`.
Če naj bi vektor predstavljal predznačeno ali ne-predznačeno število
se pred dolžino lahko doda `signed` ali `unsigned` (privzeto).

Bloke kode se definira z rezervirano besedo `begin` na začetku in `end` na koncu,
besedi imata podobno vlogo kakor zaviti oklepaji `{}` v jeziku C.

Znotraj modula je definicija logike.
Vsa logika se izvaja hkrati, možno je sicer tudi pisanje klasične sekvenčne kode,
ampak je to primerno le za simulacijsko kodo.
Stavek `assign` ali stavek `always_comb` se uporablja le za zapis asinhrone logike.
Stavek `always_ff @(clk, rst)` se uporablja za zapis sinhrone logike.
Znotraj stavka `always` je možno prirejati vrednost le signalom tipa `logic`/`reg`.
Obstajajo tudi drugi tipi stavkov, a se uporabljajo skoraj predvsem za simulacije.

Konstrukta `#` in `@` operirata nad časom:
| Konstrukt              | Opis                                                                                |
|------------------------|-------------------------------------------------------------------------------------|
| # number_of_time_units | Vstavi pavzo za dano število časovnih enot.                                         |
| @ (list_of_events)     | Počaka dokler se ne zgodi eden od dogodkov v seznamu (elementi so ločeni z vejico). |

Velikost časovne enote je podana z makro-jem `\```timescale`.

Dogodki iz seznama so lahko dveh tipov.
Za asinhrono logiko se piše kar seznam signalov (`*` pomeni vse signale),
sprememba kateregakoli signala predstavlja dogodek.
Za sinhrono logiko je potrebno pred signal postaviti besedo `posedge` (prehod `0`->`1`) ali `negedge` (prehod `1`->`0`).

Operatorja za prirejanje vrednosti signalom sta = in <=. Njun pomen je na splošno (predvsem so tu mišljene simulacije):
| Operator | Opis                                                                                                         |
|----------|--------------------------------------------------------------------------------------------------------------|
|  =       |     blocking assignment - naslednja operacija se izvede šele, ko se dana operacija zaključi (sekvenčne kode) |
| <=	   | non-blocking assignment - vse operacije se izvedejo naenkrat                                                 |

Operator `=`, ki sledi stavku assign ne blokira.
Za zapis RTL kode, se operator `=` uporablja običajno le znotraj asinhronih funkcij,
znotraj `always_ff` stavkov se uporablja operator `<=`.
Podrobneje bodo razlike med operatorji opisane v poglavju o simulacijah.

Številska konstanta se lahko zapiše z bitno širino.
`8\'b1111011` (binarno), `8'h7b` (hexadecimalno) in `8'd123` (decimalno) so ekvivalenti zapisi 8 bitnega števila 123.
Število bitov v konstanti je pomembno zaradi veriženja manjših vektorjev v večje.
Zapis `{cnt, 2'b00}` predstavlja vektor `cnt`, ki sta mu bila na desni pripeta dva bita vrednosti `0`.
Podobno je možno večkrat verižiti isti vektor, vektor `cnt` dolžine `n` se skopira v vektor dolžine `M*n` z zapisom `{M{cnt}}`.

Dejansko ima lahko vsak bit v Verilog simulaciji enega od štirih stanj `0`, `1`, `X` (nedoločena vrednost) ali `Z` (visoka impedanca),
podrobneje bodo stanja opisana kasneje.

Matematični operatorji (niso vsi našteti):
| Operator              | Opis                                                     |
|-----------------------|----------------------------------------------------------|
| `==` `!=` `===` `!==` | enakost, neenakost dveh vektorjev                        |
| `<<` `>>` `<<<` `>>>` | pomik bitov v vektorju levo, desno                       |
| `+` `-` `*` `/` `**`  | seštevanje, odštevanje, množenje, deljenje, potenciranje |
| `~` `&` `|` `^`       | bitni operatorji: negacija, in, ali, izključitveni ali   |

## Hierarhija

Podobno kakor v sekvenčnih programskih jezikih, kjer se neko funkcijo lahko kliče večkrat,
lahko v jeziku Verilog uporabimo več instanc istega modula.
Naprimer na procesorsko vodilo nataknemo večkrat isti UART vmesnik.
Ker HDL opisuje paralelno logiko, vsaka instanca nekega modula zasede svoj del čipa.

Ob instanciranju modula se priključi signale na njegov vmesnik, lahko pa se tudi spremeni parametre.
Najkrajši način priključevanja je z naštevanjem signalov v enakem vrstnem redu kakor se pojavljajo v definiciji modula:
```SystemVerilog
counter #(CW) counter_i (clk, rst, ena, clr, cnt, out);
```
Ampak običajno se raje eksplicitno napiše na kateri signal vmesnika
se priključuje kateri zunanji signal (glej znotraj `counter_tb.sv` spodaj).
V primeru večih instanc istega modula mora imeti vsaka instanca svoje ime.

Za potrebe logične simulacije sistema se testirani RTL instancira znotraj testbench Verilog kode.
Testbench generira testne signale, cilj je testiranje funkcionalnosti RTL modula. 

Pri podanem sistemu z števcem hierarhija za potrebe testiranja izgleda takole (uporabljena so imena instanc ne modulov):
```
top: + counter_tb
      -- counter_i
```
Modul na vrhu hierarhije je *top modul*.

## Testbench

Testbench je program, ki je namenjen testiranju neke druge (običajno RTL) kode.
Testbench generira signale, ki okoli testiranega modula ustvarijo okolje podobno okolju v katerem se bo modul uporabljal.
Cilj je poustvariti čim več situacij za katere je modul napisan in opazovati če se modul obnaša po pričakovanjih.

### Funkcijski opis in izvorna koda

Testbench modul `counter_tb` generira konstanten urin signal s periodo 20ns (50Mhz).
Na začetku simulacije `rst` signal aktiven za nekaj urinih period, nato se sinhrono z uro `clk` umakne.
Čez nekaj period se postavi signal `ena` in s tem omogoči štetje.
Števec naj šteje do `0`, nakar se ga čez nekaj period ure s signalom `clr` pobriše na same enice.
Za nekaj urinih ciklov se opazuje stanje sistema z aktivnim `clr` nakar se ga umakne.
Še enkrat se počaka, da se števec izteče, nakar se simulacija zaključi.

Testbench modul za števec [counter_tb.sv](/hdl/counter/counter_tb.sv):
```SystemVerilog
`timescale 1ns / 1ps

module counter_tb;

// counter width local parameter
localparam CW = 3;

// list of local signals
reg           rst;  // clock
reg           clk;  // reset (asynchronous)
reg           ena;  // clear (synchronous)
reg           clr;  // enable
wire [CW-1:0] cnt;  // counter
wire          out;  // running status output

// request for a dumpfile
initial begin
  $dumpfile("counter.vcd");
  $dumpvars(0, counter_tb);
end

// clock generation
initial    clk = 1'b1;
always #10 clk = ~clk;

// test signal generation
initial begin
  // initially the counter is under reset end disabled
  rst = 1'b1;
  clr = 1'b0;
  ena = 1'b0;
  repeat (2) @(posedge clk);
  // remove reset
  rst = 1'b0;
  repeat (2) @(posedge clk);
  // enable counter
  ena = 1'b1;
  repeat (8) @(posedge clk);
  // test the clear functionality
  clr = 1'b1;
  repeat (4) @(posedge clk);
  clr = 1'b0;
  repeat (8) @(posedge clk);
  $finish(); 
end

// instantiate counter RTL
counter #(
  .CW   (CW)
) counter_i (
  .clk  (clk),
  .rst  (rst),
  .ena  (ena),
  .clr  (clr),
  .cnt  (cnt),
  .out  (out)
);

endmodule
```

### Verilog konstrukti za testbench kodo

Najprej so v kodi našteti uporabljeni signali.
Signali, ki bi jih radi neposredno krmilili (`clk`, `rst`, `ena`, `clr`) morajo biti tipa `logic`,
signali katerih stanje le opazujemo (`cnt`, `out`) so tipa `wire`.

Stavek `initial` vsebuje kodo, ki se zažene le enkrat ob startu simulacije.
Če želimo opazovati časovne diagrame simulacije,
je potrebno (odvisno od simulatorja) definirati `$dumpfile` in seznam signalov,
ki jih želimo opazovati z `$dumpvars` (najlažje kar vsi signali).

Urin signal `clk` teče ves čas simulacije in vsi ostali signali se sinhronizirajo na uro.
`clk` je inicializiran na `1` nato se negira vsake 10 urinih enot
(enota definirana kakor `1ns`, kar daje urin signal s periodo 20ns ali 50MHz).

Glavni `initial` stavek ustvarja pravilno sosledje testnih signalov,
pavze med krmilnimi signali so sinhronizirane z sistemsko uro `clk`.
Stavek `repeat (2) @(posedge clk);` vstavi v simulacijo 2 periodi sistemske ure,
nato se simulacija nadaljuje z naslednjim stavkom.

Ker je dana simulacija namenjena testiranju RTL modula,
je del testbench kode tudi instanca modula `counter`.

## Simulacija

Simulacije omogoča testiranje kode brez potrebe po implementaciji. Uporablja se predvsem v prvih fazah razvoja, ko koda še ni razvita dovolj daleč, da bi bila FPGA implementacija uporabna, uporablja se pa tudi v kasnejših fazah razvoja, za preverjanje, če kak popravek v kodi pokvari nekaj kar je že delovalo pravilno.

Za potrebe razvoja in testranja ima simulacija dosti prednosti pred implementacijo:
za razvoj ni potrebna nobena strojna oprema
kratka pot od RTL spremembe do zaključka testa (ker ni potrebe po dolgotrajni FPGA implementaciji)
podroben vpogled v dogajanje v notranjosti logičnega vezja (na FPGA implementaciji je možno opazovati le IO signale)
možno je opazovati stanje sistema v času pred napako
možno je napisati dodatno testno kodo, ki bolj nazorno prikaže pravilnost delovanja (preverjanje protokolov)
možno je testirati situacije, ki se običajno ne pojavljajo ob normalni uporabi (lahko se pa pojavijo ob spremembi okolja)
Ima pa simulacija tudi nekaj slabosti:
koda, ki deluje v simulatorju ne deluje nujno tudi v implementaciji, možno je, da se je sploh ne da implementirati
simulacija je le aproksimacija realnega sistema, sploh to velja za IO
simulacija teče počasneje od implementacije, sploh se to pozna ob testiranju programske opreme, ki teče na procesorju znotraj simulatorja
Obstajajo še kombinirane rešitve, ki so posledično kombinacija dobrih in slabih lastnosti simulacije in implementacije. FPGA proizvajalci naprimer ponujajo orodja, s katerimi je možno opazovati interne signale pred in po napaki. Drugi pristop je simulacija z poenostavljenim RTL modelom, ta omogoča večjo hitrost simulacije.
Simulacija z OpenSource orodji
Navodila so napisana za simulator Icarus Verilog in prikazovalnik časovnih diagramov GTKWave na operacijskem sistemu Ubuntu 9.10 (Karmic Koala). Sicer je možno uporabljena programa instalirati tudi na Wndows ali Mac OS X, vendar je to izven namena tega članka. Prednost OpenSource orodij je v tem, da ne postavljajo omejitev na uporabo. ModelSim, ki ga dobimo zastonj ob Alterinem razvojnem okolju naprimer omejuje število vrstic kode, ki jo je možno simulirati.

Predhodno je potrebno instalirati dve novi aplikaciji:
$ sudo apt-get install verilog gtkwave

Naštete korake je možno zagnati s skripto iverilog_gtkwave.scr, ki je priložena v priponki na dnu strani.

Prvi korak je prevajanje Verilog kode (testbench in RTL), generira se skriptna koda counter.out
$ iverilog -o counter.out counter_tb.v counter.v
v drugem koraku se zažene simulator, ta generira časovne diagrame counter.vcd
$ vvp counter.out
za prikaz časovnih diagramov se zažene
$ gtkwave counter.vcd gtkwave.sav &
datoteka gtkwave.sav vsebuje seznam signalov, ki naj bojo prikazani, če se jo izpusti, je še vedno možno izbrati signale ročno.

Časovni diagram simulacije števca:


Simulacija z ModelSim Altera Edition
ModelSim je vrhunski profesionalni HDL simulator, eden izmed treh velikih. Za ta tečaj je uporabljen, ker ga FPGA proizvajalca Altera in Xilinx prilagata svoji zastonjski ponudbi. Zastonjska verzija je sicer omejena na simulacijo 10,000 vrstic kode (kar zadošča za manjše projekte) in je počasnejša od plačljive, hkrati pa ponuja večjo funkcionalnost in je hitrejša kakor OpenSource programi.

Za začetek bo primeren tutorial, za zahtevnejše projekte pa se mora uporabnik spopasti s kar obsežno dokumentacijo.

Tutorial za ModelSim se nahaja v instalacijski mapi /installdir/modelsim_ase/docs/pdfdocs/modelsim_tut.pdf (pot morate prilagoditi svojemu operacijskemu sistemu). Preberite si poglavje 3 "Basic Simulation", ki prav tako temelji na primeru s števcem. Priporočam, da poizkusite najprej primer iz tutoriala, nato pa še tukaj opisani primer števca (izvorna koda je v priponki spodaj counter.tgz ali pa jo poberete iz GIT skladišča).
Implementacija
Implementacija je postopek s katerim se Verilog (lahko tudi VHDL, sheme, ...) izvorna koda prevede v konfiguracijsko datoteko za FPGA vezje. Podoben, zahtevnejši postopek obstaja za ASIC vezja, vendar ne bo opisan v tem tečaju.

Naslednji koraki so potrebni za implementacijo, večino jih opravi razvojno okolje brez dodatnega posredovanja uporabnika.
parser (preveri, če je koda v skladu z standardizirano sintakso jezika)
synthesizer (prevede Verilog kodo v elemente logičnih vezij - registri, avtomati, seštevalniki, množilniki, pomnilniški bloki, IO priključki, ...)
optimizer (razdre hierarhijo in optimizira sekvenčno logiko ter nekatere avtomate)
fitter (preslika registre, sekvenčno logiko, vodila, pomnilnike, IO, ... na vire v izbranem FPGA vezju)
timing analysis (izračuna zakasnitve vseh signalov in preveri, če je dana implementacija podanim hitrosnim zahtevam)
Vsak od teh korakov javlja svojo tip opozoril in napak. Uporabnik mora spremljati opozorila in popravljati napake. Naslednji del tečaja bo povedal več o običajnih napakah pri pisanju logičnih vezij
Projekt DE1_blink
Implementacija
Projekt DE1_blink (najdete ga spodaj med priponkami) je implementacija števca na DE1 razvojni ploščici. Števec podoben tistemu opisanemu zgoraj je vezan na sponke FPGA vezja, ki so nadalje vezane na zelene LED, tako da je možno opazovati stanje števca.

Projekt obsega tri datoteke:
DE1_blink.v (Verilog koda, kjer so našteti vsi IO signali DE1 plošče in zapisana je koda števca)
DE1_blink.qpf (Quartus II projekt)
DE1_blink.qsf (vsebuje seznam datotek z izvorno kodo, seznam pin-ov in poimenovanih signalov priključenih nanje, ...)
Projekt je potrebno odpreti z orodjem Quartus, nakar se ga prevede z opcijo v meniju "Processing -> Start Compilation".
Programiranje v FPGA

