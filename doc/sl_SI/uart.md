# UART

UART ([Universal asynchronous receiver/transmitter](https://en.wikipedia.org/wiki/Universal_asynchronous_receiver-transmitter))
je vezje ali modul znotraj SoC, ki implementira ["Asynchronous serial communication"](https://en.wikipedia.org/wiki/Asynchronous_serial_communication)
protokol za komunikacijo sistema z uporabnikom.
Na PC-ju se ponavadi uporablja ime "COM port" ali RS-232.

UART je sicer zastarel in počasen standard ampak se je obdržal v embeded sistemih,
ker je zanesljiv in preprost. Ali z drugimi besedami:
* za osnovno funkcionalnost je potrebno povezati le tri žice, signala RX (sprejem), TX (odaja) in maso
* delovanje in prenesene podatke se lahko preveri kar z osciloskopom
* osnovni gonilnik se lahko napiše v nekaj vrsticah C kode

Najlažje je serijske protokole implementirati s pomikalnim ([shift](https://en.wikipedia.org/wiki/Shift_register)) registrom.
Naslednji primer je Verilog implementacija UART oddajnika (sprejemnik je nekoliko bolj zahteven).
