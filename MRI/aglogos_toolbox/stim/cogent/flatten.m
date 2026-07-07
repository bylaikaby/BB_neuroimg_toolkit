

function r = flatten(m)

    [rows cols] = size(m);
    
    q = [];
    
    for i = 1:rows
       
        q = [q m(i,:)];
        
    end

    r = q;

end