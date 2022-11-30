function f = Sdwdz(wF,RhoF,S,dXdxIF,JC)
% formula (41)
NF=size(wF,2);
M=size(wF,1);
f=zeros(size(wF));

for i = 2:NF-1
  for j=1:M
    f(j,i,:) = 1.0./RhoF(j,i,:)...
      .*(((S(j,i+1,:).*dXdxIF(j,i+1,:,2,2)+S(j,i,:).*dXdxIF(j,i,:,2,2))...
      .*(wF(j,i+1,:)+wF(j,i,:))...
      -(S(j,i-1,:).*dXdxIF(j,i-1,:,2,2)+S(j,i,:).*dXdxIF(j,i,:,2,2))...
      .*(wF(j,i-1,:)+wF(j,i,:)))...
      ./(2.0*(JC(j,i-1,:)+JC(j,i,:)))...
      -wF(j,i,:).*(S(j,i+1,:).*dXdxIF(j,i+1,:,2,2)-S(j,i-1,:).*dXdxIF(j,i-1,:,2,2))...
      ./((JC(j,i-1,:)+JC(j,i,:))));
  end
end
i=1;
for j=1:M
  f(j,i,:) = 1.0./RhoF(j,i,:)...
    .*(((S(j,i+1,:).*dXdxIF(j,i+1,:,2,2)+S(j,i,:).*dXdxIF(j,i,:,2,2))...
    .*(wF(j,i+1,:)+wF(j,i,:))...
    )...
    ./(4.0*(JC(j,i,:)))...
    -wF(j,i,:).*(S(j,i+1,:).*dXdxIF(j,i+1,:,2,2))...
    ./(2.0*(JC(j,i,:))));
end
end

