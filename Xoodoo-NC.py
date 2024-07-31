import math
from math import log2
from ast import literal_eval

class Xoodoo_NC(object):
    
    """ Input X must be in hex format"""
    
    def __init__(self, Nr):
        self.Nr = Nr
        if not Nr:
            raise ValueError("Nr must be non-zero")

    ##### Round constants #####        
        self.RC=[0x00000058,
           0x00000038,
           0x000003C0,
           0x000000D0,
           0x00000120,
           0x00000014,
           0x00000060,
           0x0000002C,
           0x00000380,
           0x000000F0,
           0x000001A0,
           0x00000012]
    
    def _hash(self,X):
        X = '{:096b}'.format(int(X))
        A=[None]*3
        A[2]=(int(X[0:32],2))
        A[1]=(int(X[32:64],2))
        A[0]=(int(X[64:96],2))

        out=[None]*3
                    
        if(self.Nr%(math.floor(self.Nr))):
            Nr_f = int(self.Nr-(self.Nr%(math.floor(self.Nr))))
            print("Nr_f=",Nr_f)
            for i in range(0,Nr_f):
                if(i==0):
                    out=self.round_xoodoo(A,self.RC[12-(Nr_f+1)+i])
                else:
                    out=self.round_xoodoo(out,self.RC[12-(Nr_f+1)+i])
            out= self.round_xoodoo_5(out,self.RC[12-(Nr_f+1)+Nr_f])
        else:
            for i in range(0,self.Nr):
                if(i==0):
                    out=self.round_xoodoo(A,self.RC[12-self.Nr+i])
                else:
                    out=self.round_xoodoo(out,self.RC[12-self.Nr+i])            

        out_bin = '{:032b}'.format(out[2]) + '{:032b}'.format(out[1]) + '{:032b}'.format(out[0])
        out_hex=hex(int(out_bin,2))
#         return out
        return out_hex
        
    
    ############ Round Function ############
    def round_xoodoo(self,A,RC):
            #theta
        P=A[0]^A[1]^A[2]
        P='{:032b}'.format(P)
        E1=P[5:32]+P[0:5]
        E2=P[14:32]+P[0:14]
        E=(int(E1,2))^(int(E2,2))

        for i in range(0,3):
            A[i]=A[i]^(E)

            #rhowest
        A[2]='{:032b}'.format(A[2])
        A[2]=A[2][11:32]+A[2][0:11]
        A[2]=int(A[2],2)

            #iota
        RC=int(RC)
        A[0]=A[0]^RC

            #chi
        B=[None]*3
        B[0]=(A[1]^0xFFFFFFFF) & (A[2])
        B[1]=(A[2]^0xFFFFFFFF) & (A[0])
        B[2]=(A[0]^0xFFFFFFFF) & (A[1])
        for i in range(0,3):
            A[i]=A[i]^B[i]

            #rhoeast
        A[1]='{:032b}'.format(A[1])
        A[1]=A[1][1:32]+A[1][0:1]
        A[1]=int(A[1],2)

        A[2]='{:032b}'.format(A[2])
        A[2]=A[2][8:32]+A[2][0:8]
        A[2]=int(A[2],2)

        return A
    
    def round_xoodoo_5(self,A,RC):
        P=A[0]^A[1]^A[2]
        P='{:032b}'.format(P)
        E1=P[5:32]+P[0:5]
        E2=P[14:32]+P[0:14]
        E=(int(E1,2))^(int(E2,2))

        for i in range(0,3):
            A[i]=A[i]^(E)

        A[2]='{:032b}'.format(A[2])
        A[2]=A[2][11:32]+A[2][0:11]
        A[2]=int(A[2],2)

        RC=int(RC)
        A[0]=A[0]^RC

        B=[None]*3
        B[0]=(A[1]^0xFFFFFFFF) & (A[2])
        B[1]=(A[2]^0xFFFFFFFF) & (A[0])
        B[2]=(A[0]^0xFFFFFFFF) & (A[1])
        for i in range(0,3):
            A[i]=A[i]^B[i]

        return A
