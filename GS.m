filtering_audio = 1;
len_win_clas = 30;
counter = 0;
output = struct()
for lambda = 0.01:0.01:0.1
    for en = 50:50:1000
        counter = counter + 1;
        [a_suc, u_suc] = grid_search(lambda, len_win_clas, en, filtering_audio);
        output(counter).a_suc = a_suc;
        output(counter).u_suc = u_suc;
        output(counter).lambda = lambda;
        output(counter).en = en;
        output(counter).filt = filtering_audio;
        output(counter).len_win_clas = len_win_clas;
        save('output_grid.mat', 'output')
    end
end