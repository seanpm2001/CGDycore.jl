function [X,J,dXdx]=JacobiCart(ksi,eta,F,Grid)
n1=size(ksi,1);
n2=size(eta,2);
X=zeros(n1,n2,3);
X(:,:,1)=0.25*(F.P(1,1).*(1-ksi)*(1-eta)+...
  F.P(1,2).*(1+ksi)*(1-eta)+...
  F.P(1,3).*(1+ksi)*(1+eta)+...
  F.P(1,4).*(1-ksi)*(1+eta));
X(:,:,2)=0.25*(F.P(2,1).*(1-ksi)*(1-eta)+...
  F.P(2,2).*(1+ksi)*(1-eta)+...
  F.P(2,3).*(1+ksi)*(1+eta)+...
  F.P(2,4).*(1-ksi)*(1+eta));
X(:,:,3)=0;

dXdx=zeros(n1,n2,2,2);

dXdx(:,:,1,1)=0.25*(-F.P(1,1)+F.P(1,2)+...
  F.P(1,3)-F.P(1,4)+...
  ( F.P(1,1)-F.P(1,2)+...
  F.P(1,3)-F.P(1,4))*(ones(n1,1)*eta));
dXdx(:,:,1,2)=0.25*(-F.P(1,1)-F.P(1,2)+...
  F.P(1,3)+F.P(1,4)+...
  ( F.P(1,1)-F.P(1,2)+...
  F.P(1,3)-F.P(1,4))*(ksi*ones(1,n2)));
dXdx(:,:,2,1)=0.25*(-F.P(2,1)+F.P(2,2)+...
  F.P(2,3)-F.P(2,4)+...
  ( F.P(2,1)-F.P(2,2)+...
  F.P(2,3)-F.P(2,4))*(ones(n1,1)*eta));
dXdx(:,:,2,2)=0.25*(-F.P(2,1)-F.P(2,2)+...
  F.P(2,3)+F.P(2,4)+...
  ( F.P(2,1)-F.P(2,2)+...
  F.P(2,3)-F.P(2,4))*(ksi*ones(1,n2)));
J=dXdx(:,:,1,1).*dXdx(:,:,2,2)-dXdx(:,:,1,2).*dXdx(:,:,2,1);
end

