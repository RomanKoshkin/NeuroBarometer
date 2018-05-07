function Z = mapminmax_c(x, a, b)
    for i = 1:size(x,1)
        Z(i,:) = ((x(i,:) - min(x(i,:)))./(max(x(i,:))-min(x(i,:))))*(b-a)+a;
    end
end