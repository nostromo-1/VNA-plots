# GNUplot script to simulate a VNA (or circuit) connected to a coax ended by a load

set terminal x11 persist size 900,750
set multiplot layout 3,1 title "VNA measurement of coax"
set parametric
unset key
unset border
set samples 20000
set dummy fm  # frequency in MHz, this is the parametric variable

j = {0.0,1.0}  # imaginary unit
c = 299792458.0  # speed of light in vacuum (m/s)

# Define a VNA (or, followed by a coax or transmission line, followed by a load
Zs = 50.0   # output impedance of VNA; the output voltage equivalt is Vs
Zo = 104.0  # characteristic impedance of coax
k = 0.50    # velocity factor of coax
len =  0.245  # lgth of coax in m
Res(f) = 15.38*((f/1e9)**0.482)   # ohm/m due to skin effect, https://ieeexplore.ieee.org/document/917765
Vp = k*c    # phase velocity in coax
fl4 = Vp/(4*len)  # lambda/4 frequency of coax
w(f) = 2*pi*f
beta(f) = w(f)/Vp
alfa(f) = Res(f)/(2.0*Zo) # Valid for G=0, R<<wL
gamma_prop(f) = alfa(f) + j*beta(f)  # propagation constant of the transmission line
# end of coax definition


# Define the load circuit at coax end (Zl)
C = 10e-12
L = 160e-9
R = 10
Yl(f) = (j*w(f)*C) #+ 1.0/(R+j*w(f)*L) + 1.0/220
Zl(f) = 1.0/Yl(f)
gammaZl(f) = (Zl(f)-Zo)/(Zl(f)+Zo)  # reflection coefficient at load
# end of load circuit

# calculate Zin at coax input
#Zin(f) = Zo * (Zl(f)+j*Zo*tan(beta(f)*l)) / (Zo+j*Zl(f)*tan(beta(f)*len))
gammaZin(f) = gammaZl(f) * exp(-2*gamma_prop(f)*len)
Zin(f) = Zo * (1.0+gammaZin(f)) / (1.0-gammaZin(f))

# Zeq is the load connected to the output of the VNA
# Zeq can be Zin (the coax) and/or another load (in parallel or series)
#Yeq(f) = 1.0/Zin(f) 
Zeq(f) = Zin(f)
#Zeq(f) = Zl(f)
#Zeq(f) = 1.0/Yeq(f)

# reflection coefficient S11 (gamma as seen by VNA)
gammaVNA(f) = (Zeq(f)-Zs)/(Zeq(f)+Zs)
# Transfer funtion at VNA output (or circuit output) (at Zeq) V(Zeq)/Vs
Vratio_Zeq(f) = (1.0+gammaVNA(f))/2
# Transfer function at coax output (at Zl) V(Zl)/Vs
Vratio_Zl(f) = Vratio_Zeq(f) * (1.0+gammaZl(f))/(1.0+gammaZin(f)) * exp(-gamma_prop(f)*len)


# Print coax values
imp = sprintf("Zo = %d ohm", Zo)
set label imp at first 2,0.5
vf = sprintf("v. factor = %.2f", k)
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

plot [0:250] real(gammaVNA(fm*1e6)), imag(gammaVNA(fm*1e6)) ,\
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
plot [0:300] fm, 180/pi*arg(gammaVNA(fm*1e6))
#plot [0:300] fm, 180/pi*(arg(Vratio_Zl(fm*1e6)*exp(j*beta(fm*1e6)*len)))


# Plot Bode plot
set title "Bode plot" offset graph -0.35,0
set size noratio 
set size nosquare
set xtics axis in scale 1,0.1 10 
set ytics axis in scale 0.1,0.1 0.2 
set xrange [0:*]
set yrange [0:1]
set xlabel "Frequency in MHz"
set grid
plot [0:300] fm, abs(Vratio_Zeq(fm*1e6))
#plot [0:300] fm, abs(Vratio_Zl(fm*1e6))



