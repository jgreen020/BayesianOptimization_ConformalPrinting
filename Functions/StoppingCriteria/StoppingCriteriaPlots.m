function [] = StoppingCriteriaPlots(x, y, n_star, crit)
    bottom = 1e-8;

    hold on
    plot(x, y,...
        'Color',[0 0.4470 0.7410], 'LineStyle','-','LineWidth',2)
    plot([n_star n_star], [bottom, crit],...
        'r--', 'LineWidth', 2);
    yline(crit, 'r--', 'LineWidth', 2);
    set(gca,'YScale','log')
    % set(gca,'XScale','log')
    text(n_star, 3*bottom, [' \leftarrow n^* = ' num2str(n_star)], ...
                                'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                                'FontSize', 12, 'Color', 'r', 'Rotation', 0);
    xlim([min(x) max(x)]);  % Start x-axis at number of initial sampling points
    ylim([bottom 1e2])
    % legend('Metric','n*','Critical Value',...
    %        'NumColumns',1,'Location','eastoutside') 
    xlabel('Number of Points (n)')
    ylabel('Metric Value (mm)')
    title('Ideal Error Convergence')
    grid on 
end

