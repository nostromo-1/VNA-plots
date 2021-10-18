
This repository will contain several files related to GNUplot calculations of filters and signals in relation to transmission lines.
It simulates a circuit with a certain output impedance Zs (can be a nanoVNA) connected to a transmission line (characteristic impedance Zo, velocity factor k, length l) and connected to a load Zl.

The reference circuit is the following:
[![Circuit](https://github.com/nostromo-1/VNA-plots/blob/main/circuit.png)](https://github.com/nostromo-1/iVNA-plots)

The files are these:
* VNA-plots: It simulates the above circuit, displaying:
  * The Smith Chart as seen by the nanoVNA
  * The phase of the S11 parameter (reflection coefficient) measured by the nanoVNA
  * The Bode plot (frequency response) at the output of the nanoVNA (or circuit)


