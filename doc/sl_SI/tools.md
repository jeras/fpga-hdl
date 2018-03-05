# Orodja (programska oprema)

Za potrebe udeležbe na tečaju je potrebno instalirati precej programske opreme.
Razdeljena je na tri dele, FPGA razvojno okolje (tečaj uporablja predvsem Altera opremo),
odprtokodno razvojno okolje (uporabljeno bo, zadnjih stopnjah tečaja)
in programska oprema za [nadzor razvoja kode](https://en.wikipedia.org/wiki/Version_control) (GIT, Subversion).

## FPGA razvojno okolje

Tečaj bo temeljil na razvojnem okolju proizvajalca [Altera (Intel FPGA)](https://www.altera.com/),
vključno z njihovim okoljem za načrtovanje procesorskih sistemov SOPC Builder procesorjem [Nios II](https://www.altera.com/products/processors/overview.html).
Odločitev za Altero ni samoumevna, z nadaljnjim razvojem tečaja je cilj doseči neodvisnost od posameznega proizvajalca,
po možnosti z Open Source razvojnimi okolji in SoC gradniki (OpenCores).

Če kdo premore FPGA razvojno okolje kakega drugega proizvajalca
([Xilinx](http://www.xilinx.com/), [Lattice](http://www.latticesemi.com/), Microsemi (https://www.microsemi.com/products/fpga-soc/fpga-and-soc), ...)
lahko prinese in uporablja tega.
Del tečaja sicer temelji na Alterinem pocesorju Nios II,
tako da za ta del tečaja Xilinx programska oprema ne zadošča,
lahko si pa udeleženci sami prikrojijo tečaj po svoje, če teko želijo.

### Altera software (priporočen SW)

Zaželeno je, da vsak sodelujoči na tečaju instalira [našteto programsko opremo](https://www.altera.com/products/design-software/fpga-design/quartus-prime/download.html),
v nasprotnem primeru bo njegovo/njeno sodelovanje oteženo.
Instalacija je možna za operacijske sisteme Winwows (XP, Vista, na Windows 7 dela vse razen USB) in Linux (z nekaj dela lahko tudi Ubuntu).

* Quartus II Web Edition
* Nios II Embedded Design Suite
* ModelSim®-Altera® Starter Edition

Seveda lahko tudi plačljivo različico, v tem primeru boste potrebovali veljavno licenco.

Navodila za instalacijo na Ubuntu:
```bash
apt-get install tcsh
```

http://www.alteraforum.com/forum/showthread.php?t=5893&highlight=ubuntu

ne dela na novejših kernelih, ker ni omogočen usbfs.

### Xilinx software (alternativen SW)

Kakor alternativa je primerno programsko okolje ISE WebPACK Design Software ali Vivado proizvajalca Xilinx.

## Odprtokodno razvojno okolje

Odprtokodno razvojno okolje sestavljajo simulator Icarus Verilog (Verilog HDL) ali GHDL (VHDL) in prikazovalnik časovnih diagramov GTKWave.
Pomembni, ne pa tudi nujni sta tudi Verilog orodji Covered in Verilator.
Ti programi sicer ne omogočajo FPGA implementacije,
zadoščajo pa za vse vse faze razvoja (simulacija in od proizvajalca neodvisna RTL koda) pred implementacijo.

### Instalacija na Ubuntu

Instalirati je potrebno dva paketa verilog in gtkwave, to lahko storite v grafičnem okolju ali pa v terminalu zaženete:
```bash
sudo apt-get install verilog gtkwave
```

### Instalacija na Windows

Na voljo so [kombinirani paketi za instalacijo Icarus Verilog in GTKWave](http://bleyer.org/icarus/).
Orodji sta potem na voljo v Windows orodni vrstici (cmd) pod imeni iverilog in gtkwave.

## Nadzor razvoja kode

To poglavje opisuje programsko opremo za nadzor razvoja kode, omenjena sta GIT in Subversion,
med bolj znanimi so pa še CVS (je zastarel a se še dosti uporablja), Mercurial, Bazaar, ...
Za tiste, ki se še niso srečali z temi orodji (bolj pogosta so v poklicnem okolju ali OpenSource projektih) sledi kratek opis čemu služijo.
Sicer pa se bo GIT uporabljal za dostop do zadnje verzije izvorne kode raznih projektov, ki so uporabljeni kakor primeri v tečaju.

Ob razvoju programske opreme (ali ob pisanju kakega daljšega dokumenta) avtor pogosto potrebuje starejšo verzijo kode (dokumenta).
Najosnovnejša metoda je preimenovanje datoteke z dodajanjem oštevilčenih pripon
(naprimer `datoteka_01.doc`, `datoteka_02.doc`, ... `datoteka_nn.doc`).
Problemi so znani vsakemu, ki je uporabljal to metodo, prej ali slej pride do zbrke.

Programi za nadzor izvorne kode omogočajo pregledno spremljanje zgodovine projekta.
Preprosto je spremljati spremembe nastale v vseh korakih med dvema verzijama projekta,
to je predvsem koristno pri iskanju na novo vnesenih napak.
Še več prednosti se pokaže, ko na projektu dela več oseb,
in je potrebno določiti, kje kdaj in kdo je napisal kodo, ki je pripeljala do napake.

### GIT

Zadnja verzija izvorne kode za projekte uporabljene v okviru tečaja se nahaja pri spletnem ponudniku github,
točneje projekt fpga-hdl (tukaj si je možno pogledati vsebino projekta preko spletnega vmesnika).

Na strani Github se nahajajo tudi vodila za uporab za Windows OS sicer pa naredite naslednje.
Potreben je program za GIT protokol za Windows-e naprimer msysgit, zadnja verzija je (bila) 1.7.0.2-preview.
Zaženite exe in potrdite vse privzete nastavitve.

Za dostop do projektov je potrebno narediti mapo na disku C: kamor boste postavljali Verilog projekte naprimer C:\Workplace.
Pot je lahko tudi drugačna, pomembno je predvsem, da pot do mape ne vsebuje presledkov in slovenskih črk, zato mapa "My documents" ni primerna.

Znotraj te mape pritisnite desno tipko in v meniju izberite "Git Bash" in zaženite vrstico (brez začetnega dolarskega znaka):
```bash
$ git clone git://github.com/jeras/fpga-hdl.git
```
Ali pa uporabite http port če ste za požarnim zidom:
```bash
$ git clone http://github.com/jeras/fpga-hdl.git
```
Sedaj se v izbrani mapi nahaja zadnja verzija kode. Bash CLI okno lahko sedaj zaprete.

Če želite posodobiti datoteke na računalniku na najnovejšo verzijo lahko ponovno klonirate vso kodo
ali pa ponovno odprete Git Bash v mapi z projekti in zaženete pull, kar bo samo osvežilo projekt z novimi spremembami iz serverja.
```bash
$ git pull origin
```
Kasneje bodo sledila osnovna navodila, kako posodabljati kodo na novejšo verzijo
in morda bo del tečaja tudi delo v razvojni skupini in bodo opisane tudi temu namenjene funkcije.

### Subversion

Subversion sicer ni neposredno uporabljen za projekte v okviru tečaja,
je pa uporabljen na strani OpenCores.org,
kjer se nahaja večina odprtokodnih FPGA in HDL projektov (navodila za uporabo).
