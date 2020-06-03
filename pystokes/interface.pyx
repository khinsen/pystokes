cimport cython
from libc.math cimport sqrt
from cython.parallel import prange
cdef double PI = 3.14159265359
import numpy as np
cimport numpy as np


@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
@cython.wraparound(False)
cdef class Rbm:
    """
    Rigid body motion (RBM)
    
    ...

    Parameters
    ----------
    radius: float
        Radius of the particles.    
    particles: int
        Number of particles 
    viscosity: viscosity of the fluid 
    Examples
    --------
    An example of the RBM

    """


    def __init__(self, radius=1, particles=1, viscosity=1.0):
        self.a   = radius
        self.Np  = particles
        self.eta = viscosity
        self.mu  = 1.0/(6*PI*self.eta*self.a)

        self.Mobility = np.zeros( (3*self.Np, 3*self.Np), dtype=np.float64)

    cpdef mobilityTT(self, double [:] v, double [:] r, double [:] F, double ll=0):
        cdef int i, j, Np=self.Np, xx=2*Np
        cdef double dx, dy, dz, idr, idr3, idr5, Fdotidr, h2, hsq, tempF
        cdef double vx, vy, vz, F1, F2, F3
        cdef double mu = 1.0/(6*PI*self.eta*self.a), mu1 = mu*self.a*0.75, a2=self.a*self.a/3.0
        cdef double ll1 = (1-ll)/(1+ll), ll2 = ll/(1+ll);

        for i in prange(Np, nogil=True):
            vx=0; vy=0; vz=0;
            for j in range(Np):
                dx = r[i]    - r[j]
                dy = r[i+Np]  - r[j+Np]
                h2  =  2*r[j+xx]; hsq=r[j+xx]*r[j+xx]
                if i!=j:
                    dz = r[i+xx]  - r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3=idr*idr*idr
                    Fdotidr = (F[j] * dx + F[j+Np] * dy + F[j+xx] * dz)*idr*idr
                    #
                    vx += (F[j]   +Fdotidr*dx)*idr + a2*(2*F[j]   -6*Fdotidr*dx)*idr3
                    vy += (F[j+Np]+Fdotidr*dy)*idr + a2*(2*F[j+Np]-6*Fdotidr*dy)*idr3
                    vz += (F[j+xx]+Fdotidr*dz)*idr + a2*(2*F[j+xx]-6*Fdotidr*dz)*idr3

                    ##contributions from the image
                    F1 = ll1*F[j];   F2 = ll1*F[j+Np];   F3 = -F[j+xx];
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr
                    idr5 = idr3*idr*idr
                    Fdotidr = ( F1*dx + F2*dy + F3*dz )*idr*idr
                    vx += (F1+Fdotidr*dx)*idr + a2*(2*F1-6*Fdotidr*dx)*idr3
                    vy += (F2+Fdotidr*dy)*idr + a2*(2*F2-6*Fdotidr*dy)*idr3
                    vz += (F3+Fdotidr*dz)*idr + a2*(2*F3-6*Fdotidr*dz)*idr3

                    tempF  = -F[j+xx]     # F_i = M_ij F_j, reflection of the strength
                    Fdotidr = ( F[j]*dx + F[j+Np]*dy + tempF*dz )*idr*idr

                    vx += ll2*(-h2*(dz*(F[j]   - 3*Fdotidr*dx) + tempF*dx)*idr3)
                    vy += ll2*(-h2*(dz*(F[j+Np]- 3*Fdotidr*dy) + tempF*dy)*idr3)
                    vz += ll2*(-h2*(dz*(tempF  - 3*Fdotidr*dz) + tempF*dz)*idr3 + h2*Fdotidr*idr)

                    vx += ll2*(hsq*( 2*F[j]   - 6*Fdotidr*dx )*idr3)
                    vy += ll2*(hsq*( 2*F[j+Np]- 6*Fdotidr*dy )*idr3)
                    vz += ll2*(hsq*( 2*tempF  - 6*Fdotidr*dz )*idr3)

                    vx += ll2*(12*a2*dz*( dz*F[j]   - 5*dz*Fdotidr*dx + 2*tempF*dx )*idr5)
                    vy += ll2*(12*a2*dz*( dz*F[j+Np]- 5*dz*Fdotidr*dy + 2*tempF*dy )*idr5)
                    vz += ll2*(12*a2*dz*( dz*tempF  - 5*dz*Fdotidr*dz + 2*tempF*dz )*idr5)

                    vx += ll2*(-h2*6*a2*(dz*F[j]   -5*Fdotidr*dx*dz + tempF*dx)*idr5)
                    vy += ll2*(-h2*6*a2*(dz*F[j+Np]-5*Fdotidr*dy*dz+ tempF*dy)*idr5)
                    vz += ll2*(-h2*6*a2*(dz*tempF  -5*Fdotidr*dz*dz + tempF*dz)*idr5 -6*a2*h2*Fdotidr*idr3)
                else:
                    ''' self contribution from the image point'''
                    F1 = ll1*F[j];   F2 = ll1*F[j+Np];   F3 = -F[j+xx];
                    dz = r[i+xx] + r[j+xx]; dx=0; dy=0
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr
                    idr5 = idr3*idr*idr
                    Fdotidr = ( F1*dx + F2*dy + F3*dz )*idr*idr
                    vx += (F1+Fdotidr*dx)*idr + a2*(2*F1-6*Fdotidr*dx)*idr3
                    vy += (F2+Fdotidr*dy)*idr + a2*(2*F2-6*Fdotidr*dy)*idr3
                    vz += (F3+Fdotidr*dz)*idr + a2*(2*F3-6*Fdotidr*dz)*idr3

                    tempF  = -F[j+xx]     # F_i = M_ij F_j, reflection of the strength
                    Fdotidr = ( F[j]*dx + F[j+Np]*dy + tempF*dz )*idr*idr

                    vx += ll2*(-h2*(dz*(F[j]   - 3*Fdotidr*dx) + tempF*dx)*idr3)
                    vy += ll2*(-h2*(dz*(F[j+Np]- 3*Fdotidr*dy) + tempF*dy)*idr3)
                    vz += ll2*(-h2*(dz*(tempF  - 3*Fdotidr*dz) + tempF*dz)*idr3 + h2*Fdotidr*idr)

                    vx += ll2*(hsq*( 2*F[j]   - 6*Fdotidr*dx )*idr3)
                    vy += ll2*(hsq*( 2*F[j+Np]- 6*Fdotidr*dy )*idr3)
                    vz += ll2*(hsq*( 2*tempF  - 6*Fdotidr*dz )*idr3)

                    vx += ll2*(12*a2*dz*( dz*F[j]   - 5*dz*Fdotidr*dx + 2*tempF*dx )*idr5)
                    vy += ll2*(12*a2*dz*( dz*F[j+Np]- 5*dz*Fdotidr*dy + 2*tempF*dy )*idr5)
                    vz += ll2*(12*a2*dz*( dz*tempF  - 5*dz*Fdotidr*dz + 2*tempF*dz )*idr5)

                    vx += ll2*(-h2*6*a2*(dz*F[j]   -5*Fdotidr*dx*dz + tempF*dx)*idr5)
                    vy += ll2*(-h2*6*a2*(dz*F[j+Np]-5*Fdotidr*dy*dz+ tempF*dy)*idr5)
                    vz += ll2*(-h2*6*a2*(dz*tempF  -5*Fdotidr*dz*dz + tempF*dz)*idr5 -6*a2*h2*Fdotidr*idr3)

            v[i  ]  += mu*F[i]    + mu1*vx
            v[i+Np] += mu*F[i+Np] + mu1*vy
            v[i+xx] += mu*F[i+xx] + mu1*vz
        return


    cpdef mobilityTR(self, double [:] v, double [:] r, double [:] T, double ll=0):
        cdef int Np = self.Np, i, j, xx=2*Np
        cdef double dx, dy, dz, idr, idr3, rlz, Tdotidr, h2,
        cdef double vx, vy, vz, T1, T2, T3
        cdef double mu1 = 1/(8*PI*self.eta)
        cdef double ll1 = (1-ll)/(1+ll), ll2 = ll/(1+ll);

        for i in prange(Np, nogil=True):
            vx=0; vy=0; vz=0;
            for j in range(Np):
                dx = r[i]   - r[j]
                dy = r[i+Np] - r[j+Np]
                h2 = 2*r[i+xx]
                if i != j:
                    #contributions from the source
                    dz = r[i+xx] - r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr

                    vx += (T[j+Np]*dz - T[j+xx]*dy )*idr3
                    vy += (T[j+xx]*dx - T[j]   *dz )*idr3
                    vz += (T[j]   *dy - T[j+Np]*dx )*idr3

                    #contributions from the image
                    T1 = T[j];
                    T2 = T[j+Np]
                    T3 = -T[j+2*Np];
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr

                    vx += (T2*dz - T3*dy )*idr3
                    vy += (T3*dx - T1*dz )*idr3
                    vz += (T1*dy - T2*dx )*idr3

                    #rlz = (dx*T[j+Np] - dy*T[j])*idr*idr
                    #vx += ll2*(h2*(T[j+Np]-3*rlz*dx) + 6*dz*dx*rlz)*idr3
                    #vy += ll2*(h2*(-T[j]  -3*rlz*dy) + 6*dz*dy*rlz)*idr3
                    #vz += ll2*(h2*(       -3*rlz*dz) + 6*dz*dz*rlz)*idr3
                else:
                    ''' the self contribution from the image point'''
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/dz
                    idr3 = idr*idr*idr
                    T1 = T[j];
                    T2 = T[j+Np]

                    vx += (T2*dz )*idr3
                    vy += (-T1 *dz )*idr3

                    #vx += ll2*h2*T[j+Np]*idr3
                    #vy += -ll2*h2*T[j]*idr3

            v[i]    -= mu1*vx
            v[i+Np] -= mu1*vy
            v[i+xx] -= mu1*vz
        return


    cpdef propulsionT2s(self, double [:] v, double [:] r, double [:] S, double ll=0):
        cdef int Np=self.Np, i, j, xx=2*Np, xx1=3*Np , xx2=4*Np
        cdef double dx, dy, dz, idr, idr2, idr3, idr5, idr7, aidr2, trS, h2, hsq
        cdef double sxx, syy, szz, sxy, syx, syz, szy, sxz, szx, srr, srx, sry, srz
        cdef double Sljrlx, Sljrly, Sljrlz, Sljrjx, Sljrjy, Sljrjz
        cdef double vx, vy, vz, mus =(28.0*self.a**3)/24

        for i in prange(Np, nogil=True):
            vx=0; vy=0;   vz=0;
            for j in  range(Np):
                h2 = 2*r[j+xx]; hsq = r[j+xx]*r[j+xx];
                sxx = S[j]  ; syy = S[j+Np]; szz = -sxx-syy;
                sxy = S[j+xx]; syx = sxy;
                sxz = S[j+xx1]; szx = sxz;
                syz = S[j+xx2]; szy = syz;
                dx = r[i]   - r[j]
                dy = r[i+Np] - r[j+Np]
                if i!=j:
                    dz = r[i+xx] - r[j+xx]
                    idr  = 1.0/sqrt( dx*dx + dy*dy + dz*dz );
                    idr2 = idr*idr; idr3 = idr2*idr; idr5 = idr3*idr2; idr7 = idr5*idr2;
                    srx = (sxx*dx +  sxy*dy + sxz*dz );
                    sry = (sxy*dx +  syy*dy + syz*dz );
                    srz = (sxz*dx +  syz*dy + szz*dz );
                    srr = sxx*dx*dx + syy*dy*dy + szz*dz*dz + 2*sxy*dx*dy + 2*sxz*dx*dz + 2*syz*dy*dz;

                    ## contributions from the source
                    vx += 3*srr*dx*idr5;
                    vy += 3*srr*dy*idr5;
                    vz += 3*srr*dz*idr5;

                    ## contributions from the image
                    dz = r[i+xx]+r[j+xx]
                    idr  = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr2 = idr*idr; idr3 = idr2*idr; idr5 = idr3*idr2; idr7 = idr5*idr2;

                    #reflecting the first index of stresslet, S_jl M_lm
                    sxz=-sxz; syz=-syz; szz=-szz;     trS=sxx+syy+szz;
                    Sljrlx = sxx*dx +  sxy*dx + sxz*dx ;
                    Sljrly = syx*dy +  syy*dy + syz*dy ;
                    Sljrlz = szx*dz +  szy*dz + szz*dz ;
                    Sljrjx = sxx*dx +  sxy*dy + sxz*dz ;
                    Sljrjy = syx*dx +  syy*dy + syz*dz ;
                    Sljrjz = szx*dx +  szy*dy + szz*dz ;
                    srr = (sxx*dx*dx + syy*dy*dy + szz*dz*dz +  2*sxy*dx*dy)*idr2 ;
                    #srx = sxy*dx + sxy*dy + szz*dz # old most probably wrong
                    srx = sxx*dx + sxy*dy + sxz*dz
                    sry = syx*dx + syy*dy + syz*dz
                    srz = sxz*dx + syz*dy + szz*dz

                    vx += (Sljrlx - Sljrjx - trS*dx + 3*srr*dx)*idr3
                    vy += (Sljrly - Sljrjy - trS*dy + 3*srr*dy)*idr3
                    vz += (Sljrlz - Sljrjz - trS*dz + 3*srr*dz)*idr3

                    #vx += -2*(dz*(sxz-3*srz*dx*idr2)+ szz*dx)*idr3;
                    #vy += -2*(dz*(syz-3*srz*dy*idr2)+ szz*dy)*idr3;
                    #vz += -2*(dz*(szz-3*srz*dz*idr2)+ szz*dz - srz)*idr3;
                    #
                    #vx += h2*( sxz-3*srz*dx*idr2)*idr3;#? h2
                    #vy += h2*( syz-3*srz*dy*idr2)*idr3;
                    #vz += h2*( szz-3*srz*dz*idr2)*idr3;
                    #
                    ##reflecting both the indices of stresslet, S_jl M_lm M_jk
                    #szx = -szx ; syz = -syz; szz = -szz;
                    #srx = (sxx*dx +  sxy*dy + sxz*dz )
                    #sry = (sxy*dx +  syy*dy + syz*dz )
                    #srz = (sxz*dx +  syz*dy + szz*dz )
                    #srr = (sxx*dx*dx + syy*dy*dy + szz*dz*dz + 2*sxy*dx*dy + 2*sxz*dx*dz + 2*syz*dy*dz)*idr2;
                    #
                    #vx += h2*( (dz*(-6*srx + 15*srr*dx)-3*srz*dx)*idr5 + (sxz)*idr3) ;
                    #vy += h2*( (dz*(-6*sry + 15*srr*dy)-3*srz*dy)*idr5 + (syz)*idr3) ;
                    #vz += h2*( (dz*(-6*srz + 15*srr*dz)-3*srz*dz)*idr5 + (szz + 3*srr)*idr3);

                    #vx += hsq*(12*srx - 30*srr*dx)*idr5
                    #vy += hsq*(12*sry - 30*srr*dy)*idr5
                    #vz += hsq*(12*srz - 30*srr*dz)*idr5

                else:
                    ''' the self contribution from the image point'''
                    dz = r[i+xx]+r[j+xx]
                    idr  = 1.0/dz
                    idr2 = idr*idr; idr3 = idr2*idr; idr5 = idr3*idr2; idr7 = idr5*idr2;

                    #reflecting the first index of stresslet, S_jl M_lm
                    sxz=-sxz; syz=-syz; szz=-szz;     trS=sxx+syy+szz;

                    Sljrlz = szx*dz +  szy*dz + szz*dz ;
                    Sljrjx = sxz*dz
                    Sljrjy = syz*dz
                    Sljrjz = szz*dz
                    srr = szz;
                    srx = szz*dz;
                    sry = syz*dz;
                    srz = szz*dz;

                    vx += -Sljrjx*idr3 ;
                    vy += -Sljrjy*idr3 ;
                    vz += (Sljrlz - Sljrjz - trS*dz +3*srr*dz)*idr3 ;

                    #vx += -2*(dz*(sxz))*idr3;
                    #vy += -2*(dz*(syz))*idr3;
                    #vz += -2*(dz*(szz-3*srz*dz*idr2)+ szz*dz - srz)*idr3;
                    #
                    #vx += h2*sxz*idr3;
                    #vy += h2*syz*idr3;
                    #vz += h2*( szz-3*srz*dz*idr2)*idr3;
                    #
                    ##reflecting both the indices of stresslet, S_jl M_lm M_jk
                    #szx = -szx ; syz = -syz; szz = -szz;
                    #srx = sxz*dz;
                    #sry = syz*dz;
                    #srz = szz*dz;
                    #
                    #vx += h2*(dz*(-6*srx )*idr5 + (sxz)*idr3) ;
                    #vy += h2*(dz*(-6*sry )*idr5 + (syz)*idr3) ;
                    #vz += h2*((dz*(-6*srz + 15*srr*dz)-3*srz*dz)*idr5 + (4*szz)*idr3);

                    #vx += hsq*12*srx*idr5
                    #vy += hsq*12*sry*idr5
                    #vz += hsq*(12*srz - 30*szz*dz)*idr5

            v[i]    += vx*mus
            v[i+Np] += vy*mus
            v[i+xx] += vz*mus
        return


    cpdef propulsionT3t(self, double [:] v, double [:] r, double [:] D, double ll=0):
        cdef int Np=self.Np, i, j, xx=2*Np
        cdef double dx, dy, dz, idr, idr3, idr5, Ddotidr, tempD, hsq, h2, D1, D2, D3
        cdef double vx, vy, vz, mud = 3.0*self.a*self.a*self.a/5, mu1 = -1.0*(self.a**5)/10
        cdef double ll1 = (1-ll)/(1+ll), ll2 = ll/(1+ll);

        for i in prange(Np, nogil=True):
            vx=0; vy=0; vz=0;
            for j in range(Np):
                dx = r[i]    - r[j]
                dy = r[i+Np]  - r[j+Np]
                h2  =  2*r[j+xx]
                if i!=j:
                    dz = r[i+xx] - r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3=idr*idr*idr
                    Ddotidr = (D[j]*dx + D[j+Np]*dy + D[j+xx]*dz)*idr*idr
                    #
                    vx += (2*D[j]    - 6*Ddotidr*dx)*idr3
                    vy += (2*D[j+Np] - 6*Ddotidr*dy)*idr3
                    vz += (2*D[j+xx] - 6*Ddotidr*dz)*idr3

                    ##contributions from the image
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr
                    idr5 = idr3*idr*idr
                    D1 = D[j];
                    D2 = D[j+Np]
                    D3 = -D[j+2*Np];
                    Ddotidr = (D1*dx + D2*dy + D3*dz)*idr*idr

                    vx += (2*D1 - 6*Ddotidr*dx )*idr3
                    vy += (2*D2 - 6*Ddotidr*dy )*idr3
                    vz += (2*D3 - 6*Ddotidr*dz )*idr3

                    #tempD = -D[j+xx]     # D_i = M_ij D_j, reflection of the strength
                    #Ddotidr = ( D[j]*dx + D[j+Np]*dy + tempD*dz )*idr*idr
                    #
                    #vx += 12*dz*( dz*D[j]   - 5*dz*Ddotidr*dx + 2*tempD*dx )*idr5
                    #vy += 12*dz*( dz*D[j+Np]- 5*dz*Ddotidr*dy + 2*tempD*dy )*idr5
                    #vz += 12*dz*( dz*tempD  - 5*dz*Ddotidr*dz + 2*tempD*dz )*idr5

                    #vx += -6*h2*(dz*D[j]   -5*Ddotidr*dx*dz + tempD*dx)*idr5
                    #vy += -6*h2*(dz*D[j+Np]-5*Ddotidr*dy*dz + tempD*dy)*idr5
                    #vz += -6*h2*(dz*tempD  -5*Ddotidr*dz*dz + tempD*dz)*idr5 -6*h2*Ddotidr*idr3

                else:
                    ''' self contribution from the image point'''
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/dz
                    idr3 = idr*idr*idr
                    idr5 = idr3*idr*idr
                    D1 = D[j];
                    D2 = D[j+Np]
                    D3 = -D[j+2*Np];
                    Ddotidr = D3*dz*idr*idr

                    vx += (2*D1 )*idr3
                    vy += (2*D2 )*idr3
                    vz += (2*D3 - 6*Ddotidr*dz )*idr3

                    #tempD = -D[j+xx]     # D_i = M_ij D_j, reflection of the strength
                    #Ddotidr = tempD*dz*idr*idr
                    #
                    #vx += 12*dz*( dz*D[j]   )*idr5
                    #vy += 12*dz*( dz*D[j+Np])*idr5
                    #vz += 12*dz*( dz*tempD  - 5*dz*Ddotidr*dz + 2*tempD*dz )*idr5

                    #vx += -6*h2*(dz*D[j]   )*idr5
                    #vy += -6*h2*(dz*D[j+Np])*idr5
                    #vz += -6*h2*(dz*tempD  -5*Ddotidr*dz*dz + tempD*dz)*idr5 -6*h2*Ddotidr*idr3

            v[i  ]  += mu1*vx
            v[i+Np] += mu1*vy
            v[i+xx] += mu1*vz
        return


    
    ## Angular Velocities
    cpdef mobilityRT(self, double [:] o, double [:] r, double [:] F, double ll=0):
        cdef int Np = self.Np, i, j, xx=2*Np
        cdef double dx, dy, dz, idr, idr3, rlz, Fdotidr, h2
        cdef double ox, oy, oz, mu1=1.0/(8*PI*self.eta)

        for i in prange(Np, nogil=True):
            ox=0; oy=0; oz=0;
            for j in range(Np):
                dx = r[i]   - r[j]
                dy = r[i+Np] - r[j+Np]
                h2 = 2*r[i+xx]
                if i != j:
                    #contributions from the source
                    dz = r[i+xx] - r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr

                    ox += (F[j+Np]*dz - F[j+xx]*dy )*idr3
                    oy += (F[j+xx]*dx - F[j]   *dz )*idr3
                    oz += (F[j]   *dy - F[j+Np]*dx )*idr3

                    #contributions from the image
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr
                    rlz = (dx*F[j+Np] - dy*F[j])*idr*idr

                    ox += (F[j+Np]*dz + F[j+xx]*dy )*idr3
                    oy += (-F[j+xx]*dx - F[j]   *dz )*idr3
                    oz += (F[j]   *dy - F[j+Np]*dx )*idr3

                    #ox += (h2*(F[j+Np]-3*rlz*dx) + 6*dz*dx*rlz)*idr3
                    #oy += (h2*(-F[j]  -3*rlz*dy) + 6*dz*dy*rlz)*idr3
                    #oz += (h2*(       -3*rlz*dz) + 6*dz*dz*rlz)*idr3

                else:
                    ''' the self contribution from the image point'''
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/dz
                    idr3 = idr*idr*idr

                    ox += (F[j+Np]*dz )*idr3
                    oy += (- F[j] *dz )*idr3

                    #ox += (h2*F[j+Np])*idr3
                    #oy += (h2*-F[j]  )*idr3

            o[i  ]  += mu1*ox
            o[i+Np] += mu1*oy
            o[i+xx] += mu1*oz
        return


    cpdef mobilityRR(self, double [:] o, double [:] r, double [:] T, double ll=0):
        cdef int Np=self.Np, i, j, xx=2*Np
        cdef double dx, dy, dz, idr, idr3, idr5, Tdotidr, tempT, hsq, h2
        cdef double ox, oy, oz, mut=1.0/(8*PI*self.eta*self.a**3), mu1=1.0/(8*PI*self.eta)

        for i in prange(Np, nogil=True):
            ox=0; oy=0; oz=0;
            for j in range(Np):
                dx = r[i]    - r[j]
                dy = r[i+Np]  - r[j+Np]
                h2  =  2*r[j+xx]
                if i!=j:
                    dz = r[i+xx] - r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3=idr*idr*idr
                    Tdotidr = (T[j]*dx + T[j+Np]*dy + T[j+xx]*dz)*idr*idr
                    #
                    ox += (2*T[j]    - 6*Tdotidr*dx)*idr3
                    oy += (2*T[j+Np] - 6*Tdotidr*dy)*idr3
                    oz += (2*T[j+xx] - 6*Tdotidr*dz)*idr3

                    ##contributions from the image
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr
                    idr5 = idr3*idr*idr
                    Tdotidr = (T[j]*dx + T[j+Np]*dy - T[j+xx]*dz)*idr*idr

                    ox += (2*T[j]    - 6*Tdotidr*dx )*idr3
                    oy += (2*T[j+Np] - 6*Tdotidr*dy )*idr3
                    oz += (-2*T[j+xx] - 6*Tdotidr*dz )*idr3

                    #tempT = -T[j+xx]     # D_i = M_ij D_j, reflection of the strength
                    #Tdotidr = ( T[j]*dx + T[j+Np]*dy + tempT*dz )*idr*idr
                    #
                    #ox += 12*dz*( dz*T[j]   - 5*dz*Tdotidr*dx + 2*tempT*dx )*idr5
                    #oy += 12*dz*( dz*T[j+Np]- 5*dz*Tdotidr*dy + 2*tempT*dy )*idr5
                    #oz += 12*dz*( dz*tempT  - 5*dz*Tdotidr*dz + 2*tempT*dz )*idr5

                    #ox += -6*h2*(dz*T[j]   -5*Tdotidr*dx*dz + tempT*dx)*idr5
                    #oy += -6*h2*(dz*T[j+Np]-5*Tdotidr*dy*dz + tempT*dy)*idr5
                    #oz += -6*h2*(dz*tempT  -5*Tdotidr*dz*dz + tempT*dz)*idr5 -6*h2*Tdotidr*idr3

                else:

                    ''' self contribution from the image point'''
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/dz
                    idr3 = idr*idr*idr

                    ox += 4*T[j]*idr3
                    oy += 4*T[j+Np]*idr3
                    oz += -4*T[j+xx]*idr3

            o[i  ]  += mut*T[i  ]  - mu1*ox
            o[i+Np] += mut*T[i+Np] - mu1*oy
            o[i+xx] += mut*T[i+xx] - mu1*oz
        return


    cpdef propulsionR2s(self, double [:] o, double [:] r, double [:] S, double ll=0):
        cdef int Np=self.Np, i, j, xx=2*Np, xx1=3*Np , xx2=4*Np
        cdef double dx, dy, dz, idr, idr2, idr3, idr5, idr7
        cdef double sxx, syy, szz, sxy, syx, syz, szy, sxz, szx, srr, srx, sry, srz
        cdef double Sljrlx, Sljrly, Sljrlz, Sljrjx, Sljrjy, Sljrjz, rlz, smr3, smkrk3
        cdef double ox, oy, oz, mus = (28.0*self.a**3)/24, h

        for i in prange(Np, nogil=True):
            ox=0;   oy=0;   oz=0;
            sxz = S[i+xx1];
            syz = S[i+xx2];
            for j in range(Np):
                #sxx = S[j    ]  ;
                #syy = S[j+Np ];
                #sxy = S[j+xx ];
                #sxz = S[j+xx1];
                #syz = S[j+xx2];
                if i != j:
                    pass
                    #syx = sxy;
                    # szx = sxz;
                    # szy = syz;
                    #szz = -sxx-syy;
                    #dx = r[i]   - r[j]
                    #dy = r[i+Np] - r[j+Np]
                    #h=r[j+xx]
                    #dz = r[i+xx] - r[j+xx]
                    #idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    #idr5 = idr*idr*idr*idr*idr
                    #srx = sxx*dx +  sxy*dy + sxz*dz
                    #sry = sxy*dx +  syy*dy + syz*dz
                    #srz = sxz*dx +  syz*dy - (sxx+syy)*dz

                    #ox += 3*(sry*dz - srz*dy )*idr5
                    #oy += 3*(srz*dx - srx*dz )*idr5
                    #oz += 3*(srx*dy - sry*dx )*idr5
                    #
                    ####contributions from the image
                    #dz = r[i+xx] + r[j+xx]
                    #idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    #idr2=idr*idr
                    #idr3 = idr2*idr
                    #idr5 = idr3*idr2
                    #
                    #rlz = (dx*syz - dy*sxz)*idr*idr
                    #ox += (2*syz  - 6*rlz*dx)*idr3
                    #oy += (-2*sxz - 6*rlz*dy)*idr3
                    #oz += (       - 6*rlz*dz)*idr3
                    #
                    ###reflecting the second index of stresslet, S_jl M_lm
                    #sxz=-sxz; syz=-syz; szz=-szz;
                    #
                    #smr3 = sxz*dy-syz*dx
                    #ox += 6*(dz*(sxx*dy-syx*dx) + smr3*dx)*idr5
                    #ox += 6*(dz*(sxy*dy-syy*dx) + smr3*dy)*idr5
                    #oz += 6*(dz*(sxz*dy-syz*dx) + smr3*dz)*idr5

                    #Sljrjx = sxx*dx +  sxy*dy + sxz*dz ;
                    #Sljrjy = syx*dx +  syy*dy + syz*dz ;
                    #Sljrjz = szx*dx +  szy*dy + szz*dz ;
                    #srr = (sxx*dx*dx + syy*dy*dy + szz*dz*dz +  2*sxy*dx*dy)*idr2 ;
                    #
                    #ox += 2*syz*idr3 - 3*(Sljrjy*dz - Sljrjz*dy)*idr5
                    #oy += 2*szx*idr3 - 3*(Sljrjz*dx - Sljrjx*dz)*idr5
                    #oz +=              3*(Sljrjx*dy - Sljrjy*dx)*idr5
                    #
                    #smkrk3 = 30*(dx*Sljrjy-dy*Sljrjx)*idr5*idr2
                    #ox += (h+dz)*smkrk3*dx
                    #ox += (h+dz)*smkrk3*dy
                    #oz += (h+dz)*smkrk3*dz

                    #ox += 2*syz*idr3  - 3*(Sljrjy*dz - Sljrjz*dy )*idr5
                    #oy += -2*szy*idr3 - 3*(Sljrjz*dx - Sljrjx*dz )*idr5
                    #oz +=             - 3*(Sljrjx*dy - Sljrjy*dx )*idr5
                    #
                    #ox += 6*h*(-Sljrjy + (sxx*dy-syx*dx))*idr5
                    #oy += 6*h*(Sljrjx  + (sxy*dy-syy*dx))*idr5
                    #ox +=                (sxz*dy-syz*dx)*idr5
                else:
                    ### self contributions from the image
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/dz
                    idr3 = idr*idr*idr
                    ox += -8*( syz)*idr3
                    oy += -8*(-sxz)*idr3
                    ##reflecting the second index of stresslet, S_jl M_lm
                    #sxz=-sxz; syz=-syz; szz=-szz;
                    #
                    #Sljrjx = sxz*dz ;
                    #Sljrjy = syz*dz ;
                    #Sljrjz = szz*dz ;
                    #srr = szz*dz*dz*idr2 ;
                    #
                    #ox += 2*syz*idr3 - 3*(Sljrjy*dz)*idr5
                    #oy += 2*szx*idr3 - 3*(- Sljrjx*dz)*idr5
                    #
                    #smkrk3 = 30*(dx*Sljrjy-dy*Sljrjx)*idr5*idr2
                    #oz += (h+dz)*smkrk3*dz

                    #ox += 2*syz*idr3  - 3*(Sljrjy*dz )*idr5
                    #oy += -2*szy*idr3 - 3*(- Sljrjx*dz )*idr5
                    #
                    #ox += 6*h*(-Sljrjy )*idr5
                    #oy += 6*h*(Sljrjx  )*idr5

            o[i]    += ox
            o[i+Np] += oy
