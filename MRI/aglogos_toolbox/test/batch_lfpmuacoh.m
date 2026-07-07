pfunc = @seslfpmuacoh;
pfunc = @sesplotlfpmuacoh;
pfunc = @sesfitlfpmuacoh;


pfunc = @seslfpmuacor;

%FUNC{01} = @seslfpmuakc;
%FUNC{02} = @seslfpmuacont;

FUNC{01} = @seslfpmuacont;
%FUNC{01} = @sesplotlfpmuacont;

for iFunc = 1:length(FUNC),
  pfunc = FUNC{iFunc};

  pfunc('c98nm1','movie1','cor');
  pfunc('c98nm1','movie2','cor');
  %pfunc('c98nm1','movie3','cor');
  %pfunc('c98nm1','movie4','cor');

  pfunc('g97nm1','movie1','cor');
  %pfunc('g97nm1','movie2','cor');
  %pfunc('g97nm1','movie3','cor');


  %pfunc('c98nm1','movie1','mi');
  %pfunc('c98nm1','movie2','mi');
  %pfunc('c98nm1','movie3','mi');
  %pfunc('c98nm1','movie4','mi');

  %pfunc('g97nm1','movie1','mi');
  %pfunc('g97nm1','movie2','mi');
  %pfunc('g97nm1','movie3','mi');

  
  pfunc('c98nm1','movie1','kc');
  pfunc('c98nm1','movie2','kc');
  pfunc('c98nm1','movie3','kc');
  %pfunc('c98nm1','movie4','kc');
  %%pfunc('c98nm1','spont1');

  pfunc('g97nm1','movie1','kc');
  % MUST RUN LATER, NO-DECORR
  %pfunc('g97nm1','movie2','kc');
  %pfunc('g97nm1','movie3','kc');
  close all
  continue;

  %pfunc = @sesplotlfpmuacor;
  %pfunc('c98nm1','movie1');
  %pfunc('c98nm1','movie2');
  %pfunc('c98nm1','movie3');
  %pfunc('c98nm1','movie4');
  %%pfunc('c98nm1','spont1');

  pfunc('r97nm1','movie1');
  pfunc('r97nm1','movie2');
  pfunc('r97nm1','movie3');
  pfunc('r97nm1','movie4');

  pfunc('b02nm2','movie1');
  pfunc('b02nm2','movie2');
  pfunc('b02nm2','movie3');
  pfunc('b02nm2','movie4');
  pfunc('b02nm2','movie5');


  pfunc('g02nm1','movie1');
  pfunc('g02nm1','movie2');
  pfunc('g02nm1','movie3');

  pfunc('s02nm1','movie1');
  pfunc('s02nm1','movie2');
  pfunc('s02nm1','movie3');
  pfunc('s02nm1','movie4');

  pfunc('g97nm1','movie1');
  pfunc('g97nm1','movie2');
  pfunc('g97nm1','movie3');

  pfunc('c98nm3','movie1');
  pfunc('c98nm3','movie2');
  pfunc('c98nm3','movie3');
  
  close all;
end




