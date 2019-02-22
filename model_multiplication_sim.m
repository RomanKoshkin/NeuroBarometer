for k = 1:100
    x = [];
    for j = 1:10
        for i = 1:1000
            x(i,j) = randsample([0,1], 1, 'true', [0.30, 0.70]);
        end
    end

    for i = 1:1000
        x(i,j+1) = round(mean(x(i,1:j)));
    end

%     disp(mean(x(:,1)))
%     disp(mean(x(:,2)))
%     disp(mean(x(:,3)))
% 
%     disp(mean(x(:,j+1)))
    acc(k) = mean(x(:,j+1));
end
figure
hist(acc)