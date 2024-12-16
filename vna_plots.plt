# GNUplot script to simulate a VNA (or circuit) connected to a coax ended by a load

set terminal qt size 900,740 persist
set multiplot layout 3,1 title "VNA measurement of transmission line"
set parametric
set dummy fm  # frequency in MHz, this is the parametric variable
unset key
unset border
set samples 20000

j = {0.0,1.0}  # imaginary unit
c = 299792458.0  # speed of light in vacuum (m/s)
Zs = 50.0   # output impedance of VNA; the output voltage equivalent is Vs

# Define a transmission line, followed by a load Zl
Zo = 50.0   # characteristic impedance of transmission line
vf = 0.66   # velocity factor of coax
len = 1.10  # length of coax in m
#Res(f) = 15.38*((f/1e9)**0.482)   # ohm/m due to skin effect, twisted cable, https://ieeexplore.ieee.org/document/917765
Res(f) = 0.1 + 4.9*((f/1e9)**0.5)   # ohm/m due to DC resistance + skin effect, RG58
#Res(f) = 0.17 + 2.5*((f/1e9)**0.5) # ohm/m due to DC resistance + skin effect, FR4 PCB, 3 mm wide trace (50 ohm Zo)
G(f) = (0.064e-11)*f   # dielectric losses RG58
#G(f) = (6.0e-11)*f   # dielectric losses FR4
Vp = vf*c    # phase velocity in coax
fl4 = Vp/(4*len)  # lambda/4 frequency of transmission line
print gprintf("Frequency at which length of coax is lambda/4: %.0f Hz", fl4)
w(f) = 2*pi*f
beta(f) = w(f)/Vp
alfa(f) = (Res(f)/Zo + G(f)*Zo)/2.0   # low loss: valid for R<<wL, G<<wC
gamma_prop(f) = alfa(f) + j*beta(f)   # propagation constant of the transmission line
att(f) = 20*log10(exp(1))*alfa(f)*100   # attenuation in dB/100m
print gprintf("Line attenuation at 100 MHz: %.1f dB/100m", att(1e8))
# end of transmission line definition


# Define the load circuit at coax end (Zl)
C = 13e-12
L = 50e-9
R = 50.0 # 1e6
Yl(f) = 1.0/R + (j*w(f)*C) #+ 1.0/j*w(f)*L
Zl(f) = 1.0/Yl(f)
# end of load circuit
gamma_Zl(f) = (Zl(f)-Zo)/(Zl(f)+Zo)  # reflection coefficient at load

# calculate Zin at coax input
gamma_Zin(f) = gamma_Zl(f) * exp(-2*gamma_prop(f)*len)
Zin(f) = Zo * (1.0+gamma_Zin(f)) / (1.0-gamma_Zin(f))

# An impedance Z can be connected in parallel with the transmission line input
# Zeq is the equivalent impedance seen by the VNA at its output port 
# Zeq can be only Zin (the coax) or combined with another load Z (in parallel or series)
L1 = 23e-9
R1 = 5000 
C1 = 68e-12
#Zamp(f) = 50.0  #j*w(f)*L1 + 1.0/(j*w(f)*C1) + R1
#Yamp(f) = 1.0/R1 #+ j*w(f)*C1
#Yeq(f) = Yamp(f) + 1.0/Zin(f)
#Yeq(f) = 1.0/R1 + j*w(f)*C1 
#Zeq(f) = j*w(f)*L1 + 1.0/Ya(f)
Zeq(f) = Zin(f)
#Zeq(f) = 1.0/Yeq(f)

# Reflection coefficient S11 (gamma as seen by VNA)
gamma_VNA(f) = (Zeq(f)-Zs)/(Zeq(f)+Zs)
# Transfer funtion at VNA output (or circuit output) (at Zeq): V(Zeq)/Vs
Vratio_Zeq(f) = (1.0+gamma_VNA(f))/2
# Transfer function between coax output and input (at Zl): V(Zl)/V(Zeq)
Vratio_coax(f) = (1.0+gamma_Zl(f))/(1.0+gamma_Zin(f)) * exp(-gamma_prop(f)*len)
# Transfer function at coax output (at Zl): V(Zl)/Vs
Vratio_Zl(f) = Vratio_Zeq(f) * Vratio_coax(f)

# Transfer function for Vratio_Zl in MHz
H(f) = Vratio_Zl(f*1e6) 


# Print coax values
imp = sprintf("Zo = %d ohm", Zo)
set label imp at first 2,0.5
imp = sprintf("Zs = %d ohm", Zs)
set label imp at first 3,0.5
vf = sprintf("v. factor = %.2f", vf)
set label vf at first 2,0.3
len_str = sprintf("length = %.2f m", len)
set label len_str at first 2,0.1


# Plot Smith Chart
set title "Smith Chart" 
set size ratio 1 0.35,0.35
set zeroaxis
#set style data lines
unset xtics
unset ytics
set xrange [-1.0:1.0] 
set yrange [-1.0:1.0]

plot [0:300] real(gamma_VNA(fm*1e6)), imag(gamma_VNA(fm*1e6)),\
 fm<2*pi?cos(fm):1/0, fm<2*pi?sin(fm):1/0 lt rgb "black" dt 2 lw 1

unset label

# Plot phase plot
set title "Phase of S11" offset graph -0.35,0
set size noratio 
set size nosquare
set xtics axis in scale 1,0.1 10
set ytics axis in scale 0.1,0.1 30
set xrange [0:*]
set yrange [-180:180]
set xlabel "Frequency in MHz"
plot [0:300] fm, 180/pi*arg(gamma_VNA(fm*1e6))
#plot [0:300] fm, 180/pi*arg(Vratio_Zeq(fm*1e6))
#plot [0:100] fm, abs(Zin(fm*1e6))
#plot [0:500] fm, 180/pi*(arg(H(fm)))


# Plot Bode plot
set title "Bode plot" offset graph -0.35,0
set size noratio 
set size nosquare
set ytics axis in scale 0.1,0.1 0.2 
set xtics axis in scale 1,0.1 10 
set xrange [0:*]
set yrange [0:1]
set xlabel "Frequency in MHz"
set grid
#plot [0:300] fm, abs(Vratio_Zeq(fm*1e6))
plot [0:300] fm, abs(H(fm)) 




