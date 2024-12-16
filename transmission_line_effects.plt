# GNUplot script to calculate output of LTI given input. LTI can be a transmission line followed by a load.
# It applies the transfer function to the fourier series of the input to generate the output signal

set terminal qt size 900,740 persist
set multiplot layout 2,1 title "Effect of loaded transmission line on input signal"
set dummy t
set print "-"  # print output is stdout
#unset key
#unset border
set samples 20000

# define some functions
even(n) = (n/2)*2==n  # only integers
sinc(x) = (x==0)?1.0:sin(pi*x)/(pi*x)
w(f) = 2*pi*f

# define some constants
j = {0.0,1.0}    # imaginary unit
c = 299792458.0  # speed of light in vacuum (m/s)
Zs = 50.0   # output impedance of VNA; the output voltage equivalent is Vs

# Define a transmission line
Zo = 50.0   # characteristic impedance of transmission line
vf = 0.66   # velocity factor of transmission line
len = 1.40  # length of transmission line in m
#Res(f) = 15.38*((f/1e9)**0.482)   # ohm/m due to skin effect, twisted cable, https://ieeexplore.ieee.org/document/917765
Res(f) = 0.1 + 4.9*((f/1e9)**0.5)   # ohm/m due to DC resistance + skin effect, RG58
#Res(f) = 0.17 + 2.5*((f/1e9)**0.5) # ohm/m due to DC resistance + skin effect, FR4 PCB, 3 mm wide trace (50 ohm Zo)
G(f) = (0.064e-11)*f   # dielectric losses RG58
#G(f) = (6.0e-11)*f   # dielectric losses FR4
Vp = vf*c    # phase velocity in transmission line
fl4 = Vp/(4*len)  # lambda/4 frequency of transmission line
print gprintf("Frequency at which length of coax is lambda/4: %.0f Hz", fl4)
beta(f) = w(f)/Vp
alfa(f) = (Res(f)/Zo + G(f)*Zo)/2.0   # low loss: valid for R<<wL, G<<wC
gamma_prop(f) = alfa(f) + j*beta(f)   # propagation constant of the transmission line
att(f) = 20*log10(exp(1))*alfa(f)*100   # attenuation in dB/100m
print gprintf("Line attenuation at 100 MHz: %.1f dB/100m", att(1e8))
# end of transmission line definition


# Define the load circuit at coax end (Zl)
C = 13e-12
L = 10e-6
R = 1e6 # 50.0
#Yl(f) = 1.0/R + (j*w(f)*C) #+ 1.0/(R+j*w(f)*L) #+ 1.0/220
#Zl(f) = 1.0/Yl(f)
Zl(f) = R #+j*w(f)*L
# end of load circuit
gamma_Zl(f) = (Zl(f)-Zo)/(Zl(f)+Zo)  # reflection coefficient at load


# calculate Zin at coax input
gamma_Zin(f) = gamma_Zl(f) * exp(-2*gamma_prop(f)*len)
Zin(f) = Zo * (1.0+gamma_Zin(f)) / (1.0-gamma_Zin(f))

# An impedance Z can be connected in parallel with the transmission line input
# Zeq is the equivalent impedance seen by the VNA at its output port
# Zeq can be only Zin (the coax) or combined with another load Z (in parallel or series)
#L1 = 45e-9
#R1 = 50.0
#C1 = 4.7e-9
#Zamp(f) = R1 #+ j*w(f)*L1 + 1.0/(j*w(f)*C1) 
#Yeq(f) = 1.0/Zin(f) + 1.0/Zamp(f) 
#Zeq(f) = j*w(f)*L1 + 1.0/Ya(f)
Zeq(f) = Zin(f)
#Zeq(f) = 1.0/Yeq(f)

# Reflection coefficient S11 (gamma as seen by VNA)
gamma_VNA(f) = (Zeq(f)-Zs)/(Zeq(f)+Zs)
# Transfer funtion at VNA output (or circuit output) (ie, at Zeq): V(Zeq)/Vs
Vratio_Zeq(f) = (1.0+gamma_VNA(f))/2
# Transfer function between coax output and input (ie, at Zl): V(Zl)/V(Zeq)
Vratio_coax(f) = (1.0+gamma_Zl(f))/(1.0+gamma_Zin(f)) * exp(-gamma_prop(f)*len)
# Transfer function at coax output (ie, at Zl): V(Zl)/Vs
Vratio_Zl(f) = Vratio_Zeq(f) * Vratio_coax(f)

# Select transfer function for graphic plot
H(f) = Vratio_Zl(f) 
Heq(f) = Vratio_Zeq(f) 

# define complex Fourier series coefficients
N = 30  # number of frequencies to sum in the signal
array Ck[N]
# define input signal: a square wave of duty cycle delta, amplitude 0 or 1, frequency freq
if (!exists("freq")) freq = 10e6   # fundamental frequency of input signal
if (!exists("delta")) delta = 0.5  # duty cicle
period = 1.0/freq

Ck0 = delta
do for [k=1:N] { 
        Ck[k] = delta*sinc(k*delta)*exp(-j*pi*k*delta)
}
# Apply LPF to square wave to reduce Gibbs effect
LPF(f) = 1.0/(1+j*f/(10*freq))  # 3 dB frequency of filter is 10 times the input signal frequency 
do for [k=1:N] { 
        Ck[k] = Ck[k]*LPF(k*freq)
}

# calculate input signal input(t), signal at Zeq middle(t), signal at Zl output(t)
input(t) = Ck0 + sum [k=1:N] 2*real(Ck[k]*exp(j*k*w(freq)*t))
middle(t) = Ck0*Heq(0) + sum [k=1:N] 2*real(Ck[k]*Heq(k*freq)*exp(j*k*w(freq)*t))
output(t) = Ck0*H(0) + sum [k=1:N] 2*real(Ck[k]*H(k*freq)*exp(j*k*w(freq)*t))

# draw plots
set title "input vs. output"
set key noautotitles
set grid
f_label = sprintf("f=%.1f MHz   Zo=%d ohm  vf=%.2f len=%.2f m", freq/1e6, Zo, vf, len)
set label 1 f_label at graph 0.05,1.03
set xrange [0:2*period]
set yrange [-0.7:1.2]
set xtics border nomirror out scale 1,0.1 0.2*period
set ytics axis in scale 0.1,0.1 0.1
set xlabel "time"

plot input(t) title "input", middle(t) title "middle"  lc rgb 'dark-grey', output(t) title "output" lc rgb 'blue' 


set title "frequency response"
unset label 1
set xtics axis in scale 0.5,0.1 10
set ytics border out scale 0.1,0.1 0.1
set xrange [0:300]
set yrange [0:1.5]
set xlabel "Frequency in MHz"

plot abs(H(t*1e6)) title "output", abs(Heq(t*1e6)) title "middle"



