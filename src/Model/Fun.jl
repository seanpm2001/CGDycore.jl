function FunProjectC!(c,f,X,CG)
  OrdPoly = CG.OrdPoly
  Nz = size(c,1)
  NF = size(c,2)
  for iF 1 : NF
    for iz = 1 : nz  
      for i = 1 : OrdPoly  
        for j = 1 : OrdPoly  
          x=0.5*(X[i,j,1,1,iz,iF]+X[i,j,2,1,iz,iF])  
          y=0.5*(X[i,j,1,2,iz,iF]+X[i,j,2,2,iz,iF])  
          z=0.5*(X[i,j,1,3,iz,iF]+X[i,j,2,3,iz,iF])  
          c[iz,iF] = f(x,y,z)
        end
      end
    end
  end
end

function FunProjectF!(c,f,X)
  OPx = size(c,1)
  OPy = size(c,2)
  for i = 1 : OPx
    for j = 1 : OPy
      c[i,j] = f(X[i,j,1],X[i,j,2],X[i,j,3])
    end
  end
end

function uFun(x,y,z)
  f = sin(pi*x)*sin(pi*z)
end
function DxuFun(x,y,z)
# f=sin(pi*x)*sin(pi*z)
  Dxf = pi*cos(pi*x)*sin(pi*z)
end
function DzuFun(x,y,z)
# f=sin(pi*x)*sin(pi*z)
  Dzf = pi*sin(pi*x)*cos(pi*z)
end  

function vFun(x,y,z)
  f = 0.0
end

function wFun(x,y,z)
  f=sin(2*pi*x)*sin(2*pi*z)
end
function DxwFun(x,y,z)
# f=sin(2*pi*x)*sin(2*pi*z)
  Dxf=2*pi*cos(2*pi*x)*sin(2*pi*z)
end
function DzwFun(x,y,z)
# f=sin(2*pi*x)*sin(2*pi*z)
  Dzf=2*pi*sin(2*pi*x)*cos(2*pi*z)
end

function RhoFun(x,y,z)
  f=sin(2*pi*x)*sin(2*pi*z) + 1.0
end
function DxRhoFun(x,y,z)
# f=sin(2*pi*x)*sin(2*pi*z) + 1.0
  Dxf=2*pi*cos(2*pi*x)*sin(2*pi*z)
end
function DzRhoFun(x,y,z)
# f=sin(2*pi*x)*sin(2*pi*z) + 1.0
  Dzf=2*pi*sin(2*pi*x)*cos(2*pi*z)
end

function DivFun(x,y,z)
# Div f
# d/dx (sin(pi*x)*sin(pi*z)*(sin(2*pi*x)*sin(2*pi*z) + 1.0) +
# d/dz (sin(2*pi*x)*sin(2*pi*z)*(sin(2*pi*x)*sin(2*pi*z) + 1.0)

  u = uFun(x,y,z)
  Dxu = DxuFun(x,y,z)
  w = wFun(x,y,z)
  Dzw = DzwFun(x,y,z)
  Rho = RhoFun(x,y,z)
  DxRho = DxRhoFun(x,y,z)
  DzRho = DzRhoFun(x,y,z)
  return -(Dxu + Dzw) * Rho - u * DxRho - w * DzRho
end

function GradZKin(x,y,z)
#  Kin = 0.5*(uFun*uFun+wFun*wFun)
  u = uFun(x,y,z)
  Dzu = -DzuFun(x,y,z)
  w = wFun(x,y,z)
  Dzw = -DzwFun(x,y,z)
  return u * Dzu + w *Dzw
end   

function GradXKin(x,y,z)
#  Kin = 0.5*(uFun*uFun+wFun*wFun)
  u = uFun(x,y,z)
  Dxu = -DxuFun(x,y,z)
  w = wFun(x,y,z)
  Dxw = -DxwFun(x,y,z)
  return u * Dxu + w *Dxw
end

function Curly(x,y,z)
#  Curly = (Dxw,-Dzu)
  Dzu = DzuFun(x,y,z)
  Dxw = DxwFun(x,y,z)
  return Dxw-Dzu
end

function AdvuMom(x,y,z)
#  w*Curly
  w = wFun(x,y,z)
  Curl = Curly(x,y,z)
  return w*Curl
end

function AdvwMom(x,y,z)
# u*Curly
  u = uFun(x,y,z)
  Curl = Curly(x,y,z)
  return -u*Curl
end


