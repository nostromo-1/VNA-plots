
This repository will contain several files related to GNUplot calculations of filters and signals in relation to transmission lines.
It simulates a circuit with a certain output impedance Zs (can be a nanoVNA) connected to a transmission line (characteristic impedance Zo, velocity factor k, length l) and connected to a load Zl.

The reference circuit is the following:

[![Circuit](https://github.com/nostromo-1/VNA-plots/blob/main/circuit.png)](https://github.com/nostromo-1/iVNA-plots)

The files are these:
* VNA_plots.plt: It simulates the above circuit, displaying:
  * The Smith Chart as seen by the nanoVNA
  * The phase of the S11 parameter (reflection coefficient) measured by the nanoVNA
  * The Bode plot (frequency response) at the output of the nanoVNA (or circuit): modulus of Vi/Vs
 
 It can also plot the phase of the frequency response Vi/Vs, and modulus/phase of the frequency response at Zl.
 An example of the output is this:
 
 [![Output](https://github.com/nostromo-1/VNA-plots/blob/main/coax1.png)](https://github.com/nostromo-1/iVNA-plots)
 

* filter_effects.plt: It takes an square wave input signal and passes it through the circuit described above, displaying the output signal at Zl. It does so by computing the Fourier coefficients of the input signal and applying them through the filter (which is the reference circuit above). It plots both input and output signals, calculated at a frequency which can be adjusted in the script, so you can see how different frequencies are affected. Note: the input signal does not look like a perfect square wave, due to the Gibbs phenomenon.

An example of the output (it simulates a probe with a RG58 coax connected to a scope, with 50 ohm input impedance and 13 pF capacitance) is this:

[![Output](https://github.com/nostromo-1/VNA-plots/blob/main/filter.png)](https://github.com/nostromo-1/iVNA-plots)
