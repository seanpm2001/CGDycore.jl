function dPresdTh(RhoTh,Param)
p=Param.Rd*(Param.Rd*RhoTh/Param.p0).^(Param.kappa/(1-Param.kappa));
return p
end
