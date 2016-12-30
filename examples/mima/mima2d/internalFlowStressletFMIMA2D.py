from __future__ import division
import numpy as np
import pystokes
import matplotlib.pyplot as plt

#parameters
dim, a, Np = 2, 25, 1
Nx, Ny = 128, 128
Lx, Ly = 128, 128

# memory allocation
v = np.zeros(dim*Nx*Ny); 
p = np.zeros(dim*Np); 
S = np.zeros(2*Np); 
r = np.zeros(dim*Np); 

# Initialise
r[0], r[1] = Nx/2 , Nx/2 
p[:Np] = 1
r[Np:2*Np]=Ny/2
S[:Np] = p[:Np]*p[:Np] -0.5
S[Np:2*Np] = p[:Np]*p[Np:2*Np]

mFlow = pystokes.mima2D.Flow(a, Np, Lx, Ly, Nx, Ny);
mFlow.stressletV(v, r, p, )

vx = v[0:Nx*Ny       ].reshape(Nx, Ny)
vy = v[Nx*Ny:2*Nx*Ny ].reshape(Nx, Ny)


x, y = np.meshgrid(range(Nx), range(Ny) )
plt.figure()
rx = r[0:Np]
ry = r[Np:2*Np]
plt.pcolor(x, y, np.sqrt(vx*vx + vy*vy), cmap=plt.cm.gray)
plt.colorbar()
plt.hold('on')
plt.plot(rx, ry, marker='o', markerfacecolor='y', markersize=8 ) 
plt.streamplot(x, y, vx, vy, density=2, color=[0.8,0.8,0.8], arrowstyle='->', arrowsize =1.5)
plt.xlim([0, Lx-1])
plt.ylim([0, Ly-1])
plt.show() 
