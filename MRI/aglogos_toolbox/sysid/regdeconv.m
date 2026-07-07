function  [x,errt,regt]=regdeconv(y, h,lambda,regstyle,x_support,varargin) 
%regularized deconvolution using a know impulse response function 
%the objective function is
% ||y-h*x||²+||Lx||²
%where L is a regularization operator
%
% syntax	 [x,errt,regt]=regdeconv(y, h,lambda,regstyle,cutborder)
%
%  inputs
%
%	y - input signal vector 
%
%	h - impulse response
%
%	lambda - regularization coefficient (the bigest the larger the
%	regularization)
%
%	regstyle - regularization operator type: 
%                 'minnorm' euclidian norm
%                 'deriv' derivative
%                 'sin' discrete derivative
%                 'cos' discrete laplacian
%
%  outputs
%
%	x - deconvolved signal
%
%	errt - residual error signal y-h*x
%
%	regt - penalty signal L x
%
%
% Author : Michel Besserve, MPI for Biological Cybernetics, Tuebingen, GERMANY
Rescale=0;
lambda2=.1;
cutborder=0;
if nargin<4
    regstyle='minnorm';
end

for karg=1:2:length(varargin)
	 switch lower(varargin{karg})
	 case 'lambda2'
		lambda2=varargin{karg+1};
	 otherwise
 		 error('unknown input argument n %d',karg)
	 end
end

switch cutborder
    case 1
        Lx=length(y)-length(h)+1;  
    otherwise
        Lx=length(y);
end%
Lx2=Lx;%pow2(nextpow2(Lx));    % Find smallest power of 2 that is > Lx
Y=fft(y, Lx2);		   % Fast Fourier transform
H=fft(h, Lx2);		   % Fast Fourier transform

switch regstyle
    case 'debias'
           n=size(y,1);
            %old version using fft: slow%%%%%%%%%%%
            %            Psi = ifft(eye(n));
            %             Ki= fft(eye(n));
            %             %convolution operator in the time domain
            %             Hmat= (Psi*diag(fft(h))*Ki);
            %new version using toeplitz: fast%%%%%%%%%%%
            Hmat=toeplitz(h,circshift(flipud(h),1));
            Hmatred=Hmat(:,x_support);
            
            x=0*y;
            x(x_support)=inv(Hmatred'*Hmatred+lambda2*eye(size(Hmatred,2)))*Hmatred'*y;
            X=fft(x,Lx2);
            errt=Y-H.*X;
            regt=X;
       case 'sparsecvx'
          
           n=size(y,1);
           Psi = ifft(eye(n));
            Ki= fft(eye(n));
            %convolution operator in the time domain
            Hmat= real(Psi*diag(fft(h))*Ki);
            %regularized deconvolution operator
            HHreg= real(Psi*diag(1./(abs(fft(h)).^2+lambda2))*Ki);
            u=cvxboundqp(lambda/4*HHreg,-y'*Hmat*HHreg,-1,1);
            x=HHreg*Hmat'*y-lambda/2*HHreg*u;
            X=fft(x,Lx2);
            errt=Y-H.*X;
            regt=X;
     case 'sparsesra'
          
           n=size(y,1);
           
        %old version using fft: slow%%%%%%%%%%%
            %Psi = ifft(eye(n));
            %Ki= fft(eye(n));
            
            %convolution operator in the time domain
            %  Hmat= real(Psi*diag(fft(h))*Ki);

            %regularized deconvoltion operator
            %HHreg= real(Psi*diag(1./(abs(fft(h)).^2+lambda2))*Ki);
            
            
        %new version using toeplitz: fast%%%%%%%%%%%
            Hmat=toeplitz(h,circshift(flipud(h),1));
            hreg=real(ifft(1./(abs(fft(h)).^2+lambda2)));
            HHreg= toeplitz(hreg,circshift(flipud(hreg),1));
           
            opt=getopts;
            out=l1reg(@lsdeconv_penalty,{y,Hmat,lambda2},HHreg*Hmat'*y,lambda,opt);
            
        X=fft(out.x,Lx2);
        errt=Y-H.*X;
        regt=X;
    
    case 'sparse'
        Nite=30;
        x=0*y;
        xpast=x;
        timeoffset=hanningmb(length(y)).^2;
        FASTIMPL=1;
        for kite=1:Nite
            if FASTIMPL
                X=fft(x, Lx2);
            xresid=ifft(conj(H).*(Y-H.*X),Lx2);
            end
          for ktime=1:length(y)
              if FASTIMPL & kite>2
              if x(ktime)==0 
                  if rand(1)<.8
                      continue
                  end
              end
              else
                   X=fft(x, Lx2);
            xresid=ifft(conj(H).*(Y-H.*X),Lx2);
          
              end
            % for the moment we use with nice results lambda=.01 et
            % lamda2=0.5 (renomalization par ajout d'une ridge penalty,
            % voir friedman 2007 pour info)
            x(ktime)=soft_thres(x(ktime)+xresid(ktime),lambda./(timeoffset(ktime)+eps))/1.5;  

          end
          if std(x-xpast)/std(x) <.001
              break;
          end
          xpast=x;
        end
        X=fft(x,Lx2);
        errt=Y-H.*X;
        regt=X;
    case 'minnorm'
        X=conj(H).*Y./(lambda+abs(H).^2);        		   % 
        errt=Y-H.*X;
        regt=X;
    case 'deriv'
        freqax=(fftshift((0:(length(H)-1))*2/length(H)-1))';
      %  freqax=[0:floor(length(H)/2) -floor(length(H)/2)+1:-1]'/length(H);
        X=conj(H).*Y./(lambda*abs(2*pi*freqax).^2+abs(H).^2);  
        errt=Y-H.*X;
        regt=-1i*2*pi*freqax.*X;  
    case 'laplace'
        freqax=(fftshift((0:(length(H)-1))*2/length(H)-1))';
        X=conj(H).*Y./(lambda*abs(freqax).^2+abs(H).^2); 
    case 'sin'
        freqax=(fftshift((0:(length(H)-1))*2/length(H)-1))';
        X=conj(H).*Y./(lambda*2*(sin(pi*freqax/2)).^2+abs(H).^2);     
        errt=Y-H.*X;
        regt=(sin(pi*freqax/2)).*X;    
    case 'cos'
        freqax=(fftshift((0:(length(H)-1))*2/length(H)-1))';
        X=conj(H).*Y./(lambda*2*(1-cos(pi*freqax)).^2+abs(H).^2);     
        errt=Y-H.*X;
        regt=(1-cos(pi*freqax)).*X;
end
errt=ifft(errt,Lx2);
regt=ifft(regt,Lx2);
x=(ifft(X, Lx2));      % Inverse fast Fourier transform
% Take just the first N elements
 x=x(1:1:Lx);      
 errt=errt(1:1:Lx);  
 regt=regt(1:1:Lx);
 

% x=x/max(abs(x));           % Normalize the output
if Rescale 
   rescalpar=real(Y'*(H.*X)/((H.*X)'*(H.*X)+eps));
   x=rescalpar*x;
end
end

function u_t=soft_thres(u,t)
u_t=sign(u).*(abs(u)-t+abs(abs(u)-t))/2;
end





 