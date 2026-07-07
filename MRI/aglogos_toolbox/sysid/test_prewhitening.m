%TEST_PREWHITENING - Testing whether prewhittening works
%
s = sin(0:0.01:10); s= s(:);
x = s + 2*(rand(size(x))-0.5)+0.1;
y = circshift(s,10) + 2*(rand(size(x))-0.5)+0.1;
[c lags] = xcov(y,x,40,'coef'); plot(lags,c)



s = sin(0:0.1:100); s= s(:);
x = s + 2*(rand(size(s))-0.5)+0.1;
y = circshift(s,10) + 2*(rand(size(s))-0.5)+0.1;
[c lags] = xcov(y,x,40,'coef'); plot(lags,c)
[ir R CL] = cra([y(:) x(:)],20,100,0); plot(ir)
[ir R CL] = cra([y(:) x(:)],20,0,0); plot(ir)
[ir R CL] = cra([y(:) x(:)],20,5,0); plot(ir)
[ir R CL] = cra([y(:) x(:)],20,10,0); plot(ir)

[ir R CL] = cra([y(:) x(:)],20,10,0); plot([0:length(ir)-1],ir)
hold on;
[c lags] = xcov(y,x,40,'coef'); plot(lags,c)
close all
[ir R CL] = cra([y(:) x(:)],40,5,0); plot([0:length(ir)-1],ir)
hold on;
[c lags] = xcov(y,x,40,'coef'); plot(lags,c)
set(gca,'xlim',[0 40])
