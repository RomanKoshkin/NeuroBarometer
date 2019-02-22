function [t] = summarySE(dat, V1, V2)
    u = unique([dat.(V1)]);
    t = table();
    t.IV = u';
    t.M = zeros(length(u),1);
    t.SE = zeros(length(u),1);
    
    
    c = 0;
    for i = u
        c = c + 1;
        r = ismember([dat.(V1)], char(i));
        p = [dat(r).(V2)];
        t.M(c) = mean(p);
        t.SE(c) = std(p)/sqrt(length(p));
    end
        
end
