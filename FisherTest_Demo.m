counter1 = 0;
counter2 = 0;
P = 0;
for successes1 = 1:15
    counter1 = counter1 + 1;
    for successes2 = 1:15
        counter2 = counter2 + 1;
        x = [[successes1,15-successes1];[successes2,15-successes2]];
        [h,p,stats] = fishertest(x);
        P(counter1, counter2) = p;
    end
    counter2 = 0;
end
imagesc(P)
colorbar
title('Click with a cross on the tiles to see p-values')
ylabel('successes')
xlabel('failures')