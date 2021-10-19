# GNUplot script to calculate output of LTI given input. LTI can be a transmission line followed by a load.
# It applies the transfer function to the fourier series of the input to generate the output signal

set terminal qt size 900,740 persist
set dummy t
#unset key
#unset border
set samples 20000

even(n) = (n/2)*2==n  # only integers
sinc(x) = sin(pi*x)/(pi*x)

j = {0.0,1.0}  # imaginary unit
c = 299792458.0  # speed of light in vacuum (m/s)
Zs = 50.0   # output impedance of VNA; the output voltage equivalent is Vs

# Define a transmission line, followed by a load Zl
Zo = 50.0   # characteristic impedance of transmission line
k = 0.66    # velocity factor of transmission line
len = 0.50  # length of transmission line in m
#Res(f) = 15.38*((f/1e9)**0.482)   # ohm/m due to skin effect, twisted cable, https://ieeexplore.ieee.org/document/917765
Res(f) = 6.2*((f/1e9)**0.5)   # ohm/m due to skin effect, RG58
Vp = k*c    # phase velocity in transmission line
fl4 = Vp/(4*len)  # lambda/4 frequency of transmission line
w(f) = 2*pi*f
beta(f) = w(f)/Vp
alfa(f) = Res(f)/(2.0*Zo) # Valid for G=0, R<<wL
gamma_prop(f) = alfa(f) + j*beta(f)  # propagation constant of the transmission line
att(f) = 20*log10(exp(1))*alfa(f*1e6)*100   # attenuation in dB/100m
# end of transmission line definition


# Define the load circuit at coax end (Zl)
C = 13e-12
#L = 160e-9
R = 50
Yl(f) = 1.0/R + (j*w(f)*C) #+ 1.0/(R+j*w(f)*L) #+ 1.0/220
Zl(f) = 1.0/Yl(f)
gammaZl(f) = (Zl(f)-Zo)/(Zl(f)+Zo)  # reflection coefficient at load
# end of load circuit

# calculate Zin at coax input
gammaZin(f) = gammaZl(f) * exp(-2*gamma_prop(f)*len)
Zin(f) = Zo * (1.0+gammaZin(f)) / (1.0-gammaZin(f))

# An impedance Z can be connected in parallel with the transmission line input
# Zeq is the equivalent impedance seen by the VNA at its output port
# Zeq can be only Zin (the coax) or combined with another load Z (in parallel or series)
#L1 = 45e-9
#R1 = 500
#C1 = 4.7e-9
#Zamp(f) = j*w(f)*L1 + 1.0/(j*w(f)*C1) + R1
#Yeq(f) = 1.0/Zin(f) + 1.0/Zamp(f) 
#Zeq(f) = j*w(f)*L1 + 1.0/Ya(f)
Zeq(f) = Zin(f)
#Zeq(f) = 1.0/Yeq(f)

# Reflection coefficient S11 (gamma as seen by VNA)
gammaVNA(f) = (Zeq(f)-Zs)/(Zeq(f)+Zs)
# Transfer funtion at VNA output (or circuit output) (at Zeq): V(Zeq)/Vs
Vratio_Zeq(f) = (1.0+gammaVNA(f))/2
# Transfer function between coax output and input (at Zl): V(Zl)/V(Zeq)
Vratio_coax(f) = (1.0+gammaZl(f))/(1.0+gammaZin(f)) * exp(-gamma_prop(f)*len)
# Transfer function at coax output (at Zl): V(Zl)/Vs
Vratio_Zl(f) = Vratio_Zeq(f) * Vratio_coax(f)

# Transfer function for graphic plot
H(f) = Vratio_Zl(f) 
Heq(f) = Vratio_Zeq(f) 

# define Fourier series coefficients
N = 50  # number of frequencies to sum in the signal
array Ck[N]
# define input signal: a square wave of duty cycle delta, amplitude 1
delta = 0.5
Ck0 = delta
do for [k=1:N] { 
        Ck[k] = delta*sinc(k*delta)*exp(-j*pi*k*delta)
}

freq = 100e6  # fundamental frequency of input signal
period = 1.0/freq
# calculate input signal input(t), signal at Zeq middle(t), signal at Zl output(t)
input(t) = Ck0 + sum [k=1:N] 2*real(Ck[k]*exp(j*k*w(freq)*t)) 
middle(t) = Ck0*Heq(1e-6) + sum [k=1:N] 2*real(Ck[k]*Heq(k*freq)*exp(j*k*w(freq)*t)) 
output(t) = Ck0*H(1e-6) + sum [k=1:N] 2*real(Ck[k]*H(k*freq)*exp(j*k*w(freq)*t)) 

set title "input vs. output"
f_label = sprintf("f=%.1f MHz   Zs=%d ohm", freq/1e6, Zs)
set label f_label at graph 0.05,1.03
set xrange [0:2*period]
set yrange [-0.2:1.2]
#set xtics axis in scale 1,0.1 20
set ytics axis in scale 0.1,0.1 0.1
set grid

plot input(t), output(t) #, middle(t)




