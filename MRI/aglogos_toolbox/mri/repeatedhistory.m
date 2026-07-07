function out = repeatedhistory(numconds,reps, lookback, outputfile, bVerbose);
%REPEATEDHISTORY - generate one of each of the possible history sequences
%	function out = REPEATEDHISTORY(numconds, reps, lookback);
%	the total number of trials generated will be 
%	(numconds^(lookback+1))*reps+lookback
%	because the first lookback trials are free (no history...)
%

if nargin < 4,  outputfile = '';  end
if nargin < 5,  bVerbose   = 0;   end


numtrial=numconds^(lookback+1)+lookback;
numtrial2=(numconds^(lookback+1))*reps+lookback;
%create array of all possible combinations of trials
%of the last lookback trials
blindAlley=1;
while blindAlley==1
  clear neworder
  clear orders
  clear zoot
  clear hold
  clear out
  
  blindAlley=0;
  for allegory=0:reps-1 %go thru once per rep.
	for loopMe=0:numconds^(lookback+1)-1;
	  for zoot=1:lookback+1
		orders((numconds^(lookback+1))*allegory+(loopMe+1),...
			(lookback+2)-zoot)=mod(floor(loopMe/numconds^(zoot-1)),numconds)+1;
	  end
	end
  end
    
  %okay.  Now, first lookback trials are free (no history)
  %and as such, any number is possible
  btn=numconds;
  for zoot=1:lookback
	%pick a random number, between 0 and 1
	drand=rand;
	%multiply that number by the current number of possibilities
	%round the result to an integer
	firstOut(zoot)=floor(drand*btn)+1;
  end
  %Now.  At this point, all numconds are still available
  
  %so.  Generate a random trial condition (from 1 to numcond)
  %check to see if history sequence (i.e., the this trial plus
  %the last lookback trials) has already been used.
  %   If not available, generate a new number and re-check, etc.
  %   if it is available, then place the number at current location
  %in firstOut array.  IMPORTANT: update the orders array to reflect the
  %fact that this order/history sequence has been used!
  
  % TO SEE DETAILS REMOVE SEMI_COLON  
  toGo=[1:numconds]';
  
  %go through once for each block of history sequences
  %multiple=(numtrials/(numconds^(lookback+1)));
  %for  mallory=1:multiple
  %go through once for each possible history sequence

  loopMe=1;
  diedOnce=0;
  while loopMe<=numconds^(lookback+1)*reps
	currentTrial=loopMe+lookback;
	notYet=1;
	failure=0;	
	while notYet==1
	  drand=rand;
	  hold=toGo(floor(drand*btn)+1);
	  
	  %now do history checking
	  %get indexes to all matches of current trial
	  %then get indexes from column3 that match previous trial's value
	  %then get indexes from column2 that match two trials ago value
	  
	  clear temp;
	  clear columnNext;
	  temp=find(orders(:,lookback+1)==hold);
	  columnNext=zeros(length(temp),lookback+1);
	  columnNext(:,1)=find(orders(:,lookback+1)==hold);
	  
	  for zoot=1:lookback
		counter=1;
		for skatman=1:length(orders)
		  if(find(columnNext(:,zoot)==skatman))
			if(orders(skatman,lookback+1-zoot)==firstOut(currentTrial-zoot))
			  columnNext(counter,zoot+1)=skatman;
			  counter=counter+1;
			end
		  end
		end
	  end
	  
	 % [maude junk]=size(columnNext);
	 % if(maude>=2)
	%	if(columnNext(2,lookback+1)~=0)
	%	  %column1
	%	  %orders(column1,:)
	%	  error('Duplicate sequences in master array. This should not be possible.');
	%	end
	%  end
	  
	  %okay.  column1 should have between 1 and reps element(s) in it 
	  %(the index of this history sequence) or nothing.  
	  %  If nothing, then this sequence is not available,
	  %and we need to try again.
	  %  If there is a number there, set firstOut, and remove this
	  %sequence from the available list
	  if(columnNext(1,lookback+1)~=0) %found one
		notYet=0;
		currentTrial;
		%so that sequence can't be chosen again
		clear neworder;
		clear lastorder;
		lastorder=orders;
		[harold junk]=size(orders);
		
		
		if(harold>1)
		  neworder(1:columnNext(1,lookback+1)-1,:)=orders(1:columnNext(1,lookback+1)-1,:);
		  neworder(columnNext(1,lookback+1):harold-1,:)=orders(columnNext(1,lookback+1)+1:harold,:);
		  clear orders;
		  orders=neworder;
		end
	  else
		failure=failure+1;
		%may not be possible to complete this sequence
		%so backtrack one trial, give it another shot
		if(failure==20) 
		  if(diedOnce==1)

			%%%%% TO SEE THE NUMBER OF CUR TRIAL REMOVE SEMI_COLON
			currentTrial;
			%%%%

			orders;
			blindAlley=1;
            if bVerbose,
              display('oops...blind allay.  Trying again.');
            end
			loopMe=numconds^(lookback+1)*reps+1 ;
			notYet=0;
		  end
		  failure=0;
		  diedOnce=diedOnce+1;
		  loopMe=loopMe-1;
		  currentTrial=loopMe+lookback;
		  %replace last sequence
		  clear orders;
		  orders=lastorder;
		  toGo=members(orders(:,lookback+1));
		  btn=length(toGo);
		end
	  end
	  
	end %end the notYet while loop...have found a good trial.
	
	firstOut(currentTrial)=hold;
	loopMe=loopMe+1;
	currentTrial=loopMe+lookback;
	toGo=members(orders(:,lookback+1));
	btn=length(toGo);
	%update available numbers:
  end
end
out=firstOut';
dcgethistory(out,lookback+1);
if exist('outputfile','var') && any(outputfile),
  dlmwrite(outputfile,out,'\t');
end