#            o[i+xx] += oz
        return



    ## Noise
    cpdef calcNoiseMuTT(self, double [:] v, double [:] r):
        cdef int i, j, Np=self.Np, xx=2*Np
        cdef double dx, dy, dz, idr, h2, hsq, idr2, idr3, idr4, idr5
        cdef double mu=self.mu, mu1=2*mu*self.a*0.75, a2=self.a*self.a/3.0
        cdef double vx, vy, vz, mm=1/(.75*self.a)

        cdef double [:, :] M = self.Mobility
        cdef double [:]    Fr = np.random.normal(size=3*Np)


        for i in prange(Np, nogil=True):
            for j in range(Np):
                dx = r[i]    - r[j]
                dy = r[i+Np] - r[j+Np]
                h2=2*r[j+xx]; hsq=r[j+xx]*r[j+xx]
                if i!=j:
                    dz = r[i+xx] - r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr2=idr*idr;  idr3=idr*idr*idr
                    dx = dx*idr; dy=dy*idr; dz=dz*idr
                    #
                    M[i,    j   ] = (1 + dx*dx)*idr + a2*(2 - 6*dx*dx)*idr3
                    M[i+Np, j+Np] = (1 + dy*dy)*idr + a2*(2 - 6*dy*dy)*idr3
                    M[i+xx, j+xx] = (1 + dz*dz)*idr + a2*(2 - 6*dz*dz)*idr3
                    M[i,    j+Np] = (    dx*dy)*idr + a2*(  - 6*dx*dy)*idr3
                    M[i,    j+xx] = (    dx*dz)*idr + a2*(  - 6*dx*dz)*idr3
                    M[i+Np, j+xx] = (    dy*dz)*idr + a2*(  - 6*dy*dz)*idr3

                    ###contributions from the image
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    dx = dx*idr; dy=dy*idr; dz=dz*idr
                    idr2=idr*idr;  idr3=idr2*idr;

                    M[i,    j   ] += (1 + dx*dx)*idr + a2*(2 - 6*dx*dx)*idr3
                    M[i+Np, j+Np] += (1 + dy*dy)*idr + a2*(2 - 6*dy*dy)*idr3
                    M[i+xx, j+xx] +=-(1 + dz*dz)*idr - a2*(2 - 6*dz*dz)*idr3
                    M[i,    j+Np] += (    dx*dy)*idr + a2*(  - 6*dx*dy)*idr3
                    M[i,    j+xx] +=-(    dx*dz)*idr - a2*(  - 6*dx*dz)*idr3
                    M[i+Np, j+xx] +=-(    dy*dz)*idr - a2*(  - 6*dy*dz)*idr3

                else:
                    # one-body mobility
                    M[i,    j   ] = mm
                    M[i+Np, j+Np] = mm
                    M[i+xx, j+xx] = mm
                    M[i,    j+Np] = 0
                    M[i,    j+xx] = 0
                    M[i+Np, j+xx] = 0

                    ##self contribtion from the image point
                    dz = r[i+xx] + r[j+xx]
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    dx = dx*idr; dy=dy*idr; dz=dz*idr
                    idr2=idr*idr;  idr3=idr2*idr

                    M[i,    j   ] += (1 + dx*dx)*idr + a2*(2 - 6*dx*dx)*idr3
                    M[i+Np, j+Np] += (1 + dy*dy)*idr + a2*(2 - 6*dy*dy)*idr3
                    M[i+xx, j+xx] +=-(1 + dz*dz)*idr - a2*(2 - 6*dz*dz)*idr3
                    M[i,    j+Np] += (    dx*dy)*idr + a2*(  - 6*dx*dy)*idr3
                    M[i,    j+xx] +=-(    dx*dz)*idr - a2*(  - 6*dx*dz)*idr3
                    M[i+Np, j+xx] +=-(    dy*dz)*idr - a2*(  - 6*dy*dz)*idr3

        for i in prange(Np, nogil=True):
            for j in range(Np):
                M[i,    j   ] = mu1*M[i,    j   ]
                M[i+Np, j+Np] = mu1*M[i+Np, j+Np]
                M[i+xx, j+xx] = mu1*M[i+xx, j+xx]
                M[i,    j+Np] = mu1*M[i,    j+Np]
                M[i,    j+xx] = mu1*M[i,    j+xx]
                M[i+Np, j+xx] = mu1*M[i+Np, j+xx]

                M[i+Np, j   ] =     M[i,    j+Np]
                M[i+xx, j   ] =     M[i,    j+xx]
                M[i+xx, j+Np] =     M[i+Np, j+xx]

        cdef double [:, :] L = np.linalg.cholesky(self.Mobility)

        for i in prange(Np, nogil=True):
            vx=0; vy=0; vz=0;
            for j in range(Np):
                vx += L[i   , j]*Fr[j] + L[i   , j+Np]*Fr[j+Np] + L[i   , j+xx]*Fr[j+xx]
                vy += L[i+Np, j]*Fr[j] + L[i+Np, j+Np]*Fr[j+Np] + L[i+Np, j+xx]*Fr[j+xx]
                vz += L[i+xx, j]*Fr[j] + L[i+xx, j+Np]*Fr[j+Np] + L[i+xx, j+xx]*Fr[j+xx]
            v[i  ]  += vx
            v[i+Np] += vy
            v[i+xx] += vz

        #'''to check the one-body solution near a plane wall'''
        #muPerp = mu*(1 - 9*self.a/(8*r[2]) + 0.5*(self.a/r[2])**3 ),
        #muParl = mu*(1 - 9*self.a/(16*r[2]) + 0.125*(self.a/r[2])**3 )
        #print self.Mobility/sqrt(2), muParl, muPerp  # note that there is a factor of sqrt(2)
        return




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class Flow:
    """
    Flow at given points
    
    ...

    Parameters
    ----------
    radius: float
        Radius of the particles.    
    particles: int
        Number of particles 
    viscosity: viscosity of the fluid 
    gridpoints: int 
        Number of grid points

    Examples
    --------
    An example of the RBM

    """

    def __init__(self, radius=1, particles=1, viscosity=1, gridpoints=32):
        self.a  = radius
        self.Np = particles
        self.Nt = gridpoints
        self.eta= viscosity


    cpdef flowField1s(self, double [:] vv, double [:] rt, double [:] r, double [:] F):
        cdef int i, j, Np=self.Np, Nt=self.Nt, xx=2*Np
        cdef double dx, dy, dz, idr, idr3, idr5, Fdotidr, tempF, hsq, h2, F3
        cdef double vx, vy, vz, mu1=1.0/(8*PI*self.eta), a2=self.a*self.a/6.0

        for i in prange(Nt, nogil=True):
            vx=0; vy=0; vz=0;
            for j in range(Np):
                h2  =  2*r[j+xx]; hsq=r[j+xx]*r[j+xx]
                dx = rt[i]    - r[j]
                dy = rt[i+Nt] - r[j+Np]
                dz = rt[i+2*Nt]  - r[j+xx]
                idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                idr3=idr*idr*idr
                idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                idr3=idr*idr*idr
                Fdotidr = (F[j] * dx + F[j+Np] * dy + F[j+xx] * dz)*idr*idr
                #
                vx += (F[j]   +Fdotidr*dx)*idr + a2*(2*F[j]   -6*Fdotidr*dx)*idr3
                vy += (F[j+Np]+Fdotidr*dy)*idr + a2*(2*F[j+Np]-6*Fdotidr*dy)*idr3
                vz += (F[j+xx]+Fdotidr*dz)*idr + a2*(2*F[j+xx]-6*Fdotidr*dz)*idr3

                ##contributions from the image
                dz = rt[i+2*Nt] + r[j+xx]
                idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                idr3 = idr*idr*idr
                idr5 = idr3*idr*idr 

                F3 = -F[j+xx]
                Fdotidr = ( F[j]*dx + F[j+Np]*dy + F3*dz )*idr*idr

                vx += (F[j]   +Fdotidr*dx)*idr - a2*(2*F[j]   -6*Fdotidr*dx)*idr3
                vy += (F[j+Np]+Fdotidr*dy)*idr - a2*(2*F[j+Np]-6*Fdotidr*dy)*idr3
                vz += (F3     +Fdotidr*dz)*idr - a2*(2*F3     -6*Fdotidr*dz)*idr3

            vv[i  ]    += mu1*vx
            vv[i+Nt]   += mu1*vy
            vv[i+2*Nt] += mu1*vz
            #with gil:
            #    print vv[i+xx]
        return 
    
    cpdef flowField2a(  self, double [:] vv, double [:] rt, double [:] r, double [:] T):
        cdef int Np = self.Np, i, j, xx=2*Np, Nt=self.Nt
        cdef double dx, dy, dz, idr, idr3, rlz, Tdotidr, h2, 
        cdef double vx, vy, vz, mu1 = 1.0/(8*PI*self.eta)
 
        for i in prange(Np, nogil=True):
            vx=0; vy=0; vz=0;
            for j in range(Np):
                dx = rt[i]   - r[j]   
                dy = rt[i+Nt] - r[j+Np]   
                h2 = 2*rt[i+xx]
                if i != j:
                    #contributions from the source 
                    dz = rt[i+2*Nt] - r[j+xx] 
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr
                     
                    vx += (T[j+Np]*dz - T[j+xx]*dy )*idr3
                    vy += (T[j+xx]*dx - T[j]   *dz )*idr3
                    vz += (T[j]   *dy - T[j+Np]*dx )*idr3
                        
                    #contributions from the image 
                    dz = r[i+2*Nt] + r[j+xx]            
                    idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                    idr3 = idr*idr*idr
                    
                    vx += -(T[j+Np]*dz - T[j+xx]*dy )*idr3
                    vy += -(T[j+xx]*dx - T[j]   *dz )*idr3
                    vz += -(T[j]   *dy - T[j+Np]*dx )*idr3
                    
                    rlz = (dx*T[j+Np] - dy*T[j])*idr*idr
                    vx += (h2*(T[j+Np]-3*rlz*dx) + 6*dz*dx*rlz)*idr3
                    vy += (h2*(-T[j]  -3*rlz*dy) + 6*dz*dy*rlz)*idr3
                    vz += (h2*(       -3*rlz*dz) + 6*dz*dz*rlz)*idr3
                else:
                    ''' the self contribution from the image point''' 
                    dz = r[i+2*Nt] + r[j+xx]            
                    idr = 1.0/dz
                    idr3 = idr*idr*idr
                    
                    vx += -(T[j+Np]*dz )*idr3
                    vy += -(- T[j] *dz )*idr3
                    
                    vx += h2*T[j+Np]*idr3
                    vy += -h2*T[j]*idr3

            vv[i  ]  += mu1*vx 
            vv[i+Nt] += mu1*vy
            vv[i+2*Nt] += mu1*vz
        return 
    
   
    cpdef flowField2s(self, double [:] vv, double [:] rt, double [:] r, double [:] S):
        cdef int Np=self.Np,  Nt=self.Nt, xx=2*Np, xx1=3*Np, xx2=4*Np
        cdef int i, j  
        cdef double dx, dy, dz, idr, idr2, idr3, idr5, idr7, aidr2, trS, h2, hsq
        cdef double sxx, syy, szz, sxy, syx, syz, szy, sxz, szx, srr, srx, sry, srz
        cdef double Sljrlx, Sljrly, Sljrlz, Sljrjx, Sljrjy, Sljrjz 
        cdef double vx, vy, vz, mus = (28.0*self.a**3)/24 

        for i in prange(Nt, nogil=True):
            vx=0; vy=0; vz=0;
            for j in  range(Np):
                sxx = S[j]  ; syy = S[j+Np]; szz = -sxx-syy;
                sxy = S[j+xx]; syx = sxy;
                sxz = S[j+xx1]; szx = sxz;
                syz = S[j+xx2]; szy = syz;
                
                dx = rt[i]   - r[j]
                dy = rt[i+Nt] - r[j+Np]
                dz = rt[i+2*Nt] - r[j+xx] 
                h2 = 2*r[j+xx]; hsq = r[j+xx]*r[j+xx];
                idr  = 1.0/sqrt( dx*dx + dy*dy + dz*dz );
                idr2 = idr*idr; idr3 = idr2*idr; idr5 = idr3*idr2; idr7 = idr5*idr2;
                srx = (sxx*dx +  sxy*dy + sxz*dz ); 
                sry = (sxy*dx +  syy*dy + syz*dz );
                srz = (sxz*dx +  syz*dy + szz*dz );
                srr = sxx*dx*dx + syy*dy*dy + szz*dz*dz + 2*sxy*dx*dy + 2*sxz*dx*dz + 2*syz*dy*dz;
                
                ## contributions from the source 
                vx += 3*srr*dx*idr5;
                vy += 3*srr*dy*idr5;
                vz += 3*srr*dz*idr5;
                 
                ## contributions from the image 
                dz = rt[i+2*Nt]+r[j+xx]
                idr  = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                idr2 = idr*idr; idr3 = idr2*idr; idr5 = idr3*idr2; idr7 = idr5*idr2;
                
                #reflecting the first index of stresslet, S_jl M_lm
                sxz=-sxz; syz=-syz; szz=szz;     trS=sxx+syy+szz; 
                Sljrlx = sxx*dx +  sxy*dx + sxz*dx ; 
                Sljrly = syx*dy +  syy*dy + syz*dy ;
                Sljrlz = szx*dz +  szy*dz + szz*dz ;
                Sljrjx = sxx*dx +  sxy*dy + sxz*dz ; 
                Sljrjy = syx*dx +  syy*dy + syz*dz ;
                Sljrjz = szx*dx +  szy*dy + szz*dz ;
                srr = (sxx*dx*dx + syy*dy*dy + szz*dz*dz +  2*sxy*dx*dy)*idr2 ;
                srx = sxx*dx + syx*dy+szx*dz;
                sry = sxy*dx + syy*dy+szy*dz;
                srz = sxz*dx + syz*dy+szz*dz;
                
                vx += -(-Sljrlx + Sljrjx + trS*dx -3*srr*dx)*idr3 ;
                vy += -(-Sljrly + Sljrjy + trS*dy -3*srr*dy)*idr3 ;
                vz += -(-Sljrlz + Sljrjz + trS*dz -3*srr*dz)*idr3 ;
                
            vv[i  ]    += mus*vx
            vv[i+Nt]   += mus*vy
            vv[i+2*Nt] += mus*vz

   
    cpdef flowField3t(self, double [:] vv, double [:] rt, double [:] r, double [:] D):
        cdef int i, j, Np=self.Np, Nt=self.Nt, xx=2*Np
        cdef double dx, dy, dz, idr, idr3, idr5, Ddotidr, tempD, hsq, h2, D3
        cdef double vx, vy, vz, mud = 3.0*self.a*self.a*self.a/5, mu1 = -1.0*(self.a**5)/10

        for i in prange(Nt, nogil=True):
            vx=0; vy=0; vz=0;
            for j in range(Np):
                h2 = 2*r[j+xx]; hsq = r[j+xx]*r[j+xx];
                dx = rt[i]      - r[j]
                dy = rt[i+Nt]   - r[j+Np]
                dz = rt[i+2*Nt] - r[j+xx] 
                idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                idr3=idr*idr*idr
                Ddotidr = (D[j]*dx + D[j+Np]*dy + D[j+xx]*dz)*idr*idr
                #
                vx += (2*D[j]    - 6*Ddotidr*dx)*idr3
                vy += (2*D[j+Np] - 6*Ddotidr*dy)*idr3
                vz += (2*D[j+xx] - 6*Ddotidr*dz)*idr3
                
                ##contributions from the image 
                dz = rt[i+2*Nt] + r[j+xx]        
                idr = 1.0/sqrt( dx*dx + dy*dy + dz*dz )
                idr3 = idr*idr*idr
                idr5 = idr3*idr*idr 
                D3 = -D[j+xx]
                Ddotidr = (D[j]*dx + D[j+Np]*dy + D3*dz)*idr*idr
                
                vx += (2*D[j]    - 6*Ddotidr*dx )*idr3
                vy += (2*D[j+Np] - 6*Ddotidr*dy )*idr3
                vz += (2*D3      - 6*Ddotidr*dz )*idr3

            vv[i  ]    += mu1*vx
            vv[i+Nt]   += mu1*vy
            vv[i+2*Nt] += mu1*vz
        return 
    
    
